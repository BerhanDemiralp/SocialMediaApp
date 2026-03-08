import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moment_app/features/home/data/friend_conversations_api_client.dart';
import 'package:moment_app/features/home/data/friends_api_client.dart';
import 'package:moment_app/features/home/presentation/home_messages_screen.dart';

void main() {
  testWidgets('shows empty state when there are no conversations',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendConversationsProvider.overrideWith(
            (ref) async => <FriendConversationSummary>[],
          ),
          messagesFriendsProvider.overrideWith(
            (ref) async => <FriendSummary>[],
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HomeMessagesScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('You have no friends yet.'), findsOneWidget);
  });

  testWidgets('renders friend conversations list',
      (WidgetTester tester) async {
    final friends = <FriendSummary>[
      const FriendSummary(id: 'friend-1', username: 'Alice', avatarUrl: null),
      const FriendSummary(id: 'friend-2', username: 'Bob', avatarUrl: null),
    ];

    final items = <FriendConversationSummary>[
      FriendConversationSummary(
        friendId: 'friend-1',
        conversationId: 'conv-1',
        matchId: 'match-1',
        displayName: 'Alice',
        avatarUrl: null,
        lastMessagePreview: 'Hey there',
        lastMessageAt: DateTime.now(),
      ),
      FriendConversationSummary(
        friendId: 'friend-2',
        conversationId: 'conv-2',
        matchId: null,
        displayName: 'Bob',
        avatarUrl: null,
        lastMessagePreview: 'What\'s up?',
        lastMessageAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          messagesFriendsProvider.overrideWith(
            (ref) async => friends,
          ),
          friendConversationsProvider.overrideWith(
            (ref) async => items,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HomeMessagesScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Hey there'), findsOneWidget);
    expect(find.text('What\'s up?'), findsOneWidget);
  });
}
