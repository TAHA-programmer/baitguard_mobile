import '../../../domain/models/app_user.dart';
import '../../../domain/models/dashboard/activity_data_point.dart';
import '../../../domain/models/dashboard/admin_dashboard_data.dart';
import '../../../domain/models/dashboard/dashboard_alert_item.dart';
import '../../../domain/models/dashboard/dashboard_system_status.dart';
import '../../../domain/models/dashboard/facility_map_zone.dart';
import '../../../domain/models/dashboard/species_breakdown_item.dart';
import '../../../domain/models/dashboard/station_map_marker.dart';
import '../../../domain/models/dashboard/station_summary_metrics.dart';
import '../../../domain/models/dashboard/user_dashboard_data.dart';
import '../../../domain/models/dashboard/dashboard_species.dart';
import '../../../domain/models/site.dart';
import '../../../domain/models/station.dart';
import '../../../domain/models/station_status.dart';
import '../../../domain/repositories/dashboard_repository.dart';
import 'realtime_station_data_source.dart';

class RealtimeDashboardRepository implements DashboardRepository {
  final RealtimeStationDataSource _dataSource;

  RealtimeDashboardRepository(this._dataSource);

  @override
  Future<UserDashboardData> getUserDashboard({
    required AppUser user,
    String? siteId,
  }) async {
    final selectedSiteId = siteId ??
        (user.siteAccessIds.isNotEmpty
            ? user.siteAccessIds.first
            : RealtimeStationDataSource.kPilotFacilityId);

    if (selectedSiteId != RealtimeStationDataSource.kPilotFacilityId) {
      return _buildEmptyUserDashboard(user, selectedSiteId);
    }

    final station = await _dataSource.fetchStation(
      RealtimeStationDataSource.kPilotStationId,
    );
    final events = await _dataSource.fetchStationEvents(
      RealtimeStationDataSource.kPilotStationId,
    );
    final alerts = await _dataSource.fetchAlerts(siteId: selectedSiteId);

    final metrics = _computeStationMetrics(station);
    final now = DateTime.now();

    final detectionsToday = events.where((e) {
      final local = e.timestamp.toLocal();
      return local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;
    }).length;

    final activitySeries = _compute7DayActivitySeries(events, now);
    final speciesBreakdown = _computeSpeciesBreakdown(events);
    final recentAlertItems = _mapRecentAlerts(alerts, station);
    final mapMarkers = _buildMapMarkers(station);
    final facilityZones = _buildFacilityZones(station);

    int healthScore = 98;
    String statusMessage = 'ALL SYSTEMS NOMINAL';
    if (station == null || station.status == StationStatus.offline) {
      healthScore = 60;
      statusMessage = 'STATION OFFLINE';
    } else if (station.status == StationStatus.lowBait) {
      healthScore = 80;
      statusMessage = 'LOW BAIT ATTENTION';
    } else if (station.status == StationStatus.alert) {
      healthScore = 70;
      statusMessage = 'RODENT ACTIVITY DETECTED';
    }

    return UserDashboardData(
      user: user,
      healthScore: healthScore,
      healthScoreChange: 0,
      statusMessage: statusMessage,
      lastUpdatedAt: DateTime.now(),
      stationMetrics: metrics,
      detectionsToday: detectionsToday,
      activityChangePercentage: 0.0,
      unreadAlertCount: alerts.length,
      speciesBreakdown: speciesBreakdown,
      activitySeries: activitySeries,
      mapMarkers: mapMarkers,
      facilityZones: facilityZones,
      recentAlerts: recentAlertItems,
    );
  }

