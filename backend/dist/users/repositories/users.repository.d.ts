import { PrismaService } from '../../prisma/prisma.service';
import { Prisma } from '@prisma/client';
export declare class UsersRepository {
    private prismaService;
    constructor(prismaService: PrismaService);
    findById(id: string): Promise<{
        email: string;
        username: string;
        id: string;
        avatar_url: string | null;
        created_at: Date;
        updated_at: Date;
    } | null>;
    findByEmail(email: string): Promise<{
        email: string;
        username: string;
        id: string;
        avatar_url: string | null;
        created_at: Date;
        updated_at: Date;
    } | null>;
    findByUsername(username: string): Promise<{
        email: string;
        username: string;
        id: string;
        avatar_url: string | null;
        created_at: Date;
        updated_at: Date;
    } | null>;
    searchByUsername(query: string, limit: number): Promise<{
        username: string;
        id: string;
        avatar_url: string | null;
    }[]>;
    update(id: string, data: Prisma.usersUpdateInput): Promise<{
        email: string;
        username: string;
        id: string;
        avatar_url: string | null;
        created_at: Date;
        updated_at: Date;
    }>;
}
