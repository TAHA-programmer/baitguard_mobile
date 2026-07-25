import '../models/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> getCurrentUser();
  Future<AppUser> login(String email, String password);
  Future<void> logout();
}
