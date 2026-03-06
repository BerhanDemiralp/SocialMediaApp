import { z } from 'zod';

export const createDailyQuestionSchema = z.object({
  questionText: z.string().min(1),
  questionDate: z.string().min(1),
});

export const submitAnswerSchema = z.object({
  answerText: z.string().min(1),
});

