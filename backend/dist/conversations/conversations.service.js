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
exports.ConversationsService = void 0;
const common_1 = require("@nestjs/common");
const client_1 = require("@prisma/client");
const prisma_service_1 = require("../prisma/prisma.service");
let ConversationsService = class ConversationsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async listConversationsForUser(userId, limit, cursor, type) {
        const take = limit && limit > 0 ? limit : 20;
        const conversations = await this.prisma.conversations.findMany({
            where: {
                ...(type && { type }),
                participants: {
                    some: { user_id: userId },
                },
            },
            orderBy: {
                updated_at: 'desc',
            },
            take,
            skip: cursor ? 1 : 0,
            ...(cursor && { cursor: { id: cursor } }),
            include: {
                participants: {
                    include: {
                        user: true,
                    },
                },
                messages: {
                    orderBy: { created_at: 'desc' },
                    take: 1,
                },
            },
        });
        const items = conversations.map((conversation) => this.mapConversationToSummary(conversation));
        const nextCursor = conversations.length === take
            ? conversations[conversations.length - 1]?.id
            : null;
        return {
            items,
            nextCursor,
        };
    }
    async ensureFriendConversationBetweenUsers(userId, friendId) {
        if (userId === friendId) {
            throw new common_1.BadRequestException('You cannot create a conversation with yourself');
        }
        const friendship = await this.prisma.friendships.findFirst({
            where: {
                status: 'accepted',
                OR: [
                    { requester_id: userId, addressee_id: friendId },
                    { requester_id: friendId, addressee_id: userId },
                ],
            },
        });
        if (!friendship) {
            throw new common_1.ForbiddenException('Users are not friends');
        }
        let conversation = await this.prisma.conversations.findFirst({
            where: {
                type: client_1.ConversationType.friend,
                participants: {
                    some: { user_id: userId },
                },
                AND: {
                    participants: {
                        some: { user_id: friendId },
                    },
                },
            },
        });
        if (!conversation) {
            const participantIds = [userId, friendId].filter((id, index, arr) => !!id && arr.indexOf(id) === index);
            const participantsCreate = participantIds.map((participantId) => ({
                user: { connect: { id: participantId } },
            }));
            conversation = await this.prisma.conversations.create({
                data: {
                    type: client_1.ConversationType.friend,
                    title: null,
                    friend_match_id: null,
                    group_match_id: null,
                    participants: {
                        create: participantsCreate,
                    },
                },
            });
        }
        const conversationWithRelations = await this.prisma.conversations.findUnique({
            where: { id: conversation.id },
            include: {
                participants: {
                    include: {
                        user: true,
                    },
                },
                messages: {
                    orderBy: { created_at: 'desc' },
                    take: 1,
                },
            },
        });
        if (!conversationWithRelations) {
            throw new common_1.NotFoundException('Conversation not found after creation');
        }
        return this.mapConversationToSummary(conversationWithRelations);
    }
    async getConversationMessages(conversationId, userId, limit, cursor) {
        const conversation = await this.prisma.conversations.findUnique({
            where: { id: conversationId },
            include: {
                participants: true,
            },
        });
        if (!conversation) {
            throw new common_1.NotFoundException('Conversation not found');
        }
        const isParticipant = conversation.participants.some((p) => p.user_id === userId);
        if (!isParticipant) {
            throw new common_1.ForbiddenException('You are not allowed to view messages for this conversation');
        }
        const take = limit && limit > 0 ? limit : 50;
        const messages = await this.prisma.messages.findMany({
            where: { conversation_id: conversationId },
            orderBy: { created_at: 'desc' },
            take,
            skip: cursor ? 1 : 0,
            ...(cursor && { cursor: { id: cursor } }),
        });
        const nextCursor = messages.length === take ? messages[messages.length - 1]?.id : null;
        return {
            items: messages,
            nextCursor,
        };
    }
    mapConversationToSummary(conversation) {
        const lastMessage = conversation.messages[0] ?? null;
        const participants = conversation.participants.map((p) => ({
            id: p.user.id,
            username: p.user.username,
            avatar_url: p.user.avatar_url,
        }));
        return {
            id: conversation.id,
            type: conversation.type,
            title: conversation.title,
            friendMatchId: conversation.friend_match_id,
            participants,
            lastMessage: lastMessage
                ? {
                    id: lastMessage.id,
                    content: lastMessage.content,
                    created_at: lastMessage.created_at,
                }
                : null,
        };
    }
};
exports.ConversationsService = ConversationsService;
exports.ConversationsService = ConversationsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], ConversationsService);
//# sourceMappingURL=conversations.service.js.map