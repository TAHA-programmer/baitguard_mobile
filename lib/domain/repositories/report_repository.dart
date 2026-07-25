import '../models/report.dart';

abstract class ReportRepository {
  Future<List<Report>> getReports();
  Future<Report> generateReport(
    String type,
    DateTime startDate,
    DateTime endDate,
  );
}
