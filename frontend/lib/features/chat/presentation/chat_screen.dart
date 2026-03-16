import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chat_message.dart';
import 'chat_controller.dart';
import '../../home/presentation/home_messages_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    this.conversationId,
    this.isTemporary = false,
  }) : assert(
          conversationId != null,
          'conversationId must be provided',
        );

  final String? conversationId;
  final bool isTemporary;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final canSend = _controller.text.trim().isNotEmpty;
    if (canSend != _canSend) {
      setState(() {
        _canSend = canSend;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(
      conversationChatControllerProvider(widget.conversationId!),
    );
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.isTemporary ? 'Moment chat' : 'Chat'),
        centerTitle: false,
        bottom: widget.isTemporary
            ? const PreferredSize(
                preferredSize: Size.fromHeight(24),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Temporary chat - may become permanent after the Moment.',
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
      reverse: true,
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[state.messages.length - 1 - index];
        final isMine = message.senderId == currentUserId;
        return _MessageBubble(message: message, isMine: isMine);
      },
    );
  }

  Widget _buildComposer(ChatState state) {
    final isBusy = state.isLoading;
    final theme = Theme.of(context);

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
                onChanged: (_) {
                  // Typing indicators are not wired for conversation-only chat yet.
                },
                decoration: InputDecoration(
                  hintText: 'Message...',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 22,
              backgroundColor: _canSend && !isBusy
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              child: IconButton(
                icon: Icon(
                  Icons.send,
                  color: _canSend && !isBusy
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: !_canSend || isBusy
                    ? null
                    : () {
                        final text = _controller.text;
                        _controller.clear();
                        if (widget.conversationId != null) {
                          ref
                              .read(
                                conversationChatControllerProvider(
                                  widget.conversationId!,
                                ).notifier,
                              )
                              .sendMessage(text);
                          // Refresh conversations summaries so Messages tab shows the latest message.
                          ref.invalidate(friendConversationsProvider);
                        }
                      },
              ),
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
    final theme = Theme.of(context);
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isMine
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final textColor =
        isMine ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isMine ? 16 : 4),
      topRight: Radius.circular(isMine ? 4 : 16),
      bottomLeft: const Radius.circular(16),
      bottomRight: const Radius.circular(16),
    );

    final screenWidth = MediaQuery.of(context).size.width;

    return Align(
      alignment: alignment,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4).copyWith(
          left: isMine ? screenWidth * 0.2 : 8,
          right: isMine ? 8 : screenWidth * 0.2,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: borderRadius,
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.content,
                  style: TextStyle(color: textColor),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    _formatMessageTime(message.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatMessageTime(DateTime time) {
  final minutes = time.minute.toString().padLeft(2, '0');
  return '${time.hour}:$minutes';
}
