import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../dashboard/view_models/admin_dashboard_view_model.dart';
import '../../dashboard/views/admin_dashboard_screen.dart';
import '../../stations/navigation/stations_flow_navigator.dart';
import '../../reports/navigation/reports_flow_navigator.dart';
import '../models/admin_alert_list_preset.dart';
import '../widgets/authenticated_bottom_navigation.dart';
import '../../alerts/navigation/alerts_flow_navigator.dart';

class AdminAppShell extends StatefulWidget {
  const AdminAppShell({super.key});

  @override
  State<AdminAppShell> createState() => _AdminAppShellState();
}

class _AdminAppShellState extends State<AdminAppShell> {
  int _currentIndex = 0;
  AdminAlertListPreset _alertPreset = AdminAlertListPreset.all;
  final GlobalKey<AlertsFlowNavigatorState> _alertsNavigatorKey =
      GlobalKey<AlertsFlowNavigatorState>();
  final GlobalKey<StationsFlowNavigatorState> _stationsNavigatorKey =
      GlobalKey<StationsFlowNavigatorState>();

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      if (index == 2) {
        _alertsNavigatorKey.currentState?.showList(
          preset: AdminAlertListPreset.all,
        );
      }
      return;
    }
    setState(() {
      _currentIndex = index;
      if (index == 2) {
        // If they manually tapped the Alerts tab, use the default 'all' preset.
        _alertPreset = AdminAlertListPreset.all;
      }
    });
  }

  void switchTab(
    int index, {
    AdminAlertListPreset preset = AdminAlertListPreset.all,
  }) {
    if (_currentIndex == index && _alertPreset == preset) return;
    setState(() {
      _currentIndex = index;
      if (index == 2) {
        _alertPreset = preset;
      }
    });
    // Need a tiny delay for navigator to be built if it was offstage or not initialized
    if (index == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _alertsNavigatorKey.currentState?.showList(preset: preset);
      });
    }
  }

  void openAlertDetail(String alertId) {
    setState(() {
      _currentIndex = 2;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _alertsNavigatorKey.currentState?.openAlertDetail(alertId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadAlertCount = context.select<AdminDashboardViewModel, int>(
      (vm) => vm.data?.unreadAlertCount ?? 0,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            AdminDashboardScreen(
              onSelectTab: switchTab,
              onAlertTap: openAlertDetail,
            ),
            // Screen 08 - Stations nested flow
            StationsFlowNavigator(key: _stationsNavigatorKey),
            // Screen 09 - Alerts nested flow
            AlertsFlowNavigator(
              key: _alertsNavigatorKey,
              initialPreset: _alertPreset,
            ),
            // Screen 14 - Reports nested flow
            ReportsFlowNavigator(
              onStationTap: (stationId) {
                setState(() {
                  _currentIndex = 1;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _stationsNavigatorKey.currentState?.openStationDetail(
                    stationId,
                  );
                });
              },
            ),
          ],
        ),
        bottomNavigationBar: AuthenticatedBottomNavigation(
          selectedIndex: _currentIndex,
          unreadAlertCount: unreadAlertCount,
          onSelected: _onTabTapped,
        ),
      ),
    );
  }
}
