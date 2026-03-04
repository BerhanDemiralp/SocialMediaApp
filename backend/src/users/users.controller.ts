import {
  Body,
  Controller,
  Get,
  Patch,
  Request,
  UseGuards,
} from '@nestjs/common';
import { Request as ExpressRequest } from 'express';
import { UsersService } from './users.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { AuthGuard } from '../auth/guards/auth.guard';

@Controller('users')
@UseGuards(AuthGuard)
export class UsersController {
  constructor(private usersService: UsersService) {}

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
