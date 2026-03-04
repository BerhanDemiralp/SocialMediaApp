import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  MessageBody,
  ConnectedSocket,
  WsException,
} from '@nestjs/websockets';
import { UseGuards } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { WsAuthGuard } from './guards/ws-auth.guard';
import { PrismaService } from '../prisma/prisma.service';

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
  constructor(private prisma: PrismaService) {}

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
  async handleMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string; content: string },
  ) {
    const { matchId, content } = data;
    const userId = client.user?.id;

    if (!userId) {
      throw new WsException('Unauthorized');
    }

    const match = await this.prisma.matches.findUnique({
      where: { id: matchId },
    });

    if (!match || (match.user_a_id !== userId && match.user_b_id !== userId)) {
      throw new WsException(
        'You are not allowed to send messages for this match',
      );
    }

    const message = await this.prisma.messages.create({
      data: {
        match_id: matchId,
        sender_id: userId,
        content,
      },
    });

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