  @override
  Future<AdminDashboardData> getAdminDashboard({
    required AppUser admin,
    String? siteId,
  }) async {
    final selectedSiteId = siteId ?? RealtimeStationDataSource.kPilotFacilityId;

    final availableSites = admin.siteAccessIds
        .map(
          (id) => Site(
            id: id,
            name: id == RealtimeStationDataSource.kPilotFacilityId
                ? 'Warehouse A'
                : id,
            location: 'Main Site',
          ),
        )
        .toList();

    if (availableSites.isEmpty) {
      availableSites.add(
        const Site(
          id: RealtimeStationDataSource.kPilotFacilityId,
          name: 'Warehouse A',
          location: 'Main Site',
        ),
      );
    }

    final selectedSite = availableSites.firstWhere(
      (s) => s.id == selectedSiteId,
      orElse: () => availableSites.first,
    );

    if (selectedSiteId != RealtimeStationDataSource.kPilotFacilityId) {
      return _buildEmptyAdminDashboard(admin, selectedSite, availableSites);
    }

    final station = await _dataSource.fetchStation(
      RealtimeStationDataSource.kPilotStationId,
    );
    final events = await _dataSource.fetchStationEvents(
      RealtimeStationDataSource.kPilotStationId,
    );
    final alerts = await _dataSource.fetchAlerts(siteId: selectedSiteId);

    final metrics = _computeStationMetrics(station);
    final now = DateTime.now();

    final detectionsToday = events.where((e) {
      final local = e.timestamp.toLocal();
      return local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;
    }).length;

    final activitySeries = _compute7DayActivitySeries(events, now);
    final speciesBreakdown = _computeSpeciesBreakdown(events);
    final recentAlertItems = _mapRecentAlerts(alerts, station);
    final mapMarkers = _buildMapMarkers(station);
    final facilityZones = _buildFacilityZones(station);

    int healthScore = 98;
    String healthStatusMessage = 'ALL SYSTEMS NOMINAL';
    DashboardSystemStatus systemStatus = DashboardSystemStatus.healthy;

    if (station == null || station.status == StationStatus.offline) {
      healthScore = 60;
      healthStatusMessage = 'STATION OFFLINE';
      systemStatus = DashboardSystemStatus.warning;
    } else if (station.status == StationStatus.lowBait) {
      healthScore = 80;
      healthStatusMessage = 'LOW BAIT ATTENTION';
      systemStatus = DashboardSystemStatus.warning;
    } else if (station.status == StationStatus.alert) {
      healthScore = 70;
      healthStatusMessage = 'RODENT ACTIVITY DETECTED';
      systemStatus = DashboardSystemStatus.critical;
    }

    return AdminDashboardData(
      selectedSite: selectedSite,
      availableSites: availableSites,
      lastUpdatedAt: DateTime.now(),
      userCount: admin.siteAccessIds.length,
      pendingRequestCount: 0,
      newPendingRequestCountToday: 0,
      systemStatus: systemStatus,
      systemHealthScore: healthScore,
      healthScoreChange: 0,
      healthStatusMessage: healthStatusMessage,
      stationMetrics: metrics,
      detectionsToday: detectionsToday,
      detectionsChangePercentage: 0.0,
      criticalAlertCount:
          alerts.where((a) => a.severity.name == 'critical').length,
      unreadAlertCount: alerts.length,
      totalAlertCount: alerts.length,
      recentAlerts: recentAlertItems,
      activitySeries: activitySeries,
      speciesBreakdown: speciesBreakdown,
      mapMarkers: mapMarkers,
      facilityZones: facilityZones,
    );
  }

  // ---------------------------------------------------------------------------
  // Helper calculations
  // ---------------------------------------------------------------------------

  StationSummaryMetrics _computeStationMetrics(Station? station) {
    if (station == null) {
      return const StationSummaryMetrics(
        totalCount: 0,
        activeCount: 0,
        refillNeededCount: 0,
        offlineCount: 0,
      );
    }

    final isConn = stationIsConnected(station);
    final isLow = stationIsLowBait(station);
    final isOff = station.status == StationStatus.offline;

    return StationSummaryMetrics(
      totalCount: 1,
      activeCount: isConn ? 1 : 0,
      refillNeededCount: isLow ? 1 : 0,
      offlineCount: isOff ? 1 : 0,
    );
  }

