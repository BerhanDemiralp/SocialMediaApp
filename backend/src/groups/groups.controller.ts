import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Request,
  UseGuards,
  ForbiddenException,
} from '@nestjs/common';
import { Request as ExpressRequest } from 'express';
import { AuthGuard } from '../auth/guards/auth.guard';
import { GroupsService } from './groups.service';
import { CreateGroupDto } from './dto/create-group.dto';
import { JoinGroupDto } from './dto/join-group.dto';

@Controller('groups')
@UseGuards(AuthGuard)
export class GroupsController {
  constructor(private groupsService: GroupsService) {}

  @Post()
  async createGroup(
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Body() body: CreateGroupDto,
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    return this.groupsService.createGroup(userId, body.name);
  }

  @Post('join')
  async joinGroup(
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Body() body: JoinGroupDto,
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    return this.groupsService.joinGroupByInviteCode(userId, body.inviteCode);
  }

  @Post(':groupId/leave')
  async leaveGroup(
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Param('groupId') groupId: string,
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    return this.groupsService.leaveGroup(userId, groupId);
  }

  @Delete(':groupId')
  async deleteGroup(
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Param('groupId') groupId: string,
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    return this.groupsService.deleteGroup(userId, groupId);
  }

  @Get(':groupId/members')
  async listGroupMembers(
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Param('groupId') groupId: string,
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    return this.groupsService.listGroupMembers(userId, groupId);
  }

  @Get()
  async listMyGroups(
    @Request() req: ExpressRequest & { user?: { id: string } },
  ) {
    const userId = req.user?.id;

    if (!userId) {
      throw new ForbiddenException('Authenticated user context is missing');
    }

    return this.groupsService.listMyGroups(userId);
  }
}
