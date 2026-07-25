import 'alert_type.dart';
import 'alert_severity.dart';
import 'alert_status.dart';

class Alert {
  final String id;
  final String stationId;
  final AlertType type;
  final AlertSeverity severity;
  final AlertStatus status;
  final DateTime timestamp;
  final String description;

  const Alert({
    required this.id,
    required this.stationId,
    required this.type,
    required this.severity,
    required this.status,
    required this.timestamp,
    required this.description,
  });
}
