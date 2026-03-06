import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_gate.dart';
import '../features/home/presentation/home_shell.dart';

final authStateProvider = StateProvider<AuthState>((ref) {
  return const AuthState.unauthenticated();
});

class AuthState {
  final bool isAuthenticated;

  const AuthState._(this.isAuthenticated);

  const AuthState.authenticated() : this._(true);

  const AuthState.unauthenticated() : this._(false);
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final loggingIn = state.matchedLocation == '/auth';

      if (!authState.isAuthenticated && !loggingIn) {
        return '/auth';
      }

      if (authState.isAuthenticated && loggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthGateScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeShellScreen()),
    ],
  );
});
