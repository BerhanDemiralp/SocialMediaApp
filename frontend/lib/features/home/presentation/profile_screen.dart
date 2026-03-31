import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_state.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../../core/theme/theme_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: isBusy,
          builder: (context, busy, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 36,
                        child: Text('M'),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Moment user',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You are logged in to MOMENT.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const ListTile(
                        leading: Icon(Icons.person),
                        title: Text('Edit profile'),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.lock),
                        title: Text('Privacy'),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.notifications),
                        title: Text('Notifications'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.groups),
                        title: const Text('My groups'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: busy
                            ? null
                            : () {
                                context.push('/groups');
                              },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.dark_mode),
                        title: const Text('Dark mode'),
                        subtitle: const Text('Use dark theme'),
                        value: themeMode == ThemeMode.dark,
                        onChanged: busy
                            ? null
                            : (value) {
                                ref.read(themeModeProvider.notifier).state =
                                    value ? ThemeMode.dark : ThemeMode.light;
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: const [
                      ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('About Moment'),
                      ),
                      Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.help_outline),
                        title: Text('Help & feedback'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: FilledButton.tonal(
                    onPressed: busy ? null : logout,
                    style: FilledButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.onErrorContainer,
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
                    ),
                    child: busy
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Log out'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
