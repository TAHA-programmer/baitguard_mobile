# BaitGuard Firebase Realtime Database (RTDB) Telemetry & Events Integration

This document defines the architecture, data models, schema mappings, security rules, and verification checklist for the Firebase Realtime Database integration in the BaitGuard Flutter mobile application.

---

## 1. Executive Summary & Pilot Scope

The BaitGuard mobile application consumes live telemetry and detection events from pilot hardware deployed at facilities:

- **Pilot Station ID**: `station_01`
- **Pilot Facility / Site ID**: `site_1`
- **Default RTDB Instance URL**: `https://bait-guard-6f470-default-rtdb.firebaseio.com/`

### Strict Boundaries & Constraints
- **Hardware-Managed Telemetry**: All telemetry writes, refills, battery percentages, and raw detections are published directly by the field hardware (e.g. ESP32). The mobile client operates as a **read-only observer**. Mutating operations on station telemetry (such as recording refills or mutating events) throw `UnsupportedError` on the client.
- **No Video Streaming**: The hardware pilot provides static camera captures and snapshots, not live RTSP/WebRTC video streams. Camera cards in the UI display `'CAMERA (PREVIEW)'` and `'Static Preview Only'`.
- **No Cloud Functions / Billing**: The architecture does not rely on Cloud Functions or billed Firebase services.
- **Scoped Facility Access**: The client strictly isolates facility data. Telemetry for `station_01` is only exposed when the active facility context is `site_1` and the user possesses authorized read grants.

---

## 2. Realtime Database Schema

### 2.1 `/stationLive/{stationId}` (Live Telemetry)
Published periodically or on-heartbeat by the station hardware.

```json
{
  "device_id": "station_01",
  "facility_id": "site_1",
  "battery_percentage": 86,
  "bait_percentage": 100,
  "online": true,
  "last_seen_at": 1756972800000
}
```

#### Field Specifications:
| Field | Type | Description | App Mapping |
| :--- | :--- | :--- | :--- |
| `device_id` | `String` | Station hardware identifier | `Station.id` |
| `facility_id` | `String` | Facility identifier | `Station.siteId` |
| `battery_percentage` | `number` | Remaining battery (0-100) | `Station.batteryPercentage` |
| `bait_percentage` | `number` | Remaining bait level (0-100) | `Station.baitPercentage` |
| `online` | `boolean` | Online connectivity flag | Status evaluation |
| `last_seen_at` | `number` | Epoch milliseconds UTC | `Station.lastSeen` |

#### Station Status Derivation:
1. **Offline**: If `online == false` OR `(DateTime.now() - last_seen_at) > 30 minutes` (staleness threshold).
2. **Low Bait**: If online, not stale, and `bait_percentage <= 25.0` (`kLowBaitThreshold`).
3. **Online**: If online, not stale, and `bait_percentage > 25.0`.

---

### 2.2 `/stationEvents/{stationId}/{eventId}` (Event Records)
Logged by hardware upon rodent detection or low-bait trigger.

```json
{
  "stationEvents": {
    "station_01": {
      "evt_001": {
        "device_id": "station_01",
        "event_type": "rat_detected",
        "timestamp": 1756972800000
      },
      "evt_002": {
        "device_id": "station_01",
        "event_type": "low_bait_alert",
        "bait_percentage": 15,
        "status": "Refill Required",
        "timestamp": 1756972900000
      }
    }
  }
}
```

#### Event Mapping Rules:
- `event_type == "rat_detected"`:
  - Generates a `DetectionEvent` (`species: DetectedSpecies.rat`, `status: DetectionEventStatus.open`, `alertId: "alert_{eventId}"`).
  - Generates an `Alert` (`type: AlertType.rodent`, `severity: AlertSeverity.critical`, `status: AlertStatus.open`).
- `event_type == "low_bait_alert"`:
  - Generates an `Alert` (`type: AlertType.lowBait`, `severity: AlertSeverity.warning`, `status: AlertStatus.open`).
  - Does not generate a rodent `DetectionEvent`.

---

### 2.3 `/mobileReaders/{uid}` (Security & Access Control Grants)
Maintained in RTDB to validate that an authenticated Firebase user is entitled to read facility telemetry:

```json
{
  "mobileReaders": {
    "<firebase_auth_uid>": {
      "active": true,
      "facilityIds": {
        "site_1": true
      }
    }
  }
}
```

---

## 3. Database Security Rules (`database.rules.json`)

