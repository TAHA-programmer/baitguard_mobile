import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:baitguard/domain/repositories/auth_repository.dart';
import 'package:baitguard/features/authentication/views/login_screen.dart';
import 'package:baitguard/features/authentication/view_models/login_view_model.dart';
import 'package:baitguard/features/authentication/views/request_submitted_screen.dart';
import 'package:baitguard/features/authentication/widgets/request_next_steps_card.dart';
import 'package:baitguard/features/authentication/widgets/request_success_icon.dart';
import 'package:baitguard/app/navigation/route_names.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/core/widgets/primary_button.dart';
import 'package:baitguard/app/state/app_session_controller.dart';

class _DummyAuthRepository implements AuthRepository {
  @override
  Future<AppUser?> getCurrentUser() async => null;
  @override
  Future<AppUser> login(String email, String password) async =>
      throw UnimplementedError();
  @override
  Future<void> logout() async {}
}

void main() {
  Widget buildTestApp() {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: _DummyAuthRepository()),
        ChangeNotifierProvider(create: (_) => AppSessionController()),
      ],
      child: MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == RouteNames.login) {
            return MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                create: (_) => LoginViewModel(
                  context.read<AuthRepository>(),
                  context.read<AppSessionController>(),
                ),
                child: const LoginScreen(),
              ),
            );
          }
          if (settings.name == RouteNames.requestSubmitted) {
            return MaterialPageRoute(
              builder: (context) => const RequestSubmittedScreen(),
            );
          }
          return null;
        },
        initialRoute: RouteNames.login,
      ),
    );
  }

  testWidgets('RequestSubmittedScreen renders correctly and back behavior', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pushNamed(RouteNames.requestSubmitted);
    await tester.pumpAndSettle();

    expect(find.byType(RequestSubmittedScreen), findsOneWidget);

    // Verify UI components
    expect(find.byType(RequestSuccessIcon), findsOneWidget);
    expect(find.text('Request Submitted\nSuccessfully'), findsOneWidget);
    expect(find.byType(RequestNextStepsCard), findsOneWidget);

    // Check specific texts in the next steps card
    expect(find.text('What happens next?'), findsOneWidget);
    expect(
      find.text('Your request will be reviewed by your system administrator.'),
      findsOneWidget,
    );
    expect(
      find.text('Your administrator will create your account if approved.'),
      findsOneWidget,
    );
    expect(
      find.text('You\'ll receive an email with login instructions.'),
      findsOneWidget,
    );

    // Test primary button back to login
    final button = find.widgetWithText(PrimaryButton, 'Back to Login');
    await tester.dragUntilVisible(
      button,
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(RequestSubmittedScreen), findsNothing);
  });

  testWidgets('System back returns to LoginScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pushNamed(RouteNames.requestSubmitted);
    await tester.pumpAndSettle();

    expect(find.byType(RequestSubmittedScreen), findsOneWidget);

    // Simulate system back
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(RequestSubmittedScreen), findsNothing);
  });
}
