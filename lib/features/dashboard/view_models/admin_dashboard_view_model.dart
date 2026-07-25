import 'package:flutter/foundation.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/dashboard/admin_dashboard_data.dart';
import '../../../domain/repositories/dashboard_repository.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../domain/models/user_role.dart';
import 'user_dashboard_view_model.dart'; // To reuse DashboardLoadStatus

class AdminDashboardViewModel extends ChangeNotifier {
  final DashboardRepository dashboardRepository;
  final AppSessionController sessionController;

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

  bool _isLoading = false;
  String? _selectedSiteId;

  AdminDashboardViewModel({
    required this.dashboardRepository,
    required this.sessionController,
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

  Future<void> selectFacility(String siteId) async {
    if (_isLoading) return;
    if (_data?.selectedSite.id == siteId) return; // Ignore if same

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

      _data = result;
      _selectedSiteId = siteId;
      _status = DashboardLoadStatus.success;
      _errorMessage = null;
    } catch (e) {
      // Retain previous dashboard data
      _refreshErrorMessage = 'Failed to load facility. Please try again.';
      _refreshErrorEventId++;
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

      final result = await dashboardRepository.getAdminDashboard(
        adminId: user.id,
        siteId: _selectedSiteId,
      );

      _data = result;
      _selectedSiteId = result.selectedSite.id;
      _status = DashboardLoadStatus.success;
      _errorMessage = null;
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
