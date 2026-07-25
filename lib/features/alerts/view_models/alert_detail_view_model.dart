import 'package:flutter/foundation.dart';
import '../../../app/state/active_facility_controller.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../domain/models/alert.dart';
import '../../../domain/models/station.dart';
import '../../../domain/repositories/alert_repository.dart';
import '../../../domain/repositories/station_repository.dart';
import '../models/alert_permissions.dart';

class AlertDetailViewModel extends ChangeNotifier {
  final String alertId;
  final AlertRepository _alertRepository;
  final StationRepository _stationRepository;
  final AppSessionController _sessionController;
  final ActiveFacilityController _activeFacilityController;

  AlertDetailViewModel({
    required this.alertId,
    required AlertRepository alertRepository,
    required StationRepository stationRepository,
    required AppSessionController sessionController,
    required ActiveFacilityController activeFacilityController,
  })  : _alertRepository = alertRepository,
        _stationRepository = stationRepository,
        _sessionController = sessionController,
        _activeFacilityController = activeFacilityController {
    _initialize();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _refreshError;
  String? get refreshError {
    final e = _refreshError;
    _refreshError = null;
    return e;
  }

  String? _actionSuccessMessage;
  String? get actionSuccessMessage {
    final m = _actionSuccessMessage;
    _actionSuccessMessage = null;
    return m;
  }

  String? _actionErrorMessage;
  String? get actionErrorMessage {
    final m = _actionErrorMessage;
    _actionErrorMessage = null;
    return m;
  }

  Alert? _alert;
  Alert? get alert => _alert;

  Station? _station;
  Station? get station => _station;

  AlertPermissions? _permissions;
  AlertPermissions? get permissions => _permissions;

  bool _isMutating = false;
  bool get isMutating => _isMutating;

  Future<void> _initialize() async {
    final role = _sessionController.currentUser?.role;
    if (role != null) {
      _permissions = AlertPermissions.fromRole(role);
    }
    await _loadData();
    if (_alert != null && !_alert!.isRead) {
      await _markRead();
    }
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final a = await _alertRepository.getAlertById(alertId);
      final s = await _stationRepository.getStationById(a.stationId);
      
      // Verify unauthorized site alert access
      if (s?.siteId != _activeFacilityController.selectedSiteId) {
        throw StateError('Unauthorized site access');
      }

      _alert = a;
      _station = s;
    } catch (e) {
      _error = 'Failed to load alert details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    try {
      final a = await _alertRepository.getAlertById(alertId);
      final s = await _stationRepository.getStationById(a.stationId);
      
      if (s?.siteId != _activeFacilityController.selectedSiteId) {
        throw StateError('Unauthorized site access');
      }

      _alert = a;
      _station = s;
    } catch (e) {
      _refreshError = 'Failed to refresh alert.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> _markRead() async {
    try {
      final updated = await _alertRepository.markAlertRead(alertId: alertId);
      _alert = updated;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> resolveAlert() async {
    if (_permissions?.canResolve != true) return;
    if (_isMutating) return;
    final user = _sessionController.currentUser;
    if (user == null) return;

    _isMutating = true;
    notifyListeners();

    try {
      final updated = await _alertRepository.resolveAlert(
        alertId: alertId,
        resolvedByUserId: user.id,
      );
      _alert = updated;
      _actionSuccessMessage = 'Alert resolved successfully.';
    } catch (e) {
      _actionErrorMessage = 'Failed to resolve alert.';
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> snoozeAlert(DateTime until) async {
    if (_permissions?.canSnooze != true) return;
    if (_isMutating) return;

    _isMutating = true;
    notifyListeners();

    try {
      final updated = await _alertRepository.snoozeAlert(
        alertId: alertId,
        until: until,
      );
      _alert = updated;
      _actionSuccessMessage = 'Alert snoozed.';
    } catch (e) {
      _actionErrorMessage = 'Failed to snooze alert.';
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> assignAlert(String technicianId) async {
    if (_permissions?.canAssign != true) return;
    if (_isMutating) return;

    _isMutating = true;
    notifyListeners();

    try {
      final updated = await _alertRepository.assignAlert(
        alertId: alertId,
        technicianId: technicianId,
      );
      _alert = updated;
      _actionSuccessMessage = 'Alert assigned to technician.';
    } catch (e) {
      _actionErrorMessage = 'Failed to assign technician.';
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> dismissAlert() async {
    if (_permissions?.canDismiss != true) return;
    if (_isMutating) return;
    final user = _sessionController.currentUser;
    if (user == null) return;

    _isMutating = true;
    notifyListeners();

    try {
      final updated = await _alertRepository.dismissAlert(
        alertId: alertId,
        dismissedByUserId: user.id,
      );
      _alert = updated;
      _actionSuccessMessage = 'Alert dismissed.';
    } catch (e) {
      _actionErrorMessage = 'Failed to dismiss alert.';
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}
