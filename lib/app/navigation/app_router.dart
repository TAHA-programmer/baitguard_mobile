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
import '../../domain/repositories/station_repository.dart';
import '../../app/state/app_session_controller.dart';
import '../../app/state/active_facility_controller.dart';
import '../../features/navigation/views/user_app_shell.dart';
import '../../features/dashboard/view_models/user_dashboard_view_model.dart';
import '../../features/navigation/views/admin_app_shell.dart';
import '../../features/dashboard/view_models/admin_dashboard_view_model.dart';
import '../../features/stations/view_models/stations_view_model.dart';
import '../../features/settings/views/settings_screen.dart';
import '../../features/settings/views/edit_profile_screen.dart';
import '../../features/settings/view_models/settings_view_model.dart';
import '../../features/settings/view_models/edit_profile_view_model.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/user_repository.dart';

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
        builder: (context) {
          final session = context.read<AppSessionController>();
          final user = session.currentUser;

          // Build the permitted site IDs for this viewer/technician.
          final permittedSiteIds = user?.siteAccessIds ?? const [];

          return MultiProvider(
            providers: [
              ChangeNotifierProvider<ActiveFacilityController>(
                create: (_) => ActiveFacilityController(
                  permittedSiteIds: List<String>.unmodifiable(permittedSiteIds),
                ),
              ),
              ChangeNotifierProvider<UserDashboardViewModel>(
                create: (_) => UserDashboardViewModel(
                  dashboardRepository: context.read<DashboardRepository>(),
                  sessionController: session,
                )..load(),
              ),
              ChangeNotifierProxyProvider<
                ActiveFacilityController,
                StationsViewModel
              >(
                create: (ctx) => StationsViewModel(
                  stationRepository: context.read<StationRepository>(),
                  sessionController: session,
                  activeFacilityController: ctx
                      .read<ActiveFacilityController>(),
                ),
                update: (context, controller, previous) => previous!,
              ),
            ],
            child: const UserAppShell(),
          );
        },
      );
    }

    if (settings.name == RouteNames.adminDashboard) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) {
          final session = context.read<AppSessionController>();
          final user = session.currentUser;
          final permittedSiteIds = user?.siteAccessIds ?? const [];

          return MultiProvider(
            providers: [
              ChangeNotifierProvider<ActiveFacilityController>(
                create: (_) => ActiveFacilityController(
                  permittedSiteIds: List<String>.unmodifiable(permittedSiteIds),
                ),
              ),
              ChangeNotifierProxyProvider<
                ActiveFacilityController,
                AdminDashboardViewModel
              >(
                create: (ctx) => AdminDashboardViewModel(
                  dashboardRepository: context.read<DashboardRepository>(),
                  sessionController: session,
                  activeFacilityController: ctx
                      .read<ActiveFacilityController>(),
                )..load(),
                update: (context, controller, previous) => previous!,
              ),
              ChangeNotifierProxyProvider<
                ActiveFacilityController,
                StationsViewModel
              >(
                create: (ctx) => StationsViewModel(
                  stationRepository: context.read<StationRepository>(),
                  sessionController: session,
                  activeFacilityController: ctx
                      .read<ActiveFacilityController>(),
                ),
                update: (context, controller, previous) => previous!,
              ),
            ],
            child: const AdminAppShell(),
          );
        },
      );
    }

    if (settings.name == RouteNames.settings) {
      final activeFacilityController =
          settings.arguments as ActiveFacilityController;
      return MaterialPageRoute(
        settings: settings,
        builder: (context) {
          final session = context.read<AppSessionController>();
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<ActiveFacilityController>.value(
                value: activeFacilityController,
              ),
              ChangeNotifierProvider<SettingsViewModel>(
                create: (_) => SettingsViewModel(
                  settingsRepository: context.read<SettingsRepository>(),
                  sessionController: session,
                  activeFacilityController: activeFacilityController,
                ),
              ),
            ],
            child: const SettingsScreen(),
          );
        },
      );
    }

    if (settings.name == RouteNames.editProfile) {
      // Arguments: the AppSessionController is globally available;
      // UserRepository is globally provided — no extra args needed.
      return MaterialPageRoute(
        settings: settings,
        builder: (context) {
          final session = context.read<AppSessionController>();
          return ChangeNotifierProvider<EditProfileViewModel>(
            create: (_) => EditProfileViewModel(
              userRepository: context.read<UserRepository>(),
              sessionController: session,
            ),
            child: const EditProfileScreen(),
          );
        },
      );
    }

    throw Exception('Unknown route: ${settings.name}');
  }
}
