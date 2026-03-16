import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env/app_env.dart';

class AuthRepository {
  AuthRepository(this._client, this._httpClient);

  final SupabaseClient _client;
  final http.Client _httpClient;

  Future<AuthResponse> signInWithEmail(
    String email,
    String password,
  ) {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Register via the NestJS `/auth/register` endpoint and then sign in
  /// with Supabase Flutter so the local client has a session.
  Future<AuthResponse> signUpWithEmail(
    String email,
    String username,
    String password,
  ) async {
    final uri = Uri.parse('${AppEnv.apiBaseUrl}/auth/register');

    http.Response response;
    try {
      response = await _httpClient.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'username': username,
        }),
      );
    } catch (_) {
      throw StateError(
        'Could not reach the registration server. Please try again later.',
      );
    }

    if (response.statusCode != 201 && response.statusCode != 200) {
      String errorMessage =
          'Registration failed. Please check your details and try again.';

      try {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;
        final dynamic rawMessage = body['message'];

        if (rawMessage is String && rawMessage.isNotEmpty) {
          errorMessage = rawMessage;
        } else if (rawMessage is List && rawMessage.isNotEmpty) {
          errorMessage = rawMessage.first.toString();
        }
      } catch (_) {
        // Ignore JSON parsing errors and fall back to the generic message.
      }

      throw StateError(errorMessage);
    }

    // On successful backend registration, sign in via Supabase so the
    // Flutter client has a valid session for subsequent API calls.
    final authResponse = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    return authResponse;
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  Session? get currentSession => _client.auth.currentSession;
}
