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
exports.GroupsService = void 0;
const common_1 = require("@nestjs/common");
const crypto_1 = require("crypto");
const groups_repository_1 = require("./groups.repository");
let GroupsService = class GroupsService {
    groupsRepository;
    constructor(groupsRepository) {
        this.groupsRepository = groupsRepository;
    }
    async createGroup(ownerId, name) {
        const inviteCode = (0, crypto_1.randomUUID)();
        const group = await this.groupsRepository.createGroupWithOwner(ownerId, name, inviteCode);
        return {
            id: group.id,
            name: group.name,
            invite_code: group.invite_code,
            conversation_id: group.conversation_id,
        };
    }
    async joinGroupByInviteCode(userId, inviteCode) {
        const group = await this.groupsRepository.findGroupByInviteCode(inviteCode);
        if (!group || group.deleted_at) {
            throw new common_1.BadRequestException('Invalid invite code');
        }
        const existingMembership = await this.groupsRepository.findMembership(userId, group.id);
        if (!existingMembership) {
            await this.groupsRepository.addMemberToGroup(userId, group.id);
        }
        return {
            id: group.id,
            name: group.name,
            invite_code: group.invite_code,
            conversation_id: group.conversation_id,
        };
    }
    async leaveGroup(userId, groupId) {
        const membership = await this.groupsRepository.findMembership(userId, groupId);
        if (!membership) {
            throw new common_1.NotFoundException('Group membership not found');
        }
        await this.groupsRepository.removeMemberFromGroup(userId, groupId);
        return { success: true };
    }
    async listGroupMembers(requestingUserId, groupId) {
        const membership = await this.groupsRepository.findMembership(requestingUserId, groupId);
        if (!membership) {
            throw new common_1.ForbiddenException('You are not a member of this group');
        }
        const users = await this.groupsRepository.listMembersForGroup(groupId);
        return users.map((user) => ({
            id: user.id,
            username: user.username,
            avatar_url: user.avatar_url,
            is_self: user.id === requestingUserId,
        }));
    }
    async listMyGroups(userId) {
        const groups = await this.groupsRepository.listGroupsForUser(userId);
        return groups.map((group) => ({
            id: group.id,
            name: group.name,
            invite_code: group.invite_code,
            conversation_id: group.conversation_id,
        }));
    }
    async deleteGroup(userId, groupId) {
        const group = await this.groupsRepository.findGroupById(groupId);
        if (!group || group.deleted_at) {
            throw new common_1.NotFoundException('Group not found');
        }
        if (group.created_by !== userId) {
            throw new common_1.ForbiddenException('Only the group creator can delete it');
        }
        await this.groupsRepository.deleteGroupWithChat(groupId);
        return { success: true };
    }
};
exports.GroupsService = GroupsService;
exports.GroupsService = GroupsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [groups_repository_1.GroupsRepository])
], GroupsService);
//# sourceMappingURL=groups.service.js.map