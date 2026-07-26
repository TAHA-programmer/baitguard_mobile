import 'package:flutter/foundation.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../app/state/app_session_controller.dart';

enum EditProfileSaveStatus { idle, saving, success, failure }

class EditProfileViewModel extends ChangeNotifier {
  final UserRepository _userRepository;
  final AppSessionController _sessionController;

  // Mutable form state
  String firstName;
  String lastName;
  String jobTitle;
  String department;
  String phoneNumber;
  String shortBio;

  EditProfileSaveStatus _saveStatus = EditProfileSaveStatus.idle;
  String? _errorMessage;

  static const int maxBioLength = 200;

  EditProfileViewModel({
    required UserRepository userRepository,
    required AppSessionController sessionController,
  }) : _userRepository = userRepository,
       _sessionController = sessionController,
       firstName =
           sessionController.currentUser?.firstName ??
           _splitFirstName(sessionController.currentUser?.name ?? ''),
       lastName =
           sessionController.currentUser?.lastName ??
           _splitLastName(sessionController.currentUser?.name ?? ''),
       jobTitle = sessionController.currentUser?.jobTitle ?? '',
       department = sessionController.currentUser?.department ?? '',
       phoneNumber = sessionController.currentUser?.phoneNumber ?? '',
       shortBio = sessionController.currentUser?.shortBio ?? '';

  AppUser? get currentUser => _sessionController.currentUser;
  EditProfileSaveStatus get saveStatus => _saveStatus;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _saveStatus == EditProfileSaveStatus.saving;
  int get bioCharCount => shortBio.length;

  // Splits "John Anderson" → "John"
  static String _splitFirstName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  // Splits "John Anderson" → "Anderson"
  static String _splitLastName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  /// Returns null if valid, or a human-readable error string.
  String? validate() {
    if (firstName.trim().isEmpty) return 'First name is required.';
    if (lastName.trim().isEmpty) return 'Last name is required.';
    if (phoneNumber.trim().isNotEmpty &&
        !_isReasonablePhone(phoneNumber.trim())) {
      return 'Enter a valid phone number.';
    }
    if (shortBio.length > maxBioLength) {
      return 'Short bio must be $maxBioLength characters or fewer.';
    }
    return null;
  }

  bool _isReasonablePhone(String phone) {
    // Accepts +, digits, spaces, dashes, parens. At least 7 digits.
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 7) return false;
    return RegExp(r'^[\+\d\s\-\(\)]+$').hasMatch(phone);
  }

  Future<bool> save() async {
    final validationError = validate();
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    final user = currentUser;
    if (user == null) return false;

    _saveStatus = EditProfileSaveStatus.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      final fullName = '${firstName.trim()} ${lastName.trim()}'.trim();
      final updatedUser = user.copyWith(
        name: fullName,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        jobTitle: jobTitle.trim(),
        department: department.trim(),
        phoneNumber: phoneNumber.trim(),
        shortBio: shortBio.trim(),
      );

      await _userRepository.updateUser(updatedUser);

      // Synchronise the session so dashboard names and Settings header update.
      _sessionController.establishSession(updatedUser);

      _saveStatus = EditProfileSaveStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save profile. Please try again.';
      _saveStatus = EditProfileSaveStatus.failure;
      notifyListeners();
      return false;
    }
  }
}
