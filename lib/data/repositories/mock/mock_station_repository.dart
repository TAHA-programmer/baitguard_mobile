import '../../../domain/models/station.dart';
import '../../../domain/models/station_status.dart';
import '../../../domain/models/detection_event.dart';
import '../../../domain/models/register_station_request.dart';
import '../../../domain/repositories/station_repository.dart';
import 'mock_baitguard_data_source.dart';

class MockStationRepository implements StationRepository {
  final MockBaitGuardDataSource _dataSource;

  MockStationRepository(this._dataSource);

  @override
  Future<List<Station>> getStations({String? siteId}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    var stations = _dataSource.stations;
    if (siteId != null) {
      stations = stations.where((s) => s.siteId == siteId).toList();
    }
    return stations;
  }

  @override
  Future<Station?> getStationById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final stations = _dataSource.stations;
    try {
      return stations.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<DetectionEvent>> getStationEvents(String stationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _dataSource.getEventsForStation(stationId);
  }

  @override
  Future<Station> recordRefill(String stationId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _dataSource.refillStation(stationId);
  }

  @override
  Future<Station> setNotificationsMuted({
    required String stationId,
    required bool muted,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _dataSource.setStationNotificationsMuted(stationId, muted);
  }

  @override
  Future<Station> registerStation(RegisterStationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _dataSource.registerStation(request);
  }
}

/// Centralized low-bait threshold.
///
/// A station is considered low-bait when its baitPercentage is at or below
/// this value. Used by StationsViewModel filters and Figma badge logic.
/// Future Firebase implementations should read this from remote config.
const double kLowBaitThreshold = 25.0;

/// Returns true when [station] is considered to have low bait.
bool stationIsLowBait(Station station) =>
    station.baitPercentage <= kLowBaitThreshold;

/// Returns true when [station] requires operational attention.
/// Covers alert status, tampered, and offline states.
bool stationNeedsAttention(Station station) =>
    station.status == StationStatus.alert ||
    station.status == StationStatus.offline ||
    station.isTampered;

/// Returns true when [station] is considered connected / online.
/// Currently all statuses except offline are treated as connected.
/// This may later become a separate backend connectivity field.
bool stationIsConnected(Station station) =>
    station.status != StationStatus.offline;