  List<ActivityDataPoint> _compute7DayActivitySeries(
    List<dynamic> events,
    DateTime now,
  ) {
    final days = <ActivityDataPoint>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final count = events.where((e) {
        final local = (e.timestamp as DateTime).toLocal();
        return local.year == day.year &&
            local.month == day.month &&
            local.day == day.day;
      }).length;

      days.add(
        ActivityDataPoint(
          time: day,
          count: count,
        ),
      );
    }
    return days;
  }

  List<SpeciesBreakdownItem> _computeSpeciesBreakdown(List<dynamic> events) {
    if (events.isEmpty) {
      return const [
        SpeciesBreakdownItem(
          species: DashboardSpecies.rat,
          count: 0,
          percentage: 0.0,
        ),
        SpeciesBreakdownItem(
          species: DashboardSpecies.mouse,
          count: 0,
          percentage: 0.0,
        ),
        SpeciesBreakdownItem(
          species: DashboardSpecies.other,
          count: 0,
          percentage: 0.0,
        ),
      ];
    }

    return [
      SpeciesBreakdownItem(
        species: DashboardSpecies.rat,
        count: events.length,
        percentage: 100.0,
      ),
      const SpeciesBreakdownItem(
        species: DashboardSpecies.mouse,
        count: 0,
        percentage: 0.0,
      ),
      const SpeciesBreakdownItem(
        species: DashboardSpecies.other,
        count: 0,
        percentage: 0.0,
      ),
    ];
  }

  List<DashboardAlertItem> _mapRecentAlerts(
    List<dynamic> alerts,
    Station? station,
  ) {
    return alerts.take(5).map((a) {
      return DashboardAlertItem(
        id: a.id as String,
        title: a.description as String,
        location: station?.locationDescription ?? 'Warehouse A',
        timestamp: a.timestamp as DateTime,
        severity: a.severity,
        type: a.type,
        status: a.status,
      );
    }).toList();
  }

  List<StationMapMarker> _buildMapMarkers(Station? station) {
    if (station == null) return const [];
    return [
      StationMapMarker(
        stationId: station.id,
        name: station.name,
        normalizedX: 0.35,
        normalizedY: 0.45,
        status: station.status,
      ),
    ];
  }

  List<FacilityMapZone> _buildFacilityZones(Station? station) {
    return const [
      FacilityMapZone(
        id: 'zone_a',
        label: 'Zone A - Main Warehouse',
        left: 0.1,
        top: 0.1,
        width: 0.8,
        height: 0.8,
        labelX: 0.15,
        labelY: 0.15,
      ),
    ];
  }

  UserDashboardData _buildEmptyUserDashboard(AppUser user, String siteId) {
    final now = DateTime.now();
    return UserDashboardData(
      user: user,
      healthScore: 0,
      healthScoreChange: 0,
      statusMessage: 'NO ACTIVE DEPLOYMENT',
      lastUpdatedAt: now,
      stationMetrics: const StationSummaryMetrics(
        totalCount: 0,
        activeCount: 0,
        refillNeededCount: 0,
        offlineCount: 0,
      ),
      detectionsToday: 0,
      activityChangePercentage: 0.0,
      unreadAlertCount: 0,
      speciesBreakdown: const [],
      activitySeries: _compute7DayActivitySeries(const [], now),
      mapMarkers: const [],
      facilityZones: const [],
      recentAlerts: const [],
    );
  }

  AdminDashboardData _buildEmptyAdminDashboard(
    AppUser admin,
    Site selectedSite,
    List<Site> availableSites,
  ) {
    final now = DateTime.now();
    return AdminDashboardData(
      selectedSite: selectedSite,
      availableSites: availableSites,
      lastUpdatedAt: now,
      userCount: 0,
      pendingRequestCount: 0,
      newPendingRequestCountToday: 0,
      systemStatus: DashboardSystemStatus.healthy,
      systemHealthScore: 0,
      healthScoreChange: 0,
      healthStatusMessage: 'NO ACTIVE DEPLOYMENT',
      stationMetrics: const StationSummaryMetrics(
        totalCount: 0,
        activeCount: 0,
        refillNeededCount: 0,
        offlineCount: 0,
      ),
      detectionsToday: 0,
      detectionsChangePercentage: 0.0,
      criticalAlertCount: 0,
      unreadAlertCount: 0,
      totalAlertCount: 0,
      recentAlerts: const [],
      activitySeries: _compute7DayActivitySeries(const [], now),
      speciesBreakdown: const [],
      mapMarkers: const [],
      facilityZones: const [],
    );
  }
}
