import '../../../domain/models/alert.dart';
import '../../../domain/models/alert_type.dart';
import '../../../domain/repositories/alert_repository.dart';
import 'mock_baitguard_data_source.dart';

class MockAlertRepository implements AlertRepository {
  final MockBaitGuardDataSource _dataSource;

  MockAlertRepository(this._dataSource);

  @override
  Future<List<Alert>> getAlerts({AlertType? filterType}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    var alerts = _dataSource.alerts;
    if (filterType != null) {
      alerts = alerts.where((a) => a.type == filterType).toList();
    }
    return alerts;
  }

  @override
  Future<Alert?> getAlertById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _dataSource.alerts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> resolveAlert(String alertId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // No-op for mock, unless we want to track it
  }
}
