import '../../../domain/models/detection_event.dart';
import '../../../domain/models/register_station_request.dart';
import '../../../domain/models/station.dart';
import '../../../domain/repositories/station_repository.dart';
import 'realtime_station_data_source.dart';

class RealtimeStationRepository implements StationRepository {
  final RealtimeStationDataSource _dataSource;

  RealtimeStationRepository(this._dataSource);

  @override
  Future<List<Station>> getStations({String? siteId}) async {
    if (siteId != null && siteId != RealtimeStationDataSource.kPilotFacilityId) {
      // Facility isolation: pilot station_01 only belongs to site_1
      return const [];
    }

    final station = await _dataSource.fetchStation(
      RealtimeStationDataSource.kPilotStationId,
    );
    if (station != null) {
      return [station];
    }
    return const [];
  }

  @override
  Future<Station?> getStationById(String id) async {
    if (id != RealtimeStationDataSource.kPilotStationId) return null;
    return _dataSource.fetchStation(id);
  }

  @override
  Future<List<DetectionEvent>> getStationEvents(String stationId) async {
    if (stationId != RealtimeStationDataSource.kPilotStationId) {
      return const [];
    }
    return _dataSource.fetchStationEvents(stationId);
  }

  @override
  Future<Station> recordRefill(String stationId) {
    throw UnsupportedError(
      'Telemetry writes are reserved for hardware stations in this pilot.',
    );
  }

  @override
  Future<Station> setNotificationsMuted({
    required String stationId,
    required bool muted,
  }) {
    throw UnsupportedError(
      'Notification mute writes are unsupported for hardware stations in this pilot.',
    );
  }

  @override
  Future<Station> registerStation(RegisterStationRequest request) {
    throw UnsupportedError(
      'Station registration is operator-managed in this pilot.',
    );
  }
}
