import '../models/app_user.dart';
import '../models/dashboard/admin_dashboard_data.dart';
import '../models/dashboard/user_dashboard_data.dart';

abstract class DashboardRepository {
  Future<UserDashboardData> getUserDashboard({
    required AppUser user,
    String? siteId,
  });

  Future<AdminDashboardData> getAdminDashboard({
    required AppUser admin,
    String? siteId,
  });
}
