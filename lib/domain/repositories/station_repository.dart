import '../models/station.dart';
import '../models/detection_event.dart';

abstract class StationRepository {
  Future<List<Station>> getStations({String? siteId});
  Future<Station?> getStationById(String id);
  Future<List<DetectionEvent>> getStationEvents(String stationId);
}
