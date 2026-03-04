import {
  Controller,
  Get,
  Param,
  Query,
  UseGuards,
  Request,
  ForbiddenException,
  ParseIntPipe,
} from '@nestjs/common';
import { Request as ExpressRequest } from 'express';
import { AuthGuard } from '../auth/guards/auth.guard';
import { PrismaService } from '../prisma/prisma.service';

@Controller('matches')
@UseGuards(AuthGuard)
export class MatchesMessagesController {
  constructor(private prisma: PrismaService) {}

  @Get(':matchId/messages')
  async getMatchMessages(
    @Param('matchId') matchId: string,
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Query('limit', new ParseIntPipe({ optional: true })) limit?: number,
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('User context is missing');
    }

    const match = await this.prisma.matches.findUnique({
      where: { id: matchId },
    });

    if (!match || (match.user_a_id !== userId && match.user_b_id !== userId)) {
      throw new ForbiddenException(
        'You are not allowed to view messages for this match',
      );
    }

    const take = limit && limit > 0 ? limit : 50;

    const messages = await this.prisma.messages.findMany({
      where: { match_id: matchId },
      orderBy: { created_at: 'asc' },
      take,
    });

    return messages;
  }
}
