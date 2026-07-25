import '../models/alert.dart';

abstract class AlertRepository {
  Future<List<Alert>> getAlerts({required String siteId});
  Future<Alert> getAlertById(String id);
  Future<Alert> markAlertRead({required String alertId});
  Future<Alert> resolveAlert({
    required String alertId,
    required String resolvedByUserId,
  });
  Future<Alert> snoozeAlert({required String alertId, required DateTime until});
  Future<Alert> assignAlert({
    required String alertId,
    required String technicianId,
  });
  Future<Alert> dismissAlert({
    required String alertId,
    required String dismissedByUserId,
  });
}
