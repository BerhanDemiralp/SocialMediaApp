import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' hide UserIdentity;
import '../../core/app_router.dart';
import '../../core/env/app_env.dart';
import '../../core/widgets/app_notice.dart';
import '../users/data/user_session.dart';
import '../users/domain/user_identity.dart';
import '../users/presentation/user_conversations.dart';
import '../home/data/matching_engine_api_client.dart';
import '../home/presentation/moment_chat_navigation.dart';
import 'firebase_push_gateway.dart';
import 'notification_controller.dart';

final notificationDestinationProvider =
    Provider<Future<Map<String, dynamic>> Function(PushEvent)>((ref) {
      final client = http.Client();
      ref.onDispose(client.close);
      return (event) async {
        final session = Supabase.instance.client.auth.currentSession;
        if (session?.user.id != event.accountId) {
          throw StateError('Account changed');
        }
        final response = await client
            .get(
              Uri.parse(
                '${AppEnv.apiBaseUrl}/notifications/conversations/${event.conversationId}',
              ).replace(
                queryParameters:
                    event.kind != 'message' && event.momentId != null
                    ? {'momentId': event.momentId!}
                    : null,
              ),
              headers: {'Authorization': 'Bearer ${session!.accessToken}'},
            )
            .timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) {
          throw StateError('Conversation unavailable');
        }
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['id'] != event.conversationId) {
          throw StateError('Invalid destination');
        }
        return data;
      };
    });

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, PushState>((ref) {
      final client = http.Client();
      ref.onDispose(client.close);
      final controller = NotificationController(FirebasePushGateway(client));
      unawaited(controller.initialize());
      return controller;
    });

class NotificationHost extends ConsumerStatefulWidget {
  const NotificationHost({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<NotificationHost> createState() => _NotificationHostState();
}

class _NotificationHostState extends ConsumerState<NotificationHost>
    with WidgetsBindingObserver {
  StreamSubscription<PushAction>? _subscription;
  late final NotificationController _controller;
  final Set<String> _opening = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ref.read(notificationControllerProvider.notifier);
    _subscription = _controller.actions.listen((action) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_handle(action)),
      );
      WidgetsBinding.instance.ensureVisualUpdate();
    });
    ref.listenManual(
      activeAccountIdProvider,
      (_, account) => _controller.setAccount(account),
      fireImmediately: true,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller.foregroundActive = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) unawaited(_controller.resume());
  }

  Future<void> _handle(PushAction action) async {
    if (!mounted || action.event.accountId != _controller.account) return;
    ref.read(conversationsRevisionProvider.notifier).state++;
    if (action.event.kind != 'message') ref.invalidate(activeMomentsProvider);
    ref
        .read(
          conversationRevisionProvider(action.event.conversationId).notifier,
        )
        .state++;
    final page = rootNavigatorKey.currentContext;
    if (page == null || !page.mounted) return;
    if (!action.open) {
      showAppNotice(
        page,
        action.event.kind == 'message'
            ? 'You have a new message.'
            : 'Your Moment is waiting.',
      );
      return;
    }
    if (!_opening.add(action.event.conversationId)) return;
    try {
      final data = await ref.read(notificationDestinationProvider)(
        action.event,
      );
      if (!mounted ||
          !page.mounted ||
          action.event.accountId != _controller.account) {
        return;
      }
      if (_controller.visibleConversation == data['id']) return;
      if (action.event.kind != 'message') {
        final rawMoment = data['moment'];
        if (rawMoment is! Map<String, dynamic>) {
          throw StateError('Moment destination unavailable');
        }
        final moment = MomentSummary.fromJson(rawMoment);
        if (moment.id != action.event.momentId ||
            moment.conversationId != action.event.conversationId) {
          throw StateError('Invalid Moment destination');
        }
        await openMomentChat(page, ref, moment, action.event.accountId);
        return;
      }
      await ref
          .read(userConversationCoordinatorProvider.notifier)
          .open(
            page,
            user: UserIdentity(
              id: '',
              username: data['title'] as String? ?? 'Chat',
            ),
            conversationId: data['id'] as String,
            isGroup: data['type'] == 'group' || data['type'] == 'group_pair',
            isTemporary: data['type'] == 'group_pair',
          );
    } catch (_) {
      if (mounted &&
          page.mounted &&
          action.event.accountId == _controller.account) {
        showAppNotice(page, 'This conversation is unavailable.');
      }
    } finally {
      _opening.remove(action.event.conversationId);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class NotificationSettingsTile extends ConsumerWidget {
  const NotificationSettingsTile({super.key});
  static const _settingsChannel = MethodChannel('moment/notification_settings');

  Future<void> _openDeviceSettings(BuildContext context) async {
    try {
      await _settingsChannel.invokeMethod<void>('open');
    } catch (_) {
      if (context.mounted) {
        showAppNotice(context, 'Could not open notification settings.');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationControllerProvider);
    if (!state.available) return const SizedBox.shrink();
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: const Text('Notifications'),
          subtitle: Text(
            state.message ??
                'Enable Moment reminders and new message notifications.',
          ),
          value: state.enabled,
          onChanged: state.busy
              ? null
              : (value) => ref
                    .read(notificationControllerProvider.notifier)
                    .setEnabled(value),
        ),
        if (state.enabled &&
            !state.allowed &&
            !state.busy &&
            !kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Device notifications are turned off for Moment.'),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () => _openDeviceSettings(context),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Open notification settings'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
