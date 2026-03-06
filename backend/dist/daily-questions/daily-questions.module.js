"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.DailyQuestionsModule = void 0;
const common_1 = require("@nestjs/common");
const prisma_module_1 = require("../prisma/prisma.module");
const auth_module_1 = require("../auth/auth.module");
const daily_questions_controller_1 = require("./daily-questions.controller");
const daily_questions_service_1 = require("./daily-questions.service");
const daily_questions_repository_1 = require("./daily-questions.repository");
let DailyQuestionsModule = class DailyQuestionsModule {
};
exports.DailyQuestionsModule = DailyQuestionsModule;
exports.DailyQuestionsModule = DailyQuestionsModule = __decorate([
    (0, common_1.Module)({
        imports: [prisma_module_1.PrismaModule, auth_module_1.AuthModule],
        controllers: [daily_questions_controller_1.DailyQuestionsController],
        providers: [daily_questions_service_1.DailyQuestionsService, daily_questions_repository_1.DailyQuestionsRepository],
    })
], DailyQuestionsModule);
//# sourceMappingURL=daily-questions.module.js.map