The rules enforce pilot isolation, reader authorization, and query indexing:

```json
{
  "rules": {
    "stationLive": {
      "station_01": {
        ".read": "auth != null && (root.child('mobileReaders').child(auth.uid).child('active').val() === true && root.child('mobileReaders').child(auth.uid).child('facilityIds').child('site_1').val() === true)",
        ".write": false
      }
    },
    "stationEvents": {
      "station_01": {
        ".read": "auth != null && (root.child('mobileReaders').child(auth.uid).child('active').val() === true && root.child('mobileReaders').child(auth.uid).child('facilityIds').child('site_1').val() === true)",
        ".write": false,
        ".indexOn": ["timestamp"]
      }
    },
    "mobileReaders": {
      "$uid": {
        ".read": "auth != null && auth.uid === $uid",
        ".write": false
      }
    }
  }
}
```

---

## 4. Architecture & Implementation

### 4.1 Reactive Data Source (`RealtimeStationDataSource`)
Located at: `lib/data/repositories/firebase/realtime_station_data_source.dart`

- Listens reactively to `/stationLive/station_01` and `/stationEvents/station_01` via `StreamSubscription<DatabaseEvent>`.
- Exposes broadcast streams:
  - `Stream<Station?> get stationStream`
  - `Stream<List<DetectionEvent>> get eventsStream`
  - `Stream<List<Alert>> get alertsStream`
- Manages facility context via `setFacilityContext(facilityId, isPermitted: ...)`:
  - Automatically activates subscriptions when switching to `site_1` with valid permissions.
  - Safely cancels subscriptions and clears caches when switching to unpermitted facilities or signing out.
- Tolerates test environments: when `Firebase.apps.isEmpty`, it safely operates without throwing `[core/no-app]`.

### 4.2 Repository Implementations
The four reactive repositories wrap `RealtimeStationDataSource` and implement the domain contracts:
1. `RealtimeStationRepository` (`lib/data/repositories/firebase/realtime_station_repository.dart`):
   - Implements `StationRepository`.
   - Filters stations by `site_1`. Returns `[station_01]` for `site_1`, and `[]` for any other site.
   - Throws `UnsupportedError` on hardware telemetry writes (`recordRefill`, `registerStation`).
2. `RealtimeAlertRepository` (`lib/data/repositories/firebase/realtime_alert_repository.dart`):
   - Implements `AlertRepository`.
   - Isolates alerts to `site_1`.
   - Supports `getAlertById` and safe `markAlertRead`.
3. `RealtimeDashboardRepository` (`lib/data/repositories/firebase/realtime_dashboard_repository.dart`):
   - Implements `DashboardRepository`.
   - Computes `StationSummaryMetrics`, 7-day activity chart series, species breakdown, recent alerts, and facility map markers for `site_1`.
   - Returns empty dashboard data with zero metrics for other sites.
4. `RealtimeReportRepository` (`lib/data/repositories/firebase/realtime_report_repository.dart`):
   - Implements `ReportRepository`.
   - Aggregates period detections, trends, and station ledger entries.

### 4.3 App Providers (`lib/app/app_providers.dart`)
- When `Firebase.apps.isNotEmpty`, registers `RealtimeStationDataSource` and the 4 Realtime repositories.
- When `Firebase.apps.isEmpty` (in automated widget/unit tests), falls back to Mock repositories ensuring all test suites run cleanly offline.

---

## 5. Verification Checklist

| Suite | Status | Details |
| :--- | :--- | :--- |
| `dart analyze lib test` | **0 issues** | Full static analysis clean |
| `test/data/repositories/realtime_station_integration_test.dart` | **11 passed** | Live telemetry, event partitioning, facility isolation, mutation guards |
| `test/features/dashboard` | **44 passed** | Profile reactivity, admin & user dashboard composition, view models |
| `test/features/stations` | **57 passed** | Station lists, filters, detail view, mutations, permissions |
| `test/features/alerts` | **20 passed** | Alert listing, detail, severity filters |
| `test/features/reports` | **19 passed** | Period selection, trends, metrics summary |
| `test/features/admin` | **69 passed** | User management, review requests, add user, system management |
| `test/features/authentication` | **57 passed** | Auth flows, login, registration, password reset |
| `test/features/settings` | **52 passed** | Profile settings, logout coordinator safety |
| `test/app/state` & `test/widget_test.dart` | **34 passed** | Session lifecycle, splash to welcome navigation |
