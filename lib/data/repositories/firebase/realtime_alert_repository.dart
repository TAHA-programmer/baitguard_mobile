import '../../../domain/models/alert.dart';
import '../../../domain/repositories/alert_repository.dart';
import 'realtime_station_data_source.dart';

class RealtimeAlertRepository implements AlertRepository {
  final RealtimeStationDataSource _dataSource;

  RealtimeAlertRepository(this._dataSource);

  @override
  Future<List<Alert>> getAlerts({required String siteId}) async {
    if (siteId != RealtimeStationDataSource.kPilotFacilityId) {
      return const [];
    }
    return _dataSource.fetchAlerts(siteId: siteId);
  }

  @override
  Future<Alert> getAlertById(String id) async {
    final alerts = await _dataSource.fetchAlerts(
      siteId: RealtimeStationDataSource.kPilotFacilityId,
    );
    final match = alerts.cast<Alert?>().firstWhere(
          (a) => a?.id == id,
          orElse: () => null,
        );
    if (match != null) {
      return match;
    }
    throw StateError('Alert not found: $id');
  }

  @override
  Future<Alert> markAlertRead({required String alertId}) async {
    // In this read-only pilot, mutations cannot alter ESP hardware events.
    // Return the alert as-is or throw UnsupportedError.
    // To allow the UI to view the alert without crashing:
    return getAlertById(alertId);
  }

  @override
  Future<Alert> resolveAlert({
    required String alertId,
    required String resolvedByUserId,
  }) {
    throw UnsupportedError(
      'Alert resolution is unsupported in this read-only telemetry pilot.',
    );
  }

  @override
  Future<Alert> snoozeAlert({
    required String alertId,
    required DateTime until,
  }) {
    throw UnsupportedError(
      'Alert snoozing is unsupported in this read-only telemetry pilot.',
    );
  }

  @override
  Future<Alert> assignAlert({
    required String alertId,
    required String technicianId,
  }) {
    throw UnsupportedError(
      'Alert assignment is unsupported in this read-only telemetry pilot.',
    );
  }

  @override
  Future<Alert> dismissAlert({
    required String alertId,
    required String dismissedByUserId,
  }) {
    throw UnsupportedError(
      'Alert dismissal is unsupported in this read-only telemetry pilot.',
    );
  }
}
