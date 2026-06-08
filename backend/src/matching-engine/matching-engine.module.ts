import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { ConversationsModule } from '../conversations/conversations.module';
import { FriendsModule } from '../friends/friends.module';
import { PrismaModule } from '../prisma/prisma.module';
import { MatchingEngineRepository } from './matching-engine.repository';
import { MatchingEngineSchedulerService } from './matching-engine-scheduler.service';
import { MatchingEngineService } from './matching-engine.service';
import { MatchingEngineAdminController } from './matching-engine-admin.controller';
import { MatchingEngineController } from './matching-engine.controller';
import {
  MomentNotificationService,
  NoopMomentNotificationService,
} from './moment-notification.service';

@Module({
  imports: [PrismaModule, AuthModule, ConversationsModule, FriendsModule],
  providers: [
    MatchingEngineRepository,
    MatchingEngineService,
    MatchingEngineSchedulerService,
    {
      provide: MomentNotificationService,
      useClass: NoopMomentNotificationService,
    },
  ],
  controllers: [MatchingEngineController, MatchingEngineAdminController],
  exports: [MatchingEngineService, MatchingEngineRepository],
})
export class MatchingEngineModule {}
