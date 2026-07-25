import '../../../domain/models/app_user.dart';
import '../../../domain/models/auth_failure.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'mock_baitguard_data_source.dart';

class MockAuthRepository implements AuthRepository {
  final MockBaitGuardDataSource _dataSource;
  AppUser? _currentUser;

  MockAuthRepository(this._dataSource);

  @override
  Future<AppUser?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _currentUser;
  }

  @override
  Future<AppUser> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final user = _dataSource.authenticate(email, password);

    if (user == null) {
      throw const AuthFailure(AuthFailureType.invalidCredentials);
    }

    if (!user.isActive) {
      throw const AuthFailure(AuthFailureType.accountInactive);
    }

    _currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }
}
