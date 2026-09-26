import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_repository.dart';
import '../data/chat_api_client.dart';
import '../domain/chat_message.dart';

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

  Future<void> _init() async {
    try {
      _repository.joinConversation(_conversationId);
      await refresh(showLoading: true);
      if (!mounted) return;

      _subscription = _repository.messageStream.listen((message) {
        if (message.conversationId == _conversationId) {
          state = state.copyWith(
            messages: _sortMessages([...state.messages, message]),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load messages.',
      );
    }
  }

  Future<void> refresh({bool showLoading = false}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, error: null);
    }

    final page = await _repository.loadMessagesForConversation(
      conversationId: _conversationId,
      limit: 50,
    );

    if (!mounted) return;
    state = state.copyWith(
      messages: _sortMessages(page.items),
      writable: page.writable,
      isLoading: false,
      error: null,
    );
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
      state = state.copyWith(
        messages: _sortMessages([
          for (final existing in state.messages)
            if (existing.id == optimisticId) message else existing,
        ]),
      );
    } on ChatRequestException catch (error) {
      state = state.copyWith(
        messages: [
          for (final existing in state.messages)
            if (existing.id != optimisticId) existing,
        ],
        writable: error.isForbidden ? false : state.writable,
        error: null,
      );
    } catch (_) {
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
    final sorted = [...messages];
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
      return ConversationChatController(repository, conversationId);
    });
