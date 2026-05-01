import { Module } from '@nestjs/common';
import { EventsGateway } from './events.gateway';
import { AuthModule } from '../auth/auth.module';
import { ConversationsModule } from '../conversations/conversations.module';

@Module({
  imports: [AuthModule, ConversationsModule],
  providers: [EventsGateway],
  exports: [EventsGateway],
})
export class EventsModule {}
