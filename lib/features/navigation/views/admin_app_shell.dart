import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../dashboard/view_models/admin_dashboard_view_model.dart';
import '../../dashboard/views/admin_dashboard_screen.dart';
import '../models/admin_alert_list_preset.dart';
import '../widgets/authenticated_bottom_navigation.dart';
import 'pending_feature_tab.dart';

class AdminAppShell extends StatefulWidget {
  const AdminAppShell({super.key});

  @override
  State<AdminAppShell> createState() => _AdminAppShellState();
}

class _AdminAppShellState extends State<AdminAppShell> {
  int _currentIndex = 0;
  AdminAlertListPreset _alertPreset = AdminAlertListPreset.all;

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
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
            AdminDashboardScreen(onSelectTab: switchTab),
            const PendingFeatureTab(
              title: 'Stations',
              icon: Icons.place_outlined,
              message: 'Station monitoring will be available here shortly.',
            ),
            // TODO: Use _alertPreset when full Alerts screen is implemented
            const PendingFeatureTab(
              title: 'Alerts',
              icon: Icons.notifications_outlined,
              message: 'Alert management will be available here shortly.',
            ),
            const PendingFeatureTab(
              title: 'Reports',
              icon: Icons.insert_chart_outlined,
              message: 'Reporting tools will be available here shortly.',
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
