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
import { ConversationType } from '@prisma/client';

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
  async handleJoinMatch(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string },
  ) {
    const { matchId } = data;

    const { conversation } = await this.ensureConversationForMatch(matchId);

    void client.join(`match:${matchId}`);
    void client.join(`conversation:${conversation.id}`);

    console.log(`User ${client.user?.id} joined match ${matchId}`);
    return {
      event: 'joined',
      data: { matchId, conversationId: conversation.id },
    };
  }

  @SubscribeMessage('leaveMatch')
  @UseGuards(WsAuthGuard)
  async handleLeaveMatch(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string },
  ) {
    const { matchId } = data;

    const { conversation } = await this.ensureConversationForMatch(matchId);

    void client.leave(`conversation:${conversation.id}`);
    void client.leave(`match:${matchId}`);

    console.log(`User ${client.user?.id} left match ${matchId}`);
    return {
      event: 'left',
      data: { matchId, conversationId: conversation.id },
    };
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

    const { match, conversation } = await this.ensureConversationForMatch(
      matchId,
    );

    if (match.user_a_id !== userId && match.user_b_id !== userId) {
      throw new WsException(
        'You are not allowed to send messages for this match',
      );
    }

    const message = await this.prisma.messages.create({
      data: {
        match_id: matchId,
        conversation_id: conversation.id,
        sender_id: userId,
        content,
      },
    });

    this.server
      .to(`conversation:${conversation.id}`)
      .emit('newMessage', message);
    // Legacy channel for transition period.
    this.server.to(`match:${matchId}`).emit('newMessage', message);
    return { event: 'messageSent', data: message };
  }

  @SubscribeMessage('typing')
  @UseGuards(WsAuthGuard)
  async handleTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string; isTyping: boolean },
  ) {
    const { matchId, isTyping } = data;

    const { conversation } = await this.ensureConversationForMatch(matchId);

    client.to(`conversation:${conversation.id}`).emit('userTyping', {
      userId: client.user?.id,
      isTyping,
    });

    // Legacy channel for transition period.
    client.to(`match:${matchId}`).emit('userTyping', {
      userId: client.user?.id,
      isTyping,
    });
    return { event: 'typingAcknowledged' };
  }

  private async ensureConversationForMatch(matchId: string) {
    const match = await this.prisma.matches.findUnique({
      where: { id: matchId },
    });

    if (!match) {
      throw new WsException('Match not found');
    }

    const isFriendMatch = match.match_type === 'friends';
    const isGroupMatch = match.match_type === 'groups';

    const where =
      isFriendMatch || !isGroupMatch
        ? { friend_match_id: match.id }
        : { group_match_id: match.id };

    let conversation = await this.prisma.conversations.findFirst({
      where,
    });

    if (!conversation) {
      const participantIds = [match.user_a_id, match.user_b_id].filter(
        (id, index, arr) => !!id && arr.indexOf(id) === index,
      );

      const participantsCreate = participantIds.map((userId) => ({
        user: { connect: { id: userId } },
      }));

      const type = isFriendMatch
        ? ConversationType.friend
        : isGroupMatch
          ? ConversationType.group_pair
          : ConversationType.friend;

      conversation = await this.prisma.conversations.create({
        data: {
          type,
          title: null,
          friend_match_id: isFriendMatch ? match.id : null,
          group_match_id: isGroupMatch ? match.id : null,
          participants: {
            create: participantsCreate,
          },
        },
      });
    }

    return { match, conversation };
  }
}
