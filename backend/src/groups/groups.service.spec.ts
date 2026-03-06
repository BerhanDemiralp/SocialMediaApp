import { Test, TestingModule } from '@nestjs/testing';
import { GroupsService } from './groups.service';
import { GroupsRepository } from './groups.repository';
import { BadRequestException, NotFoundException } from '@nestjs/common';

describe('GroupsService', () => {
  let service: GroupsService;
  let repo: {
    createGroupWithOwner: jest.Mock;
    findGroupByInviteCode: jest.Mock;
    findMembership: jest.Mock;
    addMemberToGroup: jest.Mock;
    removeMemberFromGroup: jest.Mock;
    listGroupsForUser: jest.Mock;
  };

  beforeEach(async () => {
    repo = {
      createGroupWithOwner: jest.fn(),
      findGroupByInviteCode: jest.fn(),
      findMembership: jest.fn(),
      addMemberToGroup: jest.fn(),
      removeMemberFromGroup: jest.fn(),
      listGroupsForUser: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GroupsService,
        {
          provide: GroupsRepository,
          useValue: repo,
        },
      ],
    }).compile();

    service = module.get(GroupsService);
  });

  it('creates a group and returns basic info', async () => {
    repo.createGroupWithOwner.mockResolvedValue({
      id: 'group-1',
      name: 'Group',
      invite_code: 'code',
    });

    const result = await service.createGroup('user-1', 'Group');

    expect(repo.createGroupWithOwner).toHaveBeenCalled();
    expect(result).toMatchObject({
      id: 'group-1',
      name: 'Group',
      invite_code: expect.any(String),
    });
  });

  it('joins group with valid invite code', async () => {
    repo.findGroupByInviteCode.mockResolvedValue({
      id: 'group-1',
      name: 'Group',
      invite_code: 'code',
    });
    repo.findMembership.mockResolvedValue(null);

    const result = await service.joinGroupByInviteCode('user-1', 'code');

    expect(repo.addMemberToGroup).toHaveBeenCalledWith('user-1', 'group-1');
    expect(result).toEqual({
      id: 'group-1',
      name: 'Group',
      invite_code: 'code',
    });
  });

  it('throws BadRequest for invalid invite code', async () => {
    repo.findGroupByInviteCode.mockResolvedValue(null);

    await expect(
      service.joinGroupByInviteCode('user-1', 'bad'),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('leaves group when membership exists', async () => {
    repo.findMembership.mockResolvedValue({
      user_id: 'user-1',
      group_id: 'group-1',
    });

    const result = await service.leaveGroup('user-1', 'group-1');

    expect(repo.removeMemberFromGroup).toHaveBeenCalledWith(
      'user-1',
      'group-1',
    );
    expect(result).toEqual({ success: true });
  });

  it('throws NotFound when leaving a group without membership', async () => {
    repo.findMembership.mockResolvedValue(null);

    await expect(
      service.leaveGroup('user-1', 'group-1'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('lists groups for user', async () => {
    repo.listGroupsForUser.mockResolvedValue([
      { id: 'group-1', name: 'Group 1', invite_code: 'code-1' },
    ]);

    const result = await service.listMyGroups('user-1');

    expect(result).toEqual([
      { id: 'group-1', name: 'Group 1', invite_code: 'code-1' },
    ]);
  });
});

