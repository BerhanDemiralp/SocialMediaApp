import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Request,
  UseGuards,
  ParseUUIDPipe,
  Query,
} from '@nestjs/common';
import { IsIn, IsInt, IsString, IsUUID, Length, Min } from 'class-validator';
import { AuthGuard } from '../auth/guards/auth.guard';
import { InstallationService } from './installation.service';
import { ConversationsService } from '../conversations/conversations.service';

class InstallationDto {
  @IsUUID() id!: string;
  @IsString() @Length(64, 64) secret!: string;
  @IsString() @Length(16, 4096) token!: string;
  @IsIn(['android', 'ios']) platform!: 'android' | 'ios';
  @IsInt() @Min(0) version!: number;
}
class RemoveInstallationDto {
  @IsInt() @Min(1) version!: number;
}

@Controller('notifications')
@UseGuards(AuthGuard)
export class NotificationsController {
  constructor(
    private readonly installations: InstallationService,
    private readonly conversations: ConversationsService,
  ) {}

  @Post('installations')
  register(
    @Request() req: { user: { id: string } },
    @Body() body: InstallationDto,
  ) {
    return this.installations.register(req.user.id, body);
  }

  @Delete('installations/:id')
  remove(
    @Request() req: { user: { id: string } },
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: RemoveInstallationDto,
  ) {
    return this.installations.remove(req.user.id, id, body.version);
  }

  @Get('conversations/:id')
  destination(
    @Request() req: { user: { id: string } },
    @Param('id', ParseUUIDPipe) id: string,
    @Query('momentId', new ParseUUIDPipe({ optional: true })) momentId?: string,
  ) {
    return this.conversations.notificationDestination(id, req.user.id, momentId);
  }
}
