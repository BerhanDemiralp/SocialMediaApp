import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/matching_engine_api_client.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../users/presentation/user_conversations.dart';
import '../../users/presentation/user_relationships_controller.dart';

/// Shared Moment presentation for home cards and authorized notification taps.
Future<void> openMomentChat(
  BuildContext context,
  WidgetRef ref,
  MomentSummary moment,
  String? currentUserId,
) async {
  await Navigator.of(context).push(
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
        momentOtherFriendConsent: moment.otherFriendConsentFor(currentUserId),
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

                if (!context.mounted) return created;
                ref.invalidate(activeMomentsProvider);
                ref.invalidate(userConversationsProvider);
                ref.read(userRelationshipsProvider.notifier).refresh();

                Future<void>.delayed(const Duration(milliseconds: 800), () {
                  if (!context.mounted) return;
                  ref.invalidate(activeMomentsProvider);
                  ref.invalidate(userConversationsProvider);
                  ref.read(userRelationshipsProvider.notifier).refresh();
                });

                return created;
              }
            : null,
      ),
    ),
  );
}
