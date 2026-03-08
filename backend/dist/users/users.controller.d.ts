import { Request as ExpressRequest } from 'express';
import { UsersService } from './users.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { SearchUsersQueryDto } from './dto/search-users-query.dto';
export declare class UsersController {
    private usersService;
    constructor(usersService: UsersService);
    searchUsers(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, query: SearchUsersQueryDto): Promise<{
        username: string;
        id: string;
        avatar_url: string | null;
    }[]>;
    getMyProfile(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }): Promise<{
        id: string;
        username: string;
        email: string;
        avatar_url: string | null;
        created_at: Date;
        updated_at: Date;
    }>;
    updateMyProfile(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, updateProfileDto: UpdateProfileDto): Promise<{
        id: string;
        username: string;
        email: string;
        avatar_url: string | null;
        created_at: Date;
        updated_at: Date;
    }>;
}
