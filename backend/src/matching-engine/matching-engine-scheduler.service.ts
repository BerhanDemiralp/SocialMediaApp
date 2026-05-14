import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { MatchingEngineService } from './matching-engine.service';

const DEFAULT_IDLE_INTERVAL_MS = 5 * 60_000;
const DEFAULT_ACTIVE_INTERVAL_MS = 30_000;
const DEFAULT_WORKER_INITIAL_DELAY_MS = 5_000;

@Injectable()
export class MatchingEngineSchedulerService
  implements OnModuleInit, OnModuleDestroy
{
  private timer?: NodeJS.Timeout;
  private isRunning = false;
  private stopped = false;
  private currentMode: 'idle' | 'active' = 'idle';

  constructor(private readonly matchingEngineService: MatchingEngineService) {}

  async onModuleInit() {
    if (process.env.MOMENT_WORKER_DISABLED === '1') {
      console.log('[matching-worker] disabled');
      return;
    }

    const idleIntervalMs = this.getPositiveNumberFromEnv(
      'MOMENT_WORKER_IDLE_INTERVAL_MS',
      DEFAULT_IDLE_INTERVAL_MS,
    );
    const activeIntervalMs = this.getPositiveNumberFromEnv(
      'MOMENT_WORKER_ACTIVE_INTERVAL_MS',
      DEFAULT_ACTIVE_INTERVAL_MS,
    );
    const initialDelayMs = this.getPositiveNumberFromEnv(
      'MOMENT_WORKER_INITIAL_DELAY_MS',
      DEFAULT_WORKER_INITIAL_DELAY_MS,
    );

    console.log(
      `[matching-worker] status-only idle=${idleIntervalMs}ms active=${activeIntervalMs}ms`,
    );

    this.scheduleNextTick(initialDelayMs, idleIntervalMs, activeIntervalMs);
  }

  onModuleDestroy() {
    this.stopped = true;

    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = undefined;
    }
  }

  private scheduleNextTick(
    delayMs: number,
    idleIntervalMs: number,
    activeIntervalMs: number,
  ) {
    if (this.stopped) {
      return;
    }

    if (this.timer) {
      clearTimeout(this.timer);
    }

    this.timer = setTimeout(() => {
      void this.tick(idleIntervalMs, activeIntervalMs);
    }, Math.max(1_000, delayMs));
  }

  private async tick(idleIntervalMs: number, activeIntervalMs: number) {
    if (this.stopped) {
      return;
    }

    let nextDelayMs = idleIntervalMs;

    try {
      const hasCandidates = await this.runOnce();
      nextDelayMs = hasCandidates ? activeIntervalMs : idleIntervalMs;
      this.setMode(
        hasCandidates ? 'active' : 'idle',
        hasCandidates ? activeIntervalMs : idleIntervalMs,
      );
    } finally {
      this.scheduleNextTick(nextDelayMs, idleIntervalMs, activeIntervalMs);
    }
  }

  private async runOnce() {
    if (this.isRunning) {
      return this.currentMode === 'active';
    }

    this.isRunning = true;

    try {
      const settings = await this.matchingEngineService.getRuntimeSettings();

      if (!settings.enabled) {
        return false;
      }

      const hasCandidates =
        await this.matchingEngineService.hasStatusWorkCandidates(new Date());

      if (!hasCandidates) {
        return false;
      }

      const result = await this.matchingEngineService.runStatusWork(new Date());
      if (this.shouldLogResult(result)) {
        console.log('[matching-worker] status result', result);
      }

      return this.matchingEngineService.hasStatusWorkCandidates(new Date());
    } catch (error) {
      console.error('[matching-worker] status check failed', error);
      return false;
    } finally {
      this.isRunning = false;
    }
  }

  private setMode(mode: 'idle' | 'active', intervalMs: number) {
    if (this.currentMode === mode) {
      return;
    }

    this.currentMode = mode;
    console.log(
      mode === 'active'
        ? `[matching-worker] active match found; checking every ${intervalMs}ms`
        : `[matching-worker] no active matches; checking every ${intervalMs}ms`,
    );
  }

  private getPositiveNumberFromEnv(name: string, fallback: number) {
    const value = Number(process.env[name]);
    return Number.isFinite(value) && value > 0 ? value : fallback;
  }

  private shouldLogResult(result: {
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
