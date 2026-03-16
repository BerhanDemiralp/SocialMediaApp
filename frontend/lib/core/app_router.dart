import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth/auth_state.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/auth/presentation/registration_screen.dart';
import '../features/home/presentation/home_shell.dart';
import '../features/chat/presentation/chat_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(appAuthStateProvider);
      final loggingIn = state.matchedLocation.startsWith('/auth');

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
      GoRoute(
        path: '/conversation/:conversationId',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return ChatScreen(
            conversationId: conversationId,
          );
        },
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegistrationScreen(),
      ),
    ],
  );
});
