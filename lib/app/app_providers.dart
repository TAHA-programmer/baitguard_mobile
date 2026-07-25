import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'state/app_session_controller.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/access_request_repository.dart';
import '../domain/repositories/station_repository.dart';
import '../domain/repositories/alert_repository.dart';
import '../domain/repositories/report_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/repositories/dashboard_repository.dart';
import '../domain/repositories/settings_repository.dart';

import '../data/repositories/mock/mock_baitguard_data_source.dart';
import '../data/repositories/mock/mock_auth_repository.dart';
import '../data/repositories/mock/mock_access_request_repository.dart';
import '../data/repositories/mock/mock_station_repository.dart';
import '../data/repositories/mock/mock_alert_repository.dart';
import '../data/repositories/mock/mock_report_repository.dart';
import '../data/repositories/mock/mock_user_repository.dart';
import '../data/repositories/mock/mock_dashboard_repository.dart';
import '../data/repositories/mock/mock_settings_repository.dart';

class AppProviders {
  static List<SingleChildWidget> get providers => [
    Provider<MockBaitGuardDataSource>(
      create: (_) => MockBaitGuardDataSource.seeded(),
    ),
    Provider<AuthRepository>(
      create: (context) =>
          MockAuthRepository(context.read<MockBaitGuardDataSource>()),
    ),
    Provider<AccessRequestRepository>(
      create: (context) =>
          MockAccessRequestRepository(context.read<MockBaitGuardDataSource>()),
    ),
    Provider<StationRepository>(
      create: (context) =>
          MockStationRepository(context.read<MockBaitGuardDataSource>()),
    ),
    Provider<AlertRepository>(
      create: (context) =>
          MockAlertRepository(context.read<MockBaitGuardDataSource>()),
    ),
    Provider<UserRepository>(
      create: (context) =>
          MockUserRepository(context.read<MockBaitGuardDataSource>()),
    ),
    Provider<ReportRepository>(
      create: (context) =>
          MockReportRepository(context.read<MockBaitGuardDataSource>()),
    ),
    Provider<DashboardRepository>(
      create: (context) =>
          MockDashboardRepository(context.read<MockBaitGuardDataSource>()),
    ),
    Provider<SettingsRepository>(create: (_) => MockSettingsRepository()),
    ChangeNotifierProvider<AppSessionController>(
      create: (_) => AppSessionController(),
    ),
  ];
}
