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
exports.SupabaseService = void 0;
require("dotenv/config");
const common_1 = require("@nestjs/common");
const supabase_js_1 = require("@supabase/supabase-js");
let SupabaseService = class SupabaseService {
    client;
    adminClient;
    constructor() {
        const supabaseUrl = process.env.SUPABASE_URL;
        const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;
        const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
        if (!supabaseUrl || !supabaseAnonKey) {
            console.error('Supabase env missing', {
                hasUrl: !!supabaseUrl,
                hasAnonKey: !!supabaseAnonKey,
                hasServiceKey: !!supabaseServiceKey,
            });
            throw new Error('Supabase URL or anon key is missing in environment variables');
        }
        this.client = (0, supabase_js_1.createClient)(supabaseUrl, supabaseAnonKey);
        if (supabaseServiceKey) {
            this.adminClient = (0, supabase_js_1.createClient)(supabaseUrl, supabaseServiceKey);
        }
        else {
            console.warn('SUPABASE_SERVICE_ROLE_KEY is not set; adminClient will use anon key (dev only).');
            this.adminClient = this.client;
        }
    }
};
exports.SupabaseService = SupabaseService;
exports.SupabaseService = SupabaseService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [])
], SupabaseService);
//# sourceMappingURL=supabase.service.js.map