import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../users/data/user_session.dart';

import '../../../core/env/app_env.dart';
import '../domain/chat_message.dart';

final chatSocketClientProvider = Provider.autoDispose<ChatSocketClient>((ref) {
  ref.watch(activeAccountIdProvider);
  final client = ChatSocketClient(Supabase.instance.client);
  ref.onDispose(client.dispose);
  return client;
});

class ChatSocketClient {
  ChatSocketClient(this._supabaseClient) {
    _connect();
    final account = _supabaseClient.auth.currentUser?.id;
    _authSubscription = _supabaseClient.auth.onAuthStateChange.listen((event) {
      if (event.session?.user.id != account) {
        _socket.disconnect();
        return;
      }
      final token = event.session?.accessToken;
      if (token != null && _socket.auth?['token'] != token) {
        _socket.auth = {'token': token};
        _socket.disconnect().connect();
      }
    });
  }

  final SupabaseClient _supabaseClient;
  late final io.Socket _socket;
  final Set<String> _conversations = {};
  StreamSubscription<AuthState>? _authSubscription;
  final _changes = StreamController<String?>.broadcast();
  Stream<String?> get conversationChanges => _changes.stream;

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
          .enableForceNew()
          .setAuth(token != null ? {'token': token} : {})
          .setExtraHeaders(
            token != null ? {'Authorization': 'Bearer $token'} : {},
          )
          .build(),
    );

    _socket.onConnect((_) {
      _socket.emitWithAck(
        'watchInbox',
        {},
        ack: (data) {
          if (!_changes.isClosed && data is Map && data['ok'] == true) {
            _changes.add(null);
          }
        },
      );
      for (final id in _conversations) {
        _socket.emit('joinConversation', {'conversationId': id});
      }
    });
    _socket.on('conversationChanged', (data) {
      if (data is Map &&
          data['conversationId'] is String &&
          !_changes.isClosed) {
        _changes.add(data['conversationId'] as String);
      }
    });
    _socket.on('newMessage', (data) {
      try {
        final message = ChatMessage.fromJson(
          Map<String, dynamic>.from(data as Map),
        );
        _messageController.add(message);
      } catch (_) {
        // Swallow malformed messages for now.
      }
    });
  }

  void joinConversation(String conversationId) {
    _conversations.add(conversationId);
    if (_socket.connected) {
      _socket.emit('joinConversation', {'conversationId': conversationId});
    }
  }

  void leaveConversation(String conversationId) {
    _conversations.remove(conversationId);
    if (_socket.connected) {
      _socket.emit('leaveConversation', {'conversationId': conversationId});
    }
  }

  void sendMessage({required String conversationId, required String content}) {
    _socket.emit('sendConversationMessage', {
      'conversationId': conversationId,
      'content': content,
    });
  }

  void setTyping({required String conversationId, required bool isTyping}) {
    _socket.emit('typingConversation', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  void dispose() {
    _authSubscription?.cancel();
    _changes.close();
    _messageController.close();
    _socket.dispose();
  }
}
