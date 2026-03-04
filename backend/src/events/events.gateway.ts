import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { UseGuards } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
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
  @WebSocketServer()
  server: Server;

  handleConnection(client: Socket) {
    console.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('joinMatch')
  @UseGuards(WsAuthGuard)
  handleJoinMatch(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string },
  ) {
    const { matchId } = data;
    void client.join(`match:${matchId}`);
    console.log(`User ${client.user?.id} joined match ${matchId}`);
    return { event: 'joined', data: { matchId } };
  }

  @SubscribeMessage('leaveMatch')
  @UseGuards(WsAuthGuard)
  handleLeaveMatch(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string },
  ) {
    const { matchId } = data;
    void client.leave(`match:${matchId}`);
    console.log(`User ${client.user?.id} left match ${matchId}`);
    return { event: 'left', data: { matchId } };
  }

  @SubscribeMessage('sendMessage')
  @UseGuards(WsAuthGuard)
  handleMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string; content: string },
  ) {
    const { matchId, content } = data;
    const message = {
      id: crypto.randomUUID(),
      match_id: matchId,
      sender_id: client.user?.id,
      content,
      created_at: new Date().toISOString(),
    };

    this.server.to(`match:${matchId}`).emit('newMessage', message);
    return { event: 'messageSent', data: message };
  }

  @SubscribeMessage('typing')
  @UseGuards(WsAuthGuard)
  handleTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string; isTyping: boolean },
  ) {
    const { matchId, isTyping } = data;
    client.to(`match:${matchId}`).emit('userTyping', {
      userId: client.user?.id,
      isTyping,
    });
    return { event: 'typingAcknowledged' };
  }
}
