import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'state/app_session_controller.dart';
import 'state/auth_session_coordinator.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/access_request_repository.dart';
import '../domain/repositories/admin_invitation_repository.dart';
import '../domain/repositories/station_repository.dart';
import '../domain/repositories/alert_repository.dart';
import '../domain/repositories/report_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/repositories/dashboard_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/login_preferences_repository.dart';
import '../domain/repositories/account_activation_repository.dart';

import '../data/repositories/mock/mock_baitguard_data_source.dart';
import '../data/repositories/firebase/firebase_auth_repository.dart';
import '../data/repositories/firebase/firestore_user_repository.dart';
import '../data/repositories/firebase/firestore_access_request_repository.dart';
import '../data/repositories/firebase/firestore_account_activation_repository.dart';
import '../data/repositories/mock/mock_station_repository.dart';
import '../data/repositories/mock/mock_alert_repository.dart';
import '../data/repositories/mock/mock_report_repository.dart';
import '../data/repositories/mock/mock_user_repository.dart';
import '../data/repositories/mock/mock_dashboard_repository.dart';
import '../data/repositories/mock/mock_settings_repository.dart';
import '../data/repositories/preferences/shared_preferences_login_repository.dart';

class AppProviders {
  static List<SingleChildWidget> get providers => [
    Provider<MockBaitGuardDataSource>(
      create: (_) => MockBaitGuardDataSource.seeded(),
    ),
    Provider<AuthRepository>(
      create: (_) => FirebaseAuthRepository(FirebaseAuth.instance),
    ),
    Provider<UserRepository>(
      create: (_) => FirestoreUserRepository(
        FirebaseFirestore.instance,
        FirebaseAuth.instance,
      ),
    ),
    Provider<LoginPreferencesRepository>(
      create: (_) => SharedPreferencesLoginRepository(),
    ),
    Provider<AccessRequestRepository>(
      create: (_) => FirestoreAccessRequestRepository(
        FirebaseFirestore.instance,
        FirebaseAuth.instance,
      ),
    ),
    Provider<AdminInvitationRepository>(
      create: (context) =>
          context.read<AccessRequestRepository>() as AdminInvitationRepository,
    ),
    Provider<AccountActivationRepository>(
      create: (_) => FirestoreAccountActivationRepository(
        FirebaseFirestore.instance,
        FirebaseAuth.instance,
      ),
    ),
    Provider<StationRepository>(
      create: (context) =>
          MockStationRepository(context.read<MockBaitGuardDataSource>()),
    ),
    Provider<AlertRepository>(
      create: (context) =>
          MockAlertRepository(context.read<MockBaitGuardDataSource>()),
    ),
    Provider<MockUserRepository>(
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
    Provider<SettingsRepository>(
      create: (context) =>
          MockSettingsRepository(context.read<MockBaitGuardDataSource>()),
    ),
    ChangeNotifierProvider<AppSessionController>(
      create: (_) => AppSessionController(),
    ),
    ChangeNotifierProvider<AuthSessionCoordinator>(
      lazy: false,
      create: (context) => AuthSessionCoordinator(
        authRepository: context.read<AuthRepository>(),
        userRepository: context.read<UserRepository>(),
        sessionController: context.read<AppSessionController>(),
      )..initialize(),
    ),
  ];
}
