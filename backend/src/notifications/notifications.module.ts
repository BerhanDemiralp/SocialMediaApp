import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';
import { ConversationsModule } from '../conversations/conversations.module';
import { InstallationService } from './installation.service';
import { NotificationsController } from './notifications.controller';
import {
  FirebasePushTransport,
  PushTransport,
} from './firebase-push.transport';
import { NotificationWorker } from './notification-worker';

@Module({
  imports: [AuthModule, PrismaModule, ConversationsModule],
  controllers: [NotificationsController],
  providers: [
    InstallationService,
    { provide: PushTransport, useClass: FirebasePushTransport },
    NotificationWorker,
  ],
})
export class NotificationsModule {}
