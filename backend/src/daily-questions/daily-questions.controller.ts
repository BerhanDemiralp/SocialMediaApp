import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Post,
  Query,
  Request,
  UseGuards,
  ForbiddenException,
} from '@nestjs/common';
import { Request as ExpressRequest } from 'express';
import { AuthGuard } from '../auth/guards/auth.guard';
import { DailyQuestionsService } from './daily-questions.service';
import { CreateDailyQuestionDto } from './dto/create-daily-question.dto';
import { SubmitAnswerDto } from './dto/submit-answer.dto';
import {
  createDailyQuestionSchema,
  submitAnswerSchema,
} from './daily-questions.schemas';

@Controller('daily-questions')
@UseGuards(AuthGuard)
export class DailyQuestionsController {
  constructor(private readonly dailyQuestionsService: DailyQuestionsService) {}

  @Post()
  async createDailyQuestion(
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Body() body: CreateDailyQuestionDto,
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    try {
      createDailyQuestionSchema.parse(body);
    } catch {
      throw new BadRequestException('Invalid daily question payload');
    }

    return this.dailyQuestionsService.createDailyQuestion(
      body.questionText,
      body.questionDate,
    );
  }

  @Get()
  async listDailyQuestions(
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Query('page') page = '1',
    @Query('pageSize') pageSize = '20',
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    const pageNum = Number(page) || 1;
    const pageSizeNum = Number(pageSize) || 20;

    return this.dailyQuestionsService.listDailyQuestions(
      pageNum,
      pageSizeNum,
    );
  }

  @Get('today')
  async getTodayQuestion() {
    return this.dailyQuestionsService.getTodayQuestion(new Date());
  }

  @Post('today/answer')
  async submitAnswerForToday(
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Body() body: SubmitAnswerDto,
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    try {
      submitAnswerSchema.parse(body);
    } catch {
      throw new BadRequestException('Invalid answer payload');
    }

    return this.dailyQuestionsService.submitAnswerForToday(
      userId,
      body.answerText,
    );
  }

  @Get('answers/me')
  async listMyAnswers(
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Query('page') page = '1',
    @Query('pageSize') pageSize = '20',
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    const pageNum = Number(page) || 1;
    const pageSizeNum = Number(pageSize) || 20;

    return this.dailyQuestionsService.listMyAnswers(
      userId,
      pageNum,
      pageSizeNum,
    );
  }

  @Get('answers/friends')
  async listFriendsAnswers(
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Query('page') page = '1',
    @Query('pageSize') pageSize = '20',
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    const pageNum = Number(page) || 1;
    const pageSizeNum = Number(pageSize) || 20;

    return this.dailyQuestionsService.listFriendsAnswersForToday(
      userId,
      pageNum,
      pageSizeNum,
    );
  }
}
