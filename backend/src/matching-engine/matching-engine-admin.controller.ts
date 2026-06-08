import { Body, Controller, Get, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { AuthGuard } from '../auth/guards/auth.guard';
import { RunMatchingEngineDto } from './dto/run-matching-engine.dto';
import { UpdateMatchingSettingsDto } from './dto/update-matching-settings.dto';
import { MatchingEngineService } from './matching-engine.service';

@Controller('admin/matching-engine')
@UseGuards(AuthGuard)
@ApiBearerAuth()
export class MatchingEngineAdminController {
  constructor(private readonly matchingEngineService: MatchingEngineService) {}

  @Get('settings')
  async getSettings() {
    return this.matchingEngineService.getSettings();
  }

  @Patch('settings')
  async updateSettings(@Body() body: UpdateMatchingSettingsDto) {
    return this.matchingEngineService.updateSettings(body);
  }

  @Post('run')
  @ApiQuery({
    name: 'debug',
    required: false,
    type: Boolean,
    description: 'When true, includes candidate and skip debug counters.',
  })
  async runDueWork(
    @Body() body?: RunMatchingEngineDto,
    @Query('debug') debug?: string,
  ) {
    return this.matchingEngineService.runDueWork(
      new Date(),
      body?.dailyTimeLocal,
      debug === 'true',
    );
  }
}
