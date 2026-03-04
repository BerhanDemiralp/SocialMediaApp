import { OnGatewayConnection, OnGatewayDisconnect } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { PrismaService } from '../prisma/prisma.service';
declare module 'socket.io' {
    interface Socket {
        user?: {
            id: string;
            email?: string;
        };
    }
}
export declare class EventsGateway implements OnGatewayConnection, OnGatewayDisconnect {
    private prisma;
    constructor(prisma: PrismaService);
    server: Server;
    handleConnection(client: Socket): void;
    handleDisconnect(client: Socket): void;
    handleJoinMatch(client: Socket, data: {
        matchId: string;
    }): {
        event: string;
        data: {
            matchId: string;
        };
    };
    handleLeaveMatch(client: Socket, data: {
        matchId: string;
    }): {
        event: string;
        data: {
            matchId: string;
        };
    };
    handleMessage(client: Socket, data: {
        matchId: string;
        content: string;
    }): Promise<{
        event: string;
        data: {
            id: string;
            created_at: Date;
            content: string;
            match_id: string;
            sender_id: string;
        };
    }>;
    handleTyping(client: Socket, data: {
        matchId: string;
        isTyping: boolean;
    }): {
        event: string;
    };
}
