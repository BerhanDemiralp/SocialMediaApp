import { UsersRepository } from './repositories/users.repository';
import { UpdateProfileDto } from './dto/update-profile.dto';
export declare class UsersService {
    private usersRepository;
    constructor(usersRepository: UsersRepository);
    getProfile(userId: string): Promise<{
        id: string;
        username: string;
        email: string;
        avatar_url: string | null;
        created_at: Date;
        updated_at: Date;
    }>;
    updateProfile(userId: string, updateProfileDto: UpdateProfileDto): Promise<{
        id: string;
        username: string;
        email: string;
        avatar_url: string | null;
        created_at: Date;
        updated_at: Date;
    }>;
    searchUsers(query: string, limit: number, currentUserId: string): Promise<{
        username: string;
        id: string;
        avatar_url: string | null;
    }[]>;
}
