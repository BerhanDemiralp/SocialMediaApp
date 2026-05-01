import { Request as ExpressRequest } from 'express';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
export declare class AuthController {
    private authService;
    constructor(authService: AuthService);
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
    syncCurrentUser(req: ExpressRequest & {
        user?: {
            id: string;
            email: string;
            username: string;
            avatar_url: string | null;
        };
    }): Promise<{
        user: {
            id: string;
            email: string;
            username: string;
            avatar_url: string | null;
        } | undefined;
    }>;
    logout(authHeader: string): Promise<{
        message: string;
    }>;
}
