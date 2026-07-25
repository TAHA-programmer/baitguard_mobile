import '../../../domain/models/app_user.dart';
import '../../../domain/repositories/user_repository.dart';
import 'mock_baitguard_data_source.dart';

class MockUserRepository implements UserRepository {
  final MockBaitGuardDataSource _dataSource;

  MockUserRepository(this._dataSource);

  @override
  Future<List<AppUser>> getUsers({String? siteId}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _dataSource.users;
  }

  @override
  Future<AppUser?> getUserById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _dataSource.users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }
}
