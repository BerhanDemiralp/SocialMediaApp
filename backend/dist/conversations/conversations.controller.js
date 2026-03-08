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
exports.ConversationsController = void 0;
const common_1 = require("@nestjs/common");
const client_1 = require("@prisma/client");
const auth_guard_1 = require("../auth/guards/auth.guard");
const conversations_service_1 = require("./conversations.service");
const list_conversations_query_dto_1 = require("./dto/list-conversations-query.dto");
const get_conversation_messages_query_dto_1 = require("./dto/get-conversation-messages-query.dto");
const create_friend_conversation_dto_1 = require("./dto/create-friend-conversation.dto");
let ConversationsController = class ConversationsController {
    conversationsService;
    constructor(conversationsService) {
        this.conversationsService = conversationsService;
    }
    async listConversations(req, query) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        const { limit, cursor, type } = query;
        const conversationType = type && Object.values(client_1.ConversationType).includes(type)
            ? type
            : undefined;
        return this.conversationsService.listConversationsForUser(userId, limit, cursor, conversationType);
    }
    async getConversationMessages(conversationId, req, query) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        const { limit, cursor } = query;
        return this.conversationsService.getConversationMessages(conversationId, userId, limit, cursor);
    }
    async createConversationMessage(conversationId, req, body) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        const content = body.content ?? '';
        return this.conversationsService.createMessageForConversation(conversationId, userId, content);
    }
    async createOrReuseFriendConversation(req, body) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        if (!body.friendId) {
            throw new common_1.BadRequestException('friendId is required');
        }
        return this.conversationsService.ensureFriendConversationBetweenUsers(userId, body.friendId);
    }
};
exports.ConversationsController = ConversationsController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, list_conversations_query_dto_1.ListConversationsQueryDto]),
    __metadata("design:returntype", Promise)
], ConversationsController.prototype, "listConversations", null);
__decorate([
    (0, common_1.Get)(':id/messages'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Request)()),
    __param(2, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, get_conversation_messages_query_dto_1.GetConversationMessagesQueryDto]),
    __metadata("design:returntype", Promise)
], ConversationsController.prototype, "getConversationMessages", null);
__decorate([
    (0, common_1.Post)(':id/messages'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Request)()),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], ConversationsController.prototype, "createConversationMessage", null);
__decorate([
    (0, common_1.Post)('friends'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, create_friend_conversation_dto_1.CreateFriendConversationDto]),
    __metadata("design:returntype", Promise)
], ConversationsController.prototype, "createOrReuseFriendConversation", null);
exports.ConversationsController = ConversationsController = __decorate([
    (0, common_1.Controller)('conversations'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    __metadata("design:paramtypes", [conversations_service_1.ConversationsService])
], ConversationsController);
//# sourceMappingURL=conversations.controller.js.map