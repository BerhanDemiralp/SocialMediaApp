import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_state.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response.session != null) {
        ref.read(appAuthStateProvider.notifier).state =
            const AppAuthState.authenticated();
        if (mounted) {
          context.go('/');
        }
      } else {
        setState(() {
          _error = 'Sign in failed. Please check your credentials.';
        });
      }
    } catch (e) {
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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response.user != null) {
        setState(() {
          _error = 'Check your email to confirm your account.';
        });
      } else {
        setState(() {
          _error = 'Sign up failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Sign up failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    final isBusy = _isLoading;

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
                FilledButton(
                  onPressed: isBusy ? null : _signIn,
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
                  onPressed: isBusy ? null : _signUp,
                  child: const Text('Sign up'),
                ),
                TextButton(
                  onPressed: isBusy ? null : _sendResetEmail,
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
