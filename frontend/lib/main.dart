import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_router.dart';
import 'core/auth/auth_state.dart';
import 'core/supabase/supabase_init.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/data/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: MomentApp()));
}

class MomentApp extends ConsumerStatefulWidget {
  const MomentApp({super.key});

  @override
  ConsumerState<MomentApp> createState() => _MomentAppState();
}

class _MomentAppState extends ConsumerState<MomentApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSupabase();
    });
  }

  Future<void> _initializeSupabase() async {
    final notifier = ref.read(supabaseInitializationProvider.notifier);
    notifier.state = const AsyncValue<void>.loading();

    try {
      await initializeSupabaseClient();
      final authRepository = ref.read(authRepositoryProvider);
      if (authRepository.currentSession != null) {
        await authRepository.syncCurrentUser();
        ref.read(appAuthStateProvider.notifier).state =
            const AppAuthState.authenticated();
      }
      notifier.state = const AsyncValue<void>.data(null);
    } catch (error, stackTrace) {
      notifier.state = AsyncValue<void>.error(error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'MOMENT',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
