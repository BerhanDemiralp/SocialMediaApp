import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_state.dart';
import '../../auth/presentation/auth_gate.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBusy = ValueNotifier<bool>(false);

    Future<void> logout() async {
      if (isBusy.value) return;
      isBusy.value = true;
      try {
        final repo = ref.read(authRepositoryProvider);
        await repo.signOut();
        ref.read(appAuthStateProvider.notifier).state =
            const AppAuthState.unauthenticated();
        if (context.mounted) {
          context.go('/auth');
        }
      } finally {
        isBusy.value = false;
      }
    }

    return Center(
      child: ValueListenableBuilder<bool>(
        valueListenable: isBusy,
        builder: (context, busy, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('You are logged in to MOMENT.'),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: busy ? null : logout,
                child: busy
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Log out'),
              ),
            ],
          );
        },
      ),
    );
  }
}

