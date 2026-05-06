import {
  Controller,
  Body,
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
import { ListMomentHistoryQueryDto } from './dto/list-moment-history-query.dto';
import { MatchingEngineService } from './matching-engine.service';

@Controller('matching-engine')
@UseGuards(AuthGuard)
export class MatchingEngineController {
  constructor(private readonly matchingEngineService: MatchingEngineService) {}

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
    @Body() body?: { dailyTimeUtc?: string },
    @Query('debug') debug?: string,
  ) {
    return this.matchingEngineService.runDueWork(
      new Date(),
      body?.dailyTimeUtc,
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
