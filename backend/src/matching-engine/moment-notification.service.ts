import { Injectable } from '@nestjs/common';
import { MomentMatchWithRelations } from './matching-engine.repository';
import { PrismaService } from '../prisma/prisma.service';
import { enqueueNotification } from '../notifications/notification-outbox';

export abstract class MomentNotificationService {
  abstract notifyMatchStarted(match: MomentMatchWithRelations): Promise<void>;
  abstract notifyReminder(
    match: MomentMatchWithRelations,
    now?: Date,
  ): Promise<void>;
}

@Injectable()
export class DurableMomentNotificationService implements MomentNotificationService {
  constructor(private readonly prisma: PrismaService) {}
  async notifyMatchStarted(match: MomentMatchWithRelations) {
    await this.prisma.$transaction(async (tx) => {
      const updated = await tx.moment_matches.updateMany({
        where: { id: match.id, status: 'scheduled' },
        data: { status: 'active' },
      });
      if (!updated.count) return;
      await enqueueNotification(tx, {
        kind: 'moment_started',
        sourceId: match.id,
        conversationId: match.conversation_id,
        recipients: [match.user_a_id, match.user_b_id],
        expiresAt: match.expires_at,
      });
    });
  }
  async notifyReminder(match: MomentMatchWithRelations, now = new Date()) {
    await this.prisma.$transaction(async (tx) => {
      const updated = await tx.moment_matches.updateMany({
        where: {
          id: match.id,
          status: 'active',
          reminder_sent_at: null,
          expires_at: { gt: now },
        },
        data: { reminder_sent_at: now },
      });
      if (!updated.count) return;
      await enqueueNotification(tx, {
        kind: 'moment_reminder',
        sourceId: match.id,
        conversationId: match.conversation_id,
        recipients: [match.user_a_id, match.user_b_id],
        expiresAt: match.expires_at,
      });
    });
  }
}
