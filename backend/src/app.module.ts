import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { SupabaseModule } from './supabase/supabase.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { EventsModule } from './events/events.module';
import { FriendsModule } from './friends/friends.module';
import { GroupsModule } from './groups/groups.module';
import { DailyQuestionsModule } from './daily-questions/daily-questions.module';
import { ConversationsModule } from './conversations/conversations.module';
import { MatchingEngineModule } from './matching-engine/matching-engine.module';
import { RequestTimingMiddleware } from './diagnostics/request-timing.middleware';

@Module({
  imports: [
    PrismaModule,
    SupabaseModule,
    AuthModule,
    UsersModule,
    EventsModule,
    FriendsModule,
    GroupsModule,
    DailyQuestionsModule,
    ConversationsModule,
    MatchingEngineModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(RequestTimingMiddleware).forRoutes('*');
  }
}
