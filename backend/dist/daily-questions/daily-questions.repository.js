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
exports.DailyQuestionsRepository = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let DailyQuestionsRepository = class DailyQuestionsRepository {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async createDailyQuestion(questionText, questionDate) {
        return this.prisma.daily_questions.create({
            data: {
                question_text: questionText,
                question_date: questionDate,
            },
        });
    }
    async listDailyQuestions(take, skip) {
        return this.prisma.daily_questions.findMany({
            orderBy: { question_date: 'desc' },
            take,
            skip,
        });
    }
    async findQuestionForAppDay(now) {
        const startOfDay = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
        const endOfDay = new Date(startOfDay);
        endOfDay.setUTCDate(endOfDay.getUTCDate() + 1);
        return this.prisma.daily_questions.findFirst({
            where: {
                question_date: {
                    gte: startOfDay,
                    lt: endOfDay,
                },
            },
            orderBy: { question_date: 'asc' },
        });
    }
    async upsertUserAnswer(userId, questionId, answerText) {
        return this.prisma.user_answers.upsert({
            where: {
                question_id_user_id: {
                    question_id: questionId,
                    user_id: userId,
                },
            },
            create: {
                user_id: userId,
                question_id: questionId,
                answer_text: answerText,
            },
            update: {
                answer_text: answerText,
            },
        });
    }
    async listUserAnswers(userId, take, skip) {
        return this.prisma.user_answers.findMany({
            where: { user_id: userId },
            orderBy: { created_at: 'desc' },
            take,
            skip,
            include: {
                question: true,
            },
        });
    }
    async listFriendsAnswersForQuestion(requesterId, questionId, take, skip) {
        const friendships = await this.prisma.friendships.findMany({
            where: {
                status: 'accepted',
                OR: [{ requester_id: requesterId }, { addressee_id: requesterId }],
            },
        });
        const friendIds = friendships.map((f) => f.requester_id === requesterId ? f.addressee_id : f.requester_id);
        if (!friendIds.length) {
            return [];
        }
        return this.prisma.user_answers.findMany({
            where: {
                question_id: questionId,
                user_id: {
                    in: friendIds,
                },
            },
            orderBy: { created_at: 'desc' },
            take,
            skip,
            include: {
                user: true,
            },
        });
    }
};
exports.DailyQuestionsRepository = DailyQuestionsRepository;
exports.DailyQuestionsRepository = DailyQuestionsRepository = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], DailyQuestionsRepository);
//# sourceMappingURL=daily-questions.repository.js.map