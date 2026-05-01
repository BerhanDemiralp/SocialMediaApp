import { NestMiddleware } from '@nestjs/common';
import { NextFunction, Request, Response } from 'express';
export declare class RequestTimingMiddleware implements NestMiddleware {
    use(req: Request, res: Response, next: NextFunction): void;
}
