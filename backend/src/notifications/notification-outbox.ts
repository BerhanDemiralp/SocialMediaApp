import { Prisma } from '@prisma/client';

export const pushEnabled = () => process.env.PUSH_ENABLED === '1';

export type NotificationKind = 'moment_started' | 'moment_reminder' | 'message';
export interface NotificationEvent {
  kind: NotificationKind;
  sourceId: string;
  conversationId: string;
  recipients: string[];
  expiresAt: Date;
}

/** Only call inside the transaction that commits the business event. */
export async function enqueueNotification(
  tx: Prisma.TransactionClient,
  event: NotificationEvent,
) {
  if (!pushEnabled()) return;
  for (const recipientId of new Set(event.recipients)) {
    // PostgreSQL ON CONFLICT handles concurrent producers inside the transaction.
    // Prisma upsert with an empty update can otherwise race on the unique key.
    await tx.notification_intents.createMany({
      data: {
        kind: event.kind,
        source_id: event.sourceId,
        recipient_id: recipientId,
        conversation_id: event.conversationId,
        expires_at: event.expiresAt,
      },
      skipDuplicates: true,
    });
    const intent = await tx.notification_intents.findUniqueOrThrow({
      where: {
        kind_source_id_recipient_id: {
          kind: event.kind,
          source_id: event.sourceId,
          recipient_id: recipientId,
        },
      },
    });
    // Snapshot eligible installations at event time; no replay on later signup.
    const installations = await tx.notification_installations.findMany({
      where: {
        user_id: recipientId,
        enabled: true,
        last_seen_at: { lte: intent.created_at },
      },
    });
    if (installations.length) {
      await tx.notification_deliveries.createMany({
        data: installations.map((device) => ({
          intent_id: intent.id,
          installation_id: device.id,
          installation_version: device.version,
        })),
        skipDuplicates: true,
      });
    }
  }
}
