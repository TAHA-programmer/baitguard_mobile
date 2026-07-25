import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'route_names.dart';
import '../../legacy/legacy_main_navigation.dart';
import '../../features/onboarding/views/welcome_screen.dart';
import '../../features/authentication/views/login_screen.dart';
import '../../features/authentication/view_models/login_view_model.dart';
import '../../features/authentication/views/request_access_screen.dart';
import '../../features/authentication/views/request_submitted_screen.dart';
import '../../features/authentication/view_models/request_access_view_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/access_request_repository.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../app/state/app_session_controller.dart';
import '../../features/navigation/views/user_app_shell.dart';
import '../../features/dashboard/view_models/user_dashboard_view_model.dart';
import '../../features/navigation/views/admin_app_shell.dart';
import '../../features/dashboard/view_models/admin_dashboard_view_model.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    if (settings.name == RouteNames.legacy) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const MainNavigation(),
      );
    }

    if (settings.name == RouteNames.welcome) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const WelcomeScreen(),
      );
    }

    if (settings.name == RouteNames.login) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => ChangeNotifierProvider(
          create: (_) => LoginViewModel(
            context.read<AuthRepository>(),
            context.read<AppSessionController>(),
          ),
          child: const LoginScreen(),
        ),
      );
    }

    if (settings.name == RouteNames.requestAccess) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => ChangeNotifierProvider(
          create: (_) =>
              RequestAccessViewModel(context.read<AccessRequestRepository>()),
          child: const RequestAccessScreen(),
        ),
      );
    }

    if (settings.name == RouteNames.requestSubmitted) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const RequestSubmittedScreen(),
      );
    }

    if (settings.name == RouteNames.userDashboard) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => ChangeNotifierProvider(
          create: (_) => UserDashboardViewModel(
            dashboardRepository: context.read<DashboardRepository>(),
            sessionController: context.read<AppSessionController>(),
          )..load(),
          child: const UserAppShell(),
        ),
      );
    }

    if (settings.name == RouteNames.adminDashboard) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => ChangeNotifierProvider(
          create: (_) => AdminDashboardViewModel(
            dashboardRepository: context.read<DashboardRepository>(),
            sessionController: context.read<AppSessionController>(),
          )..load(),
          child: const AdminAppShell(),
        ),
      );
    }

    throw Exception('Unknown route: ${settings.name}');
  }
}
