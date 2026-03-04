import { Module } from '@nestjs/common';
import { MatchesMessagesController } from './matches-messages.controller';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [AuthModule, PrismaModule],
  controllers: [MatchesMessagesController],
})
export class MatchesModule {}

