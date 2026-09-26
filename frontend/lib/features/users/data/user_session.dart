import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/auth_state.dart';

final _sessionChangesProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Token refreshes do not reset the relationship store; account changes do.
final activeAccountIdProvider = Provider<String?>((ref) {
  if (!ref.watch(appAuthStateProvider).isAuthenticated) return null;
  final session = ref.watch(_sessionChangesProvider);
  return session.hasValue
      ? session.requireValue.session?.user.id
      : Supabase.instance.client.auth.currentUser?.id;
});

final conversationsRevisionProvider = StateProvider<int>((ref) => 0);
final identityRevisionProvider = StateProvider<int>((ref) => 0);
