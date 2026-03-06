import { Request as ExpressRequest } from 'express';
import { DailyQuestionsService } from './daily-questions.service';
import { CreateDailyQuestionDto } from './dto/create-daily-question.dto';
import { SubmitAnswerDto } from './dto/submit-answer.dto';
export declare class DailyQuestionsController {
    private readonly dailyQuestionsService;
    constructor(dailyQuestionsService: DailyQuestionsService);
    createDailyQuestion(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, body: CreateDailyQuestionDto): Promise<{
        id: string;
        created_at: Date;
        question_text: string;
        question_date: Date;
    }>;
    listDailyQuestions(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, page?: string, pageSize?: string): Promise<{
        id: string;
        created_at: Date;
        question_text: string;
        question_date: Date;
    }[]>;
    getTodayQuestion(): Promise<{
        id: string;
        created_at: Date;
        question_text: string;
        question_date: Date;
    }>;
    submitAnswerForToday(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, body: SubmitAnswerDto): Promise<{
        id: string;
        created_at: Date;
        user_id: string;
        answer_text: string;
        question_id: string;
    }>;
    listMyAnswers(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, page?: string, pageSize?: string): Promise<{
        id: string;
        answer_text: string;
        created_at: Date;
        question: {
            id: string;
            question_text: string;
            question_date: Date;
        };
    }[]>;
    listFriendsAnswers(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, page?: string, pageSize?: string): Promise<{
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
