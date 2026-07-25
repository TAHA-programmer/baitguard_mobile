import 'package:flutter/foundation.dart';
import '../../../app/state/active_facility_controller.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/dashboard/admin_dashboard_data.dart';
import '../../../domain/repositories/dashboard_repository.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../domain/models/user_role.dart';
import 'user_dashboard_view_model.dart'; // To reuse DashboardLoadStatus

class AdminDashboardViewModel extends ChangeNotifier {
  final DashboardRepository dashboardRepository;
  final AppSessionController sessionController;
  final ActiveFacilityController activeFacilityController;

  DashboardLoadStatus _status = DashboardLoadStatus.initial;
  DashboardLoadStatus get status => _status;

  AdminDashboardData? _data;
  AdminDashboardData? get data => _data;

  AppUser get adminUser => sessionController.currentUser!;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _refreshErrorEventId = 0;
  int get refreshErrorEventId => _refreshErrorEventId;
  String? _refreshErrorMessage;
  String? get refreshErrorMessage => _refreshErrorMessage;

  // One-time facility-change error event (e.g. switching to a new facility fails)
  int _facilityErrorEventId = 0;
  int get facilityErrorEventId => _facilityErrorEventId;
  String? _facilityErrorMessage;
  String? get facilityErrorMessage => _facilityErrorMessage;

  bool _isLoading = false;

  AdminDashboardViewModel({
    required this.dashboardRepository,
    required this.sessionController,
    required this.activeFacilityController,
  });

  Future<void> load() async {
    if (_isLoading) return;

    _isLoading = true;
    _status = DashboardLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    await _fetchData(isRefresh: false);
  }

  Future<void> refresh() async {
    if (_isLoading) return;

    _isLoading = true;
    // Do not change _status to loading so existing data stays visible
    notifyListeners();

    await _fetchData(isRefresh: true);
  }

  /// Selects a new facility and reloads dashboard data.
  ///
  /// Selection rules:
  /// 1. Ignore same-site selection.
  /// 2. Validate the candidate site is permitted.
  /// 3. Preserve existing dashboard data.
  /// 4. Request dashboard data for the candidate site.
  /// 5. Only after repository success: update data AND commit to controller.
  /// 6. On failure: preserve previous data and site, expose one-time error.
  Future<void> selectFacility(String siteId) async {
    if (_isLoading) return;

    // Ignore same-site selection
    if (activeFacilityController.selectedSiteId == siteId) return;

    // Validate the candidate site
    if (!activeFacilityController.isPermitted(siteId)) {
      _facilityErrorMessage = 'You do not have access to that facility.';
      _facilityErrorEventId++;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final user = sessionController.currentUser;
      if (user == null || user.role != UserRole.admin) {
        throw Exception('Invalid session or role');
      }

      final result = await dashboardRepository.getAdminDashboard(
        adminId: user.id,
        siteId: siteId,
      );

      // Only commit after success
      _data = result;
      _status = DashboardLoadStatus.success;
      _errorMessage = null;

      // Commit selected site to the shared controller AFTER success.
      // This notifies StationsViewModel (and future Alerts/Reports) to reload.
      activeFacilityController.selectSite(siteId);
    } catch (e) {
      // Preserve previous dashboard data and selected site
      _facilityErrorMessage = 'Failed to load facility. Please try again.';
      _facilityErrorEventId++;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchData({required bool isRefresh}) async {
    try {
      final user = sessionController.currentUser;
      if (user == null || user.role != UserRole.admin) {
        throw Exception('Invalid session or role');
      }

      // Use the shared controller's current selected site.
      final siteId = activeFacilityController.selectedSiteId;

      final result = await dashboardRepository.getAdminDashboard(
        adminId: user.id,
        siteId: siteId,
      );

      _data = result;
      _status = DashboardLoadStatus.success;
      _errorMessage = null;

      // Sync the controller if the repository resolved a different default site.
      if (result.selectedSite.id != activeFacilityController.selectedSiteId) {
        activeFacilityController.selectSite(result.selectedSite.id);
      }
    } catch (e) {
      if (isRefresh && _data != null) {
        _refreshErrorMessage = 'Failed to refresh dashboard. Please try again.';
        _refreshErrorEventId++;
      } else {
        _status = DashboardLoadStatus.failure;
        _errorMessage = 'Could not load dashboard data. Please try again.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
