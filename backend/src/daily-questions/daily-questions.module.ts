import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';
import { DailyQuestionsController } from './daily-questions.controller';
import { DailyQuestionsService } from './daily-questions.service';
import { DailyQuestionsRepository } from './daily-questions.repository';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [DailyQuestionsController],
  providers: [DailyQuestionsService, DailyQuestionsRepository],
})
export class DailyQuestionsModule {}

