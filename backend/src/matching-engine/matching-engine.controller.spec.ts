import { Test, TestingModule } from '@nestjs/testing';
import { MatchingEngineController } from './matching-engine.controller';
import { MatchingEngineService } from './matching-engine.service';
import { AuthGuard } from '../auth/guards/auth.guard';

describe('MatchingEngineController', () => {
  let controller: MatchingEngineController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [MatchingEngineController],
      providers: [
        {
          provide: MatchingEngineService,
          useValue: {
            runDailyMatching: jest.fn(),
            getCurrentMomentForUser: jest.fn(),
            getMatchHistoryForUser: jest.fn(),
            optInToGroupMatch: jest.fn(),
          },
        },
      ],
    })
      .overrideGuard(AuthGuard)
      .useValue({ canActivate: jest.fn().mockResolvedValue(true) })
      .compile();

    controller = module.get<MatchingEngineController>(MatchingEngineController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});

