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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.EventsGateway = void 0;
const websockets_1 = require("@nestjs/websockets");
const common_1 = require("@nestjs/common");
const socket_io_1 = require("socket.io");
const ws_auth_guard_1 = require("./guards/ws-auth.guard");
const prisma_service_1 = require("../prisma/prisma.service");
const client_1 = require("@prisma/client");
let EventsGateway = class EventsGateway {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    server;
    handleConnection(client) {
        console.log(`Client connected: ${client.id}`);
    }
    handleDisconnect(client) {
        console.log(`Client disconnected: ${client.id}`);
    }
    async handleJoinMatch(client, data) {
        const { matchId } = data;
        const { conversation } = await this.ensureConversationForMatch(matchId);
        void client.join(`match:${matchId}`);
        void client.join(`conversation:${conversation.id}`);
        console.log(`User ${client.user?.id} joined match ${matchId}`);
        return {
            event: 'joined',
            data: { matchId, conversationId: conversation.id },
        };
    }
    async handleLeaveMatch(client, data) {
        const { matchId } = data;
        const { conversation } = await this.ensureConversationForMatch(matchId);
        void client.leave(`conversation:${conversation.id}`);
        void client.leave(`match:${matchId}`);
        console.log(`User ${client.user?.id} left match ${matchId}`);
        return {
            event: 'left',
            data: { matchId, conversationId: conversation.id },
        };
    }
    async handleMessage(client, data) {
        const { matchId, content } = data;
        const userId = client.user?.id;
        if (!userId) {
            throw new websockets_1.WsException('Unauthorized');
        }
        const { match, conversation } = await this.ensureConversationForMatch(matchId);
        if (match.user_a_id !== userId && match.user_b_id !== userId) {
            throw new websockets_1.WsException('You are not allowed to send messages for this match');
        }
        if (match.match_type === 'friends') {
            const friendship = await this.prisma.friendships.findFirst({
                where: {
                    status: 'accepted',
                    OR: [
                        {
                            requester_id: match.user_a_id,
                            addressee_id: match.user_b_id,
                        },
                        {
                            requester_id: match.user_b_id,
                            addressee_id: match.user_a_id,
                        },
                    ],
                },
            });
            if (!friendship) {
                throw new websockets_1.WsException('Chat is read-only because you are no longer friends');
            }
        }
        const message = await this.prisma.messages.create({
            data: {
                match_id: matchId,
                conversation_id: conversation.id,
                sender_id: userId,
                content,
            },
        });
        this.server
            .to(`conversation:${conversation.id}`)
            .emit('newMessage', message);
        this.server.to(`match:${matchId}`).emit('newMessage', message);
        return { event: 'messageSent', data: message };
    }
    async handleTyping(client, data) {
        const { matchId, isTyping } = data;
        const { conversation } = await this.ensureConversationForMatch(matchId);
        client.to(`conversation:${conversation.id}`).emit('userTyping', {
            userId: client.user?.id,
            isTyping,
        });
        client.to(`match:${matchId}`).emit('userTyping', {
            userId: client.user?.id,
            isTyping,
        });
        return { event: 'typingAcknowledged' };
    }
    async ensureConversationForMatch(matchId) {
        const match = await this.prisma.matches.findUnique({
            where: { id: matchId },
        });
        if (!match) {
            throw new websockets_1.WsException('Match not found');
        }
        const isFriendMatch = match.match_type === 'friends';
        const isGroupMatch = match.match_type === 'groups';
        const where = isFriendMatch || !isGroupMatch
            ? { friend_match_id: match.id }
            : { group_match_id: match.id };
        let conversation = await this.prisma.conversations.findFirst({
            where,
        });
        if (!conversation) {
            const participantIds = [match.user_a_id, match.user_b_id].filter((id, index, arr) => !!id && arr.indexOf(id) === index);
            const participantsCreate = participantIds.map((userId) => ({
                user: { connect: { id: userId } },
            }));
            const type = isFriendMatch
                ? client_1.ConversationType.friend
                : isGroupMatch
                    ? client_1.ConversationType.group_pair
                    : client_1.ConversationType.friend;
            conversation = await this.prisma.conversations.create({
                data: {
                    type,
                    title: null,
                    friend_match_id: isFriendMatch ? match.id : null,
                    group_match_id: isGroupMatch ? match.id : null,
                    participants: {
                        create: participantsCreate,
                    },
                },
            });
        }
        return { match, conversation };
    }
};
exports.EventsGateway = EventsGateway;
__decorate([
    (0, websockets_1.WebSocketServer)(),
    __metadata("design:type", socket_io_1.Server)
], EventsGateway.prototype, "server", void 0);
__decorate([
    (0, websockets_1.SubscribeMessage)('joinMatch'),
    (0, common_1.UseGuards)(ws_auth_guard_1.WsAuthGuard),
    __param(0, (0, websockets_1.ConnectedSocket)()),
    __param(1, (0, websockets_1.MessageBody)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [socket_io_1.Socket, Object]),
    __metadata("design:returntype", Promise)
], EventsGateway.prototype, "handleJoinMatch", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('leaveMatch'),
    (0, common_1.UseGuards)(ws_auth_guard_1.WsAuthGuard),
    __param(0, (0, websockets_1.ConnectedSocket)()),
    __param(1, (0, websockets_1.MessageBody)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [socket_io_1.Socket, Object]),
    __metadata("design:returntype", Promise)
], EventsGateway.prototype, "handleLeaveMatch", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('sendMessage'),
    (0, common_1.UseGuards)(ws_auth_guard_1.WsAuthGuard),
    __param(0, (0, websockets_1.ConnectedSocket)()),
    __param(1, (0, websockets_1.MessageBody)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [socket_io_1.Socket, Object]),
    __metadata("design:returntype", Promise)
], EventsGateway.prototype, "handleMessage", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('typing'),
    (0, common_1.UseGuards)(ws_auth_guard_1.WsAuthGuard),
    __param(0, (0, websockets_1.ConnectedSocket)()),
    __param(1, (0, websockets_1.MessageBody)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [socket_io_1.Socket, Object]),
    __metadata("design:returntype", Promise)
], EventsGateway.prototype, "handleTyping", null);
exports.EventsGateway = EventsGateway = __decorate([
    (0, websockets_1.WebSocketGateway)({
        cors: {
            origin: '*',
        },
    }),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], EventsGateway);
//# sourceMappingURL=events.gateway.js.map