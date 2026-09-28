import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { ConversationsService } from '../conversations/conversations.service';
import { PushFailure, PushTransport } from './firebase-push.transport';
import { pushEnabled } from './notification-outbox';
import { maxAttempts, retentionDays } from './notification-config';

@Injectable()
export class NotificationWorker implements OnModuleInit, OnModuleDestroy {
  private timer?: NodeJS.Timeout;
  private running = false;
  private stopped = false;
  private lastCleanup = 0;
  private readonly logger = new Logger(NotificationWorker.name);
  constructor(
    private readonly prisma: PrismaService,
    private readonly transport: PushTransport,
    private readonly conversations: ConversationsService,
  ) {}

  onModuleInit() {
    if (pushEnabled()) this.timer = setInterval(() => void this.tick(), 5000);
  }
  onModuleDestroy() {
    this.stopped = true;
    if (this.timer) clearInterval(this.timer);
  }

  async tick() {
    if (this.running || this.stopped || !pushEnabled()) return;
    this.running = true;
    try {
      const now = new Date();
      if (Date.now() - this.lastCleanup > 3600000) {
        await this.prisma.notification_intents.deleteMany({
          where: {
            expires_at: {
              lt: new Date(Date.now() - retentionDays() * 86400000),
            },
          },
        });
        this.lastCleanup = Date.now();
      }
      const candidates = await this.prisma.notification_deliveries.findMany({
        where: {
          next_attempt_at: { lte: now },
          OR: [
            { status: 'pending' },
            { status: 'sending', lease_until: { lte: now } },
          ],
        },
        orderBy: { next_attempt_at: 'asc' },
        take: 25,
      });
      for (const candidate of candidates) {
        if (this.stopped) break;
        const claim = randomUUID();
        const claimed = await this.prisma.notification_deliveries.updateMany({
          where: {
            id: candidate.id,
            next_attempt_at: { lte: now },
            OR: [
              { status: 'pending' },
              { status: 'sending', lease_until: { lte: now } },
            ],
          },
          data: {
            status: 'sending',
            claim_id: claim,
            lease_until: new Date(Date.now() + 120000),
            attempts: { increment: 1 },
          },
        });
        if (!claimed.count) continue;
        await this.deliver(candidate.id, claim);
      }
    } catch {
      this.logger.warn(
        'Notification worker failed; unfinished leases will be retried',
      );
    } finally {
      this.running = false;
    }
  }

  private async deliver(id: string, claim: string) {
    const row = await this.prisma.notification_deliveries.findUniqueOrThrow({
      where: { id },
      include: { intent: true, installation: true },
    });
    const finish = (status: string, errorCode?: string, retryAt?: Date) =>
      this.prisma.notification_deliveries.updateMany({
        where: { id, claim_id: claim },
        data: {
          status,
          claim_id: null,
          lease_until: null,
          error_code: errorCode ?? null,
          ...(status === 'accepted' ? { accepted_at: new Date() } : {}),
          ...(retryAt ? { next_attempt_at: retryAt } : {}),
        },
      });
    const event = row.intent;
    const installation = row.installation;
    if (event.expires_at.getTime() <= Date.now()) {
      await finish('expired');
      return;
    }
    if (row.attempts > maxAttempts()) {
      await finish('failed', 'attempt_limit');
      return;
    }
    if (
      !installation.enabled ||
      installation.user_id !== event.recipient_id ||
      installation.version !== row.installation_version
    ) {
      await finish('skipped', 'registration_changed');
      return;
    }
    try {
      await this.conversations.assertUserCanAccessConversation(
        event.conversation_id,
        event.recipient_id,
      );
    } catch (error) {
      // Only authorization/not-found errors are terminal; DB failures retry.
      const status = (error as { getStatus?: () => number }).getStatus?.();
      if (status === 403 || status === 404) {
        await finish('skipped', 'access_revoked');
        return;
      }
      await finish(
        'pending',
        'access_check_failed',
        new Date(Date.now() + 30000),
      );
      return;
    }
    if (event.kind === 'moment_reminder' || event.kind === 'moment_started') {
      const moment = await this.prisma.moment_matches.findUnique({
        where: { id: event.source_id },
      });
      if (
        !moment ||
        moment.expires_at.getTime() <= Date.now() ||
        !['active', 'successful'].includes(moment.status)
      ) {
        await finish('expired');
        return;
      }
      if (event.kind === 'moment_reminder') {
        const count = await this.prisma.messages.count({
          where: {
            conversation_id: moment.conversation_id,
            deleted_at: null,
            created_at: { gte: moment.scheduled_at, lte: moment.expires_at },
          },
        });
        if (count > 0) {
          await finish('skipped', 'moment_has_messages');
          return;
        }
      }
    }
    // Re-read immediately before the external call, after authorization queries.
    const current = await this.prisma.notification_installations.findUnique({
      where: { id: installation.id },
    });
    if (
      !current?.enabled ||
      current.version !== row.installation_version ||
      current.user_id !== event.recipient_id
    ) {
      await finish('skipped', 'registration_changed');
      return;
    }
    try {
      await this.transport.send(
        current.token,
        {
          version: '1',
          eventId: event.id,
          kind: event.kind,
          accountId: event.recipient_id,
          conversationId: event.conversation_id,
          ...(event.kind === 'message'
            ? { messageId: event.source_id }
            : { momentId: event.source_id }),
        },
        event.expires_at,
      );
      await finish('accepted');
    } catch (error) {
      const category =
        error instanceof PushFailure ? error.category : 'transient';
      if (category === 'invalid_registration') {
        await this.prisma.notification_installations.updateMany({
          where: { id: current.id, version: current.version },
          data: { enabled: false },
        });
      }
      const retry = category === 'transient' && row.attempts < maxAttempts();
      await finish(
        retry ? 'pending' : 'failed',
        category,
        retry
          ? new Date(Date.now() + Math.min(300000, 10000 * 2 ** row.attempts))
          : undefined,
      );
    }
  }
}
