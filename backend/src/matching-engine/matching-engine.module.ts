import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { ConversationsModule } from '../conversations/conversations.module';
import { PrismaModule } from '../prisma/prisma.module';
import { MatchingEngineRepository } from './matching-engine.repository';
import { MatchingEngineService } from './matching-engine.service';
import { MatchingEngineController } from './matching-engine.controller';
import {
  MomentNotificationService,
  NoopMomentNotificationService,
} from './moment-notification.service';

@Module({
  imports: [PrismaModule, AuthModule, ConversationsModule],
  providers: [
    MatchingEngineRepository,
    MatchingEngineService,
    {
      provide: MomentNotificationService,
      useClass: NoopMomentNotificationService,
    },
  ],
  controllers: [MatchingEngineController],
  exports: [MatchingEngineService, MatchingEngineRepository],
})
export class MatchingEngineModule {}
