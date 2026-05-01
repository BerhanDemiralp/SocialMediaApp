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
                deleted_at: null,
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
                    where: { deleted_at: null },
                    orderBy: { created_at: 'desc' },
                    take: 1,
                },
                group: true,
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
    async createMessageForConversation(conversationId, userId, content) {
        if (!content.trim()) {
            throw new common_1.BadRequestException('Message content cannot be empty');
        }
        const conversation = await this.prisma.conversations.findUnique({
            where: { id: conversationId },
            include: {
                participants: true,
                group: {
                    include: {
                        members: true,
                    },
                },
            },
        });
        if (!conversation || conversation.deleted_at) {
            throw new common_1.NotFoundException('Conversation not found');
        }
        this.assertCanAccessConversation(conversation, userId);
        if (conversation.type === client_1.ConversationType.friend) {
            const participantIds = conversation.participants
                .map((p) => p.user_id)
                .filter((id, index, arr) => !!id && arr.indexOf(id) === index);
            if (participantIds.length === 2) {
                const [userAId, userBId] = participantIds;
                const friendship = await this.prisma.friendships.findFirst({
                    where: {
                        status: 'accepted',
                        OR: [
                            { requester_id: userAId, addressee_id: userBId },
                            { requester_id: userBId, addressee_id: userAId },
                        ],
                    },
                });
                if (!friendship) {
                    throw new common_1.ForbiddenException('Chat is read-only because you are no longer friends');
                }
            }
        }
        const message = await this.prisma.$transaction(async (tx) => {
            const created = await tx.messages.create({
                data: {
                    conversation_id: conversation.id,
                    sender_id: userId,
                    content: content.trim(),
                },
                include: {
                    sender: true,
                },
            });
            await tx.conversations.update({
                where: { id: conversation.id },
                data: { updated_at: new Date() },
            });
            return created;
        });
        return message;
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
                    where: { deleted_at: null },
                    orderBy: { created_at: 'desc' },
                    take: 1,
                },
                group: true,
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
                group: {
                    include: {
                        members: true,
                    },
                },
            },
        });
        if (!conversation || conversation.deleted_at) {
            throw new common_1.NotFoundException('Conversation not found');
        }
        this.assertCanAccessConversation(conversation, userId);
        const take = limit && limit > 0 ? limit : 50;
        const messages = await this.prisma.messages.findMany({
            where: { conversation_id: conversationId, deleted_at: null },
            include: {
                sender: true,
            },
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
    async assertUserCanAccessConversation(conversationId, userId) {
        const conversation = await this.prisma.conversations.findUnique({
            where: { id: conversationId },
            include: {
                participants: true,
                group: {
                    include: {
                        members: true,
                    },
                },
            },
        });
        if (!conversation || conversation.deleted_at) {
            throw new common_1.NotFoundException('Conversation not found');
        }
        this.assertCanAccessConversation(conversation, userId);
    }
    assertCanAccessConversation(conversation, userId) {
        if (conversation.type === client_1.ConversationType.group) {
            const isCurrentGroupMember = !!conversation.group &&
                !conversation.group.deleted_at &&
                conversation.group.members.some((member) => member.user_id === userId);
            if (!isCurrentGroupMember) {
                throw new common_1.ForbiddenException('You are not allowed to access this group chat');
            }
            return;
        }
        const isParticipant = conversation.participants.some((p) => p.user_id === userId);
        if (!isParticipant) {
            throw new common_1.ForbiddenException('You are not allowed to access this conversation');
        }
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
            title: conversation.group?.name ?? conversation.title,
            friendMatchId: null,
            groupId: conversation.group?.id ?? null,
            groupName: conversation.group?.name ?? null,
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