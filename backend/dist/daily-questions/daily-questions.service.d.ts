import { DailyQuestionsRepository } from './daily-questions.repository';
export declare class DailyQuestionsService {
    private readonly dailyQuestionsRepository;
    constructor(dailyQuestionsRepository: DailyQuestionsRepository);
    createDailyQuestion(questionText: string, questionDate: string): Promise<{
        id: string;
        created_at: Date;
        question_text: string;
        question_date: Date;
    }>;
    listDailyQuestions(page: number, pageSize: number): Promise<{
        id: string;
        created_at: Date;
        question_text: string;
        question_date: Date;
    }[]>;
    getTodayQuestion(now: Date): Promise<{
        id: string;
        created_at: Date;
        question_text: string;
        question_date: Date;
    }>;
    submitAnswerForToday(userId: string, answerText: string): Promise<{
        id: string;
        created_at: Date;
        user_id: string;
        answer_text: string;
        question_id: string;
    }>;
    listMyAnswers(userId: string, page: number, pageSize: number): Promise<{
        id: string;
        answer_text: string;
        created_at: Date;
        question: {
            id: string;
            question_text: string;
            question_date: Date;
        };
    }[]>;
    listFriendsAnswersForToday(requesterId: string, page: number, pageSize: number): Promise<{
        id: string;
        answer_text: string;
        created_at: Date;
        user: {
            id: string;
            username: string;
            avatar_url: string | null;
        };
    }[]>;
}
