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
Object.defineProperty(exports, "__esModule", { value: true });
exports.MatchingEngineService = void 0;
const common_1 = require("@nestjs/common");
const matching_engine_repository_1 = require("./matching-engine.repository");
let MatchingEngineService = class MatchingEngineService {
    matchingEngineRepository;
    constructor(matchingEngineRepository) {
        this.matchingEngineRepository = matchingEngineRepository;
    }
    getDayRange(now) {
        const start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
        const end = new Date(start);
        end.setUTCDate(end.getUTCDate() + 1);
        return { start, end };
    }
    async runDailyMatching(now) {
        await this.evaluateExpiredMatches(now);
        const { start, end } = this.getDayRange(now);
        const users = await this.matchingEngineRepository.findUsersWithoutActiveMatch(now);
        const assigned = new Set();
        const created = [];
        for (const user of users) {
            if (assigned.has(user.id)) {
                continue;
            }
            const friendIds = await this.matchingEngineRepository.findAcceptedFriends(user.id);
            let partnerId = null;
            let matchType = null;
            for (const fid of friendIds) {
                if (assigned.has(fid)) {
                    continue;
                }
                const exists = await this.matchingEngineRepository.existsMatchBetweenUsersOnDay(user.id, fid, start, end);
                if (!exists) {
                    partnerId = fid;
                    matchType = 'friends';
                    break;
                }
            }
            if (!partnerId) {
                const groupCandidateIds = await this.matchingEngineRepository.findGroupMemberCandidates(user.id);
                for (const gid of groupCandidateIds) {
                    if (assigned.has(gid)) {
                        continue;
                    }
                    const exists = await this.matchingEngineRepository.existsMatchBetweenUsersOnDay(user.id, gid, start, end);
                    if (!exists) {
                        partnerId = gid;
                        matchType = 'groups';
                        break;
                    }
                }
            }
            if (partnerId && matchType) {
                const match = await this.matchingEngineRepository.createMatch(user.id, partnerId, matchType, now);
                created.push(match);
                assigned.add(user.id);
                assigned.add(partnerId);
            }
        }
        return { createdCount: created.length };
    }
    async evaluateExpiredMatches(now) {
        const matches = await this.matchingEngineRepository.findMatchesToEvaluate(now);
        for (const match of matches) {
            const messages = await this.matchingEngineRepository.getMessagesForMatchInWindow(match.id, match.scheduled_at, match.expires_at);
            const totalMessages = messages.length;
            const byUser = new Map();
            for (const message of messages) {
                const current = byUser.get(message.sender_id) ?? 0;
                byUser.set(message.sender_id, current + 1);
            }
            const userAMessages = byUser.get(match.user_a_id) ?? 0;
            const userBMessages = byUser.get(match.user_b_id) ?? 0;
            const isSuccessful = totalMessages >= 10 && userAMessages >= 1 && userBMessages >= 1;
            await this.matchingEngineRepository.updateMatchStatus(match.id, isSuccessful ? 'successful' : 'expired');
        }
    }
    async getCurrentMomentForUser(userId, now) {
        return this.matchingEngineRepository.getCurrentActiveMatchForUser(userId, now);
    }
    async getMatchHistoryForUser(userId, page, pageSize) {
        const take = pageSize;
        const skip = (page - 1) * pageSize;
        return this.matchingEngineRepository.getHistoricalMatchesForUser(userId, skip, take);
    }
    async optInToGroupMatch(matchId, userId) {
        return this.matchingEngineRepository.setGroupOptIn(matchId, userId);
    }
};
exports.MatchingEngineService = MatchingEngineService;
exports.MatchingEngineService = MatchingEngineService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [matching_engine_repository_1.MatchingEngineRepository])
], MatchingEngineService);
//# sourceMappingURL=matching-engine.service.js.map