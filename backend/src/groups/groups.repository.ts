import { Injectable } from '@nestjs/common';
import { ConversationType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class GroupsRepository {
  constructor(private prisma: PrismaService) {}

  async createGroupWithOwner(
    ownerId: string,
    name: string,
    inviteCode: string,
  ) {
    return this.prisma.$transaction(async (tx) => {
      const conversation = await tx.conversations.create({
        data: {
          type: ConversationType.group,
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

  async findGroupByInviteCode(inviteCode: string) {
    return this.prisma.groups.findUnique({
      where: { invite_code: inviteCode },
    });
  }

  async findMembership(userId: string, groupId: string) {
    return this.prisma.group_members.findUnique({
      where: {
        user_id_group_id: {
          user_id: userId,
          group_id: groupId,
        },
      },
    });
  }

  async addMemberToGroup(userId: string, groupId: string) {
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

  async removeMemberFromGroup(userId: string, groupId: string) {
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

  async listGroupsForUser(userId: string) {
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

  async listMembersForGroup(groupId: string) {
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

  async findGroupById(groupId: string) {
    return this.prisma.groups.findUnique({
      where: { id: groupId },
    });
  }

  async deleteGroupWithChat(groupId: string) {
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
}
