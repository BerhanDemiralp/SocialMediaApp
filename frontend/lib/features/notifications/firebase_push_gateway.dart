import 'dart:convert';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/env/app_env.dart';
import 'notification_controller.dart';

class FirebasePushGateway implements PushGateway {
  FirebasePushGateway(this.client);
  final http.Client client;
  SharedPreferences? _prefs;
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  static const enabled = bool.fromEnvironment('PUSH_ENABLED');
  bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<bool> initialize() async {
    if (!enabled ||
        kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
        ].contains(defaultTargetPlatform)) {
      return false;
    }
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    if ([apiKey, appId, senderId, projectId].any((v) => v.isEmpty)) {
      return false;
    }
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: senderId,
        projectId: projectId,
        iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
      ),
    );
    _prefs = await SharedPreferences.getInstance();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
    return true;
  }

  @override
  Future<bool> permission({bool request = false}) async {
    var settings = await _messaging.getNotificationSettings();
    final asked = _prefs!.getBool('push.asked') ?? false;
    if (request &&
        !asked &&
        settings.authorizationStatus != AuthorizationStatus.authorized) {
      await _prefs!.setBool('push.asked', true);
      settings = await _messaging.requestPermission();
    }
    return [
      AuthorizationStatus.authorized,
      AuthorizationStatus.provisional,
    ].contains(settings.authorizationStatus);
  }

  @override
  Future<String?> token() async {
    if (_ios && await _messaging.getAPNSToken() == null) return null;
    await _messaging.setAutoInitEnabled(true);
    return _messaging.getToken();
  }

  @override
  Future<void> deleteToken() async {
    await _messaging.setAutoInitEnabled(false);
    await _messaging.deleteToken();
  }

  @override
  Stream<String> get tokenChanges => _messaging.onTokenRefresh;
  Stream<PushEvent> _events(Stream<RemoteMessage> stream) => stream
      .map((m) => PushEvent.parse(m.data))
      .where((e) => e != null)
      .cast<PushEvent>();
  @override
  Stream<PushEvent> get foreground => _events(FirebaseMessaging.onMessage);
  @override
  Stream<PushEvent> get taps => _events(FirebaseMessaging.onMessageOpenedApp);
  @override
  Future<PushEvent?> initialEvent() async {
    final initial = await _messaging.getInitialMessage();
    return initial == null ? null : PushEvent.parse(initial.data);
  }

  String _hex(int count) {
    final random = Random.secure();
    return List.generate(
      count,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<String> _installationId() async {
    var id = _prefs!.getString('push.id');
    if (id != null) return id;
    final raw = _hex(16);
    id =
        '${raw.substring(0, 8)}-${raw.substring(8, 12)}-4${raw.substring(13, 16)}-a${raw.substring(17, 20)}-${raw.substring(20)}';
    await _prefs!.setString('push.id', id);
    await _prefs!.setString('push.secret', _hex(32));
    await _prefs!.setInt('push.version', 0);
    return id;
  }

  Map<String, String> _headers(String account) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session?.user.id != account) throw StateError('Account changed');
    return {
      'Authorization': 'Bearer ${session!.accessToken}',
      'Content-Type': 'application/json',
    };
  }

  @override
  Future<void> register(String accountId, String token) async {
    final id = await _installationId();
    final response = await client
        .post(
          Uri.parse('${AppEnv.apiBaseUrl}/notifications/installations'),
          headers: _headers(accountId),
          body: jsonEncode({
            'id': id,
            'secret': _prefs!.getString('push.secret'),
            'token': token,
            'platform': _ios ? 'ios' : 'android',
            'version': _prefs!.getInt('push.version') ?? 0,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 409) {
      // A lost response or stale owner version must not permanently wedge registration.
      await setCleanupPending(true);
      await deleteToken();
      await _prefs!.remove('push.id');
      await _prefs!.remove('push.owner');
      await setCleanupPending(false);
      throw StateError('Registration changed; retry with a new installation');
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw StateError('Registration failed');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    await _prefs!.setInt('push.version', body['version'] as int);
    await _prefs!.setString('push.owner', accountId);
  }

  @override
  Future<void> detach() async {
    final id = _prefs?.getString('push.id');
    final owner = _prefs?.getString('push.owner');
    if (id == null || owner == null) return;
    final version = _prefs!.getInt('push.version') ?? 0;
    final response = await client
        .delete(
          Uri.parse('${AppEnv.apiBaseUrl}/notifications/installations/$id'),
          headers: _headers(owner),
          body: jsonEncode({'version': version}),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw StateError('Detach failed');
    await _prefs!.setInt('push.version', version + 1);
    await _prefs!.remove('push.owner');
  }

  @override
  Future<bool> cleanupPending() async =>
      _prefs?.getBool('push.cleanup') ?? false;
  @override
  Future<void> setCleanupPending(bool value) async {
    await _prefs?.setBool('push.cleanup', value);
  }

  @override
  Future<bool> enabledPreference() async =>
      _prefs?.getBool('push.enabled') ?? true;

  @override
  Future<void> setEnabledPreference(bool value) async {
    await _prefs?.setBool('push.enabled', value);
  }
}
