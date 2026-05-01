import { OnGatewayConnection, OnGatewayDisconnect } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ConversationsService } from '../conversations/conversations.service';
declare module 'socket.io' {
    interface Socket {
        user?: {
            id: string;
            email?: string;
        };
    }
}
export declare class EventsGateway implements OnGatewayConnection, OnGatewayDisconnect {
    private readonly conversationsService;
    constructor(conversationsService: ConversationsService);
    server: Server;
    handleConnection(client: Socket): void;
    handleDisconnect(client: Socket): void;
    joinConversation(client: Socket, payload: {
        conversationId?: string;
    }): Promise<void>;
    leaveConversation(client: Socket, payload: {
        conversationId?: string;
    }): Promise<void>;
    sendConversationMessage(client: Socket, payload: {
        conversationId?: string;
        content?: string;
    }): Promise<void>;
}
