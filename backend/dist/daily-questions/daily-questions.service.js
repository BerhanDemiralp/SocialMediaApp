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
exports.DailyQuestionsService = void 0;
const common_1 = require("@nestjs/common");
const daily_questions_repository_1 = require("./daily-questions.repository");
let DailyQuestionsService = class DailyQuestionsService {
    dailyQuestionsRepository;
    constructor(dailyQuestionsRepository) {
        this.dailyQuestionsRepository = dailyQuestionsRepository;
    }
    async createDailyQuestion(questionText, questionDate) {
        const date = new Date(questionDate);
        if (Number.isNaN(date.getTime())) {
            throw new common_1.BadRequestException('Invalid questionDate');
        }
        try {
            return await this.dailyQuestionsRepository.createDailyQuestion(questionText, date);
        }
        catch (error) {
            throw new common_1.BadRequestException('Could not create daily question');
        }
    }
    async listDailyQuestions(page, pageSize) {
        const take = pageSize;
        const skip = (page - 1) * pageSize;
        return this.dailyQuestionsRepository.listDailyQuestions(take, skip);
    }
    async getTodayQuestion(now) {
        const question = await this.dailyQuestionsRepository.findQuestionForAppDay(now);
        if (!question) {
            throw new common_1.NotFoundException('No daily question for today');
        }
        return question;
    }
    async submitAnswerForToday(userId, answerText) {
        const todayQuestion = await this.getTodayQuestion(new Date());
        return this.dailyQuestionsRepository.upsertUserAnswer(userId, todayQuestion.id, answerText);
    }
    async listMyAnswers(userId, page, pageSize) {
        const take = pageSize;
        const skip = (page - 1) * pageSize;
        const answers = await this.dailyQuestionsRepository.listUserAnswers(userId, take, skip);
        return answers.map((answer) => ({
            id: answer.id,
            answer_text: answer.answer_text,
            created_at: answer.created_at,
            question: {
                id: answer.question.id,
                question_text: answer.question.question_text,
                question_date: answer.question.question_date,
            },
        }));
    }
    async listFriendsAnswersForToday(requesterId, page, pageSize) {
        const todayQuestion = await this.getTodayQuestion(new Date());
        const take = pageSize;
        const skip = (page - 1) * pageSize;
        const answers = await this.dailyQuestionsRepository.listFriendsAnswersForQuestion(requesterId, todayQuestion.id, take, skip);
        return answers.map((answer) => ({
            id: answer.id,
            answer_text: answer.answer_text,
            created_at: answer.created_at,
            user: {
                id: answer.user.id,
                username: answer.user.username,
                avatar_url: answer.user.avatar_url,
            },
        }));
    }
};
exports.DailyQuestionsService = DailyQuestionsService;
exports.DailyQuestionsService = DailyQuestionsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [daily_questions_repository_1.DailyQuestionsRepository])
], DailyQuestionsService);
//# sourceMappingURL=daily-questions.service.js.map