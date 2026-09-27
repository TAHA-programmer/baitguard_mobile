import '../../../domain/models/report_models.dart';
import '../../../domain/repositories/report_repository.dart';
import 'realtime_station_data_source.dart';

class RealtimeReportRepository implements ReportRepository {
  final RealtimeStationDataSource _dataSource;

  RealtimeReportRepository(this._dataSource);

  @override
  Future<ReportsDashboardData> getDashboardData({
    required String siteId,
    required ReportPeriod period,
  }) async {
    if (siteId != RealtimeStationDataSource.kPilotFacilityId) {
      return _buildEmptyReportsData();
    }

    final station = await _dataSource.fetchStation(
      RealtimeStationDataSource.kPilotStationId,
    );
    final allEvents = await _dataSource.fetchStationEvents(
      RealtimeStationDataSource.kPilotStationId,
    );

    final (startDate, endDate) = _resolveDateRange(period);

    final periodEvents = allEvents.where((e) {
      final ts = e.timestamp.toLocal();
      return ts.isAfter(startDate) && ts.isBefore(endDate);
    }).toList();

    final totalDetections = periodEvents.length;

    final summary = ReportSummary(
      totalDetections: totalDetections,
      baitRefills: null, // Unsupported by RTDB schema
      systemUptimePercent: null, // Unsupported by RTDB schema
      averageAiConfidencePercent: null, // Unsupported by RTDB schema
      detectionsChangePercent: null,
      baitRefillsChangePercent: null,
      uptimeChangePercent: null,
      confidenceChangePercent: null,
    );

    final trendPoints = _computeTrendPoints(periodEvents, startDate, endDate, period.type);

    final ledger = <StationReportLedgerEntry>[];
    if (station != null) {
      ledger.add(
        StationReportLedgerEntry(
          stationId: station.id,
          stationCode: station.name,
          location: station.locationDescription,
          detections: totalDetections,
          baitRefills: null,
          uptimePercent: null,
        ),
      );
    }

    return ReportsDashboardData(
      summary: summary,
      detectionTrend: trendPoints,
      stationLedger: ledger,
      recentExports: const [],
    );
  }

  @override
  Future<ReportExport> generateReport(ReportGenerationRequest request) async {
    return ReportExport(
      id: 'export_${DateTime.now().millisecondsSinceEpoch}',
      siteId: request.siteId,
      templateType: request.templateType,
      format: ReportFileFormat.pdf,
      title: 'Activity Report',
      fileName: 'activity_report.pdf',
      fileSizeBytes: 1024,
      generatedAt: DateTime.now(),
      period: request.period,
    );
  }

  @override
  Future<List<ReportExport>> getRecentExports({required String siteId}) async {
    return const [];
  }

  // ---------------------------------------------------------------------------
  // Date Range and Trend Computation
  // ---------------------------------------------------------------------------

  (DateTime, DateTime) _resolveDateRange(ReportPeriod period) {
    final anchor = period.anchorDate;
    switch (period.type) {
      case ReportPeriodType.week:
        final start = anchor.subtract(const Duration(days: 7));
        return (start, anchor.add(const Duration(days: 1)));
      case ReportPeriodType.month:
        final start = DateTime(anchor.year, anchor.month - 1, anchor.day);
        return (start, anchor.add(const Duration(days: 1)));
      case ReportPeriodType.quarter:
        final start = DateTime(anchor.year, anchor.month - 3, anchor.day);
        return (start, anchor.add(const Duration(days: 1)));
      case ReportPeriodType.year:
        final start = DateTime(anchor.year - 1, anchor.month, anchor.day);
        return (start, anchor.add(const Duration(days: 1)));
    }
  }

  List<ReportTrendPoint> _computeTrendPoints(
    List<dynamic> events,
    DateTime startDate,
    DateTime endDate,
    ReportPeriodType type,
  ) {
    final points = <ReportTrendPoint>[];
    final totalDays = endDate.difference(startDate).inDays;
    final stepDays = (totalDays / 7).clamp(1, 30).round();

    DateTime current = startDate;
    while (current.isBefore(endDate)) {
      final next = current.add(Duration(days: stepDays));
      final count = events.where((e) {
        final ts = (e.timestamp as DateTime).toLocal();
        return ts.isAfter(current) && ts.isBefore(next);
      }).length;

      points.add(ReportTrendPoint(date: current, value: count.toDouble()));
      current = next;
    }
    return points;
  }

  ReportsDashboardData _buildEmptyReportsData() {
    return const ReportsDashboardData(
      summary: ReportSummary(
        totalDetections: 0,
        baitRefills: null,
        systemUptimePercent: null,
        averageAiConfidencePercent: null,
        detectionsChangePercent: null,
        baitRefillsChangePercent: null,
        uptimeChangePercent: null,
        confidenceChangePercent: null,
      ),
      detectionTrend: [],
      stationLedger: [],
      recentExports: [],
    );
  }
}
