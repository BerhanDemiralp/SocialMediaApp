import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moment_app/features/auth/data/auth_repository.dart';
import 'package:moment_app/features/auth/presentation/auth_gate.dart';
import 'package:moment_app/features/auth/presentation/registration_screen.dart';
import 'package:moment_app/core/auth/auth_state.dart';
import 'package:moment_app/core/analytics/app_analytics.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Session? get currentSession => null;

  @override
  Future<AuthResponse> signInWithEmail(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<AuthResponse> signUpWithEmail(
    String email,
    String username,
    String password,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError();
  }
}

class _SuccessfulRegistrationController extends RegistrationController {
  _SuccessfulRegistrationController()
      : super(_FakeAuthRepository(), const AppAnalytics());

  @override
  Future<bool> submit(WidgetRef ref) async {
    if (!state.isValid || state.isSubmitting) {
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    // Simulate a successful registration that authenticates the user.
    ref.read(appAuthStateProvider.notifier).state =
        const AppAuthState.authenticated();

    state = state.copyWith(isSubmitting: false);

    // Return false so the widget's onPressed callback does not
    // attempt to call context.go('/') in this test environment,
    // where no GoRouter is configured.
    return false;
  }
}

class _ErrorRegistrationController extends RegistrationController {
  _ErrorRegistrationController(this._message)
      : super(_FakeAuthRepository(), const AppAnalytics());

  final String _message;

  @override
  Future<bool> submit(WidgetRef ref) async {
    if (!state.isValid || state.isSubmitting) {
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);
    state = state.copyWith(errorMessage: _message, isSubmitting: false);
    return false;
  }
}

class _BusyRegistrationController extends RegistrationController {
  _BusyRegistrationController()
      : super(_FakeAuthRepository(), const AppAnalytics()) {
    // Simulate an in-flight request.
    state = state.copyWith(isSubmitting: true);
  }
}

void main() {
  testWidgets(
    'registration submit is disabled when form is invalid and enabled when valid',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RegistrationScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially, the form is empty and the submit button should be disabled.
      FilledButton button =
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      // Fill in valid values for all fields.
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Username'),
        'testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'password123',
      );

      await tester.pumpAndSettle();

      button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets(
    'registration screen shows inline validation messages for invalid input',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RegistrationScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter an invalid email.
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'invalid-email',
      );

      // Enter a too-short username.
      await tester.enterText(
        find.widgetWithText(TextField, 'Username'),
        'ab',
      );

      // Enter a too-short password.
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'short',
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Enter a valid email address'),
        findsOneWidget,
      );
      expect(
        find.text('Username must be at least 3 characters'),
        findsOneWidget,
      );
      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'boundary values (email with spaces, username length 3, password length 8) still enable submit',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RegistrationScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Valid email with leading/trailing spaces.
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        '  user@example.com  ',
      );
      // Username at minimum length.
      await tester.enterText(
        find.widgetWithText(TextField, 'Username'),
        'abc',
      );
      // Password at minimum length.
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        '12345678',
      );

      await tester.pumpAndSettle();

      final button =
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets(
    'successful registration authenticates the user (5.2)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            registrationControllerProvider.overrideWith(
              (ref) => _SuccessfulRegistrationController(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RegistrationScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fill in valid values.
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Username'),
        'testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'password123',
      );

      await tester.pumpAndSettle();

      // Tap the submit button.
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Verify that the auth state has been set to authenticated,
      // which is the prerequisite for navigating to the Home shell.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(RegistrationScreen)),
        listen: false,
      );
      final authState = container.read(appAuthStateProvider);
      expect(authState.isAuthenticated, isTrue);
    },
  );

  testWidgets(
    'backend error message is shown on the registration screen (5.3)',
    (WidgetTester tester) async {
      const errorMessage = 'Email already registered';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            registrationControllerProvider.overrideWith(
              (ref) => _ErrorRegistrationController(errorMessage),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RegistrationScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fill in valid values (to enable the submit button).
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Username'),
        'testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'password123',
      );

      await tester.pumpAndSettle();

      // Tap the submit button.
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // The error from the "backend" should be rendered in the UI.
      expect(find.text(errorMessage), findsOneWidget);
    },
  );

  testWidgets(
    'submit button stays disabled while a registration request is in-flight',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            registrationControllerProvider.overrideWith(
              (ref) => _BusyRegistrationController(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RegistrationScreen()),
          ),
        ),
      );

      // Just pump a single frame to build the widget tree.
      await tester.pump();

      final button =
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    },
  );
}
