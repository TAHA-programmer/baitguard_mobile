import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../domain/models/alert.dart';
import '../../../domain/models/alert_type.dart';
import '../../../domain/models/alert_status.dart';
import '../../../domain/models/alert_severity.dart';
import '../view_models/alert_detail_view_model.dart';

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AlertDetailViewModel>();

    if (vm.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      );
    }

    if (vm.error != null) {
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
                onPressed: () => context.read<AlertDetailViewModel>().refresh(),
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
    
    if (vm.actionSuccessMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.actionSuccessMessage!),
            backgroundColor: AppColors.successGreen,
          ),
        );
      });
    }

    final alert = vm.alert;
    final station = vm.station;

    if (alert == null || station == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Alert not found.')),
      );
    }

    final isResolved = alert.status == AlertStatus.resolved;
    final isDismissed = alert.status == AlertStatus.dismissed;
    final isActionable = !isResolved && !isDismissed;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBackButton(context),
                  const SizedBox(height: 24),
                  Text(
                    'Alert Detail',
                    style: AppTypography.manropeBold.copyWith(
                      fontSize: 24,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSummaryCard(alert, station.locationDescription),
                  const SizedBox(height: 24),
                  _buildInformationCard(alert, station.name, station.locationDescription),
                  if (alert.type == AlertType.rodent) ...[
                    const SizedBox(height: 24),
                    _buildEvidenceCard(),
                  ],
                  const SizedBox(height: 32),
                  if (isActionable) _buildActionArea(context, vm),
                  if (vm.permissions?.canViewStation == true) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/station-detail', arguments: station.id);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.borderSecondary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('View Station'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: AppColors.borderSecondary),
        ),
        child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildSummaryCard(Alert alert, String location) {
    IconData iconData = Icons.info_outline;
    Color color = AppColors.primaryBlue;

    switch (alert.type) {
      case AlertType.rodent:
        iconData = Icons.pest_control;
        color = AppColors.criticalRed;
        break;
      case AlertType.lowBait:
        iconData = Icons.battery_alert;
        color = AppColors.warningAmber;
        break;
      case AlertType.tamper:
        iconData = Icons.warning_amber_rounded;
        color = AppColors.criticalRed;
        break;
      case AlertType.stationOffline:
        iconData = Icons.wifi_off;
        color = AppColors.primaryBlue;
        break;
    }

    if (alert.severity == AlertSeverity.critical) {
      color = AppColors.criticalRed;
    }

    String statusText = '';
    Color statusBgColor = Colors.transparent;
    Color statusTextColor = Colors.black;

    switch (alert.status) {
      case AlertStatus.open:
        statusText = 'Open';
        statusBgColor = AppColors.criticalRed.withOpacity(0.1);
        statusTextColor = AppColors.criticalRed;
        break;
      case AlertStatus.pending:
        statusText = 'Pending';
        statusBgColor = AppColors.warningAmber.withOpacity(0.1);
        statusTextColor = AppColors.warningAmber;
        break;
      case AlertStatus.inReview:
        statusText = 'In review';
        statusBgColor = AppColors.primaryBlue.withOpacity(0.1);
        statusTextColor = AppColors.primaryBlue;
        break;
      case AlertStatus.resolved:
        statusText = 'Resolved';
        statusBgColor = AppColors.successGreen.withOpacity(0.1);
        statusTextColor = AppColors.successGreen;
        break;
      case AlertStatus.dismissed:
        statusText = 'Dismissed';
        statusBgColor = AppColors.borderSecondary;
        statusTextColor = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSecondary),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: color, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            alert.description,
            style: AppTypography.manropeBold.copyWith(
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${alert.stationId} · $location',
            style: AppTypography.manropeRegular.copyWith(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: AppTypography.manropeMedium.copyWith(
                fontSize: 13,
                color: statusTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard(Alert alert, String stationName, String location) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Information',
            style: AppTypography.manropeSemiBold.copyWith(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Station', stationName),
          _buildInfoRow('Location', location),
          _buildInfoRow('Date', '${alert.timestamp.month}/${alert.timestamp.day}/${alert.timestamp.year}'),
          _buildInfoRow('Time', _formatTime(alert.timestamp)),
          _buildInfoRow('Alert type', _getAlertTypeName(alert.type)),
          _buildInfoRow('Priority', _getSeverityName(alert.severity)),
          if (alert.snoozedUntil != null)
            _buildInfoRow('Snoozed until', '${alert.snoozedUntil!.month}/${alert.snoozedUntil!.day} ${_formatTime(alert.snoozedUntil!)}'),
          if (alert.assignedTechnicianId != null)
            _buildInfoRow('Assigned to', 'Technician (${alert.assignedTechnicianId})'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.manropeRegular.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.manropeMedium.copyWith(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evidence',
            style: AppTypography.manropeSemiBold.copyWith(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSecondary),
            ),
            child: const Center(
              child: Icon(Icons.camera_alt_outlined, color: AppColors.textSecondary, size: 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea(BuildContext context, AlertDetailViewModel vm) {
    return Column(
      children: [
        if (vm.permissions?.canResolve == true)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: vm.isMutating ? null : () => vm.resolveAlert(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Mark as resolved'),
            ),
          ),
        const SizedBox(height: 12),
        if (vm.permissions?.canSnooze == true)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: vm.isMutating ? null : () {
                vm.snoozeAlert(DateTime.now().add(const Duration(hours: 1)));
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.borderSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Snooze'),
            ),
          ),
        const SizedBox(height: 12),
        if (vm.permissions?.canAssign == true)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: vm.isMutating ? null : () {
                _showAssignDialog(context, vm);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.borderSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Assign to technician'),
            ),
          ),
        const SizedBox(height: 12),
        if (vm.permissions?.canDismiss == true)
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: vm.isMutating ? null : () => vm.dismissAlert(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: AppColors.criticalRed,
              ),
              child: const Text('Dismiss alert'),
            ),
          ),
      ],
    );
  }

  void _showAssignDialog(BuildContext context, AlertDetailViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assign Technician',
                  style: AppTypography.manropeBold.copyWith(
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  title: const Text('Ahmed Khan'),
                  subtitle: const Text('technician@baitguard.com'),
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  onTap: () {
                    Navigator.pop(ctx);
                    vm.assignAlert('tech_1');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }

  String _getAlertTypeName(AlertType type) {
    switch (type) {
      case AlertType.rodent: return 'Rodent';
      case AlertType.lowBait: return 'Low bait';
      case AlertType.tamper: return 'Tamper';
      case AlertType.stationOffline: return 'Offline';
    }
  }

  String _getSeverityName(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical: return 'High';
      case AlertSeverity.warning: return 'Medium';
      case AlertSeverity.info: return 'Low';
    }
  }
}
