import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../chat/data/chat_repository.dart';
import '../../chat/domain/chat_message.dart';

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
      final page = await _repository.loadMessagesForConversation(
        conversationId: _conversationId,
        limit: 50,
      );
      state = state.copyWith(
        messages: _sortMessages(page.items),
        writable: page.writable,
        isLoading: false,
      );

      _subscription = _repository.messageStream.listen((message) {
        if (message.conversationId == _conversationId) {
          state = state.copyWith(
            messages: _sortMessages([...state.messages, message]),
          );
        }
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load messages.',
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
    } catch (_) {
      state = state.copyWith(
        messages: [
          for (final existing in state.messages)
            if (existing.id != optimisticId) existing,
        ],
        error: 'Failed to send message.',
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

final conversationChatControllerProvider =
    StateNotifierProvider.family<ConversationChatController, ChatState, String>(
        (ref, conversationId) {
  final repository = ref.watch(chatRepositoryProvider);
  return ConversationChatController(repository, conversationId);
});

final currentUserIdProvider = StreamProvider<String?>((ref) async* {
  final client = Supabase.instance.client;
  yield client.auth.currentUser?.id;
  await for (final event in client.auth.onAuthStateChange) {
    yield event.session?.user.id;
  }
});
