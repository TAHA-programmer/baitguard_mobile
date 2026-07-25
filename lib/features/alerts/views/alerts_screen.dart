import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../domain/models/alert.dart';
import '../../../domain/models/alert_status.dart';
import '../view_models/alerts_view_model.dart';
import '../models/alert_list_filter.dart';
import 'widgets/alert_severity_summary_card.dart';
import 'widgets/alert_row.dart';
import 'widgets/critical_attention_banner.dart';
import 'widgets/hotspot_station_row.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AlertsViewModel>();

    if (vm.isLoading && vm.todayAlerts.isEmpty && vm.earlierAlerts.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      );
    }

    if (vm.error != null && vm.todayAlerts.isEmpty && vm.earlierAlerts.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                vm.error!,
                style: AppTypography.manropeRegular.copyWith(
                  fontSize: 14,
                  color: AppColors.criticalRed,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<AlertsViewModel>().refresh(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (vm.refreshError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.refreshError!),
            backgroundColor: AppColors.criticalRed,
          ),
        );
      });
    }
    
    if (vm.actionErrorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.actionErrorMessage!),
            backgroundColor: AppColors.criticalRed,
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: () => context.read<AlertsViewModel>().refresh(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(vm),
                    const SizedBox(height: 24),
                    _buildSeverityCards(vm),
                    const SizedBox(height: 24),
                    _buildCriticalBanner(vm),
                    const SizedBox(height: 24),
                    _buildFilters(vm),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildAlertSection(
              context,
              title: _getPrimarySectionTitle(vm.selectedFilter),
              alerts: vm.todayAlerts,
              vm: vm,
            ),
            _buildAlertSection(
              context,
              title: 'Earlier',
              alerts: vm.earlierAlerts,
              vm: vm,
            ),
            if (vm.todayAlerts.isEmpty && vm.earlierAlerts.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  child: Center(
                    child: Text(
                      'No alerts match this filter.',
                      style: AppTypography.manropeRegular.copyWith(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildActivityChart(vm),
                    const SizedBox(height: 32),
                    _buildHotspots(vm),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AlertsViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alerts',
          style: AppTypography.manropeBold.copyWith(
            fontSize: 24,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${vm.unreadCount} unread · ${vm.unresolvedCount} unresolved',
          style: AppTypography.manropeRegular.copyWith(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityCards(AlertsViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: AlertSeveritySummaryCard(
            label: 'High',
            count: vm.highCount,
            color: AppColors.criticalRed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AlertSeveritySummaryCard(
            label: 'Medium',
            count: vm.mediumCount,
            color: AppColors.warningAmber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AlertSeveritySummaryCard(
            label: 'Low',
            count: vm.lowCount,
            color: AppColors.primaryBlue, // or textSecondary/info
          ),
        ),
      ],
    );
  }

  Widget _buildCriticalBanner(AlertsViewModel vm) {
    final criticals = vm.criticalUnresolvedAlerts;
    if (criticals.isEmpty) return const SizedBox.shrink();

    final stationIds = criticals.map((a) => a.stationId).toSet().toList();
    final stationText = stationIds.join(' & ');

    return CriticalAttentionBanner(
      count: criticals.length,
      stationIdsText: stationText,
      onTap: () {
        vm.setFilter(AlertListFilter.all);
      },
    );
  }

  Widget _buildFilters(AlertsViewModel vm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AlertListFilter.values.map((filter) {
          final isSelected = vm.selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_getFilterName(filter)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  vm.setFilter(filter);
                }
              },
              selectedColor: AppColors.primaryBlue,
              backgroundColor: Colors.white,
              labelStyle: AppTypography.manropeRegular.copyWith(
                fontSize: 13,
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryBlue : AppColors.borderSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFilterName(AlertListFilter filter) {
    switch (filter) {
      case AlertListFilter.all: return 'All';
      case AlertListFilter.rodent: return 'Rodent';
      case AlertListFilter.lowBait: return 'Low bait';
      case AlertListFilter.tamper: return 'Tamper';
      case AlertListFilter.offline: return 'Offline';
    }
  }

  String _getPrimarySectionTitle(AlertListFilter filter) {
    switch (filter) {
      case AlertListFilter.all: return 'Today';
      case AlertListFilter.rodent: return 'Rodent';
      case AlertListFilter.lowBait: return 'Low bait';
      case AlertListFilter.tamper: return 'Tamper';
      case AlertListFilter.offline: return 'Offline';
    }
  }

  Widget _buildAlertSection(BuildContext context, {required String title, required List<Alert> alerts, required AlertsViewModel vm}) {
    if (alerts.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  title,
                  style: AppTypography.manropeBold.copyWith(
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }
            final alert = alerts[index - 1];
            final station = vm.getStationForAlert(alert.id);
            return AlertRow(
              alert: alert,
              stationLocation: station?.locationDescription ?? 'Unknown location',
              onTap: () {
                Navigator.of(context).pushNamed('/alert-detail', arguments: alert.id);
              },
              onResolve: vm.permissions?.canResolve == true && alert.status != AlertStatus.resolved && alert.status != AlertStatus.dismissed
                  ? () => vm.resolveAlert(alert.id)
                  : null,
              onSnooze: vm.permissions?.canSnooze == true && alert.status != AlertStatus.resolved && alert.status != AlertStatus.dismissed
                  ? () => vm.snoozeAlert(alert.id, DateTime.now().add(const Duration(hours: 1)))
                  : null,
            );
          },
          childCount: alerts.length + 1,
        ),
      ),
    );
  }

  Widget _buildActivityChart(AlertsViewModel vm) {
    final activity = vm.sevenDayActivity;
    if (activity.isEmpty) return const SizedBox.shrink();

    // Max count for Y axis scaling
    final maxY = activity.map((e) => e.count).fold(0, (a, b) => a > b ? a : b).toDouble();
    final topY = (maxY + 5).ceilToDouble(); // give some padding

    final spots = activity.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.count.toDouble());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This week',
          style: AppTypography.manropeSemiBold.copyWith(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 150,
          padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8, left: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSecondary),
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < activity.length) {
                        final date = activity[idx].day;
                        final isFirstOrLast = idx == 0 || idx == activity.length - 1;
                        if (!isFirstOrLast && idx % 2 != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '${date.month}/${date.day}',
                            style: AppTypography.manropeBold.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    interval: 1,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (activity.length - 1).toDouble(),
              minY: 0,
              maxY: topY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.criticalRed,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.criticalRed.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHotspots(AlertsViewModel vm) {
    final hotspots = vm.hotspotStations;
    if (hotspots.isEmpty) return const SizedBox.shrink();
    
    final maxCount = hotspots.first.alertCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hotspot stations',
          style: AppTypography.manropeSemiBold.copyWith(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSecondary),
          ),
          child: Column(
            children: hotspots.map((h) {
              return HotspotStationRow(
                hotspot: h,
                maxCount: maxCount,
                onTap: () {
                  Navigator.of(context).pushNamed('/station-detail', arguments: h.stationId);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
