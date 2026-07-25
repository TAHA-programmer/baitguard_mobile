import 'user_role.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final List<String> siteAccessIds;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    List<String> siteAccessIds = const [],
  }) : siteAccessIds = List.unmodifiable(siteAccessIds);
}
