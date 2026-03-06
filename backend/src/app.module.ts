import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { SupabaseModule } from './supabase/supabase.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { EventsModule } from './events/events.module';
import { MatchesModule } from './matches/matches.module';
import { FriendsModule } from './friends/friends.module';
import { GroupsModule } from './groups/groups.module';
import { DailyQuestionsModule } from './daily-questions/daily-questions.module';
import { MatchingEngineModule } from './matching-engine/matching-engine.module';

@Module({
  imports: [
    PrismaModule,
    SupabaseModule,
    AuthModule,
    UsersModule,
    EventsModule,
    MatchesModule,
    FriendsModule,
    GroupsModule,
    DailyQuestionsModule,
    MatchingEngineModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
