import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  Param,
  Post,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { Request as ExpressRequest } from 'express';
import { AuthGuard } from '../auth/guards/auth.guard';
import { MatchingEngineService } from './matching-engine.service';

@Controller('matching-engine')
@UseGuards(AuthGuard)
export class MatchingEngineController {
  constructor(private readonly matchingEngineService: MatchingEngineService) {}

  @Post('run')
  async runMatching(
    @Request() req: ExpressRequest & { user?: { id: string } },
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    const result = await this.matchingEngineService.runDailyMatching(new Date());
    return result;
  }

  @Get('me/current')
  async getCurrentMoment(
    @Request() req: ExpressRequest & { user?: { id: string } },
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    return this.matchingEngineService.getCurrentMomentForUser(
      userId,
      new Date(),
    );
  }

  @Get('me/history')
  async getHistory(
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

    return this.matchingEngineService.getMatchHistoryForUser(
      userId,
      pageNum,
      pageSizeNum,
    );
  }

  @Post(':matchId/opt-in')
  async optInToGroupMatch(
    @Param('matchId') matchId: string,
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Body('optIn') optIn = true,
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    if (!optIn) {
      return { message: 'Opt-out is not supported in this MVP' };
    }

    const result = await this.matchingEngineService.optInToGroupMatch(
      matchId,
      userId,
    );

    if (!result) {
      throw new ForbiddenException('You are not part of this match');
    }

    return { message: 'Opt-in recorded' };
  }
}
