import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/app_text_field.dart';
import '../data/matching_engine_api_client.dart';
import '../../chat/presentation/chat_screen.dart';
import 'home_friends_screen.dart';
import 'home_messages_screen.dart';

class HomeMainScreen extends ConsumerStatefulWidget {
  const HomeMainScreen({super.key});

  @override
  ConsumerState<HomeMainScreen> createState() => _HomeMainScreenState();
}

class _HomeMainScreenState extends ConsumerState<HomeMainScreen> {
  Timer? _successPollTimer;
  Timer? _activeMomentsRefreshTimer;
  final Set<String> _acknowledgedSuccessfulMomentIds = <String>{};
  bool _hasSeededSuccessfulMoments = false;
  bool _isCheckingSuccessfulMoments = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForSuccessfulMoments();
    });
    _successPollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkForSuccessfulMoments(),
    );
    _activeMomentsRefreshTimer = Timer.periodic(const Duration(seconds: 30), (
      _,
    ) {
      if (mounted) {
        ref.invalidate(activeMomentsProvider);
      }
    });
  }

  @override
  void dispose() {
    _successPollTimer?.cancel();
    _activeMomentsRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkForSuccessfulMoments() async {
    if (_isCheckingSuccessfulMoments) {
      return;
    }

    _isCheckingSuccessfulMoments = true;

    try {
      final client = ref.read(matchingEngineApiClientProvider);
      final currentUserId = client.currentUserId;

      if (currentUserId == null) {
        return;
      }

      final history = await client.getMomentHistory(limit: 50);
      final successfulMoments = history
          .where((moment) => moment.status == 'successful')
          .toList();

      if (!_hasSeededSuccessfulMoments) {
        _acknowledgedSuccessfulMomentIds.addAll(
          successfulMoments.map((moment) => moment.id),
        );
        _hasSeededSuccessfulMoments = true;
      }

      for (final moment in successfulMoments) {
        if (_acknowledgedSuccessfulMomentIds.contains(moment.id)) {
          continue;
        }

        _acknowledgedSuccessfulMomentIds.add(moment.id);

        if (!mounted) {
          return;
        }

        await _showSuccessfulMomentDialog(moment, currentUserId);
        if (mounted) {
          ref.invalidate(activeMomentsProvider);
        }
        break;
      }
    } catch (_) {
      // The home feed should stay quiet if this background check fails.
    } finally {
      _isCheckingSuccessfulMoments = false;
    }
  }

  Future<void> _showSuccessfulMomentDialog(
    MomentSummary moment,
    String currentUserId,
  ) {
    final otherParticipantName = moment.otherParticipantName(currentUserId);
    final isGroupMoment = moment.isGroup;

    return showDialog<void>(
      context: context,
      barrierDismissible: !isGroupMoment,
      builder: (context) {
        final theme = Theme.of(context);

        return PopScope(
          canPop: !isGroupMoment,
          child: AlertDialog(
            icon: Icon(
              Icons.verified_rounded,
              size: 44,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Moment başarıyla tamamlandı'),
            content: Text(
              isGroupMoment
                  ? '$otherParticipantName ile Moment başarıyla tamamlandı. Arkadaş eklemek ister misin?'
                  : '$otherParticipantName ile Moment başarıyla tamamlandı.',
            ),
            actions: isGroupMoment
                ? [
                    TextButton(
                      onPressed: () {
                        _submitFriendshipResponse(moment, false);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Hayır'),
                    ),
                    FilledButton(
                      onPressed: () {
                        _submitFriendshipResponse(moment, true);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Evet'),
                    ),
                  ]
                : [
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Tamam'),
                    ),
                  ],
          ),
        );
      },
    );
  }

  Future<void> _submitFriendshipResponse(
    MomentSummary moment,
    bool wantsFriend,
  ) async {
    _acknowledgedSuccessfulMomentIds.add(moment.id);

    try {
      final created = await ref
          .read(matchingEngineApiClientProvider)
          .respondToGroupMomentFriendship(
            matchId: moment.id,
            wantsFriend: wantsFriend,
          );

      if (!mounted) {
        return;
      }

      _refreshMomentFriendshipViews();

      if (wantsFriend) {
        Future<void>.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          _refreshMomentFriendshipViews();
        });
      }

      if (created) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Arkadaşlık eklendi.')));
      }
    } catch (_) {
      _acknowledgedSuccessfulMomentIds.remove(moment.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arkadaşlık cevabı gönderilemedi.')),
      );
    }
  }

  void _refreshMomentFriendshipViews() {
    ref.invalidate(activeMomentsProvider);
    ref.invalidate(friendConversationsProvider);
    ref.invalidate(messagesFriendsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeMomentsAsync = ref.watch(activeMomentsProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              snap: false,
              toolbarHeight: 96,
              titleSpacing: 16,
              title: Row(
                children: [
                  Expanded(
                    child: Text('Moment', style: theme.textTheme.titleLarge),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    tooltip: 'Find friends',
                    onPressed: () {
                      dismissKeyboard();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const HomeFriendsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: activeMomentsAsync.when(
                  data: (moments) => _ActiveMomentsSection(
                    moments: moments,
                    currentUserId: currentUserId,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
}

class _ActiveMomentsSection extends StatelessWidget {
  const _ActiveMomentsSection({
    required this.moments,
    required this.currentUserId,
  });

  final List<MomentSummary> moments;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    if (moments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Active Moments', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...moments.map(
          (moment) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MomentCard(moment: moment, currentUserId: currentUserId),
          ),
        ),
      ],
    );
  }
}

class _MomentCard extends ConsumerWidget {
  const _MomentCard({required this.moment, required this.currentUserId});

  final MomentSummary moment;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final label = moment.isGroup ? 'Group Moment' : 'Friend Moment';
    final expires =
        '${moment.expiresAt.hour}:${moment.expiresAt.minute.toString().padLeft(2, '0')}';
    final isSuccessful = moment.status == 'successful';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: moment.isGroup
              ? theme.colorScheme.secondaryContainer
              : theme.colorScheme.primaryContainer,
          foregroundColor: moment.isGroup
              ? theme.colorScheme.onSecondaryContainer
              : theme.colorScheme.onPrimaryContainer,
          child: Icon(moment.isGroup ? Icons.groups_2 : Icons.person),
        ),
        title: Text(moment.otherParticipantName(currentUserId)),
        subtitle: isSuccessful
            ? RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  children: [
                    TextSpan(text: '$label - '),
                    const TextSpan(
                      text: 'Successful',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            : Text('$label - active until $expires'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (moment.isGroup) ...[
              Icon(
                Icons.bolt,
                size: 20,
                color: moment.otherFriendConsentFor(currentUserId) == true
                    ? Colors.green
                    : theme.colorScheme.error,
              ),
              const SizedBox(width: 4),
            ],
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: 'Open chat',
              onPressed: () {
                dismissKeyboard();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => ChatScreen(
                      conversationId: moment.conversationId,
                      isGroup: moment.isGroup,
                      isTemporary: true,
                      compactMomentPresentation: true,
                      title: moment.otherParticipantName(currentUserId),
                      visibleFrom: moment.scheduledAt,
                      visibleUntil: moment.expiresAt,
                      showMomentFriendshipActions:
                          moment.isGroup && moment.status == 'successful',
                      momentFriendConsent: moment.friendConsentFor(
                        currentUserId,
                      ),
                      momentOtherFriendConsent: moment.otherFriendConsentFor(
                        currentUserId,
                      ),
                      momentFriendshipLocked: moment.isFriendshipLocked,
                      onMomentFriendshipResponse:
                          moment.isGroup && moment.status == 'successful'
                          ? (wantsFriend) async {
                              final created = await ref
                                  .read(matchingEngineApiClientProvider)
                                  .respondToGroupMomentFriendship(
                                    matchId: moment.id,
                                    wantsFriend: wantsFriend,
                                  );

                              ref.invalidate(activeMomentsProvider);
                              ref.invalidate(friendConversationsProvider);
                              ref.invalidate(messagesFriendsProvider);

                              Future<void>.delayed(
                                const Duration(milliseconds: 800),
                                () {
                                  ref.invalidate(activeMomentsProvider);
                                  ref.invalidate(friendConversationsProvider);
                                  ref.invalidate(messagesFriendsProvider);
                                },
                              );

                              return created;
                            }
                          : null,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
