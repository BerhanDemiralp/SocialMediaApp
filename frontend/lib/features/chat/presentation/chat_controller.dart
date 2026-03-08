import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../chat/data/chat_repository.dart';
import '../../chat/domain/chat_message.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    required this.messages,
    required this.isLoading,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  factory ChatState.initial() =>
      const ChatState(messages: [], isLoading: true, error: null);
}

class ChatController extends StateNotifier<ChatState> {
  ChatController(this._repository, this._matchId) : super(ChatState.initial()) {
    _init();
  }

  final ChatRepository _repository;
  final String _matchId;

  StreamSubscription<ChatMessage>? _subscription;

  Future<void> _init() async {
    try {
      _repository.joinMatch(_matchId);
      final initialMessages =
          await _repository.loadMessages(matchId: _matchId, limit: 50);
      state = state.copyWith(messages: initialMessages, isLoading: false);

      _subscription = _repository.messageStream.listen((message) {
        if (message.matchId == _matchId) {
          state = state.copyWith(
            messages: [...state.messages, message],
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
    if (content.trim().isEmpty) return;

    try {
      _repository.sendMessage(matchId: _matchId, content: content.trim());
    } catch (_) {
      state = state.copyWith(error: 'Failed to send message.');
    }
  }

  void setTyping(bool isTyping) {
    _repository.setTyping(matchId: _matchId, isTyping: isTyping);
  }

  @override
  void dispose() {
    _repository.leaveMatch(_matchId);
    _subscription?.cancel();
    super.dispose();
  }
}

final chatControllerProvider = StateNotifierProvider.family<ChatController,
    ChatState, String>((ref, matchId) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatController(repository, matchId);
});

class ConversationChatController extends StateNotifier<ChatState> {
  ConversationChatController(this._repository, this._conversationId)
      : super(ChatState.initial()) {
    _init();
  }

  final ChatRepository _repository;
  final String _conversationId;

  Future<void> _init() async {
    try {
      final initialMessages = await _repository.loadMessagesForConversation(
        conversationId: _conversationId,
        limit: 50,
      );
      state = state.copyWith(messages: initialMessages, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load messages.',
      );
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    try {
      final message = await _repository.sendMessageToConversation(
        conversationId: _conversationId,
        content: content.trim(),
      );
      state = state.copyWith(
        messages: [...state.messages, message],
      );
    } catch (_) {
      state = state.copyWith(error: 'Failed to send message.');
    }
  }
}

final conversationChatControllerProvider =
    StateNotifierProvider.family<ConversationChatController, ChatState, String>(
        (ref, conversationId) {
  final repository = ref.watch(chatRepositoryProvider);
  return ConversationChatController(repository, conversationId);
});

final currentUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});
