import { Injectable, NestMiddleware } from '@nestjs/common';
import { NextFunction, Request, Response } from 'express';

@Injectable()
export class RequestTimingMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const startedAt = process.hrtime.bigint();
    const enabled = process.env.ENABLE_TEMP_TIMING_LOGS !== '0';

    res.on('finish', () => {
      if (!enabled) {
        return;
      }

      const durationMs = Number(process.hrtime.bigint() - startedAt) / 1_000_000;
      console.warn(
        `[api-time] ${req.method} ${req.originalUrl} ${res.statusCode} ${durationMs.toFixed(0)}ms`,
      );
    });

    next();
  }
}
