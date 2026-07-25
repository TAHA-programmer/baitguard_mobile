import '../models/dashboard/admin_dashboard_data.dart';
import '../models/dashboard/user_dashboard_data.dart';

abstract class DashboardRepository {
  Future<UserDashboardData> getUserDashboard({
    required String userId,
    String? siteId,
  });

  Future<AdminDashboardData> getAdminDashboard({
    required String adminId,
    String? siteId,
  });
}
