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
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const supabase_service_1 = require("../supabase/supabase.service");
const prisma_service_1 = require("../prisma/prisma.service");
let AuthService = class AuthService {
    supabaseService;
    prismaService;
    constructor(supabaseService, prismaService) {
        this.supabaseService = supabaseService;
        this.prismaService = prismaService;
    }
    async register(registerDto) {
        const { email, password, username } = registerDto;
        const { data, error } = await this.supabaseService.client.auth.signUp({
            email,
            password,
        });
        if (error) {
            throw new common_1.BadRequestException(error.message);
        }
        if (!data.user) {
            throw new common_1.BadRequestException('Failed to create user');
        }
        const user = await this.prismaService.users.create({
            data: {
                id: data.user.id,
                email,
                username,
            },
        });
        return {
            user: {
                id: user.id,
                email: user.email,
                username: user.username,
            },
            session: data.session,
        };
    }
    async login(loginDto) {
        const { email, password } = loginDto;
        const { data, error } = await this.supabaseService.client.auth.signInWithPassword({
            email,
            password,
        });
        if (error) {
            throw new common_1.UnauthorizedException(error.message);
        }
        if (!data.user) {
            throw new common_1.UnauthorizedException('Invalid credentials');
        }
        let user = await this.prismaService.users.findUnique({
            where: { id: data.user.id },
        });
        if (!user) {
            user = await this.prismaService.users.create({
                data: {
                    id: data.user.id,
                    email: data.user.email ?? '',
                    username: await this.buildAvailableFallbackUsername(data.user),
                },
            });
        }
        return {
            user: {
                id: user.id,
                email: user.email,
                username: user.username,
                avatar_url: user.avatar_url,
            },
            session: data.session,
        };
    }
    async logout() {
        const { error } = await this.supabaseService.client.auth.signOut();
        if (error) {
            throw new common_1.BadRequestException(error.message);
        }
        return { message: 'Logged out successfully' };
    }
    async validateToken(token) {
        const { data, error } = await this.supabaseService.client.auth.getUser(token);
        if (error) {
            throw new common_1.UnauthorizedException(error.message);
        }
        const supaUser = data.user;
        if (!supaUser) {
            throw new common_1.UnauthorizedException('User not found for token');
        }
        let user = await this.prismaService.users.findUnique({
            where: { id: supaUser.id },
        });
        if (!user) {
            user = await this.prismaService.users.create({
                data: {
                    id: supaUser.id,
                    email: supaUser.email ?? '',
                    username: await this.buildAvailableFallbackUsername(supaUser),
                },
            });
        }
        return {
            id: user.id,
            email: user.email,
            username: user.username,
            avatar_url: user.avatar_url,
        };
    }
    async buildAvailableFallbackUsername(user) {
        const base = this.buildFallbackUsernameBase(user);
        const existing = await this.prismaService.users.findUnique({
            where: { username: base },
        });
        if (!existing) {
            return base;
        }
        return `${base}_${user.id.slice(0, 6)}`;
    }
    buildFallbackUsernameBase(user) {
        const rawBase = user.user_metadata?.['username']?.toString() ?? user.email?.split('@')[0] ?? 'user';
        const base = rawBase
            .toLowerCase()
            .replace(/[^a-z0-9_]/g, '_')
            .replace(/_+/g, '_')
            .replace(/^_+|_+$/g, '')
            .slice(0, 24);
        return base || 'user';
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supabase_service_1.SupabaseService,
        prisma_service_1.PrismaService])
], AuthService);
//# sourceMappingURL=auth.service.js.map