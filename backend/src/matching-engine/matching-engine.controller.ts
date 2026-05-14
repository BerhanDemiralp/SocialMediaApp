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
import { ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { Request as ExpressRequest } from 'express';
import { AuthGuard } from '../auth/guards/auth.guard';
import { ListMomentHistoryQueryDto } from './dto/list-moment-history-query.dto';
import { RespondGroupMomentFriendshipDto } from './dto/respond-group-moment-friendship.dto';
import { RunMatchingEngineDto } from './dto/run-matching-engine.dto';
import { UpdateMatchingSettingsDto } from './dto/update-matching-settings.dto';
import { MatchingEngineService } from './matching-engine.service';

@Controller('matching-engine')
@UseGuards(AuthGuard)
@ApiBearerAuth()
export class MatchingEngineController {
  constructor(private readonly matchingEngineService: MatchingEngineService) {}

  @Get('settings')
  async getSettings() {
    return this.matchingEngineService.getSettings();
  }

  @Patch('settings')
  async updateSettings(@Body() body: UpdateMatchingSettingsDto) {
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
  @ApiQuery({
    name: 'debug',
    required: false,
    type: Boolean,
    description: 'When true, includes candidate and skip debug counters.',
  })
  async runDueWork(
    @Body() body?: RunMatchingEngineDto,
    @Query('debug') debug?: string,
  ) {
    return this.matchingEngineService.runDueWork(
      new Date(),
      body?.dailyTimeLocal,
      debug === 'true',
    );
  }

  @Post('run-creation')
  @ApiQuery({
    name: 'debug',
    required: false,
    type: Boolean,
    description: 'When true, includes candidate and skip debug counters.',
  })
  async runCreationWork(
    @Body() body?: RunMatchingEngineDto,
    @Query('debug') debug?: string,
  ) {
    return this.matchingEngineService.runCreationWork(
      new Date(),
      body?.dailyTimeLocal,
      debug === 'true',
    );
  }

  @Post('run-status')
  async runStatusWork() {
    return this.matchingEngineService.runStatusWork(new Date());
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

  @Post(':matchId/friendship-response')
  async respondToGroupMomentFriendship(
    @Param('matchId') matchId: string,
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Body() body: RespondGroupMomentFriendshipDto,
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    return this.matchingEngineService.respondToGroupMomentFriendship(
      matchId,
      userId,
      body.wantsFriend,
    );
  }
}
