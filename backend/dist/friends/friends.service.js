"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.FriendsService = void 0;
const common_1 = require("@nestjs/common");
const friends_repository_1 = require("./friends.repository");
const conversations_service_1 = require("../conversations/conversations.service");
let FriendsService = class FriendsService {
    friendsRepository;
    conversationsService;
    constructor(friendsRepository, conversationsService) {
        this.friendsRepository = friendsRepository;
        this.conversationsService = conversationsService;
    }
    async sendFriendRequest(requesterId, targetUserId) {
        if (requesterId === targetUserId) {
            throw new common_1.BadRequestException('You cannot send a request to yourself');
        }
        const existing = await this.friendsRepository.findFriendshipBetweenUsers(requesterId, targetUserId);
        if (existing) {
            if (existing.status === 'pending') {
                throw new common_1.BadRequestException('A pending friend request already exists');
            }
            if (existing.status === 'accepted') {
                throw new common_1.BadRequestException('Users are already friends');
            }
            if ((existing.status === 'canceled' || existing.status === 'rejected') &&
                existing.requester_id === requesterId &&
                existing.addressee_id === targetUserId) {
                return this.friendsRepository.updateFriendshipStatus(existing.id, 'pending');
            }
        }
        return this.friendsRepository.createFriendRequest(requesterId, targetUserId);
    }
    async acceptRequest(userId, requestId) {
        const friendship = await this.friendsRepository.findFriendshipById(requestId);
        if (!friendship) {
            throw new common_1.NotFoundException('Friend request not found');
        }
        if (friendship.addressee_id !== userId) {
            throw new common_1.ForbiddenException('You cannot accept this friend request');
        }
        if (friendship.status !== 'pending') {
            throw new common_1.BadRequestException('Only pending friend requests can be accepted');
        }
        const updated = await this.friendsRepository.updateFriendshipStatus(requestId, 'accepted');
        await this.conversationsService.ensureFriendConversationBetweenUsers(updated.requester_id, updated.addressee_id);
        return updated;
    }
    async rejectRequest(userId, requestId) {
        const friendship = await this.friendsRepository.findFriendshipById(requestId);
        if (!friendship) {
            throw new common_1.NotFoundException('Friend request not found');
        }
        if (friendship.addressee_id !== userId) {
            throw new common_1.ForbiddenException('You cannot reject this friend request');
        }
        if (friendship.status !== 'pending') {
            throw new common_1.BadRequestException('Only pending friend requests can be rejected');
        }
        return this.friendsRepository.updateFriendshipStatus(requestId, 'rejected');
    }
    async cancelRequest(userId, requestId) {
        const friendship = await this.friendsRepository.findFriendshipById(requestId);
        if (!friendship) {
            throw new common_1.NotFoundException('Friend request not found');
        }
        if (friendship.requester_id !== userId) {
            throw new common_1.ForbiddenException('You cannot cancel this friend request');
        }
        if (friendship.status !== 'pending') {
            throw new common_1.BadRequestException('Only pending friend requests can be canceled');
        }
        return this.friendsRepository.updateFriendshipStatus(requestId, 'canceled');
    }
    async listFriends(userId) {
        const friendships = await this.friendsRepository.listAcceptedFriendshipsForUser(userId);
        return friendships.map((friendship) => {
            const otherUser = friendship.requester_id === userId
                ? friendship.addressee
                : friendship.requester;
            return {
                id: otherUser.id,
                username: otherUser.username,
                avatar_url: otherUser.avatar_url,
            };
        });
    }
    async listIncomingRequests(userId) {
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
    async listOutgoingRequests(userId) {
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
    async removeFriend(userId, friendId) {
        const friendship = await this.friendsRepository.findFriendshipBetweenUsers(userId, friendId);
        if (!friendship || friendship.status !== 'accepted') {
            throw new common_1.NotFoundException('Friendship not found');
        }
        return this.friendsRepository.updateFriendshipStatus(friendship.id, 'rejected');
    }
};
exports.FriendsService = FriendsService;
exports.FriendsService = FriendsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [friends_repository_1.FriendsRepository,
        conversations_service_1.ConversationsService])
], FriendsService);
//# sourceMappingURL=friends.service.js.map