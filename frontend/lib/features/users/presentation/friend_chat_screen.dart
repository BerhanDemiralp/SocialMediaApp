import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../chat/presentation/chat_screen.dart';
import '../data/conversations_repository.dart';
import '../data/user_session.dart';
import '../domain/user_relationship.dart';
import 'user_relationships_controller.dart';

// Keep the resolved ID for this account so reopening never repeats ensure.
final friendChatIdProvider = FutureProvider.family<String, String>((
  ref,
  userId,
) async {
  final accountId = ref.watch(activeAccountIdProvider);
  final repository = ref.watch(conversationsRepositoryProvider);
  final relationships = ref.read(userRelationshipsProvider.notifier);
  if (accountId != null && !ref.read(userRelationshipsProvider).loaded) {
    await relationships.refresh();
  }
  if (!relationships.isActive ||
      accountId == null ||
      ref.read(userRelationshipsProvider).kindFor(userId) !=
          RelationshipKind.friend) {
    throw StateError('Friendship required');
  }
  final conversation = await repository.ensureFriendConversation(userId);
  return conversation.conversationId;
});

/// Open the chat surface immediately; resolve a new conversation inside it.
class FriendChatScreen extends ConsumerWidget {
  const FriendChatScreen({
    super.key,
    required this.userId,
    required this.title,
  });
  final String userId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversation = ref.watch(friendChatIdProvider(userId));
    if (!conversation.isLoading && conversation.hasValue) {
      return ChatScreen(
        conversationId: conversation.requireValue,
        title: title,
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: conversation.hasError
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not open conversation.'),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(friendChatIdProvider(userId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(),
            ),
    );
  }
}
