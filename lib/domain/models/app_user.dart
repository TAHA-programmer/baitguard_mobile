import 'user_role.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final List<String> siteAccessIds;

  // Profile specific fields
  final String? firstName;
  final String? lastName;
  final String? jobTitle;
  final String? department;
  final String? phoneNumber;
  final String? shortBio;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    List<String> siteAccessIds = const [],
    this.firstName,
    this.lastName,
    this.jobTitle,
    this.department,
    this.phoneNumber,
    this.shortBio,
  }) : siteAccessIds = List.unmodifiable(siteAccessIds);

  AppUser copyWith({
    String? name,
    String? firstName,
    String? lastName,
    String? jobTitle,
    String? department,
    String? phoneNumber,
    String? shortBio,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      isActive: isActive,
      siteAccessIds: siteAccessIds,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      jobTitle: jobTitle ?? this.jobTitle,
      department: department ?? this.department,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      shortBio: shortBio ?? this.shortBio,
    );
  }
}
