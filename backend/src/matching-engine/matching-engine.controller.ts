import {
  Controller,
  Body,
  ForbiddenException,
  Param,
  Post,
  Get,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth } from '@nestjs/swagger';
import { Request as ExpressRequest } from 'express';
import { AuthGuard } from '../auth/guards/auth.guard';
import { ListMomentHistoryQueryDto } from './dto/list-moment-history-query.dto';
import { RespondGroupMomentFriendshipDto } from './dto/respond-group-moment-friendship.dto';
import { MatchingEngineService } from './matching-engine.service';

@Controller('matching-engine')
@UseGuards(AuthGuard)
@ApiBearerAuth()
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
