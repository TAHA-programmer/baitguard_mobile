import '../models/report_models.dart';

abstract class ReportRepository {
  Future<ReportsDashboardData> getDashboardData({
    required String siteId,
    required ReportPeriod period,
  });

  Future<ReportExport> generateReport(ReportGenerationRequest request);

  Future<List<ReportExport>> getRecentExports({required String siteId});
}
