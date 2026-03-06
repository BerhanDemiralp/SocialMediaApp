import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';
import { MatchingEngineController } from './matching-engine.controller';
import { MatchingEngineService } from './matching-engine.service';
import { MatchingEngineRepository } from './matching-engine.repository';

@Module({
  imports: [AuthModule, PrismaModule],
  controllers: [MatchingEngineController],
  providers: [MatchingEngineService, MatchingEngineRepository],
})
export class MatchingEngineModule {}

