import { Test, TestingModule } from '@nestjs/testing';
import { FriendsService } from './friends.service';
import { FriendsRepository } from './friends.repository';
import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';

describe('FriendsService', () => {
  let service: FriendsService;
  let repo: {
    findFriendshipBetweenUsers: jest.Mock;
    createFriendRequest: jest.Mock;
    findFriendshipById: jest.Mock;
    updateFriendshipStatus: jest.Mock;
    listAcceptedFriendshipsForUser: jest.Mock;
    listIncomingRequests: jest.Mock;
    listOutgoingRequests: jest.Mock;
  };

  beforeEach(async () => {
    repo = {
      findFriendshipBetweenUsers: jest.fn(),
      createFriendRequest: jest.fn(),
      findFriendshipById: jest.fn(),
      updateFriendshipStatus: jest.fn(),
      listAcceptedFriendshipsForUser: jest.fn(),
      listIncomingRequests: jest.fn(),
      listOutgoingRequests: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FriendsService,
        {
          provide: FriendsRepository,
          useValue: repo,
        },
      ],
    }).compile();

    service = module.get(FriendsService);
  });

  it('prevents sending friend request to self', async () => {
    await expect(
      service.sendFriendRequest('user-1', 'user-1'),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('creates a new friend request when none exists', async () => {
    repo.findFriendshipBetweenUsers.mockResolvedValue(null);
    repo.createFriendRequest.mockResolvedValue({ id: 'req-1' });

    const result = await service.sendFriendRequest('user-1', 'user-2');

    expect(repo.createFriendRequest).toHaveBeenCalledWith('user-1', 'user-2');
    expect(result).toEqual({ id: 'req-1' });
  });

  it('rejects when a pending friendship already exists', async () => {
    repo.findFriendshipBetweenUsers.mockResolvedValue({
      id: 'req-1',
      status: 'pending',
    });

    await expect(
      service.sendFriendRequest('user-1', 'user-2'),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('accepts a pending request for the addressee', async () => {
    repo.findFriendshipById.mockResolvedValue({
      id: 'req-1',
      requester_id: 'user-1',
      addressee_id: 'user-2',
      status: 'pending',
    });
    repo.updateFriendshipStatus.mockResolvedValue({ id: 'req-1' });

    const result = await service.acceptRequest('user-2', 'req-1');

    expect(repo.updateFriendshipStatus).toHaveBeenCalledWith(
      'req-1',
      'accepted',
    );
    expect(result).toEqual({ id: 'req-1' });
  });

  it('throws NotFound when accepting unknown request', async () => {
    repo.findFriendshipById.mockResolvedValue(null);

    await expect(
      service.acceptRequest('user-2', 'missing'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('throws Forbidden when non-addressee tries to accept', async () => {
    repo.findFriendshipById.mockResolvedValue({
      id: 'req-1',
      requester_id: 'user-1',
      addressee_id: 'user-2',
      status: 'pending',
    });

    await expect(
      service.acceptRequest('user-3', 'req-1'),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('lists friends mapped to other user profile', async () => {
    repo.listAcceptedFriendshipsForUser.mockResolvedValue([
      {
        requester_id: 'user-1',
        addressee_id: 'user-2',
        requester: { id: 'user-1', username: 'u1', avatar_url: null },
        addressee: { id: 'user-2', username: 'u2', avatar_url: 'a2' },
      },
    ]);

    const result = await service.listFriends('user-1');

    expect(result).toEqual([
      { id: 'user-2', username: 'u2', avatar_url: 'a2' },
    ]);
  });
});

