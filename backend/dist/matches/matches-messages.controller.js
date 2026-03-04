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
exports.MatchesMessagesController = void 0;
const common_1 = require("@nestjs/common");
const auth_guard_1 = require("../auth/guards/auth.guard");
const prisma_service_1 = require("../prisma/prisma.service");
let MatchesMessagesController = class MatchesMessagesController {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getMatchMessages(matchId, req, limit) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('User context is missing');
        }
        const match = await this.prisma.matches.findUnique({
            where: { id: matchId },
        });
        if (!match || (match.user_a_id !== userId && match.user_b_id !== userId)) {
            throw new common_1.ForbiddenException('You are not allowed to view messages for this match');
        }
        const take = limit && limit > 0 ? limit : 50;
        const messages = await this.prisma.messages.findMany({
            where: { match_id: matchId },
            orderBy: { created_at: 'asc' },
            take,
        });
        return messages;
    }
};
exports.MatchesMessagesController = MatchesMessagesController;
__decorate([
    (0, common_1.Get)(':matchId/messages'),
    __param(0, (0, common_1.Param)('matchId')),
    __param(1, (0, common_1.Request)()),
    __param(2, (0, common_1.Query)('limit', new common_1.ParseIntPipe({ optional: true }))),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Number]),
    __metadata("design:returntype", Promise)
], MatchesMessagesController.prototype, "getMatchMessages", null);
exports.MatchesMessagesController = MatchesMessagesController = __decorate([
    (0, common_1.Controller)('matches'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], MatchesMessagesController);
//# sourceMappingURL=matches-messages.controller.js.map