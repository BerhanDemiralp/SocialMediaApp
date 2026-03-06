import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Future<AuthResponse> signInWithEmail(
    String email,
    String password,
  ) {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail(
    String email,
    String password,
  ) {
    return _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  Session? get currentSession => _client.auth.currentSession;
}
