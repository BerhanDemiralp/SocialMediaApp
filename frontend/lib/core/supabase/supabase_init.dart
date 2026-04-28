import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../env/app_env.dart';

final supabaseInitializationProvider = StateProvider<AsyncValue<void>>((ref) {
  return const AsyncValue<void>.loading();
});

Future<void> initializeSupabaseClient() async {
  if (!AppEnv.isSupabaseConfigured) {
    throw StateError(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY. Pass them with --dart-define.',
    );
  }

  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey,
  );
}
