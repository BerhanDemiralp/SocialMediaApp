import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { MatchingEngineService } from './matching-engine.service';

const DEFAULT_WORKER_INTERVAL_MS = 60_000;
const DEFAULT_ACTIVE_INTERVAL_MS = 30_000;
const DEFAULT_INITIAL_DELAY_MS = 5_000;
const MAX_TIMEOUT_MS = 2_147_483_647;

@Injectable()
export class MatchingEngineSchedulerService
  implements OnModuleInit, OnModuleDestroy
{
  private timer?: NodeJS.Timeout;
  private isRunning = false;
  private stopped = false;
  private lastCreationWindowKey?: string;

  constructor(private readonly matchingEngineService: MatchingEngineService) {}

  onModuleInit() {
    if (process.env.MOMENT_WORKER_DISABLED === '1') {
      console.log('[matching-worker] disabled');
      return;
    }

    const initialDelayMs = this.getPositiveNumberFromEnv(
      'MOMENT_WORKER_INITIAL_DELAY_MS',
      DEFAULT_INITIAL_DELAY_MS,
    );

    console.log('[matching-worker] started as single lifecycle worker');
    this.scheduleNextTick(initialDelayMs);
  }

  onModuleDestroy() {
    this.stopped = true;

    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = undefined;
    }
  }

  private scheduleNextTick(delayMs: number) {
    if (this.stopped) {
      return;
    }

    if (this.timer) {
      clearTimeout(this.timer);
    }

    this.timer = setTimeout(() => {
      void this.tick();
    }, Math.max(1_000, Math.min(delayMs, MAX_TIMEOUT_MS)));
  }

  private async tick() {
    let nextDelayMs = this.getPositiveNumberFromEnv(
      'MOMENT_WORKER_INTERVAL_MS',
      DEFAULT_WORKER_INTERVAL_MS,
    );

    try {
      nextDelayMs = await this.runOnce(nextDelayMs);
    } finally {
      this.scheduleNextTick(nextDelayMs);
    }
  }

  private async runOnce(defaultDelayMs: number) {
    if (this.stopped) {
      return defaultDelayMs;
    }

    if (this.isRunning) {
      return this.getPositiveNumberFromEnv(
        'MOMENT_WORKER_ACTIVE_INTERVAL_MS',
        DEFAULT_ACTIVE_INTERVAL_MS,
      );
    }

    this.isRunning = true;

    try {
      const now = new Date();
      const settings = await this.matchingEngineService.getRuntimeSettings();

      if (!settings.enabled) {
        return defaultDelayMs;
      }

      const creationWindow = this.matchingEngineService.getNextScheduleWindow(
        now,
        settings.dailyTimeLocal,
        settings.timezone,
        settings.activeDurationMinutes,
      );
      const inCreationWindow =
        now.getTime() >= creationWindow.scheduledAt.getTime() &&
        now.getTime() < creationWindow.expiresAt.getTime();
      const creationWindowKey = creationWindow.scheduledAt.toISOString();

      if (
        inCreationWindow &&
        this.lastCreationWindowKey !== creationWindowKey
      ) {
        const creation = await this.matchingEngineService.runCreationWork(now);
        this.lastCreationWindowKey = creationWindowKey;

        if (creation.created.friend > 0 || creation.created.group > 0) {
          console.log('[matching-worker] creation result', creation);
        }
      }

      const hasStatusCandidates =
        await this.matchingEngineService.hasStatusWorkCandidates(now);

      if (hasStatusCandidates) {
        const status = await this.matchingEngineService.runStatusWork(now);

        if (this.shouldLogStatusResult(status)) {
          console.log('[matching-worker] status result', status);
        }
      }

      return this.getNextDelayMs(
        now,
        creationWindow.scheduledAt,
        hasStatusCandidates,
        defaultDelayMs,
      );
    } catch (error) {
      console.error('[matching-worker] run failed', error);
      return defaultDelayMs;
    } finally {
      this.isRunning = false;
    }
  }

  private getNextDelayMs(
    now: Date,
    nextCreationAt: Date,
    hasStatusCandidates: boolean,
    defaultDelayMs: number,
  ) {
    const activeIntervalMs = this.getPositiveNumberFromEnv(
      'MOMENT_WORKER_ACTIVE_INTERVAL_MS',
      DEFAULT_ACTIVE_INTERVAL_MS,
    );
    const baseDelayMs = hasStatusCandidates ? activeIntervalMs : defaultDelayMs;
    const msUntilCreation = nextCreationAt.getTime() - now.getTime();

    if (msUntilCreation > 0) {
      return Math.min(baseDelayMs, msUntilCreation);
    }

    return baseDelayMs;
  }

  private getPositiveNumberFromEnv(name: string, fallback: number) {
    const value = Number(process.env[name]);
    return Number.isFinite(value) && value > 0 ? value : fallback;
  }

  private shouldLogStatusResult(result: {
    activated: number;
    remindersSent: number;
    expired: number;
    successful: number;
  }) {
    return (
      result.activated > 0 ||
      result.remindersSent > 0 ||
      result.expired > 0 ||
      result.successful > 0
    );
  }
}
