import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/models/alert.dart';
import '../../../domain/models/alert_severity.dart';
import '../../../domain/models/alert_status.dart';
import '../../../domain/models/alert_type.dart';
import '../../../domain/models/detected_species.dart';
import '../../../domain/models/detection_event.dart';
import '../../../domain/models/station.dart';
import '../../../domain/models/station_status.dart';

/// Central reactive data source connecting to Firebase Realtime Database
/// for hardware station telemetry and detection events.
///
/// Pilot Configuration:
/// - Station ID: 'station_01'
/// - Facility ID: 'site_1'
/// - RTDB URL: https://bait-guard-6f470-default-rtdb.firebaseio.com/
class RealtimeStationDataSource {
  static const String kDefaultDatabaseUrl =
      'https://bait-guard-6f470-default-rtdb.firebaseio.com/';
  static const String kPilotStationId = 'station_01';
  static const String kPilotFacilityId = 'site_1';

  final FirebaseDatabase? _database;
  final Duration stalenessThreshold;

  // Active subscriptions
  StreamSubscription<DatabaseEvent>? _liveSubscription;
  StreamSubscription<DatabaseEvent>? _eventsSubscription;

  // Cached state
  Station? _cachedStation;
  List<DetectionEvent> _cachedEvents = const [];
  List<Alert> _cachedAlerts = const [];

  // Stream broadcast controllers
  final _stationController = StreamController<Station?>.broadcast();
  final _eventsController = StreamController<List<DetectionEvent>>.broadcast();
  final _alertsController = StreamController<List<Alert>>.broadcast();

  bool _isListening = false;
  String? _activeFacilityId;

  RealtimeStationDataSource({
    FirebaseDatabase? database,
    this.stalenessThreshold = const Duration(minutes: 30),
  }) : _database = database ??
            (Firebase.apps.isNotEmpty
                ? FirebaseDatabase.instanceFor(
                    app: Firebase.app(),
                    databaseURL: kDefaultDatabaseUrl,
                  )
                : null);

  Station? get currentStation => _cachedStation;
  List<DetectionEvent> get currentEvents => _cachedEvents;
  List<Alert> get currentAlerts => _cachedAlerts;

  Stream<Station?> get stationStream => _stationController.stream;
  Stream<List<DetectionEvent>> get eventsStream => _eventsController.stream;
  Stream<List<Alert>> get alertsStream => _alertsController.stream;

  /// Starts listening to RTDB if [facilityId] matches the pilot facility [kPilotFacilityId]
  /// and the user is permitted to view it.
  void setFacilityContext(String? facilityId, {required bool isPermitted}) {
    if (_activeFacilityId == facilityId && _isListening) return;

    _activeFacilityId = facilityId;

    if (facilityId == kPilotFacilityId && isPermitted) {
      _startListening();
    } else {
      _stopListeningAndClear();
    }
  }

  void _startListening() {
    _stopSubscriptions();
    _isListening = true;

    final db = _database;
    if (db == null) return;

    try {
      final liveRef = db.ref('stationLive/$kPilotStationId');
      _liveSubscription = liveRef.onValue.listen(
        (event) {
          final raw = event.snapshot.value;
          _cachedStation = parseStationLive(
            raw,
            stalenessThreshold: stalenessThreshold,
          );
          _stationController.add(_cachedStation);
        },
        onError: (error) {
          if (kDebugMode) {
            debugPrint('RealtimeStationDataSource stationLive error: $error');
          }
          _stationController.addError(error);
        },
      );

      final eventsRef = db.ref('stationEvents/$kPilotStationId');
      _eventsSubscription = eventsRef.onValue.listen(
        (event) {
          final raw = event.snapshot.value;
          final parsed = parseStationEventsMap(raw);
          _cachedEvents = parsed.events;
          _cachedAlerts = parsed.alerts;

          _eventsController.add(_cachedEvents);
          _alertsController.add(_cachedAlerts);
        },
        onError: (error) {
          if (kDebugMode) {
            debugPrint('RealtimeStationDataSource stationEvents error: $error');
          }
          _eventsController.addError(error);
          _alertsController.addError(error);
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to attach RTDB listeners: $e');
      }
    }
  }

  void _stopSubscriptions() {
    _liveSubscription?.cancel();
    _liveSubscription = null;
    _eventsSubscription?.cancel();
    _eventsSubscription = null;
    _isListening = false;
  }

  void _stopListeningAndClear() {
    _stopSubscriptions();
    _cachedStation = null;
    _cachedEvents = const [];
    _cachedAlerts = const [];

    _stationController.add(null);
    _eventsController.add(const []);
    _alertsController.add(const []);
  }

  /// One-off read for station_01 telemetry
  Future<Station?> fetchStation(String stationId) async {
    if (stationId != kPilotStationId) return null;
    if (_cachedStation != null) return _cachedStation;
    final db = _database;
    if (db == null) return null;

    try {
      final snapshot = await db.ref('stationLive/$kPilotStationId').get();
      final station = parseStationLive(
        snapshot.value,
        stalenessThreshold: stalenessThreshold,
      );
      if (station != null) {
        _cachedStation = station;
        _stationController.add(station);
      }
      return station;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('fetchStation failed: $e');
      }
      rethrow;
    }
  }

