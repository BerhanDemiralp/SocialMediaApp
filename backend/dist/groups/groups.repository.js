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
exports.GroupsRepository = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let GroupsRepository = class GroupsRepository {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async createGroupWithOwner(ownerId, name, inviteCode) {
        const [group] = await this.prisma.$transaction([
            this.prisma.groups.create({
                data: {
                    name,
                    invite_code: inviteCode,
                    created_by: ownerId,
                },
            }),
        ]);
        await this.prisma.group_members.create({
            data: {
                user_id: ownerId,
                group_id: group.id,
            },
        });
        return group;
    }
    async findGroupByInviteCode(inviteCode) {
        return this.prisma.groups.findUnique({
            where: { invite_code: inviteCode },
        });
    }
    async findMembership(userId, groupId) {
        return this.prisma.group_members.findUnique({
            where: {
                user_id_group_id: {
                    user_id: userId,
                    group_id: groupId,
                },
            },
        });
    }
    async addMemberToGroup(userId, groupId) {
        return this.prisma.group_members.create({
            data: {
                user_id: userId,
                group_id: groupId,
            },
        });
    }
    async removeMemberFromGroup(userId, groupId) {
        return this.prisma.group_members.delete({
            where: {
                user_id_group_id: {
                    user_id: userId,
                    group_id: groupId,
                },
            },
        });
    }
    async listGroupsForUser(userId) {
        const memberships = await this.prisma.group_members.findMany({
            where: { user_id: userId },
            include: {
                group: true,
            },
        });
        return memberships.map((membership) => membership.group);
    }
    async listMembersForGroup(groupId) {
        const memberships = await this.prisma.group_members.findMany({
            where: { group_id: groupId },
            include: {
                user: true,
            },
        });
        return memberships.map((membership) => membership.user);
    }
};
exports.GroupsRepository = GroupsRepository;
exports.GroupsRepository = GroupsRepository = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], GroupsRepository);
//# sourceMappingURL=groups.repository.js.map