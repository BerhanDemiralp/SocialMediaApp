import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
  Request,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { Request as ExpressRequest } from 'express';
import { ConversationType } from '@prisma/client';
import { AuthGuard } from '../auth/guards/auth.guard';
import { ConversationsService } from './conversations.service';
import { ListConversationsQueryDto } from './dto/list-conversations-query.dto';
import { GetConversationMessagesQueryDto } from './dto/get-conversation-messages-query.dto';
import { CreateFriendConversationDto } from './dto/create-friend-conversation.dto';

@Controller('conversations')
@UseGuards(AuthGuard)
export class ConversationsController {
  constructor(private readonly conversationsService: ConversationsService) {}

  @Get()
  async listConversations(
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Query() query: ListConversationsQueryDto,
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    const { limit, cursor, type } = query;

    const conversationType =
      type && Object.values(ConversationType).includes(type as ConversationType)
        ? (type as ConversationType)
        : undefined;

    return this.conversationsService.listConversationsForUser(
      userId,
      limit,
      cursor,
      conversationType,
    );
  }

  @Get(':id/messages')
  async getConversationMessages(
    @Param('id') conversationId: string,
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Query() query: GetConversationMessagesQueryDto,
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    const { limit, cursor } = query;

    return this.conversationsService.getConversationMessages(conversationId, userId, limit, cursor);
  }

  @Post('friends')
  async createOrReuseFriendConversation(
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Body() body: CreateFriendConversationDto,
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    if (!body.friendId) {
      throw new BadRequestException('friendId is required');
    }

    return this.conversationsService.ensureFriendConversationBetweenUsers(
      userId,
      body.friendId,
    );
  }
}
