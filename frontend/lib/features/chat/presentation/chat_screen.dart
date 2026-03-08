import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chat_message.dart';
import 'chat_controller.dart';
import '../../home/presentation/home_messages_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    this.matchId,
    this.conversationId,
    this.isTemporary = false,
  }) : assert(matchId != null || conversationId != null,
            'Either matchId or conversationId must be provided');

  final String? matchId;
  final String? conversationId;
  final bool isTemporary;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = widget.matchId != null
        ? ref.watch(chatControllerProvider(widget.matchId!))
        : ref.watch(
            conversationChatControllerProvider(widget.conversationId!),
          );
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTemporary ? 'Moment chat' : 'Chat'),
        centerTitle: false,
        bottom: widget.isTemporary
            ? const PreferredSize(
                preferredSize: Size.fromHeight(24),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Temporary chat – may become permanent after the Moment.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(chatState, currentUserId),
          ),
          const Divider(height: 1),
          _buildComposer(chatState),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ChatState state, String? currentUserId) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text(state.error!));
    }

    if (state.messages.isEmpty) {
      return const Center(child: Text('No messages yet. Say hi!'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        final isMine = message.senderId == currentUserId;
        return _MessageBubble(message: message, isMine: isMine);
      },
    );
  }

  Widget _buildComposer(ChatState state) {
    final isBusy = state.isLoading;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                onChanged: (value) {
                  final matchId = widget.matchId;
                  if (matchId != null) {
                    ref
                        .read(chatControllerProvider(matchId).notifier)
                        .setTyping(value.isNotEmpty);
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: isBusy
                  ? null
                  : () {
                      final text = _controller.text;
                      _controller.clear();
                      if (widget.matchId != null) {
                        ref
                            .read(chatControllerProvider(widget.matchId!).notifier)
                            .sendMessage(text);
                      } else if (widget.conversationId != null) {
                        ref
                            .read(conversationChatControllerProvider(widget.conversationId!).notifier)
                            .sendMessage(text);
                        // Refresh conversations summaries so Messages tab shows the latest message.
                        ref.invalidate(friendConversationsProvider);
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
  });

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final color = isMine
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final textColor =
        isMine ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }
}
