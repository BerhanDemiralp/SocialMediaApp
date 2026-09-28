import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chat_socket_client.dart';
import '../../users/data/user_session.dart';

/// Coalesce bursts without losing updates for different conversations.
class ConversationSync {
  ConversationSync(Stream<String?> events, this.onRefresh) {
    _subscription = events.listen(changed);
  }
  final void Function(Set<String?> conversations) onRefresh;
  late final StreamSubscription<String?> _subscription;
  final Set<String?> _pending = {};
  Timer? _timer;
  void changed(String? conversation) {
    _pending.add(conversation);
    _timer ??= Timer(const Duration(milliseconds: 150), () {
      _timer = null;
      final updates = Set<String?>.of(_pending);
      _pending.clear();
      onRefresh(updates);
    });
  }

  void dispose() {
    _timer?.cancel();
    _subscription.cancel();
  }
}

final conversationSyncEventsProvider = Provider.autoDispose<Stream<String?>>((
  ref,
) {
  return ref.watch(chatSocketClientProvider).conversationChanges;
});

final conversationSyncProvider = Provider.autoDispose<ConversationSync>((ref) {
  final account = ref.watch(activeAccountIdProvider);
  final events = account == null
      ? const Stream<String?>.empty()
      : ref.watch(conversationSyncEventsProvider);
  final sync = ConversationSync(events, (updates) {
    if (account == null || ref.read(activeAccountIdProvider) != account) return;
    ref.read(conversationsRevisionProvider.notifier).state++;
    if (updates.contains(null)) {
      ref.read(appResyncRevisionProvider.notifier).state++;
    } else {
      for (final id in updates.whereType<String>()) {
        ref.read(conversationRevisionProvider(id).notifier).state++;
      }
    }
  });
  ref.onDispose(sync.dispose);
  return sync;
});

class ConversationSyncHost extends ConsumerStatefulWidget {
  const ConversationSyncHost({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<ConversationSyncHost> createState() =>
      _ConversationSyncHostState();
}

class _ConversationSyncHostState extends ConsumerState<ConversationSyncHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(conversationSyncProvider).changed(null);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(conversationSyncProvider);
    return widget.child;
  }
}
