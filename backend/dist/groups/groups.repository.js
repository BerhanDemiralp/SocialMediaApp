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
const client_1 = require("@prisma/client");
const prisma_service_1 = require("../prisma/prisma.service");
let GroupsRepository = class GroupsRepository {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async createGroupWithOwner(ownerId, name, inviteCode) {
        return this.prisma.$transaction(async (tx) => {
            const conversation = await tx.conversations.create({
                data: {
                    type: client_1.ConversationType.group,
                    title: name,
                },
            });
            const group = await tx.groups.create({
                data: {
                    name,
                    invite_code: inviteCode,
                    created_by: ownerId,
                    conversation_id: conversation.id,
                },
            });
            await tx.group_members.create({
                data: {
                    user_id: ownerId,
                    group_id: group.id,
                },
            });
            await tx.conversation_participants.create({
                data: {
                    conversation_id: conversation.id,
                    user_id: ownerId,
                },
            });
            return group;
        });
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
        return this.prisma.$transaction(async (tx) => {
            const membership = await tx.group_members.create({
                data: {
                    user_id: userId,
                    group_id: groupId,
                },
                include: {
                    group: true,
                },
            });
            if (membership.group.conversation_id) {
                await tx.conversation_participants.upsert({
                    where: {
                        conversation_id_user_id: {
                            conversation_id: membership.group.conversation_id,
                            user_id: userId,
                        },
                    },
                    create: {
                        conversation_id: membership.group.conversation_id,
                        user_id: userId,
                    },
                    update: {},
                });
            }
            return membership;
        });
    }
    async removeMemberFromGroup(userId, groupId) {
        return this.prisma.$transaction(async (tx) => {
            const group = await tx.groups.findUnique({
                where: { id: groupId },
            });
            const membership = await tx.group_members.delete({
                where: {
                    user_id_group_id: {
                        user_id: userId,
                        group_id: groupId,
                    },
                },
            });
            if (group?.conversation_id) {
                await tx.conversation_participants.deleteMany({
                    where: {
                        conversation_id: group.conversation_id,
                        user_id: userId,
                    },
                });
            }
            return membership;
        });
    }
    async listGroupsForUser(userId) {
        const memberships = await this.prisma.group_members.findMany({
            where: {
                user_id: userId,
                group: {
                    deleted_at: null,
                },
            },
            include: {
                group: true,
            },
        });
        return memberships.map((membership) => membership.group);
    }
    async listMembersForGroup(groupId) {
        const memberships = await this.prisma.group_members.findMany({
            where: {
                group_id: groupId,
                group: {
                    deleted_at: null,
                },
            },
            include: {
                user: true,
            },
        });
        return memberships.map((membership) => membership.user);
    }
    async findGroupById(groupId) {
        return this.prisma.groups.findUnique({
            where: { id: groupId },
        });
    }
    async deleteGroupWithChat(groupId) {
        return this.prisma.$transaction(async (tx) => {
            const group = await tx.groups.findUnique({
                where: { id: groupId },
            });
            if (!group) {
                return null;
            }
            const now = new Date();
            await tx.groups.update({
                where: { id: groupId },
                data: { deleted_at: now },
            });
            await tx.group_members.deleteMany({
                where: { group_id: groupId },
            });
            if (group.conversation_id) {
                await tx.messages.updateMany({
                    where: {
                        conversation_id: group.conversation_id,
                        deleted_at: null,
                    },
                    data: { deleted_at: now },
                });
                await tx.conversation_participants.deleteMany({
                    where: { conversation_id: group.conversation_id },
                });
                await tx.conversations.update({
                    where: { id: group.conversation_id },
                    data: { deleted_at: now },
                });
            }
            return group;
        });
    }
};
exports.GroupsRepository = GroupsRepository;
exports.GroupsRepository = GroupsRepository = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], GroupsRepository);
//# sourceMappingURL=groups.repository.js.map