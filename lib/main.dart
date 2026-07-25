import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Attempt Firebase initialization, but don't block the mock frontend if it fails
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint(
      'Firebase init bypassed or failed (expected in mock frontend phase): \$e',
    );
  }

  runApp(const BaitGuardApp());
}
