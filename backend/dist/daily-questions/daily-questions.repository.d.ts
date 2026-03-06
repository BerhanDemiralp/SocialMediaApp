import { PrismaService } from '../prisma/prisma.service';
export declare class DailyQuestionsRepository {
    private prisma;
    constructor(prisma: PrismaService);
    createDailyQuestion(questionText: string, questionDate: Date): Promise<{
        id: string;
        created_at: Date;
        question_text: string;
        question_date: Date;
    }>;
    listDailyQuestions(take: number, skip: number): Promise<{
        id: string;
        created_at: Date;
        question_text: string;
        question_date: Date;
    }[]>;
    findQuestionForAppDay(now: Date): Promise<{
        id: string;
        created_at: Date;
        question_text: string;
        question_date: Date;
    } | null>;
    upsertUserAnswer(userId: string, questionId: string, answerText: string): Promise<{
        id: string;
        created_at: Date;
        user_id: string;
        answer_text: string;
        question_id: string;
    }>;
    listUserAnswers(userId: string, take: number, skip: number): Promise<({
        question: {
            id: string;
            created_at: Date;
            question_text: string;
            question_date: Date;
        };
    } & {
        id: string;
        created_at: Date;
        user_id: string;
        answer_text: string;
        question_id: string;
    })[]>;
    listFriendsAnswersForQuestion(requesterId: string, questionId: string, take: number, skip: number): Promise<({
        user: {
            email: string;
            username: string;
            id: string;
            avatar_url: string | null;
            created_at: Date;
            updated_at: Date;
        };
    } & {
        id: string;
        created_at: Date;
        user_id: string;
        answer_text: string;
        question_id: string;
    })[]>;
}
