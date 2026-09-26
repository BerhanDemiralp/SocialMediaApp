import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/conversations_repository.dart';
import '../data/friend_conversations_api_client.dart';
import '../data/user_session.dart';
import '../domain/user_identity.dart';
import '../domain/user_relationship.dart';
import 'user_relationships_controller.dart';

final userConversationsProvider =
    FutureProvider<List<FriendConversationSummary>>((ref) {
      final accountId = ref.watch(activeAccountIdProvider);
      // Same-account updates are refreshes: retain the visible rows until
      // fresh previews arrive. Account changes above remain dependency reloads
      // so the previous account's data is never displayed.
      ref.listen(conversationsRevisionProvider, (_, _) => ref.invalidateSelf());
      ref.listen(identityRevisionProvider, (_, _) => ref.invalidateSelf());
      if (accountId == null) return [];
      return ref
          .watch(conversationsRepositoryProvider)
          .loadFriendConversations();
    });

class UserConversationCoordinator extends StateNotifier<Set<String>> {
  UserConversationCoordinator({
    required this.repository,
    required this.canStart,
    required this.onChanged,
    this.findExisting,
  }) : super({});
  final ConversationsRepository? repository;
  final bool Function(String userId) canStart;
  final VoidCallback onChanged;
  final String? Function(String userId)? findExisting;

  Future<void> open(
    BuildContext context, {
    required UserIdentity user,
    String? conversationId,
    bool isGroup = false,
    bool isTemporary = false,
    String? title,
  }) async {
    final key = user.id.isEmpty ? 'conversation:$conversationId' : user.id;
    if (!mounted || repository == null || state.contains(key)) return;
    if (conversationId == null && !canStart(user.id)) return;
    state = {...state, key};
    dismissKeyboard();
    try {
      final id = conversationId ?? findExisting?.call(user.id);
      final route = Uri(
        path: id == null ? '/friend/${user.id}' : '/conversation/$id',
        queryParameters: {
          if (isGroup) 'type': 'group',
          if (isTemporary) 'temporary': '1',
          'title': title ?? user.username,
        },
      ).toString();
      await context.push(route);
      if (mounted) onChanged();
    } catch (_) {
      if (mounted && context.mounted) {
        showAppNotice(context, 'Could not open conversation. Try again.');
      }
    } finally {
      if (mounted) state = {...state}..remove(key);
    }
  }
}

final userConversationCoordinatorProvider =
    StateNotifierProvider<UserConversationCoordinator, Set<String>>((ref) {
      final accountId = ref.watch(activeAccountIdProvider);
      return UserConversationCoordinator(
        repository: accountId == null
            ? null
            : ref.watch(conversationsRepositoryProvider),
        findExisting: (id) {
          final conversations = ref.read(userConversationsProvider);
          if (conversations.isReloading) return null;
          for (final conversation
              in conversations.valueOrNull ??
                  const <FriendConversationSummary>[]) {
            if (conversation.friendId == id &&
                conversation.conversationType == 'friend' &&
                conversation.writable) {
              return conversation.conversationId;
            }
          }
          return null;
        },
        canStart: (id) {
          final relationships = ref.read(userRelationshipsProvider);
          return relationships.kindFor(id) == RelationshipKind.friend &&
              !relationships.busy.contains(id);
        },
        onChanged: () =>
            ref.read(conversationsRevisionProvider.notifier).state++,
      );
    });
