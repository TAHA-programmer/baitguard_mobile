import '../models/alert.dart';
import '../models/alert_type.dart';

abstract class AlertRepository {
  Future<List<Alert>> getAlerts({AlertType? filterType});
  Future<Alert?> getAlertById(String id);
  Future<void> resolveAlert(String alertId);
}
