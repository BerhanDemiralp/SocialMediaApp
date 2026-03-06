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
exports.DailyQuestionsController = void 0;
const common_1 = require("@nestjs/common");
const auth_guard_1 = require("../auth/guards/auth.guard");
const daily_questions_service_1 = require("./daily-questions.service");
const create_daily_question_dto_1 = require("./dto/create-daily-question.dto");
const submit_answer_dto_1 = require("./dto/submit-answer.dto");
const daily_questions_schemas_1 = require("./daily-questions.schemas");
let DailyQuestionsController = class DailyQuestionsController {
    dailyQuestionsService;
    constructor(dailyQuestionsService) {
        this.dailyQuestionsService = dailyQuestionsService;
    }
    async createDailyQuestion(req, body) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        try {
            daily_questions_schemas_1.createDailyQuestionSchema.parse(body);
        }
        catch {
            throw new common_1.BadRequestException('Invalid daily question payload');
        }
        return this.dailyQuestionsService.createDailyQuestion(body.questionText, body.questionDate);
    }
    async listDailyQuestions(req, page = '1', pageSize = '20') {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        const pageNum = Number(page) || 1;
        const pageSizeNum = Number(pageSize) || 20;
        return this.dailyQuestionsService.listDailyQuestions(pageNum, pageSizeNum);
    }
    async getTodayQuestion() {
        return this.dailyQuestionsService.getTodayQuestion(new Date());
    }
    async submitAnswerForToday(req, body) {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        try {
            daily_questions_schemas_1.submitAnswerSchema.parse(body);
        }
        catch {
            throw new common_1.BadRequestException('Invalid answer payload');
        }
        return this.dailyQuestionsService.submitAnswerForToday(userId, body.answerText);
    }
    async listMyAnswers(req, page = '1', pageSize = '20') {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        const pageNum = Number(page) || 1;
        const pageSizeNum = Number(pageSize) || 20;
        return this.dailyQuestionsService.listMyAnswers(userId, pageNum, pageSizeNum);
    }
    async listFriendsAnswers(req, page = '1', pageSize = '20') {
        const userId = req.user?.id;
        if (!userId) {
            throw new common_1.ForbiddenException('Authenticated user context is missing');
        }
        const pageNum = Number(page) || 1;
        const pageSizeNum = Number(pageSize) || 20;
        return this.dailyQuestionsService.listFriendsAnswersForToday(userId, pageNum, pageSizeNum);
    }
};
exports.DailyQuestionsController = DailyQuestionsController;
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, create_daily_question_dto_1.CreateDailyQuestionDto]),
    __metadata("design:returntype", Promise)
], DailyQuestionsController.prototype, "createDailyQuestion", null);
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('page')),
    __param(2, (0, common_1.Query)('pageSize')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object, Object]),
    __metadata("design:returntype", Promise)
], DailyQuestionsController.prototype, "listDailyQuestions", null);
__decorate([
    (0, common_1.Get)('today'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], DailyQuestionsController.prototype, "getTodayQuestion", null);
__decorate([
    (0, common_1.Post)('today/answer'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, submit_answer_dto_1.SubmitAnswerDto]),
    __metadata("design:returntype", Promise)
], DailyQuestionsController.prototype, "submitAnswerForToday", null);
__decorate([
    (0, common_1.Get)('answers/me'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('page')),
    __param(2, (0, common_1.Query)('pageSize')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object, Object]),
    __metadata("design:returntype", Promise)
], DailyQuestionsController.prototype, "listMyAnswers", null);
__decorate([
    (0, common_1.Get)('answers/friends'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('page')),
    __param(2, (0, common_1.Query)('pageSize')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object, Object]),
    __metadata("design:returntype", Promise)
], DailyQuestionsController.prototype, "listFriendsAnswers", null);
exports.DailyQuestionsController = DailyQuestionsController = __decorate([
    (0, common_1.Controller)('daily-questions'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    __metadata("design:paramtypes", [daily_questions_service_1.DailyQuestionsService])
], DailyQuestionsController);
//# sourceMappingURL=daily-questions.controller.js.map