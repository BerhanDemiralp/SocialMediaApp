import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { MatchingEngineService } from './matching-engine.service';

const DEFAULT_CREATION_INITIAL_DELAY_MS = 5_000;
const ONE_DAY_MS = 24 * 60 * 60 * 1000;
const MAX_TIMEOUT_MS = 2_147_483_647;

@Injectable()
export class MatchingEngineCreationSchedulerService
  implements OnModuleInit, OnModuleDestroy
{
  private timer?: NodeJS.Timeout;
  private stopped = false;
  private isRunning = false;

  constructor(private readonly matchingEngineService: MatchingEngineService) {}

  onModuleInit() {
    if (
      process.env.MOMENT_WORKER_DISABLED === '1' ||
      process.env.MOMENT_CREATION_WORKER_DISABLED === '1'
    ) {
      console.log('[matching-creation-worker] disabled');
      return;
    }

    const initialDelayMs = this.getPositiveNumberFromEnv(
      'MOMENT_CREATION_WORKER_INITIAL_DELAY_MS',
      DEFAULT_CREATION_INITIAL_DELAY_MS,
    );

    this.timer = setTimeout(() => {
      void this.scheduleNextRun();
    }, initialDelayMs);
  }

  onModuleDestroy() {
    this.stopped = true;

    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = undefined;
    }
  }

  private async scheduleNextRun() {
    if (this.stopped) {
      return;
    }

    try {
      const settings = await this.matchingEngineService.getRuntimeSettings();

      if (!settings.enabled) {
        console.log('[matching-creation-worker] matching is disabled');
        this.scheduleTimer(ONE_DAY_MS);
        return;
      }

      const now = new Date();
      const window = this.matchingEngineService.getNextScheduleWindow(
        now,
        settings.dailyTimeLocal,
        settings.timezone,
        settings.activeDurationMinutes,
      );

      if (now.getTime() >= window.scheduledAt.getTime()) {
        await this.runCreationOnce();
        this.scheduleTimer(ONE_DAY_MS);
        return;
      }

      const delayMs = window.scheduledAt.getTime() - now.getTime();
      console.log(
        `[matching-creation-worker] next creation run at ${window.scheduledAt.toISOString()}`,
      );
      this.scheduleTimer(delayMs);
    } catch (error) {
      console.error('[matching-creation-worker] scheduling failed', error);
      this.scheduleTimer(ONE_DAY_MS);
    }
  }

  private scheduleTimer(delayMs: number) {
    if (this.stopped) {
      return;
    }

    if (this.timer) {
      clearTimeout(this.timer);
    }

    this.timer = setTimeout(() => {
      void this.handleTimer();
    }, Math.max(1_000, Math.min(delayMs, MAX_TIMEOUT_MS)));
  }

  private async handleTimer() {
    await this.runCreationOnce();

    try {
      const settings = await this.matchingEngineService.getRuntimeSettings();
      const now = new Date();
      const window = this.matchingEngineService.getNextScheduleWindow(
        now,
        settings.dailyTimeLocal,
        settings.timezone,
        settings.activeDurationMinutes,
      );

      if (now.getTime() < window.expiresAt.getTime()) {
        this.scheduleTimer(window.expiresAt.getTime() - now.getTime() + 1_000);
        return;
      }
    } catch (error) {
      console.error('[matching-creation-worker] reschedule failed', error);
    }

    await this.scheduleNextRun();
  }

  private async runCreationOnce() {
    if (this.isRunning) {
      return;
    }

    this.isRunning = true;

    try {
      const result = await this.matchingEngineService.runCreationWork(
        new Date(),
      );
      console.log('[matching-creation-worker] creation result', result);
    } catch (error) {
      console.error('[matching-creation-worker] creation failed', error);
    } finally {
      this.isRunning = false;
    }
  }

  private getPositiveNumberFromEnv(name: string, fallback: number) {
    const value = Number(process.env[name]);
    return Number.isFinite(value) && value > 0 ? value : fallback;
  }
}
