import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth/auth_state.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/auth/presentation/registration_screen.dart';
import '../features/home/presentation/home_shell.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/groups/presentation/groups_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Moment')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Could not open this screen.'),
        ),
      ),
    ),
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
        path: '/groups',
        builder: (context, state) => const GroupsScreen(),
      ),
      GoRoute(
        path: '/conversation/:conversationId',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return ChatScreen(
            conversationId: conversationId,
            isGroup: state.uri.queryParameters['type'] == 'group',
            isTemporary: state.uri.queryParameters['temporary'] == '1',
            title: state.uri.queryParameters['title'],
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
