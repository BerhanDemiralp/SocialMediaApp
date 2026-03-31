import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class GroupsRepository {
  constructor(private prisma: PrismaService) {}

  async createGroupWithOwner(
    ownerId: string,
    name: string,
    inviteCode: string,
  ) {
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
    return this.prisma.group_members.create({
      data: {
        user_id: userId,
        group_id: groupId,
      },
    });
  }

  async removeMemberFromGroup(userId: string, groupId: string) {
    return this.prisma.group_members.delete({
      where: {
        user_id_group_id: {
          user_id: userId,
          group_id: groupId,
        },
      },
    });
  }

  async listGroupsForUser(userId: string) {
    const memberships = await this.prisma.group_members.findMany({
      where: { user_id: userId },
      include: {
        group: true,
      },
    });

    return memberships.map((membership) => membership.group);
  }

  async listMembersForGroup(groupId: string) {
    const memberships = await this.prisma.group_members.findMany({
      where: { group_id: groupId },
      include: {
        user: true,
      },
    });

    return memberships.map((membership) => membership.user);
  }
}