  /// One-off read for station events
  Future<List<DetectionEvent>> fetchStationEvents(String stationId) async {
    if (stationId != kPilotStationId) return const [];
    if (_cachedEvents.isNotEmpty) return _cachedEvents;
    final db = _database;
    if (db == null) return const [];

    try {
      final snapshot = await db.ref('stationEvents/$kPilotStationId').get();
      final parsed = parseStationEventsMap(snapshot.value);
      _cachedEvents = parsed.events;
      _cachedAlerts = parsed.alerts;

      _eventsController.add(_cachedEvents);
      _alertsController.add(_cachedAlerts);
      return _cachedEvents;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('fetchStationEvents failed: $e');
      }
      rethrow;
    }
  }

  /// One-off read for alerts derived from events
  Future<List<Alert>> fetchAlerts({required String siteId}) async {
    if (siteId != kPilotFacilityId) return const [];
    if (_cachedAlerts.isNotEmpty) return _cachedAlerts;
    final db = _database;
    if (db == null) return const [];

    try {
      final snapshot = await db.ref('stationEvents/$kPilotStationId').get();
      final parsed = parseStationEventsMap(snapshot.value);
      _cachedEvents = parsed.events;
      _cachedAlerts = parsed.alerts;

      _eventsController.add(_cachedEvents);
      _alertsController.add(_cachedAlerts);
      return _cachedAlerts;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('fetchAlerts failed: $e');
      }
      rethrow;
    }
  }

  /// Feeds simulated live telemetry directly for testing and reactive updates.
  @visibleForTesting
  void updateFromLivePayload(dynamic raw) {
    _cachedStation = parseStationLive(
      raw,
      stalenessThreshold: stalenessThreshold,
    );
    _stationController.add(_cachedStation);
  }

  /// Feeds simulated station events directly for testing and reactive updates.
  @visibleForTesting
  void updateFromEventsPayload(dynamic raw) {
    final parsed = parseStationEventsMap(raw);
    _cachedEvents = parsed.events;
    _cachedAlerts = parsed.alerts;
    _eventsController.add(_cachedEvents);
    _alertsController.add(_cachedAlerts);
  }

  // ---------------------------------------------------------------------------
  // Static Parsing Helpers
  // ---------------------------------------------------------------------------

  static Station? parseStationLive(
    dynamic data, {
    Duration stalenessThreshold = const Duration(minutes: 30),
  }) {
    if (data == null || data is! Map) return null;
    final map = Map<String, dynamic>.from(data);

    final deviceId = map['device_id'] as String? ?? kPilotStationId;
    final facilityId = map['facility_id'] as String? ?? kPilotFacilityId;
    final battery = (map['battery_percentage'] as num?)?.toDouble() ?? 0.0;
    final bait = (map['bait_percentage'] as num?)?.toDouble() ?? 0.0;
    final isOnline = map['online'] == true;
    final lastSeenMillis = (map['last_seen_at'] as num?)?.toInt() ?? 0;
    final lastSeen = DateTime.fromMillisecondsSinceEpoch(
      lastSeenMillis,
      isUtc: true,
    ).toLocal();

    final isStale = DateTime.now().toUtc().difference(
          DateTime.fromMillisecondsSinceEpoch(lastSeenMillis, isUtc: true),
        ) >
        stalenessThreshold;

    StationStatus status;
    if (!isOnline || isStale) {
      status = StationStatus.offline;
    } else if (bait <= kLowBaitThreshold) {
      status = StationStatus.lowBait;
    } else {
      status = StationStatus.online;
    }

    return Station(
      id: deviceId,
      name: 'Pilot Station 01',
      siteId: facilityId,
      locationDescription: 'Warehouse A · Main Zone',
      status: status,
      baitPercentage: bait.clamp(0.0, 100.0),
      batteryPercentage: battery.clamp(0.0, 100.0),
      temperature: null, // Unsupported by RTDB schema
      humidity: null, // Unsupported by RTDB schema
      isTampered: false, // Unsupported by RTDB schema
      lastSeen: lastSeen,
      hasCamera: true, // Static camera placeholder available
      notificationsMuted: false,
    );
  }

  static ({List<DetectionEvent> events, List<Alert> alerts})
      parseStationEventsMap(dynamic data) {
    if (data == null || data is! Map) {
      return (events: const <DetectionEvent>[], alerts: const <Alert>[]);
    }

    final rawMap = Map<String, dynamic>.from(data);
    final eventsList = <DetectionEvent>[];
    final alertsList = <Alert>[];

    final sortedEntries = rawMap.entries.toList()
      ..sort((a, b) {
        final aVal = a.value is Map ? (a.value['timestamp'] as num?) ?? 0 : 0;
        final bVal = b.value is Map ? (b.value['timestamp'] as num?) ?? 0 : 0;
        return bVal.compareTo(aVal); // Newest first
      });

    for (final entry in sortedEntries) {
      final key = entry.key;
      final val = entry.value;
      if (val is! Map) continue;
      final map = Map<String, dynamic>.from(val);

      final eventType = map['event_type'] as String?;
      final deviceId = map['device_id'] as String? ?? kPilotStationId;
      final tsMillis = (map['timestamp'] as num?)?.toInt() ?? 0;
      final ts = DateTime.fromMillisecondsSinceEpoch(
        tsMillis,
        isUtc: true,
      ).toLocal();

      if (eventType == 'rat_detected') {
        final alertId = 'alert_$key';
        eventsList.add(
          DetectionEvent(
            id: key,
            stationId: deviceId,
            timestamp: ts,
            species: DetectedSpecies.rat,
            confidenceScore: null, // Unavailable in hardware schema
            evidenceImageUrl: null,
            status: DetectionEventStatus.open,
            alertId: alertId,
          ),
        );

        alertsList.add(
          Alert(
            id: alertId,
            stationId: deviceId,
            type: AlertType.rodent,
            severity: AlertSeverity.critical,
            status: AlertStatus.open,
            timestamp: ts,
            description: 'Rat detected at $deviceId',
            detectionEventId: key,
            isRead: false,
          ),
        );
      } else if (eventType == 'low_bait_alert') {
        final baitPct = (map['bait_percentage'] as num?)?.toInt();
        final statusStr = map['status'] as String? ?? 'Refill Required';
        final desc = baitPct != null
            ? 'Low bait level ($baitPct%) — $statusStr'
            : 'Low bait level — $statusStr';

        alertsList.add(
          Alert(
            id: 'alert_$key',
            stationId: deviceId,
            type: AlertType.lowBait,
            severity: AlertSeverity.warning,
            status: AlertStatus.open,
            timestamp: ts,
            description: desc,
            detectionEventId: null,
            isRead: false,
          ),
        );
      }
    }

    return (
      events: List.unmodifiable(eventsList),
      alerts: List.unmodifiable(alertsList),
    );
  }

  void dispose() {
    _stopSubscriptions();
    _stationController.close();
    _eventsController.close();
    _alertsController.close();
  }
}
