import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { DailyQuestionsRepository } from './daily-questions.repository';

@Injectable()
export class DailyQuestionsService {
  constructor(
    private readonly dailyQuestionsRepository: DailyQuestionsRepository,
  ) {}

  async createDailyQuestion(questionText: string, questionDate: string) {
    const date = new Date(questionDate);

    if (Number.isNaN(date.getTime())) {
      throw new BadRequestException('Invalid questionDate');
    }

    try {
      return await this.dailyQuestionsRepository.createDailyQuestion(
        questionText,
        date,
      );
    } catch (error) {
      throw new BadRequestException('Could not create daily question');
    }
  }

  async listDailyQuestions(page: number, pageSize: number) {
    const take = pageSize;
    const skip = (page - 1) * pageSize;

    return this.dailyQuestionsRepository.listDailyQuestions(take, skip);
  }

  async getTodayQuestion(now: Date) {
    const question = await this.dailyQuestionsRepository.findQuestionForAppDay(
      now,
    );

    if (!question) {
      throw new NotFoundException('No daily question for today');
    }

    return question;
  }

  async submitAnswerForToday(userId: string, answerText: string) {
    const todayQuestion = await this.getTodayQuestion(new Date());

    return this.dailyQuestionsRepository.upsertUserAnswer(
      userId,
      todayQuestion.id,
      answerText,
    );
  }

  async listMyAnswers(userId: string, page: number, pageSize: number) {
    const take = pageSize;
    const skip = (page - 1) * pageSize;

    const answers = await this.dailyQuestionsRepository.listUserAnswers(
      userId,
      take,
      skip,
    );

    return answers.map((answer) => ({
      id: answer.id,
      answer_text: answer.answer_text,
      created_at: answer.created_at,
      question: {
        id: answer.question.id,
        question_text: answer.question.question_text,
        question_date: answer.question.question_date,
      },
    }));
  }

  async listFriendsAnswersForToday(
    requesterId: string,
    page: number,
    pageSize: number,
  ) {
    const todayQuestion = await this.getTodayQuestion(new Date());
    const take = pageSize;
    const skip = (page - 1) * pageSize;

    const answers =
      await this.dailyQuestionsRepository.listFriendsAnswersForQuestion(
        requesterId,
        todayQuestion.id,
        take,
        skip,
      );

    return answers.map((answer) => ({
      id: answer.id,
      answer_text: answer.answer_text,
      created_at: answer.created_at,
      user: {
        id: answer.user.id,
        username: answer.user.username,
        avatar_url: answer.user.avatar_url,
      },
    }));
  }
}

