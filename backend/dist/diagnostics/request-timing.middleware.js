"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.RequestTimingMiddleware = void 0;
const common_1 = require("@nestjs/common");
let RequestTimingMiddleware = class RequestTimingMiddleware {
    use(req, res, next) {
        const startedAt = process.hrtime.bigint();
        const enabled = process.env.ENABLE_TEMP_TIMING_LOGS !== '0';
        res.on('finish', () => {
            if (!enabled) {
                return;
            }
            const durationMs = Number(process.hrtime.bigint() - startedAt) / 1_000_000;
            console.warn(`[api-time] ${req.method} ${req.originalUrl} ${res.statusCode} ${durationMs.toFixed(0)}ms`);
        });
        next();
    }
};
exports.RequestTimingMiddleware = RequestTimingMiddleware;
exports.RequestTimingMiddleware = RequestTimingMiddleware = __decorate([
    (0, common_1.Injectable)()
], RequestTimingMiddleware);
//# sourceMappingURL=request-timing.middleware.js.map