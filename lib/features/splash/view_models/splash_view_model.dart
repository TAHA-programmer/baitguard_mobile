import 'dart:async';
import 'package:flutter/foundation.dart';

class SplashViewModel extends ChangeNotifier {
  bool _isCompleted = false;
  bool get isCompleted => _isCompleted;
  Timer? _timer;

  void initialize(Duration splashDuration) {
    // Prevent multiple initializations
    if (_timer != null || _isCompleted) return;

    _timer = Timer(splashDuration, () {
      _isCompleted = true;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
