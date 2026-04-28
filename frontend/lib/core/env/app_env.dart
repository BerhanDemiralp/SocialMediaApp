import 'package:flutter/foundation.dart';

class AppEnv {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _wsBaseUrlOverride = String.fromEnvironment(
    'WS_BASE_URL',
  );

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    return kIsWeb ? 'http://localhost:3000/api' : 'http://10.0.2.2:3000/api';
  }

  static String get wsBaseUrl {
    if (_wsBaseUrlOverride.isNotEmpty) {
      return _wsBaseUrlOverride;
    }

    return kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
  }

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
