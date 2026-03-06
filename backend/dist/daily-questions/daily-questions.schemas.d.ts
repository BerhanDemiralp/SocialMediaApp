import { z } from 'zod';
export declare const createDailyQuestionSchema: z.ZodObject<{
    questionText: z.ZodString;
    questionDate: z.ZodString;
}, "strip", z.ZodTypeAny, {
    questionText: string;
    questionDate: string;
}, {
    questionText: string;
    questionDate: string;
}>;
export declare const submitAnswerSchema: z.ZodObject<{
    answerText: z.ZodString;
}, "strip", z.ZodTypeAny, {
    answerText: string;
}, {
    answerText: string;
}>;
