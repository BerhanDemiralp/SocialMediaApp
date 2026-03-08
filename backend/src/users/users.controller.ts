import {
  Body,
  Controller,
  Get,
  Patch,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { Request as ExpressRequest } from 'express';
import { UsersService } from './users.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { AuthGuard } from '../auth/guards/auth.guard';
import { SearchUsersQueryDto } from './dto/search-users-query.dto';

@Controller('users')
@UseGuards(AuthGuard)
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Get('search')
  async searchUsers(
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Query() query: SearchUsersQueryDto,
  ) {
    if (!req.user?.id) {
      throw new Error('Authenticated user context is missing');
    }

    return this.usersService.searchUsers(
      query.query,
      query.limit ?? 20,
      req.user.id,
    );
  }

  @Get('me')
  async getMyProfile(
    @Request() req: ExpressRequest & { user?: { id: string } },
  ) {
    if (!req.user?.id) {
      throw new Error('Authenticated user context is missing');
    }
    return this.usersService.getProfile(req.user.id);
  }

  @Patch('me')
  async updateMyProfile(
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Body() updateProfileDto: UpdateProfileDto,
  ) {
    if (!req.user?.id) {
      throw new Error('Authenticated user context is missing');
    }
    return this.usersService.updateProfile(req.user.id, updateProfileDto);
  }
}
