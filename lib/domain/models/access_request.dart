class AccessRequest {
  const AccessRequest({
    required this.fullName,
    required this.email,
    required this.company,
    required this.phone,
    this.department,
    this.message,
    required this.submittedAt,
  });

  final String fullName;
  final String email;
  final String company;
  final String phone;
  final String? department;
  final String? message;
  final DateTime submittedAt;
}
