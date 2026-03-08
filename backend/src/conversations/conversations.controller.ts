import {
  Controller,
  Get,
  Param,
  Query,
  UseGuards,
  Request,
  ForbiddenException,
} from '@nestjs/common';
import { Request as ExpressRequest } from 'express';
import { AuthGuard } from '../auth/guards/auth.guard';
import { ConversationsService } from './conversations.service';
import { ListConversationsQueryDto } from './dto/list-conversations-query.dto';
import { GetConversationMessagesQueryDto } from './dto/get-conversation-messages-query.dto';

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

    const { limit, cursor } = query;

    return this.conversationsService.listConversationsForUser(userId, limit, cursor);
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
}
