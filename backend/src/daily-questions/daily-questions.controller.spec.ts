import { Test, TestingModule } from '@nestjs/testing';
import { DailyQuestionsController } from './daily-questions.controller';
import { DailyQuestionsService } from './daily-questions.service';
import { AuthGuard } from '../auth/guards/auth.guard';

describe('DailyQuestionsController', () => {
  let controller: DailyQuestionsController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [DailyQuestionsController],
      providers: [
        {
          provide: DailyQuestionsService,
          useValue: {
            createDailyQuestion: jest.fn(),
            listDailyQuestions: jest.fn(),
            getTodayQuestion: jest.fn(),
            submitAnswerForToday: jest.fn(),
            listMyAnswers: jest.fn(),
            listFriendsAnswersForToday: jest.fn(),
          },
        },
      ],
    })
      .overrideGuard(AuthGuard)
      .useValue({ canActivate: jest.fn().mockResolvedValue(true) })
      .compile();

    controller = module.get<DailyQuestionsController>(DailyQuestionsController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
