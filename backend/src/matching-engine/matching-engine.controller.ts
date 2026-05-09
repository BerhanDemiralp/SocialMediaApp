import {
  Controller,
  Body,
  ForbiddenException,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { Request as ExpressRequest } from 'express';
import { AuthGuard } from '../auth/guards/auth.guard';
import { ListMomentHistoryQueryDto } from './dto/list-moment-history-query.dto';
import { MatchingEngineService } from './matching-engine.service';

@Controller('matching-engine')
@UseGuards(AuthGuard)
export class MatchingEngineController {
  constructor(private readonly matchingEngineService: MatchingEngineService) {}

  @Get('settings')
  async getSettings() {
    return this.matchingEngineService.getSettings();
  }

  @Patch('settings')
  async updateSettings(
    @Body()
    body: {
      dailyTimeLocal?: string;
      timezone?: string;
      enabled?: boolean;
      reminderAfterMinutes?: number;
      activeDurationMinutes?: number;
    },
  ) {
    return this.matchingEngineService.updateSettings(body);
  }

  @Get('me/current')
  async getCurrentMoments(
    @Request() req: ExpressRequest & { user?: { id: string } },
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    return this.matchingEngineService.getCurrentMomentsForUser(userId);
  }

  @Get('me/history')
  async getMomentHistory(
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Query() query: ListMomentHistoryQueryDto,
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    return this.matchingEngineService.getMomentHistoryForUser(
      userId,
      query.limit,
      query.cursor,
    );
  }

  @Post('run')
  async runDueWork(
    @Body() body?: { dailyTimeLocal?: string },
    @Query('debug') debug?: string,
  ) {
    return this.matchingEngineService.runDueWork(
      new Date(),
      body?.dailyTimeLocal,
      debug === 'true',
    );
  }

  @Post(':matchId/opt-in')
  async optInToGroupMoment(
    @Param('matchId') matchId: string,
    @Request() req: ExpressRequest & { user?: { id: string } },
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    return this.matchingEngineService.optInToGroupMoment(matchId, userId);
  }
}
