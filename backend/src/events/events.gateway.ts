import {
  UseGuards,
} from '@nestjs/common';
import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ConversationsService } from '../conversations/conversations.service';
import { WsAuthGuard } from './guards/ws-auth.guard';

declare module 'socket.io' {
  interface Socket {
    user?: {
      id: string;
      email?: string;
    };
  }
}

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class EventsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  constructor(private readonly conversationsService: ConversationsService) {}

  @WebSocketServer()
  server: Server;

  handleConnection(client: Socket) {
    console.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
  }

  @UseGuards(WsAuthGuard)
  @SubscribeMessage('joinConversation')
  async joinConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { conversationId?: string },
  ) {
    const conversationId = payload?.conversationId;

    if (!conversationId || !client.user?.id) {
      client.emit('error', { message: 'conversationId is required' });
      return;
    }

    await this.conversationsService.assertUserCanAccessConversation(
      conversationId,
      client.user.id,
    );

    await client.join(`conversation:${conversationId}`);
  }

  @SubscribeMessage('leaveConversation')
  async leaveConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { conversationId?: string },
  ) {
    if (payload?.conversationId) {
      await client.leave(`conversation:${payload.conversationId}`);
    }
  }

  @UseGuards(WsAuthGuard)
  @SubscribeMessage('sendConversationMessage')
  async sendConversationMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { conversationId?: string; content?: string },
  ) {
    const conversationId = payload?.conversationId;
    const content = payload?.content ?? '';

    if (!conversationId || !client.user?.id) {
      client.emit('error', { message: 'conversationId is required' });
      return;
    }

    const message = await this.conversationsService.createMessageForConversation(
      conversationId,
      client.user.id,
      content,
    );

    this.server.to(`conversation:${conversationId}`).emit('newMessage', message);
  }
}
