"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.submitAnswerSchema = exports.createDailyQuestionSchema = void 0;
const zod_1 = require("zod");
exports.createDailyQuestionSchema = zod_1.z.object({
    questionText: zod_1.z.string().min(1),
    questionDate: zod_1.z.string().min(1),
});
exports.submitAnswerSchema = zod_1.z.object({
    answerText: zod_1.z.string().min(1),
});
//# sourceMappingURL=daily-questions.schemas.js.map