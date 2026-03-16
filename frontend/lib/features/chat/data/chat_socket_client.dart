import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env/app_env.dart';
import '../domain/chat_message.dart';

class ChatSocketClient {
  ChatSocketClient(this._supabaseClient) {
    _connect();
  }

  final SupabaseClient _supabaseClient;
  late final io.Socket _socket;

  final _messageController = StreamController<ChatMessage>.broadcast();

  Stream<ChatMessage> get messageStream => _messageController.stream;

  void _connect() {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken;

    _socket = io.io(
      AppEnv.wsBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth(token != null ? {'token': token} : {})
          .setExtraHeaders(
            token != null ? {'Authorization': 'Bearer $token'} : {},
          )
          .build(),
    );

    _socket.on('newMessage', (data) {
      try {
        final message =
            ChatMessage.fromJson(Map<String, dynamic>.from(data as Map));
        _messageController.add(message);
      } catch (_) {
        // Swallow malformed messages for now.
      }
    });
  }

  void joinConversation(String conversationId) {
    _socket.emit('joinConversation', {'conversationId': conversationId});
  }

  void leaveConversation(String conversationId) {
    _socket.emit('leaveConversation', {'conversationId': conversationId});
  }

  void sendMessage({
    required String conversationId,
    required String content,
  }) {
    _socket.emit('sendConversationMessage', {
      'conversationId': conversationId,
      'content': content,
    });
  }

  void setTyping({
    required String conversationId,
    required bool isTyping,
  }) {
    _socket.emit('typingConversation', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  void dispose() {
    _messageController.close();
    _socket.dispose();
  }
}
