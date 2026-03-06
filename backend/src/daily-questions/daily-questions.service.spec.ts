import { Test, TestingModule } from '@nestjs/testing';
import { DailyQuestionsService } from './daily-questions.service';
import { DailyQuestionsRepository } from './daily-questions.repository';

describe('DailyQuestionsService', () => {
  let service: DailyQuestionsService;
  let repository: DailyQuestionsRepository;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DailyQuestionsService,
        {
          provide: DailyQuestionsRepository,
          useValue: {
            createDailyQuestion: jest.fn(),
            listDailyQuestions: jest.fn(),
            findQuestionForAppDay: jest.fn(),
            upsertUserAnswer: jest.fn(),
            listUserAnswers: jest.fn(),
            listFriendsAnswersForQuestion: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<DailyQuestionsService>(DailyQuestionsService);
    repository = module.get<DailyQuestionsRepository>(
      DailyQuestionsRepository,
    );
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('submitAnswerForToday should call upsertUserAnswer', async () => {
    const mockQuestion = { id: 'question-id' } as unknown as {
      id: string;
    };

    jest
      .spyOn(repository, 'findQuestionForAppDay')
      .mockResolvedValue(mockQuestion as never);
    const upsertSpy = jest
      .spyOn(repository, 'upsertUserAnswer')
      .mockResolvedValue({} as never);

    await service.submitAnswerForToday('user-id', 'My answer');

    expect(upsertSpy).toHaveBeenCalledWith('user-id', mockQuestion.id, 'My answer');
  });
});

