import '../../../domain/models/access_request.dart';
import '../../../domain/models/access_request_record.dart';
import '../../../domain/repositories/access_request_repository.dart';
import 'mock_baitguard_data_source.dart';

class MockAccessRequestRepository implements AccessRequestRepository {
  final MockBaitGuardDataSource _dataSource;

  MockAccessRequestRepository(this._dataSource);

  @override
  Future<void> submitRequest(AccessRequest request) async {
    await Future.delayed(const Duration(seconds: 1));
    _dataSource.addAccessRequest(request);
  }

  @override
  Future<List<AccessRequestRecord>> getPendingRequests({String? siteId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _dataSource.accessRequests
        .where((r) => r.status == AccessRequestStatus.pending)
        .toList();
  }
}
