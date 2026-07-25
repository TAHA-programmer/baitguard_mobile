import '../models/station.dart';
import '../models/detection_event.dart';
import '../models/register_station_request.dart';

abstract class StationRepository {
  Future<List<Station>> getStations({String? siteId});
  Future<Station?> getStationById(String id);
  Future<List<DetectionEvent>> getStationEvents(String stationId);

  /// Records a bait refill for [stationId].
  ///
  /// Sets baitPercentage to 100 and updates lastRefilledAt.
  /// Clears StationStatus.lowBait only when that was the sole condition.
  /// Preserves alert, tamper, and offline state.
  /// Returns the updated Station.
  /// Throws a [StateError] when the station is not found.
  Future<Station> recordRefill(String stationId);

  /// Sets the notification-muted state for [stationId].
  ///
  /// Does not resolve alerts, stop detection, disable the camera,
  /// or change StationStatus.
  /// Returns the updated Station.
  /// Throws a [StateError] when the station is not found.
  Future<Station> setNotificationsMuted({
    required String stationId,
    required bool muted,
  });

  /// Registers a new station.
  ///
  /// Persists the station via the provided data source.
  /// Throws if a station with the same ID already exists.
  Future<Station> registerStation(RegisterStationRequest request);
}
