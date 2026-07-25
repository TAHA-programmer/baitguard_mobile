// ignore_for_file: unused_field

import '../../../domain/models/report.dart';
import '../../../domain/repositories/report_repository.dart';
import 'mock_baitguard_data_source.dart';

class MockReportRepository implements ReportRepository {
  final MockBaitGuardDataSource _dataSource;

  MockReportRepository(this._dataSource);

  @override
  Future<List<Report>> getReports() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return [];
  }

  @override
  Future<Report> generateReport(
    String type,
    DateTime startDate,
    DateTime endDate,
  ) async {
    await Future.delayed(const Duration(seconds: 2));
    throw UnimplementedError(); // Simplified for mock MVP
  }
}
