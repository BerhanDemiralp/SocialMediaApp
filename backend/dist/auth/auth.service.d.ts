import { SupabaseService } from '../supabase/supabase.service';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
export declare class AuthService {
    private supabaseService;
    private prismaService;
    private readonly tokenCache;
    constructor(supabaseService: SupabaseService, prismaService: PrismaService);
    register(registerDto: RegisterDto): Promise<{
        user: {
            id: string;
            email: string;
            username: string;
        };
        session: import("@supabase/auth-js").Session | null;
    }>;
    login(loginDto: LoginDto): Promise<{
        user: {
            id: string;
            email: string;
            username: string;
            avatar_url: string | null;
        };
        session: import("@supabase/auth-js").Session;
    }>;
    logout(): Promise<{
        message: string;
    }>;
    validateToken(token: string): Promise<{
        id: string;
        email: string;
        username: string;
        avatar_url: string | null;
    }>;
    private getTokenCacheTtlMs;
    private logTiming;
    private buildAvailableFallbackUsername;
    private buildFallbackUsernameBase;
}
