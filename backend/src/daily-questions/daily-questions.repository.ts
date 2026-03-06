import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class DailyQuestionsRepository {
  constructor(private prisma: PrismaService) {}

  async createDailyQuestion(questionText: string, questionDate: Date) {
    return this.prisma.daily_questions.create({
      data: {
        question_text: questionText,
        question_date: questionDate,
      },
    });
  }

  async listDailyQuestions(take: number, skip: number) {
    return this.prisma.daily_questions.findMany({
      orderBy: { question_date: 'desc' },
      take,
      skip,
    });
  }

  async findQuestionForAppDay(now: Date) {
    const startOfDay = new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
    );
    const endOfDay = new Date(startOfDay);
    endOfDay.setUTCDate(endOfDay.getUTCDate() + 1);

    return this.prisma.daily_questions.findFirst({
      where: {
        question_date: {
          gte: startOfDay,
          lt: endOfDay,
        },
      },
      orderBy: { question_date: 'asc' },
    });
  }

  async upsertUserAnswer(
    userId: string,
    questionId: string,
    answerText: string,
  ) {
    return this.prisma.user_answers.upsert({
      where: {
        question_id_user_id: {
          question_id: questionId,
          user_id: userId,
        },
      },
      create: {
        user_id: userId,
        question_id: questionId,
        answer_text: answerText,
      },
      update: {
        answer_text: answerText,
      },
    });
  }

  async listUserAnswers(userId: string, take: number, skip: number) {
    return this.prisma.user_answers.findMany({
      where: { user_id: userId },
      orderBy: { created_at: 'desc' },
      take,
      skip,
      include: {
        question: true,
      },
    });
  }

  async listFriendsAnswersForQuestion(
    requesterId: string,
    questionId: string,
    take: number,
    skip: number,
  ) {
    const friendships = await this.prisma.friendships.findMany({
      where: {
        status: 'accepted',
        OR: [{ requester_id: requesterId }, { addressee_id: requesterId }],
      },
    });

    const friendIds = friendships.map((f) =>
      f.requester_id === requesterId ? f.addressee_id : f.requester_id,
    );

    if (!friendIds.length) {
      return [];
    }

    return this.prisma.user_answers.findMany({
      where: {
        question_id: questionId,
        user_id: {
          in: friendIds,
        },
      },
      orderBy: { created_at: 'desc' },
      take,
      skip,
      include: {
        user: true,
      },
    });
  }
}

