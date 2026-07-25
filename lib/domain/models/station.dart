import 'station_status.dart';

class Station {
  final String id;
  final String name;
  final String siteId;
  final String locationDescription;
  final StationStatus status;
  final double baitPercentage;
  final double batteryPercentage;
  final double? temperature;
  final double? humidity;
  final bool isTampered;
  final DateTime lastSeen;

  const Station({
    required this.id,
    required this.name,
    required this.siteId,
    required this.locationDescription,
    required this.status,
    required this.baitPercentage,
    required this.batteryPercentage,
    this.temperature,
    this.humidity,
    required this.isTampered,
    required this.lastSeen,
  });
}
