import { Test, TestingModule } from '@nestjs/testing';
import { MatchingEngineService } from './matching-engine.service';
import { MatchingEngineRepository } from './matching-engine.repository';

describe('MatchingEngineService', () => {
  let service: MatchingEngineService;
  let repo: jest.Mocked<MatchingEngineRepository>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MatchingEngineService,
        {
          provide: MatchingEngineRepository,
          useValue: {
            findUsersWithoutActiveMatch: jest.fn().mockResolvedValue([]),
            findAcceptedFriends: jest.fn().mockResolvedValue([]),
            findGroupMemberCandidates: jest.fn().mockResolvedValue([]),
            existsMatchBetweenUsersOnDay: jest.fn().mockResolvedValue(false),
            createMatch: jest.fn(),
            findMatchesToEvaluate: jest.fn().mockResolvedValue([]),
            getMessagesForMatchInWindow: jest.fn(),
            updateMatchStatus: jest.fn(),
            getCurrentActiveMatchForUser: jest.fn(),
            getHistoricalMatchesForUser: jest.fn(),
            setGroupOptIn: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get(MatchingEngineService);
    repo = module.get(
      MatchingEngineRepository,
    ) as jest.Mocked<MatchingEngineRepository>;
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('runDailyMatching should call findUsersWithoutActiveMatch', async () => {
    const now = new Date();
    await service.runDailyMatching(now);
    expect(repo.findUsersWithoutActiveMatch).toHaveBeenCalled();
  });
});

