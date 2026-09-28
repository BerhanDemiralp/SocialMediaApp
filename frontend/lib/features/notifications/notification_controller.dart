import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PushEvent {
  const PushEvent(
    this.id,
    this.accountId,
    this.conversationId,
    this.kind, {
    this.momentId,
  });
  final String id, accountId, conversationId, kind;
  final String? momentId;
  static PushEvent? parse(Map<String, dynamic> data) {
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (data['version'] != '1' ||
        ![
          'message',
          'moment_started',
          'moment_reminder',
        ].contains(data['kind'])) {
      return null;
    }
    for (final key in ['eventId', 'accountId', 'conversationId']) {
      if (data[key] is! String || !uuid.hasMatch(data[key] as String)) {
        return null;
      }
    }
    return PushEvent(
      data['eventId'] as String,
      data['accountId'] as String,
      data['conversationId'] as String,
      data['kind'] as String,
      momentId:
          data['momentId'] is String &&
              uuid.hasMatch(data['momentId'] as String)
          ? data['momentId'] as String
          : null,
    );
  }
}

abstract class PushGateway {
  Future<bool> initialize();
  Future<bool> permission({bool request = false});
  Future<String?> token();
  Future<void> deleteToken();
  Stream<String> get tokenChanges;
  Stream<PushEvent> get foreground;
  Stream<PushEvent> get taps;
  Future<PushEvent?> initialEvent();
  Future<void> register(String accountId, String token);
  Future<void> detach();
  Future<bool> cleanupPending();
  Future<void> setCleanupPending(bool value);
  Future<bool> enabledPreference();
  Future<void> setEnabledPreference(bool value);
}

class PushState {
  const PushState({
    this.available = false,
    this.allowed = false,
    this.busy = false,
    this.enabled = true,
    this.message,
  });
  final bool available, allowed, busy, enabled;
  final String? message;
}

class PushAction {
  const PushAction(this.event, {required this.open});
  final PushEvent event;
  final bool open;
}

class NotificationController extends StateNotifier<PushState> {
  NotificationController(this.gateway) : super(const PushState());
  final PushGateway gateway;
  final _actions = StreamController<PushAction>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Set<String> _seen = {};
  final Set<String> _opened = {};
  Future<void> _queue = Future.value();
  String? _account;
  String? get account => _account;
  String? visibleConversation;
  bool foregroundActive = true;
  PushEvent? _pending;
  int _generation = 0;
  Stream<PushAction> get actions => _actions.stream;

  Future<void> initialize() async {
    try {
      final available = await gateway.initialize();
      if (!mounted) return;
      state = PushState(
        available: available,
        enabled: available ? await gateway.enabledPreference() : true,
      );
      if (!available) return;
      _subscriptions.add(
        gateway.tokenChanges.listen((_) => unawaited(resume())),
      );
      _subscriptions.add(
        gateway.foreground.listen((e) => receive(e, open: false)),
      );
      _subscriptions.add(gateway.taps.listen((e) => receive(e, open: true)));
      final initial = await gateway.initialEvent();
      if (!mounted) return;
      if (initial != null) receive(initial, open: true);
      await resume();
    } catch (_) {
      if (mounted) {
        state = const PushState(
          message: 'Notifications are unavailable on this build.',
        );
      }
    }
  }

  void setAccount(String? value) {
    if (_account == value) return;
    _generation++;
    _account = value;
    _seen.clear();
    _opened.clear();
    if (_pending != null && value != null) {
      final pending = _pending!;
      _pending = null;
      receive(pending, open: true);
    }
    unawaited(resume());
  }

  Future<void> resume({bool request = false}) {
    final generation = _generation;
    _queue = _queue.then((_) async {
      if (!mounted || !state.available || generation != _generation) return;
      await _sync(generation, request: request);
    });
    return _queue;
  }

  Future<void> setEnabled(bool enabled) {
    final generation = _generation;
    _queue = _queue.then((_) async {
      if (!mounted || !state.available || generation != _generation) return;
      state = PushState(
        available: true,
        allowed: enabled && state.allowed,
        busy: true,
        enabled: enabled,
      );
      try {
        await gateway.setEnabledPreference(enabled);
        if (!mounted || generation != _generation) return;
        await _sync(generation, request: enabled);
      } catch (_) {
        if (mounted && generation == _generation) {
          state = PushState(
            available: true,
            allowed: false,
            enabled: enabled,
            message: enabled
                ? 'Notification setup could not finish. Try again.'
                : 'Notifications are off. Device cleanup will retry.',
          );
        }
      }
    });
    return _queue;
  }

  Future<void> _sync(int generation, {bool request = false}) async {
    state = PushState(
      available: true,
      allowed: state.allowed,
      enabled: state.enabled,
      busy: true,
    );
    try {
      if (await gateway.cleanupPending()) {
        await gateway.deleteToken();
        await gateway.setCleanupPending(false);
      }
      final enabled = await gateway.enabledPreference();
      if (!mounted || generation != _generation) return;
      if (!enabled) {
        try {
          if (_account != null) await gateway.detach();
        } finally {
          await gateway.deleteToken();
        }
        if (mounted && generation == _generation) {
          state = const PushState(
            available: true,
            enabled: false,
            message: 'Notifications are off in this app.',
          );
        }
        return;
      }
      final allowed = await gateway.permission(
        request: request && _account != null,
      );
      if (!mounted || generation != _generation) return;
      var registered = false;
      if (allowed && _account != null) {
        final token = await gateway.token();
        if (!mounted || generation != _generation) return;
        if (token != null) {
          await gateway.register(_account!, token);
          registered = true;
        }
      } else if (_account != null) {
        await gateway.detach();
      }
      if (mounted && generation == _generation) {
        state = PushState(
          available: true,
          enabled: true,
          allowed: allowed,
          message: allowed && !registered
              ? 'Waiting for device registration.'
              : allowed
              ? 'Notifications enabled.'
              : 'Device notification permission is off.',
        );
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        state = PushState(
          available: true,
          enabled: state.enabled,
          allowed: state.enabled && state.allowed,
          message: state.enabled
              ? 'Notification setup could not finish. Try again.'
              : 'Notifications are off. Device cleanup will retry.',
        );
      }
    }
  }

  Future<void> beforeLogout() async {
    _generation++;
    _account = null;
    _pending = null;
    _seen.clear();
    _opened.clear();
    await _queue;
    if (!mounted || !state.available) return;
    try {
      await gateway.setCleanupPending(true);
      await gateway.detach();
      await gateway.deleteToken();
      await gateway.setCleanupPending(false);
    } catch (_) {
      /* Retry token deletion on next launch/resume, without storing auth tokens. */
    }
  }

  void receive(PushEvent event, {required bool open}) {
    if (!mounted) return;
    if (_account == null) {
      if (open) _pending = event;
      return;
    }
    if (event.accountId != _account) return;
    final seen = open ? _opened : _seen;
    if (!seen.add(event.id)) return;
    if (seen.length > 100) seen.remove(seen.first);
    if (foregroundActive && visibleConversation == event.conversationId) return;
    _actions.add(PushAction(event, open: open));
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_actions.close());
    super.dispose();
  }
}
