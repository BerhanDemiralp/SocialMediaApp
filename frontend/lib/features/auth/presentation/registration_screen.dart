import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/app_analytics.dart';
import '../../../core/auth/auth_state.dart';
import '../data/auth_repository.dart';
import 'auth_gate.dart';

class RegistrationState {
  final String email;
  final String username;
  final String password;
  final bool isSubmitting;
  final String? errorMessage;

  const RegistrationState({
    required this.email,
    required this.username,
    required this.password,
    required this.isSubmitting,
    this.errorMessage,
  });

  bool get isValid =>
      email.trim().isNotEmpty &&
      email.contains('@') &&
      username.trim().isNotEmpty &&
      password.trim().length >= 8;

  RegistrationState copyWith({
    String? email,
    String? username,
    String? password,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return RegistrationState(
      email: email ?? this.email,
      username: username ?? this.username,
      password: password ?? this.password,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  const RegistrationState.initial()
      : email = '',
        username = '',
        password = '',
        isSubmitting = false,
        errorMessage = null;
}

class RegistrationController extends StateNotifier<RegistrationState> {
  RegistrationController(this._authRepository, this._analytics)
      : super(const RegistrationState.initial());

  final AuthRepository _authRepository;
  final AppAnalytics _analytics;

  void updateEmail(String value) {
    state = state.copyWith(email: value);
  }

  void updateUsername(String value) {
    state = state.copyWith(username: value);
  }

  void updatePassword(String value) {
    state = state.copyWith(password: value);
  }

  Future<bool> submit(WidgetRef ref) async {
    if (!state.isValid || state.isSubmitting) {
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);
    _analytics.trackEvent('registration_submitted', {});

    try {
      final response = await _authRepository.signUpWithEmail(
        state.email.trim(),
        state.username.trim(),
        state.password.trim(),
      );

      if (response.session != null) {
        _analytics.trackEvent('registration_succeeded', {});
        ref.read(appAuthStateProvider.notifier).state =
            const AppAuthState.authenticated();
        return true;
      } else {
        _analytics.trackEvent('registration_failed', {'type': 'validation'});
        state = state.copyWith(
          errorMessage:
              'Registration failed. Please check your details and try again.',
        );
        return false;
      }
    } on StateError catch (e) {
      // Server-side / validation error coming from the backend.
      final message = e.message;
      var failureType = 'server';

      if (message.toLowerCase().contains('already')) {
        failureType = 'validation';
      } else if (message.toLowerCase().contains('password')) {
        failureType = 'validation';
      }

      _analytics.trackEvent('registration_failed', {'type': failureType});
      state = state.copyWith(
        errorMessage: message.isNotEmpty
            ? message
            : 'Registration failed. Please try again later.',
      );
      return false;
    } catch (_) {
      _analytics.trackEvent('registration_failed', {'type': 'network'});
      state = state.copyWith(
        errorMessage: 'Could not register. Please try again later.',
      );
      return false;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}

final registrationControllerProvider =
    StateNotifierProvider<RegistrationController, RegistrationState>((ref) {
  final authRepo = ref.read(authRepositoryProvider);
  final analytics = ref.read(appAnalyticsProvider);
  return RegistrationController(authRepo, analytics);
});

class RegistrationScreen extends ConsumerWidget {
  const RegistrationScreen({super.key});

  String? _emailError(RegistrationState state) {
    final value = state.email.trim();
    if (value.isEmpty) return null;
    if (!value.contains('@')) return 'Enter a valid email address';
    return null;
  }

  String? _usernameError(RegistrationState state) {
    final value = state.username.trim();
    if (value.isEmpty) return null;
    if (value.length < 3) return 'Username must be at least 3 characters';
    return null;
  }

  String? _passwordError(RegistrationState state) {
    final value = state.password;
    if (value.isEmpty) return null;
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registrationControllerProvider);
    final isBusy = state.isSubmitting;

    // Fire registration_started once per mount.
    ref.listen<RegistrationState>(registrationControllerProvider,
        (previous, next) {
      if (previous == null) {
        ref.read(appAnalyticsProvider).trackEvent('registration_started', {});
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create your MOMENT account'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'MOMENT helps you build a cozy conversation habit with friends.',
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    errorText: _emailError(state),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) =>
                      ref.read(registrationControllerProvider.notifier).updateEmail(
                            value,
                          ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Username',
                    errorText: _usernameError(state),
                  ),
                  onChanged: (value) =>
                      ref.read(registrationControllerProvider.notifier).updateUsername(
                            value,
                          ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    errorText: _passwordError(state),
                  ),
                  obscureText: true,
                  onChanged: (value) =>
                      ref.read(registrationControllerProvider.notifier).updatePassword(
                            value,
                          ),
                ),
                const SizedBox(height: 16),
                if (state.errorMessage != null) ...[
                  Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                FilledButton(
                  onPressed: !state.isValid || isBusy
                      ? null
                      : () async {
                          final ok = await ref
                              .read(registrationControllerProvider.notifier)
                              .submit(ref);
                          if (ok && context.mounted) {
                            context.go('/');
                          }
                        },
                  child: isBusy
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create account'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: isBusy
                      ? null
                      : () {
                          if (context.mounted) {
                            context.go('/auth');
                          }
                        },
                  child: const Text('Already have an account? Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
