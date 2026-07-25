import '../models/access_request.dart';
import '../models/access_request_record.dart';

abstract class AccessRequestRepository {
  Future<void> submitRequest(AccessRequest request);

  Future<List<AccessRequestRecord>> getPendingRequests({String? siteId});
}
