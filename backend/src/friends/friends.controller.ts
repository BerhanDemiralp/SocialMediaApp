import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Request,
  UseGuards,
  ForbiddenException,
} from '@nestjs/common';
import { Request as ExpressRequest } from 'express';
import { AuthGuard } from '../auth/guards/auth.guard';
import { FriendsService } from './friends.service';
import { SendFriendRequestDto } from './dto/send-friend-request.dto';

@Controller('friends')
@UseGuards(AuthGuard)
export class FriendsController {
  constructor(private friendsService: FriendsService) {}

  @Post('requests')
  async sendFriendRequest(
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Body() body: SendFriendRequestDto,
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    return this.friendsService.sendFriendRequest(userId, body.targetUserId);
  }

  @Patch('requests/:id/accept')
  async acceptRequest(
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Param('id') id: string,
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    return this.friendsService.acceptRequest(userId, id);
  }

  @Patch('requests/:id/reject')
  async rejectRequest(
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Param('id') id: string,
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    return this.friendsService.rejectRequest(userId, id);
  }

  @Patch('requests/:id/cancel')
  async cancelRequest(
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Param('id') id: string,
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    return this.friendsService.cancelRequest(userId, id);
  }

  @Get()
  async listFriends(
    @Request() req: ExpressRequest & { user?: { id: string } },
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    return this.friendsService.listFriends(userId);
  }

  @Get('requests/incoming')
  async listIncomingRequests(
    @Request() req: ExpressRequest & { user?: { id: string } },
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    return this.friendsService.listIncomingRequests(userId);
  }

  @Get('requests/outgoing')
  async listOutgoingRequests(
    @Request() req: ExpressRequest & { user?: { id: string } },
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    return this.friendsService.listOutgoingRequests(userId);
  }
}

