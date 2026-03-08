import { Module } from '@nestjs/common';
import { FriendsController } from './friends.controller';
import { FriendsService } from './friends.service';
import { FriendsRepository } from './friends.repository';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';
import { ConversationsModule } from '../conversations/conversations.module';

@Module({
  imports: [PrismaModule, AuthModule, ConversationsModule],
  controllers: [FriendsController],
  providers: [FriendsService, FriendsRepository],
  exports: [FriendsService],
})
export class FriendsModule {}
