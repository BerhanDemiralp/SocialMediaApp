import {
  UseGuards,
  OnModuleInit,
  OnModuleDestroy,
  Logger,
} from '@nestjs/common';
import { Subscription } from 'rxjs';
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
export class EventsGateway
  implements
    OnGatewayConnection,
    OnGatewayDisconnect,
    OnModuleInit,
    OnModuleDestroy
{
  private messagesSubscription?: Subscription;
  private readonly logger = new Logger(EventsGateway.name);
  constructor(private readonly conversationsService: ConversationsService) {}

  onModuleInit() {
    this.messagesSubscription =
      this.conversationsService.messageCreated$.subscribe((message) => {
        this.server
          .to(`conversation:${message.conversation_id}`)
          .emit('newMessage', message);
        void this.notifyInbox(message.conversation_id);
      });
  }

  onModuleDestroy() {
    this.messagesSubscription?.unsubscribe();
  }

  private async notifyInbox(conversationId: string) {
    try {
      const audience =
        await this.conversationsService.getConversationAudience(conversationId);
      if (audience.length) {
        this.server
          .to(audience.map((id) => `inbox:${id}`))
          .emit('conversationChanged', { conversationId });
      }
    } catch {
      this.logger.warn(
        'Inbox update unavailable; clients resync on reconnect/resume',
      );
    }
  }

  @UseGuards(WsAuthGuard)
  @SubscribeMessage('watchInbox')
  async watchInbox(@ConnectedSocket() client: Socket) {
    if (!client.user?.id) return { ok: false };
    await client.join(`inbox:${client.user.id}`);
    return { ok: true };
  }

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

    await this.conversationsService.createMessageForConversation(
      conversationId,
      client.user.id,
      content,
    );
  }
}
