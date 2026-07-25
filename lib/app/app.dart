import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_providers.dart';
import 'theme/app_theme.dart';
import 'navigation/app_router.dart';
import '../features/splash/views/splash_screen.dart';
import '../features/splash/view_models/splash_view_model.dart';

class BaitGuardApp extends StatelessWidget {
  const BaitGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProviders.providers,
      child: MaterialApp(
        title: 'BaitGuard',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: ChangeNotifierProvider(
          create: (_) => SplashViewModel(),
          child: const SplashScreen(),
        ),
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
