import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chat_message.dart';
import 'chat_controller.dart';

typedef MomentFriendshipResponseHandler = Future<bool> Function(
  bool wantsFriend,
);

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    this.conversationId,
    this.isTemporary = false,
    this.isGroup = false,
    this.title,
    this.compactMomentPresentation = false,
    this.visibleFrom,
    this.visibleUntil,
    this.showMomentFriendshipActions = false,
    this.momentFriendConsent,
    this.momentOtherFriendConsent,
    this.momentFriendshipLocked = false,
    this.onMomentFriendshipResponse,
  }) : assert(conversationId != null, 'conversationId must be provided');

  final String? conversationId;
  final bool isTemporary;
  final bool isGroup;
  final String? title;
  final bool compactMomentPresentation;
  final DateTime? visibleFrom;
  final DateTime? visibleUntil;
  final bool showMomentFriendshipActions;
  final bool? momentFriendConsent;
  final bool? momentOtherFriendConsent;
  final bool momentFriendshipLocked;
  final MomentFriendshipResponseHandler? onMomentFriendshipResponse;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _canSend = false;
  int _lastMessageCount = 0;
  bool? _lastWritable;
  bool? _momentFriendConsentOverride;
  bool? _momentOtherFriendConsentOverride;
  bool _momentFriendshipLockedOverride = false;
  bool _isSubmittingFriendshipResponse = false;

  bool? get _momentFriendConsent =>
      _momentFriendConsentOverride ?? widget.momentFriendConsent;

  bool? get _momentOtherFriendConsent =>
      _momentOtherFriendConsentOverride ?? widget.momentOtherFriendConsent;

  bool get _momentFriendshipLocked =>
      _momentFriendshipLockedOverride || widget.momentFriendshipLocked;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
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
    final currentUserId = ref.watch(currentUserIdProvider).valueOrNull;

    if (_lastWritable != chatState.writable) {
      _lastWritable = chatState.writable;
      if (!chatState.writable && _controller.text.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _controller.clear();
        });
      }
    }

    final visibleMessages = _visibleMessages(chatState.messages);

    if (visibleMessages.length != _lastMessageCount) {
      _lastMessageCount = visibleMessages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      });
    }

    if (widget.compactMomentPresentation) {
      return _buildCompactScaffold(
        chatState: chatState,
        currentUserId: currentUserId,
        visibleMessages: visibleMessages,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.title ??
              (widget.isGroup
                  ? 'Group chat'
                  : widget.isTemporary
                      ? 'Moment chat'
                      : 'Chat'),
        ),
        centerTitle: false,
        bottom: widget.isTemporary || widget.isGroup
            ? PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    widget.isTemporary
                        ? 'Temporary Moment chat'
                        : 'Shared group conversation',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(
              chatState,
              currentUserId,
              visibleMessages,
            ),
          ),
          const Divider(height: 1),
          _buildComposer(chatState),
        ],
      ),
    );
  }

  Widget _buildCompactScaffold({
    required ChatState chatState,
    required String? currentUserId,
    required List<ChatMessage> visibleMessages,
  }) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width =
                constraints.maxWidth > 600 ? 520.0 : constraints.maxWidth - 40;
            final height =
                constraints.maxHeight > 760 ? 660.0 : constraints.maxHeight * 0.82;

            return Center(
              child: SizedBox(
                width: width,
                height: height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildCompactHeader(context),
                        Expanded(
                          child: _buildMessagesList(
                            chatState,
                            currentUserId,
                            visibleMessages,
                          ),
                        ),
                        _buildComposer(chatState, compact: true),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.title ?? 'Moment chat',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Icon(
              Icons.bolt,
              size: 20,
              color: _momentOtherFriendConsent == true
                  ? Colors.green
                  : theme.colorScheme.error,
            ),
            if (widget.showMomentFriendshipActions &&
                widget.onMomentFriendshipResponse != null) ...[
              const SizedBox(width: 8),
              _MomentFriendshipSwitch(
                consent: _momentFriendConsent,
                isBusy: _isSubmittingFriendshipResponse,
                isLocked: _momentFriendshipLocked,
                onChanged: _submitMomentFriendshipResponse,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submitMomentFriendshipResponse(bool wantsFriend) async {
    if (_isSubmittingFriendshipResponse) return;

    setState(() {
      _isSubmittingFriendshipResponse = true;
    });

    try {
      final created =
          await widget.onMomentFriendshipResponse?.call(wantsFriend) ?? false;
      if (!mounted) return;

      setState(() {
        _momentFriendConsentOverride = wantsFriend;
        if (created) {
          _momentFriendshipLockedOverride = true;
          _momentOtherFriendConsentOverride = true;
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arkadaslik cevabi guncellenemedi.')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmittingFriendshipResponse = false;
      });
    }
  }

  Widget _buildMessagesList(
    ChatState state,
    String? currentUserId,
    List<ChatMessage> messages,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text(state.error!));
    }

    if (messages.isEmpty) {
      return Center(
        child: Text(
          state.writable ? 'No messages yet. Say hi!' : 'No messages yet.',
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMine = message.senderId == currentUserId;
        return _MessageBubble(
          message: message,
          isMine: isMine,
          showSender: widget.isGroup && !isMine,
        );
      },
    );
  }

  List<ChatMessage> _visibleMessages(List<ChatMessage> messages) {
    if (!widget.compactMomentPresentation) {
      return messages;
    }

    final from = widget.visibleFrom;
    final until = widget.visibleUntil;

    if (from == null && until == null) {
      return messages;
    }

    return messages.where((message) {
      final createdAt = message.createdAt;
      if (from != null && createdAt.isBefore(from)) {
        return false;
      }
      if (until != null && createdAt.isAfter(until)) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildComposer(ChatState state, {bool compact = false}) {
    final isBusy = state.isLoading;
    final isReadOnly = !state.writable;
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: compact
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, 10, 8, compact ? 10 : 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !isReadOnly,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        isReadOnly ? 'This chat is read-only' : 'Message...',
                    filled: true,
                    fillColor: compact
                        ? theme.colorScheme.surface
                        : theme.colorScheme.surfaceContainerHighest,
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
              SizedBox(
                width: 48,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _canSend && !isBusy
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: _canSend && !isBusy
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: !_canSend || isBusy || isReadOnly
                        ? null
                        : () {
                            final text = _controller.text;
                            _controller.clear();
                            ref
                                .read(
                                  conversationChatControllerProvider(
                                    widget.conversationId!,
                                  ).notifier,
                                )
                                .sendMessage(text);
                          },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MomentFriendshipSwitch extends StatelessWidget {
  const _MomentFriendshipSwitch({
    required this.consent,
    required this.isBusy,
    required this.isLocked,
    required this.onChanged,
  });

  final bool? consent;
  final bool isBusy;
  final bool isLocked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accepted = consent == true;

    return Switch(
      value: accepted,
      onChanged: isBusy || isLocked ? null : onChanged,
      activeThumbColor: Colors.green,
      activeTrackColor: Colors.green.withValues(alpha: 0.35),
      inactiveThumbColor: theme.colorScheme.error,
      inactiveTrackColor: theme.colorScheme.error.withValues(alpha: 0.28),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return theme.colorScheme.outlineVariant;
        }
        return accepted ? Colors.green : theme.colorScheme.error;
      }),
      thumbIcon: WidgetStateProperty.resolveWith((states) {
        if (isBusy) {
          return const Icon(Icons.more_horiz, size: 16);
        }
        if (isLocked) {
          return const Icon(Icons.check, size: 16);
        }
        return Icon(accepted ? Icons.check : Icons.close, size: 16);
      }),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.showSender,
  });

  final ChatMessage message;
  final bool isMine;
  final bool showSender;

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

    final bubble = Container(
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
              if (showSender) ...[
                Text(
                  message.senderUsername ?? 'Group member',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(message.content, style: TextStyle(color: textColor)),
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
    );

    if (!showSender) {
      return Align(alignment: alignment, child: bubble);
    }

    return Align(
      alignment: alignment,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _SenderAvatar(message: message),
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

class _SenderAvatar extends StatelessWidget {
  const _SenderAvatar({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final username = message.senderUsername ?? '?';
    final avatarUrl = message.senderAvatarUrl;

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: theme.colorScheme.tertiaryContainer,
        foregroundColor: theme.colorScheme.onTertiaryContainer,
        backgroundImage:
            avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null || avatarUrl.isEmpty
            ? Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: theme.textTheme.labelSmall,
              )
            : null,
      ),
    );
  }
}

String _formatMessageTime(DateTime time) {
  final minutes = time.minute.toString().padLeft(2, '0');
  return '${time.hour}:$minutes';
}
