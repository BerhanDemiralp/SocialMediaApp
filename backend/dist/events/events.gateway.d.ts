import { OnGatewayConnection, OnGatewayDisconnect } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
declare module 'socket.io' {
    interface Socket {
        user?: {
            id: string;
            email?: string;
        };
    }
}
export declare class EventsGateway implements OnGatewayConnection, OnGatewayDisconnect {
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
    }): {
        event: string;
        data: {
            id: `${string}-${string}-${string}-${string}-${string}`;
            match_id: string;
            sender_id: string | undefined;
            content: string;
            created_at: string;
        };
    };
    handleTyping(client: Socket, data: {
        matchId: string;
        isTyping: boolean;
    }): {
        event: string;
    };
}
