import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:baitguard/domain/models/access_request.dart';
import 'package:baitguard/domain/models/access_request_record.dart';
import 'package:baitguard/domain/repositories/access_request_repository.dart';
import 'package:baitguard/domain/repositories/auth_repository.dart';
import 'package:baitguard/features/authentication/views/login_screen.dart';
import 'package:baitguard/features/authentication/views/request_access_screen.dart';
import 'package:baitguard/features/authentication/view_models/login_view_model.dart';
import 'package:baitguard/features/authentication/view_models/request_access_view_model.dart';
import 'package:baitguard/features/authentication/views/request_submitted_screen.dart';
import 'package:baitguard/app/navigation/route_names.dart';
import 'package:baitguard/core/widgets/primary_button.dart';
import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/domain/models/app_user.dart';

class MockTestAccessRequestRepository implements AccessRequestRepository {
  bool requestAccessCalled = false;
  AccessRequest? lastRequest;

  @override
  Future<void> submitRequest(AccessRequest request) async {
    requestAccessCalled = true;
    lastRequest = request;
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<List<AccessRequestRecord>> getPendingRequests({
    String? siteId,
  }) async => [];
}

class DummyAuthRepository implements AuthRepository {
  @override
  Future<AppUser?> getCurrentUser() async => null;
  @override
  Future<AppUser> login(String email, String password) async =>
      throw UnimplementedError();
  @override
  Future<void> logout() async {}
}

void main() {
  Widget buildTestApp(MockTestAccessRequestRepository mockRepo) {
    return MultiProvider(
      providers: [
        Provider<AccessRequestRepository>.value(value: mockRepo),
        Provider<AuthRepository>.value(value: DummyAuthRepository()),
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
          if (settings.name == RouteNames.requestAccess) {
            return MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                create: (_) => RequestAccessViewModel(
                  context.read<AccessRequestRepository>(),
                ),
                child: const RequestAccessScreen(),
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

  testWidgets('Navigation and Request Access form behavior', (
    WidgetTester tester,
  ) async {
    final mockRepo = MockTestAccessRequestRepository();

    await tester.pumpWidget(buildTestApp(mockRepo));
    await tester.pumpAndSettle();

    // 1. Navigate from Login to Request Access
    await tester.ensureVisible(find.text('Contact Administrator'));
    await tester.tap(find.text('Contact Administrator'));
    await tester.pumpAndSettle();

    expect(find.byType(RequestAccessScreen), findsOneWidget);

    // 2. Empty submission shows inline errors for required fields
    await tester.ensureVisible(find.text('Send Request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Request'));
    await tester.pump(); // Pump for validation state

    expect(find.text('Full name is required.'), findsOneWidget);
    expect(find.text('Company email is required.'), findsOneWidget);
    expect(find.text('Company or organisation is required.'), findsOneWidget);
    expect(find.text('Phone number is required.'), findsOneWidget);

    // 3. Fill invalid email and phone
    await tester.enterText(find.byType(TextFormField).at(0), 'John Smith');
    await tester.enterText(find.byType(TextFormField).at(1), 'bademail');
    await tester.enterText(find.byType(TextFormField).at(2), 'Acme Corp');
    await tester.enterText(
      find.byType(TextFormField).at(3),
      '123',
    ); // Too short

    await tester.ensureVisible(find.text('Send Request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Request'));
    await tester.pump();

    expect(find.text('Enter a valid company email.'), findsOneWidget);
    expect(find.text('Enter a valid phone number.'), findsOneWidget);

    // 4. Fill valid required fields, leave optional empty
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'john@company.com',
    );
    await tester.enterText(find.byType(TextFormField).at(3), '555-019-9999');

    await tester.ensureVisible(find.text('Send Request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Request'));
    await tester.pump(); // Start loading

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the mock request to complete
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    // 5. Verify repository was called correctly
    expect(mockRepo.requestAccessCalled, isTrue);
    expect(mockRepo.lastRequest?.fullName, 'John Smith');
    expect(mockRepo.lastRequest?.email, 'john@company.com');
    expect(mockRepo.lastRequest?.department, isNull);
    expect(mockRepo.lastRequest?.message, isNull);

    // 6. Verify navigation occurred instead of toast
    expect(find.text('Request submitted successfully.'), findsNothing);
    expect(find.byType(RequestSubmittedScreen), findsOneWidget);
    expect(find.byType(RequestAccessScreen), findsNothing);

    // 7. Ensure Back to Login button returns to Login
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
}
