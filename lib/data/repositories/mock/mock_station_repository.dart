import '../../../domain/models/station.dart';
import '../../../domain/models/detection_event.dart';
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
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }
}
