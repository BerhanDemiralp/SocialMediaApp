import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/matching_engine_api_client.dart';
import '../../chat/presentation/chat_screen.dart';
import 'home_friends_screen.dart';
import 'home_messages_screen.dart';

/// New Home tab UI skeleton.
///
/// This currently uses static / placeholder content for:
/// - Daily message
/// - Games
/// - Feed items
///
/// Real data can be wired later from repositories.
class HomeMainScreen extends ConsumerStatefulWidget {
  const HomeMainScreen({super.key});

  @override
  ConsumerState<HomeMainScreen> createState() => _HomeMainScreenState();
}

class _HomeMainScreenState extends ConsumerState<HomeMainScreen> {
  Timer? _successPollTimer;
  Timer? _activeMomentsRefreshTimer;
  final Set<String> _acknowledgedSuccessfulMomentIds = <String>{};
  final Set<String> _handledFriendConsentMomentIds = <String>{};
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
    _activeMomentsRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) {
          ref.invalidate(activeMomentsProvider);
        }
      },
    );
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
      final pendingConsentMomentIds = successfulMoments
          .where((moment) => moment.hasPendingFriendConsentFor(currentUserId))
          .map((moment) => moment.id)
          .toSet();

      if (!_hasSeededSuccessfulMoments) {
        _acknowledgedSuccessfulMomentIds.addAll(
          successfulMoments
              .where((moment) => !pendingConsentMomentIds.contains(moment.id))
              .map((moment) => moment.id),
        );
        _hasSeededSuccessfulMoments = true;
      }

      for (final moment in successfulMoments) {
        final hasPendingFriendConsent =
            moment.hasPendingFriendConsentFor(currentUserId);

        if (hasPendingFriendConsent &&
            _handledFriendConsentMomentIds.contains(moment.id)) {
          continue;
        }

        if (!hasPendingFriendConsent &&
            _acknowledgedSuccessfulMomentIds.contains(moment.id)) {
          continue;
        }

        if (!hasPendingFriendConsent) {
          _acknowledgedSuccessfulMomentIds.add(moment.id);
        }

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
          title: const Text('Pairing başarılı'),
          content: Text(
            isGroupMoment
                ? '$otherParticipantName ile pairing başarılı. Arkadaş eklemek ister misin?'
                : '$otherParticipantName ile pairing başarıyla tamamlandı.',
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
    _handledFriendConsentMomentIds.add(moment.id);

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arkadaşlık eklendi.')),
        );
      }
    } catch (_) {
      _handledFriendConsentMomentIds.remove(moment.id);

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
                    child: Text(
                      'Moment',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    tooltip: 'Find friends',
                    onPressed: () {
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
                padding: const EdgeInsets.all(16),
                child: _DailyMessageCard(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SectionHeader(
                  title: 'Games for today',
                  actionLabel: 'See all',
                  onActionTap: () {
                    // TODO: navigate to games screen when implemented.
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    return _GameCard(
                      title: 'Game ${index + 1}',
                      description: 'Short description for game ${index + 1}.',
                    );
                  },
                  separatorBuilder: (context, _) =>
                      const SizedBox(width: 12),
                  itemCount: 3,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Feed',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _FeedItemCard(
                      username: 'Friend ${index + 1}',
                      content: 'This is a placeholder post from Friend '
                          '${index + 1}. Replace with real feed data later.',
                    ),
                  );
                },
                childCount: 5,
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
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
        Text(
          'Active pairings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...moments.map(
          (moment) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MomentCard(
              moment: moment,
              currentUserId: currentUserId,
            ),
          ),
        ),
      ],
    );
  }
}

class _MomentCard extends ConsumerWidget {
  const _MomentCard({
    required this.moment,
    required this.currentUserId,
  });

  final MomentSummary moment;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final label = moment.isGroup ? 'Group Moment' : 'Friend Moment';
    final expires =
        '${moment.expiresAt.hour}:${moment.expiresAt.minute.toString().padLeft(2, '0')}';

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
        subtitle: Text('$label - active until $expires'),
        trailing: IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          tooltip: 'Open chat',
          onPressed: () {
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
                  momentFriendConsent: moment.friendConsentFor(currentUserId),
                  momentOtherFriendConsent:
                      moment.otherFriendConsentFor(currentUserId),
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
      ),
    );
  }
}

class _DailyMessageCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Daily Moment',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This is a placeholder daily message. '
              'Schedule and load the real message for the user here.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next update at 20:00',
                  style: theme.textTheme.bodySmall,
                ),
                FilledButton(
                  onPressed: () {
                    // TODO: implement daily action (e.g. respond / share).
                  },
                  child: const Text('Respond'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium,
        ),
        if (actionLabel != null && onActionTap != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.videogame_asset_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  description,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: FilledButton.tonal(
                  onPressed: () {
                    // TODO: navigate to specific game.
                  },
                  child: const Text('Play'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedItemCard extends StatelessWidget {
  const _FeedItemCard({
    required this.username,
    required this.content,
  });

  final String username;
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(username.isNotEmpty
                      ? username[0].toUpperCase()
                      : '?'),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      'Just now',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
