import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_repository.dart';
import '../data/chat_api_client.dart';
import '../domain/chat_message.dart';
import '../../users/data/user_session.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool writable;
  final String? error;

  const ChatState({
    required this.messages,
    required this.isLoading,
    this.writable = true,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? writable,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      writable: writable ?? this.writable,
      error: error,
    );
  }

  factory ChatState.initial() =>
      const ChatState(messages: [], isLoading: true, error: null);
}

// Legacy match-based ChatController has been removed in favor of
// conversation-based chat via ConversationChatController.

class ConversationChatController extends StateNotifier<ChatState> {
  ConversationChatController(this._repository, this._conversationId)
    : super(ChatState.initial()) {
    _init();
  }

  final ChatRepository _repository;
  final String _conversationId;
  StreamSubscription<ChatMessage>? _subscription;
  int _refreshSerial = 0;

  Future<void> _init() async {
    try {
      _subscription = _repository.messageStream.listen((message) {
        if (message.conversationId == _conversationId) {
          state = state.copyWith(
            messages: _sortMessages([...state.messages, message]),
          );
        }
      });
      _repository.joinConversation(_conversationId);
      await refresh(showLoading: true);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load messages.',
      );
    }
  }

  Future<void> refresh({bool showLoading = false}) async {
    if (!mounted) return;
    final serial = ++_refreshSerial;
    final before = state.messages.map((message) => message.id).toSet();
    if (showLoading) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final page = await _repository.loadMessagesForConversation(
        conversationId: _conversationId,
        limit: 50,
      );

      if (!mounted || serial != _refreshSerial) return;
      state = state.copyWith(
        messages: _sortMessages([
          ...page.items,
          ...state.messages.where(
            (message) =>
                !before.contains(message.id) || message.id.startsWith('local-'),
          ),
        ]),
        writable: page.writable,
        isLoading: false,
        error: null,
      );
    } catch (_) {
      if (!mounted || serial != _refreshSerial) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to refresh messages.',
      );
    }
  }

  Future<void> sendMessage(String content) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty || !state.writable) return;

    final optimisticId =
        'local-${DateTime.now().microsecondsSinceEpoch.toString()}';
    final optimisticMessage = ChatMessage(
      id: optimisticId,
      conversationId: _conversationId,
      senderId: _repository.currentUserId ?? '',
      senderUsername: 'You',
      content: trimmedContent,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: _sortMessages([...state.messages, optimisticMessage]),
      error: null,
    );

    try {
      final message = await _repository.sendMessageToConversation(
        conversationId: _conversationId,
        content: trimmedContent,
      );
      if (!mounted) return;
      state = state.copyWith(
        messages: _sortMessages([
          for (final existing in state.messages)
            if (existing.id == optimisticId) message else existing,
        ]),
      );
    } on ChatRequestException catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        messages: [
          for (final existing in state.messages)
            if (existing.id != optimisticId) existing,
        ],
        writable: error.isForbidden ? false : state.writable,
        error: null,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        messages: [
          for (final existing in state.messages)
            if (existing.id != optimisticId) existing,
        ],
        error: null,
      );
    }
  }

  List<ChatMessage> _sortMessages(List<ChatMessage> messages) {
    final sorted = {
      for (final message in messages) message.id: message,
    }.values.toList();
    sorted.sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
    return sorted;
  }

  @override
  void dispose() {
    _repository.leaveConversation(_conversationId);
    _subscription?.cancel();
    super.dispose();
  }
}

final conversationChatControllerProvider = StateNotifierProvider.autoDispose
    .family<ConversationChatController, ChatState, String>((
      ref,
      conversationId,
    ) {
      final repository = ref.watch(chatRepositoryProvider);
      final controller = ConversationChatController(repository, conversationId);
      ref.listen(
        appResyncRevisionProvider,
        (_, _) => unawaited(controller.refresh()),
      );
      ref.listen(
        conversationRevisionProvider(conversationId),
        (_, _) => unawaited(controller.refresh()),
      );
      return controller;
    });
