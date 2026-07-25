import '../models/app_user.dart';

abstract class UserRepository {
  Future<List<AppUser>> getUsers();
  Future<AppUser?> getUserById(String id);
}
