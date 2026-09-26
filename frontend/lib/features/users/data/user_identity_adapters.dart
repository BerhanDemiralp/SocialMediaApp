import '../../chat/domain/chat_message.dart';
import '../../groups/data/groups_api_client.dart';
import '../../home/data/matching_engine_api_client.dart';
import '../domain/user_identity.dart';
import 'friend_conversations_api_client.dart';
import 'friend_requests_api_client.dart';
import 'friends_api_client.dart';
import 'user_profile_api_client.dart';
import 'user_search_api_client.dart';

extension SearchIdentity on UserSummary {
  UserIdentity get identity =>
      UserIdentity(id: id, username: username, avatarUrl: avatarUrl);
}

extension FriendIdentity on FriendSummary {
  UserIdentity get identity =>
      UserIdentity(id: id, username: username, avatarUrl: avatarUrl);
}

extension RequestIdentity on FriendRequestItem {
  UserIdentity get identity =>
      UserIdentity(id: userId, username: username, avatarUrl: avatarUrl);
}

extension MemberIdentity on GroupMemberSummary {
  UserIdentity get identity =>
      UserIdentity(id: id, username: username, avatarUrl: avatarUrl);
}

extension ProfileIdentity on UserProfile {
  UserIdentity get identity =>
      UserIdentity(id: id, username: username, avatarUrl: avatarUrl);
}

extension ConversationIdentity on FriendConversationSummary {
  UserIdentity get identity => UserIdentity(
    id: friendId ?? '',
    username: displayName,
    avatarUrl: avatarUrl,
  );
}

extension SenderIdentity on ChatMessage {
  UserIdentity get identity => UserIdentity(
    id: senderId,
    username: senderUsername ?? 'User',
    avatarUrl: senderAvatarUrl,
  );
}

extension ParticipantIdentity on MomentParticipantSummary {
  UserIdentity get identity =>
      UserIdentity(id: id, username: username, avatarUrl: avatarUrl);
}

extension MomentIdentity on MomentSummary {
  UserIdentity otherIdentity(String? currentUserId) {
    for (final participant in participants) {
      if (participant.id != currentUserId) return participant.identity;
    }
    return UserIdentity(
      id: currentUserId == userAId ? userBId : userAId,
      username: otherParticipantName(currentUserId),
    );
  }
}
