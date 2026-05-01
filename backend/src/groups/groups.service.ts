import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { GroupsRepository } from './groups.repository';

@Injectable()
export class GroupsService {
  constructor(private groupsRepository: GroupsRepository) {}

  async createGroup(ownerId: string, name: string) {
    const inviteCode = randomUUID();
    const group = await this.groupsRepository.createGroupWithOwner(
      ownerId,
      name,
      inviteCode,
    );

    return {
      id: group.id,
      name: group.name,
      invite_code: group.invite_code,
      conversation_id: group.conversation_id,
    };
  }

  async joinGroupByInviteCode(userId: string, inviteCode: string) {
    const group =
      await this.groupsRepository.findGroupByInviteCode(inviteCode);

    if (!group || group.deleted_at) {
      throw new BadRequestException('Invalid invite code');
    }

    const existingMembership = await this.groupsRepository.findMembership(
      userId,
      group.id,
    );

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

  async leaveGroup(userId: string, groupId: string) {
    const membership = await this.groupsRepository.findMembership(
      userId,
      groupId,
    );

    if (!membership) {
      throw new NotFoundException('Group membership not found');
    }

    await this.groupsRepository.removeMemberFromGroup(userId, groupId);

    return { success: true };
  }

  async listGroupMembers(requestingUserId: string, groupId: string) {
    const membership = await this.groupsRepository.findMembership(
      requestingUserId,
      groupId,
    );

    if (!membership) {
      throw new ForbiddenException('You are not a member of this group');
    }

    const users = await this.groupsRepository.listMembersForGroup(groupId);

    return users.map((user) => ({
      id: user.id,
      username: user.username,
      avatar_url: user.avatar_url,
      is_self: user.id === requestingUserId,
    }));
  }

  async listMyGroups(userId: string) {
    const groups = await this.groupsRepository.listGroupsForUser(userId);

    return groups.map((group) => ({
      id: group.id,
      name: group.name,
      invite_code: group.invite_code,
      conversation_id: group.conversation_id,
    }));
  }

  async deleteGroup(userId: string, groupId: string) {
    const group = await this.groupsRepository.findGroupById(groupId);

    if (!group || group.deleted_at) {
      throw new NotFoundException('Group not found');
    }

    if (group.created_by !== userId) {
      throw new ForbiddenException('Only the group creator can delete it');
    }

    await this.groupsRepository.deleteGroupWithChat(groupId);

    return { success: true };
  }
}
