"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MatchingEngineController = void 0;
const common_1 = require("@nestjs/common");
const auth_guard_1 = require("../auth/guards/auth.guard");
const matching_engine_service_1 = require("./matching-engine.service");
let MatchingEngineController = class MatchingEngineController {
    matchingEngineService;
    constructor(matchingEngineService) {
        this.matchingEngineService = matchingEngineService;
    }
    async runMatching(req) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        const result = await this.matchingEngineService.runDailyMatching(new Date());
        return result;
    }
    async getCurrentMoment(req) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        return this.matchingEngineService.getCurrentMomentForUser(userId, new Date());
    }
    async getHistory(req, page = '1', pageSize = '20') {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        const pageNum = Number(page) || 1;
        const pageSizeNum = Number(pageSize) || 20;
        return this.matchingEngineService.getMatchHistoryForUser(userId, pageNum, pageSizeNum);
    }
    async optInToGroupMatch(matchId, req, optIn = true) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        if (!optIn) {
            return { message: 'Opt-out is not supported in this MVP' };
        }
        const result = await this.matchingEngineService.optInToGroupMatch(matchId, userId);
        if (!result) {
            throw new common_1.ForbiddenException('You are not part of this match');
        }
        return { message: 'Opt-in recorded' };
    }
};
exports.MatchingEngineController = MatchingEngineController;
__decorate([
    (0, common_1.Post)('run'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], MatchingEngineController.prototype, "runMatching", null);
__decorate([
    (0, common_1.Get)('me/current'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], MatchingEngineController.prototype, "getCurrentMoment", null);
__decorate([
    (0, common_1.Get)('me/history'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('page')),
    __param(2, (0, common_1.Query)('pageSize')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object, Object]),
    __metadata("design:returntype", Promise)
], MatchingEngineController.prototype, "getHistory", null);
__decorate([
    (0, common_1.Post)(':matchId/opt-in'),
    __param(0, (0, common_1.Param)('matchId')),
    __param(1, (0, common_1.Request)()),
    __param(2, (0, common_1.Body)('optIn')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], MatchingEngineController.prototype, "optInToGroupMatch", null);
exports.MatchingEngineController = MatchingEngineController = __decorate([
    (0, common_1.Controller)('matching-engine'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    __metadata("design:paramtypes", [matching_engine_service_1.MatchingEngineService])
], MatchingEngineController);
//# sourceMappingURL=matching-engine.controller.js.map