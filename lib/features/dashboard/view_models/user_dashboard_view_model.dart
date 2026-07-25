import 'package:flutter/foundation.dart';
import '../../../domain/models/dashboard/user_dashboard_data.dart';
import '../../../domain/repositories/dashboard_repository.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../domain/models/user_role.dart';

enum DashboardLoadStatus { initial, loading, success, empty, failure }

class UserDashboardViewModel extends ChangeNotifier {
  final DashboardRepository dashboardRepository;
  final AppSessionController sessionController;

  DashboardLoadStatus _status = DashboardLoadStatus.initial;
  DashboardLoadStatus get status => _status;

  UserDashboardData? _data;
  UserDashboardData? get data => _data;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _refreshErrorEventId = 0;
  int get refreshErrorEventId => _refreshErrorEventId;
  String? _refreshErrorMessage;
  String? get refreshErrorMessage => _refreshErrorMessage;

  bool _isLoading = false;

  UserDashboardViewModel({
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

  Future<void> _fetchData({required bool isRefresh}) async {
    try {
      final user = sessionController.currentUser;
      if (user == null ||
          (user.role != UserRole.viewer && user.role != UserRole.technician)) {
        throw Exception('Invalid session or role');
      }

      final siteId = user.siteAccessIds.isNotEmpty
          ? user.siteAccessIds.first
          : null;

      final result = await dashboardRepository.getUserDashboard(
        userId: user.id,
        siteId: siteId,
      );

      _data = result;
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
