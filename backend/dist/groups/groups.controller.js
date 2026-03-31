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
exports.GroupsController = void 0;
const common_1 = require("@nestjs/common");
const auth_guard_1 = require("../auth/guards/auth.guard");
const groups_service_1 = require("./groups.service");
const create_group_dto_1 = require("./dto/create-group.dto");
const join_group_dto_1 = require("./dto/join-group.dto");
let GroupsController = class GroupsController {
    groupsService;
    constructor(groupsService) {
        this.groupsService = groupsService;
    }
    async createGroup(req, body) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        return this.groupsService.createGroup(userId, body.name);
    }
    async joinGroup(req, body) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        return this.groupsService.joinGroupByInviteCode(userId, body.inviteCode);
    }
    async leaveGroup(req, groupId) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        return this.groupsService.leaveGroup(userId, groupId);
    }
    async listGroupMembers(req, groupId) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        return this.groupsService.listGroupMembers(userId, groupId);
    }
    async listMyGroups(req) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        return this.groupsService.listMyGroups(userId);
    }
};
exports.GroupsController = GroupsController;
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, create_group_dto_1.CreateGroupDto]),
    __metadata("design:returntype", Promise)
], GroupsController.prototype, "createGroup", null);
__decorate([
    (0, common_1.Post)('join'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, join_group_dto_1.JoinGroupDto]),
    __metadata("design:returntype", Promise)
], GroupsController.prototype, "joinGroup", null);
__decorate([
    (0, common_1.Post)(':groupId/leave'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('groupId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], GroupsController.prototype, "leaveGroup", null);
__decorate([
    (0, common_1.Get)(':groupId/members'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('groupId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], GroupsController.prototype, "listGroupMembers", null);
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], GroupsController.prototype, "listMyGroups", null);
exports.GroupsController = GroupsController = __decorate([
    (0, common_1.Controller)('groups'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    __metadata("design:paramtypes", [groups_service_1.GroupsService])
], GroupsController);
//# sourceMappingURL=groups.controller.js.map