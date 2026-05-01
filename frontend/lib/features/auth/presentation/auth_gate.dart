import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/app_analytics.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/supabase/supabase_init.dart';
import '../data/auth_repository.dart';

class AuthGateScreen extends ConsumerStatefulWidget {
  const AuthGateScreen({super.key});

  @override
  ConsumerState<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<AuthGateScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final analytics = ref.read(appAnalyticsProvider);

    setState(() {
      _isLoading = true;
      _error = null;
    });

    analytics.trackEvent('login_submitted', {});

    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response.session != null) {
        analytics.trackEvent('login_succeeded', {});
        ref.read(appAuthStateProvider.notifier).state =
            const AppAuthState.authenticated();
        if (mounted) {
          context.go('/');
        }
      } else {
        analytics.trackEvent('login_failed', {'type': 'validation'});
        setState(() {
          _error = 'Sign in failed. Please check your credentials.';
        });
      }
    } on StateError catch (e) {
      analytics.trackEvent('login_failed', {'type': 'server'});
      setState(() {
        _error = e.message.isNotEmpty
            ? e.message
            : 'Sign in failed. Please try again.';
      });
    } catch (_) {
      analytics.trackEvent('login_failed', {'type': 'network'});
      setState(() {
        _error = 'Sign in failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signUp() async {
    if (!mounted) return;
    context.go('/auth/register');
  }

  Future<void> _sendResetEmail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.sendPasswordResetEmail(_emailController.text.trim());
      setState(() {
        _error = 'If an account exists, a reset email has been sent.';
      });
    } catch (e) {
      setState(() {
        _error = 'Could not send reset email. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabaseState = ref.watch(supabaseInitializationProvider);
    final isSupabaseReady = supabaseState.hasValue;
    final isSupabaseLoading = supabaseState.isLoading;
    final isBusy = _isLoading || isSupabaseLoading;
    final supabaseError = supabaseState.hasError
        ? 'Missing Supabase config. Restart with SUPABASE_URL and SUPABASE_ANON_KEY.'
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to MOMENT')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (supabaseError != null) ...[
                  Text(
                    supabaseError,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                FilledButton(
                  onPressed: !isSupabaseReady || isBusy ? null : _signIn,
                  child: isBusy
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign in'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: !isSupabaseReady || isBusy ? null : _signUp,
                  child: const Text('Sign up'),
                ),
                TextButton(
                  onPressed:
                      !isSupabaseReady || isBusy ? null : _sendResetEmail,
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
