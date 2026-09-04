# BaitGuard — Smart IoT Rodent Monitoring System

[![Flutter](https://img.shields.io/badge/Flutter-3.44.9-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12.2-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase)](https://firebase.google.com)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20MVVM%20%2B%20Provider-4CAF50)](#architecture--design-patterns)
[![License](https://img.shields.io/badge/License-Proprietary-red)](#)

BaitGuard is a mission-critical Flutter mobile application designed for enterprise IoT smart rodent bait-station monitoring across industrial warehouses, commercial buildings, healthcare facilities, cold storage, laboratories, and food processing environments.

---

## 1. Product Overview

In large facilities, manual rodent bait inspection is labor-intensive, error-prone, and reactive. BaitGuard bridges edge IoT hardware with cloud intelligence to deliver 24/7 autonomous monitoring:

```text
[ Physical Station (ESP32-S3) ] 
       │ (PIR/IR motion, Load Cell bait %, Tamper switch, IR camera)
       ▼
[ On-Device Edge ML (YOLOv8-nano / TFLite) ]
       │ (Rodent vs Non-rodent classification, Confidence, Telemetry)
       ▼
[ Cloud Backend (Firebase Auth & Firestore) ]
       │
       ├─────────────────────────────────────────────┐
       ▼                                             ▼
[ BaitGuard Flutter Mobile App ]           [ BaitGuard Web Dashboard ]
 (Field Techs, Facility Admins, Viewers)       (Central Ops Command)
```

---

## 2. Core Mobile Application Features

### 🔐 Authentication, Access & Role Control
- **Firebase Authentication**: Robust Email/Password authentication with persistent session restoration.
- **Role-Aware Navigation Shells**: Separate, optimized persistent navigation shells for:
  - **Administrator**: Full facility control, user request approvals/rejections, invitations, and access management.
  - **Technician**: Active operational station inspections, alert resolution, and report generation.
  - **Viewer**: Facility-scoped read-only operational telemetry and dashboard monitoring.
- **Public Request Access**: Multi-step access request flow submitted directly to Firestore.
- **Admin Review & Approvals**: Transactional approval with assigned role and facility scoping, or rejection with reason.
- **Account Activation**: Email-verified onboarding flow with forced token refresh.
- **Security & Profile**: Self-service profile updates, Re-authentication Password Change, and Remember Me.

### 📊 Real-Time Facility Dashboards
- **Facility Scoping**: Filter all operational data across authorized facilities (`Warehouse A`, `Distribution Center`, etc.).
- **Interactive Floor Map**: Custom facility layout with station status markers, zone highlights, and direct drill-down.
- **Activity Trends & Breakdown**: Real-time detection charts, today's detection counts, and species breakdowns (Rats, Mice, None).
- **Admin Dashboard Integration**: Real-time counters for pending access requests and system health.

### 📡 Stations Management & Diagnostics
- **Station Roster**: Filter stations by status (`Active`, `Alert`, `Low Bait`, `Offline`, `Tampered`).
- **Detailed Station Telemetry**: Battery voltage, bait percentage, temperature, humidity, tamper sensor status, and last-seen timestamp.
- **Static Camera Area**: Inspection camera feed placeholder designed according to design system guidelines.
- **Station Registration**: Clean registration flow with Wi-Fi, 4G/LTE, or LoRaWAN configuration.

### 🚨 Smart Alerts & Incident Resolution
- **Multi-Filter Presets**: Fast categorization across `All`, `Rodent Detections`, `Low Bait`, `Tamper Alerts`, and `Offline Stations`.
- **Evidence Review**: High-contrast classification confidence, time, and technician action triggers.

### 📑 Reports & Operational Analytics
- **Executive KPI Cards**: Activity metrics, bait consumption, and active station ratios.
- **Trend Visualizations & Station Ledger**: Historical trend charts and export logs.
- **Report Generation Feedback**: In-app modal confirmation and recent export tracking.

---

## 3. Architecture & Design Patterns

The application is engineered strictly following **Clean Architecture**, **Feature-First modularity**, and **MVVM (Model - View - ViewModel)**:

```text
lib/
├── app/
│   ├── app.dart                   # MultiProvider root & MaterialApp configuration
│   ├── app_providers.dart         # Global Dependency Injection graph
│   ├── navigation/                # Named routing (AppRouter) & route names
│   ├── state/                     # Session & active facility state controllers
│   └── theme/                     # AppColors, AppTypography, AppSpacing, AppRadii, AppTheme
├── core/
│   └── widgets/                   # Reusable components (AppTopToast, PrimaryButton, AppTextField)
├── domain/
│   ├── models/                    # 33 pure domain entities (AppUser, Station, Alert, Report, etc.)
│   └── repositories/              # 11 abstract repository contracts
├── data/
│   └── repositories/
│       ├── firebase/              # Real Firebase data sources (Auth, Users, AccessRequests)
│       ├── mock/                  # Seeded mock operational data (Stations, Alerts, Reports)
│       └── preferences/           # SharedPreferences for local settings
├── features/                      # 10 self-contained feature modules
│   ├── admin/                     # Request review, User Management, Add User
│   ├── alerts/                    # Alerts list, filter presets, alert detail
│   ├── authentication/            # Login, Request Access, Forgot Password, Activation
│   ├── dashboard/                 # Admin & User interactive dashboards
│   ├── navigation/                # Persistent AdminAppShell & UserAppShell
│   ├── onboarding/                # Welcome screen
│   ├── reports/                   # Reports, KPI charts, recent exports
│   ├── settings/                  # Profile, preferences, change password, policies
│   ├── splash/                    # Brand splash with custom animations
│   └── stations/                  # Stations list, detail view, station registration
└── docs/                          # Engineering handover & Firebase web integration guides
```

### Key Architectural Guidelines
- **State Management**: `provider` only (`ChangeNotifier` ViewModels). No mixing of state management libraries.
- **Dependency Inversion**: Views interact exclusively with ViewModels; ViewModels consume abstract domain repositories.
- **Design System**: Strict light-mode design tokens (centralized `AppColors`, `AppTypography` using *Manrope*, *JetBrains Mono*, and *Inter*).
- **User Feedback**: Custom non-blocking `AppTopToast` for status feedback (no generic `SnackBar`).

---

## 4. Firebase Configuration

| Parameter | Value |
|---|---|
| **Project Name** | `Bait Guard` |
| **Project ID** | `bait-guard-6f470` |
| **Project Number** | `609454017958` |
| **Realtime Database** | `https://bait-guard-6f470-default-rtdb.firebaseio.com` |
| **Storage Bucket** | `bait-guard-6f470.firebasestorage.app` |
| **Active Auth Provider** | Email / Password |
| **Security Rules** | Enforced via `firestore.rules` |

> 📖 **Working with the Web Team?**  
> Refer to [docs/FIREBASE_WEB_INTEGRATION_GUIDE.md](docs/FIREBASE_WEB_INTEGRATION_GUIDE.md) for full credentials, schemas, and instructions for integrating the web dashboard with this Firebase backend.

---

## 5. Getting Started & Setup

### Prerequisites
- **Flutter SDK**: `3.44.x` (or `^3.8.1` SDK environment)
- **Dart SDK**: `3.12.x`
- **Android SDK**: Android 14 / API 34+ recommended (Minimum SDK: 23)

### Windows Symlink Setup (Important)
On Windows 10/11, Flutter plugin resolution requires symlink privileges:
```cmd
start ms-settings:developers
```
*Toggle **Developer Mode** to **ON**.*

### Installation & Execution
```bash
# 1. Clone the repository
git clone https://github.com/TAHA-programmer/baitguard_mobile.git
cd baitguard_mobile

# 2. Install dependencies
flutter pub get

# 3. Verify code health (0 issues)
dart analyze lib test

# 4. Run automated test suite
flutter test

# 5. Launch the application
flutter run
```

---

## 6. Verification & Quality Gates

All code conforms to strict linting and test coverage standards:

```bash
# Static analysis
dart analyze lib test
# Output: Analyzing lib, test... No issues found!

# Unit & Widget tests
flutter test test/features/admin/manage_user_batch8d2_test.dart
# Output: 00:01 +16: All tests passed!
```

---

## 7. Repository & Author

- **Repository**: [https://github.com/TAHA-programmer/baitguard_mobile](https://github.com/TAHA-programmer/baitguard_mobile)
- **Developer**: [TAHA-programmer](https://github.com/TAHA-programmer)
- **Project**: Trinode Industrial Internship Project
