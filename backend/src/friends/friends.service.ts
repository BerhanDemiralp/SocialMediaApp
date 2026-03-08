import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { FriendsRepository } from './friends.repository';
import { ConversationsService } from '../conversations/conversations.service';

@Injectable()
export class FriendsService {
  constructor(
    private friendsRepository: FriendsRepository,
    private conversationsService: ConversationsService,
  ) {}

  async sendFriendRequest(requesterId: string, targetUserId: string) {
    if (requesterId === targetUserId) {
      throw new BadRequestException('You cannot send a request to yourself');
    }

    const existing = await this.friendsRepository.findFriendshipBetweenUsers(
      requesterId,
      targetUserId,
    );

    if (existing) {
      if (existing.status === 'pending') {
        throw new BadRequestException(
          'A pending friend request already exists',
        );
      }

      if (existing.status === 'accepted') {
        throw new BadRequestException('Users are already friends');
      }

      // Allow sending a new request after a previous one was canceled or rejected
      // by re-activating the existing friendship record instead of creating a new one.
      if (
        (existing.status === 'canceled' || existing.status === 'rejected') &&
        existing.requester_id === requesterId &&
        existing.addressee_id === targetUserId
      ) {
        return this.friendsRepository.updateFriendshipStatus(
          existing.id,
          'pending',
        );
      }
    }

    return this.friendsRepository.createFriendRequest(
      requesterId,
      targetUserId,
    );
  }

  async acceptRequest(userId: string, requestId: string) {
    const friendship =
      await this.friendsRepository.findFriendshipById(requestId);

    if (!friendship) {
      throw new NotFoundException('Friend request not found');
    }

    if (friendship.addressee_id !== userId) {
      throw new ForbiddenException('You cannot accept this friend request');
    }

    if (friendship.status !== 'pending') {
      throw new BadRequestException(
        'Only pending friend requests can be accepted',
      );
    }

    const updated = await this.friendsRepository.updateFriendshipStatus(
      requestId,
      'accepted',
    );

    // Ensure a friend conversation (and backing match) exists for this friendship.
    await this.conversationsService.ensureFriendConversationBetweenUsers(
      updated.requester_id,
      updated.addressee_id,
    );

    return updated;
  }

  async rejectRequest(userId: string, requestId: string) {
    const friendship =
      await this.friendsRepository.findFriendshipById(requestId);

    if (!friendship) {
      throw new NotFoundException('Friend request not found');
    }

    if (friendship.addressee_id !== userId) {
      throw new ForbiddenException('You cannot reject this friend request');
    }

    if (friendship.status !== 'pending') {
      throw new BadRequestException(
        'Only pending friend requests can be rejected',
      );
    }

    return this.friendsRepository.updateFriendshipStatus(requestId, 'rejected');
  }

  async cancelRequest(userId: string, requestId: string) {
    const friendship =
      await this.friendsRepository.findFriendshipById(requestId);

    if (!friendship) {
      throw new NotFoundException('Friend request not found');
    }

    if (friendship.requester_id !== userId) {
      throw new ForbiddenException('You cannot cancel this friend request');
    }

    if (friendship.status !== 'pending') {
      throw new BadRequestException(
        'Only pending friend requests can be canceled',
      );
    }

    return this.friendsRepository.updateFriendshipStatus(requestId, 'canceled');
  }

  async listFriends(userId: string) {
    const friendships =
      await this.friendsRepository.listAcceptedFriendshipsForUser(userId);

    return friendships.map((friendship) => {
      const otherUser =
        friendship.requester_id === userId
          ? friendship.addressee
          : friendship.requester;

      return {
        id: otherUser.id,
        username: otherUser.username,
        avatar_url: otherUser.avatar_url,
      };
    });
  }

  async listIncomingRequests(userId: string) {
    const incoming = await this.friendsRepository.listIncomingRequests(userId);

    return incoming.map((request) => ({
      id: request.id,
      from: {
        id: request.requester.id,
        username: request.requester.username,
        avatar_url: request.requester.avatar_url,
      },
      status: request.status,
      created_at: request.created_at,
    }));
  }

  async listOutgoingRequests(userId: string) {
    const outgoing = await this.friendsRepository.listOutgoingRequests(userId);

    return outgoing.map((request) => ({
      id: request.id,
      to: {
        id: request.addressee.id,
        username: request.addressee.username,
        avatar_url: request.addressee.avatar_url,
      },
      status: request.status,
      created_at: request.created_at,
    }));
  }

  async removeFriend(userId: string, friendId: string) {
    const friendship =
      await this.friendsRepository.findFriendshipBetweenUsers(userId, friendId);

    if (!friendship || friendship.status !== 'accepted') {
      throw new NotFoundException('Friendship not found');
    }

    return this.friendsRepository.updateFriendshipStatus(
      friendship.id,
      'rejected',
    );
  }
}
