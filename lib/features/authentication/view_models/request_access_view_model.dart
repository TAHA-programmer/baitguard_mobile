import 'package:flutter/foundation.dart';
import '../../../domain/models/access_request.dart';
import '../../../domain/repositories/access_request_repository.dart';

class RequestAccessViewModel extends ChangeNotifier {
  RequestAccessViewModel(this._accessRequestRepository);

  final AccessRequestRepository _accessRequestRepository;

  String _fullName = '';
  String _email = '';
  String _company = '';
  String _phone = '';
  String _department = '';
  String _message = '';

  String? _fullNameError;
  String? _emailError;
  String? _companyError;
  String? _phoneError;
  String? _generalError;

  bool _isLoading = false;
  bool _isSubmitted = false;

  String get fullName => _fullName;
  String get email => _email;
  String get company => _company;
  String get phone => _phone;
  String get department => _department;
  String get message => _message;

  String? get fullNameError => _fullNameError;
  String? get emailError => _emailError;
  String? get companyError => _companyError;
  String? get phoneError => _phoneError;
  String? get generalError => _generalError;

  bool get isLoading => _isLoading;
  bool get isSubmitted => _isSubmitted;

  void _onFieldEdited() {
    bool changed = false;
    if (_isSubmitted) {
      _isSubmitted = false;
      changed = true;
    }
    if (_generalError != null) {
      _generalError = null;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  void setFullName(String value) {
    _fullName = value;
    if (_fullNameError != null) {
      _fullNameError = null;
      notifyListeners();
    }
    _onFieldEdited();
  }

  void setEmail(String value) {
    _email = value;
    if (_emailError != null) {
      _emailError = null;
      notifyListeners();
    }
    _onFieldEdited();
  }

  void setCompany(String value) {
    _company = value;
    if (_companyError != null) {
      _companyError = null;
      notifyListeners();
    }
    _onFieldEdited();
  }

  void setPhone(String value) {
    _phone = value;
    if (_phoneError != null) {
      _phoneError = null;
      notifyListeners();
    }
    _onFieldEdited();
  }

  void setDepartment(String value) {
    _department = value;
    _onFieldEdited();
  }

  void setMessage(String value) {
    _message = value;
    _onFieldEdited();
  }

  bool _validate() {
    bool isValid = true;
    _fullNameError = null;
    _emailError = null;
    _companyError = null;
    _phoneError = null;
    _generalError = null;

    final trimmedFullName = _fullName.trim();
    if (trimmedFullName.isEmpty) {
      _fullNameError = 'Full name is required.';
      isValid = false;
    } else if (trimmedFullName.length < 2) {
      _fullNameError = 'Enter a valid full name.';
      isValid = false;
    }

    final trimmedEmail = _email.trim();
    if (trimmedEmail.isEmpty) {
      _emailError = 'Company email is required.';
      isValid = false;
    } else if (!trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
      _emailError = 'Enter a valid company email.';
      isValid = false;
    }

    final trimmedCompany = _company.trim();
    if (trimmedCompany.isEmpty) {
      _companyError = 'Company or organisation is required.';
      isValid = false;
    } else if (trimmedCompany.length < 2) {
      _companyError = 'Enter a valid company or organisation.';
      isValid = false;
    }

    final trimmedPhone = _phone.trim();
    if (trimmedPhone.isEmpty) {
      _phoneError = 'Phone number is required.';
      isValid = false;
    } else {
      final digitsOnly = trimmedPhone.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.length < 7 || digitsOnly.length > 15) {
        _phoneError = 'Enter a valid phone number.';
        isValid = false;
      }
    }

    if (!isValid) {
      notifyListeners();
    }
    return isValid;
  }

  Future<bool> submit() async {
    if (_isLoading || _isSubmitted) return false;

    if (!_validate()) return false;

    _isLoading = true;
    _generalError = null;
    notifyListeners();

    try {
      final request = AccessRequest(
        fullName: _fullName.trim(),
        email: _email.trim(),
        company: _company.trim(),
        phone: _phone.trim(),
        department: _department.trim().isNotEmpty ? _department.trim() : null,
        message: _message.trim().isNotEmpty ? _message.trim() : null,
        submittedAt: DateTime.now(),
      );

      await _accessRequestRepository.submitRequest(request);

      _isLoading = false;
      _isSubmitted = true;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _generalError = 'Failed to submit request. Please try again later.';
      notifyListeners();
      return false;
    }
  }
}
