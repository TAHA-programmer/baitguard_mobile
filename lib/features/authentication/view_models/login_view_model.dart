import 'package:flutter/foundation.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/models/auth_failure.dart';
import '../../../app/state/app_session_controller.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final AppSessionController _sessionController;

  LoginViewModel(this._authRepository, this._sessionController);

  String _email = '';
  String _password = '';
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;
  String? _generalError;

  String get email => _email;
  String get password => _password;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get rememberMe => _rememberMe;
  bool get isLoading => _isLoading;

  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  String? get generalError => _generalError;

  void setEmail(String value) {
    _email = value;
    if (_emailError != null) {
      _emailError = null;
      notifyListeners();
    }
  }

  void setPassword(String value) {
    _password = value;
    if (_passwordError != null) {
      _passwordError = null;
      notifyListeners();
    }
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    notifyListeners();
  }

  void clearErrors() {
    _emailError = null;
    _passwordError = null;
    _generalError = null;
    notifyListeners();
  }

  bool _validate() {
    bool isValid = true;
    clearErrors();

    final trimmedEmail = _email.trim();
    if (trimmedEmail.isEmpty) {
      _emailError = 'Email address is required.';
      isValid = false;
    } else if (!trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
      _emailError = 'Enter a valid email address.';
      isValid = false;
    }

    if (_password.isEmpty) {
      _passwordError = 'Password is required.';
      isValid = false;
    } else if (_password.length < 6) {
      _passwordError = 'Password must contain at least 6 characters.';
      isValid = false;
    }

    if (!isValid) {
      notifyListeners();
    }
    return isValid;
  }

  Future<bool> login() async {
    if (_isLoading) return false;

    if (!_validate()) return false;

    _isLoading = true;
    _generalError = null;
    notifyListeners();

    try {
      final user = await _authRepository.login(_email.trim(), _password);
      _sessionController.establishSession(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthFailure catch (e) {
      _isLoading = false;
      if (e.type == AuthFailureType.invalidCredentials) {
        _generalError = 'Incorrect email or password. Please try again.';
      } else if (e.type == AuthFailureType.accountInactive) {
        _generalError = 'This account is inactive. Contact your administrator.';
      } else {
        _generalError = 'Unable to sign in right now. Please try again.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _generalError = 'Unable to sign in right now. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
