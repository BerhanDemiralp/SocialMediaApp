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
exports.FriendsController = void 0;
const common_1 = require("@nestjs/common");
const auth_guard_1 = require("../auth/guards/auth.guard");
const friends_service_1 = require("./friends.service");
const send_friend_request_dto_1 = require("./dto/send-friend-request.dto");
let FriendsController = class FriendsController {
    friendsService;
    constructor(friendsService) {
        this.friendsService = friendsService;
    }
    async sendFriendRequest(req, body) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        return this.friendsService.sendFriendRequest(userId, body.targetUserId);
    }
    async acceptRequest(req, id) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        return this.friendsService.acceptRequest(userId, id);
    }
    async rejectRequest(req, id) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        return this.friendsService.rejectRequest(userId, id);
    }
    async cancelRequest(req, id) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        return this.friendsService.cancelRequest(userId, id);
    }
    async listFriends(req) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        return this.friendsService.listFriends(userId);
    }
    async listIncomingRequests(req) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        return this.friendsService.listIncomingRequests(userId);
    }
    async listOutgoingRequests(req) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        return this.friendsService.listOutgoingRequests(userId);
    }
};
exports.FriendsController = FriendsController;
__decorate([
    (0, common_1.Post)('requests'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, send_friend_request_dto_1.SendFriendRequestDto]),
    __metadata("design:returntype", Promise)
], FriendsController.prototype, "sendFriendRequest", null);
__decorate([
    (0, common_1.Patch)('requests/:id/accept'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], FriendsController.prototype, "acceptRequest", null);
__decorate([
    (0, common_1.Patch)('requests/:id/reject'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], FriendsController.prototype, "rejectRequest", null);
__decorate([
    (0, common_1.Patch)('requests/:id/cancel'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], FriendsController.prototype, "cancelRequest", null);
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], FriendsController.prototype, "listFriends", null);
__decorate([
    (0, common_1.Get)('requests/incoming'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], FriendsController.prototype, "listIncomingRequests", null);
__decorate([
    (0, common_1.Get)('requests/outgoing'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], FriendsController.prototype, "listOutgoingRequests", null);
exports.FriendsController = FriendsController = __decorate([
    (0, common_1.Controller)('friends'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    __metadata("design:paramtypes", [friends_service_1.FriendsService])
], FriendsController);
//# sourceMappingURL=friends.controller.js.map