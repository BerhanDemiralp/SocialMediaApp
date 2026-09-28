import { Injectable, OnModuleInit } from '@nestjs/common';
import { App, applicationDefault, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { pushEnabled } from './notification-outbox';

export class PushFailure extends Error {
  constructor(
    public readonly category:
      | 'invalid_registration'
      | 'transient'
      | 'permanent',
  ) {
    super(category);
  }
}
export abstract class PushTransport {
  abstract send(
    token: string,
    data: Record<string, string>,
    expiresAt: Date,
  ): Promise<void>;
}

@Injectable()
export class FirebasePushTransport
  extends PushTransport
  implements OnModuleInit
{
  private app?: App;
  onModuleInit() {
    if (!pushEnabled()) return;
    if (!process.env.FIREBASE_PROJECT_ID)
      throw new Error(
        'PUSH_ENABLED requires FIREBASE_PROJECT_ID and application default credentials',
      );
    this.app = initializeApp(
      {
        credential: applicationDefault(),
        projectId: process.env.FIREBASE_PROJECT_ID,
      },
      'moment-push',
    );
  }

  async send(token: string, data: Record<string, string>, expiresAt: Date) {
    if (!this.app) throw new PushFailure('permanent');
    const body =
      data.kind === 'message'
        ? 'You have a new message.'
        : data.kind === 'moment_started'
          ? 'Your Moment is ready.'
          : 'There is still time to join your Moment.';
    try {
      await getMessaging(this.app).send({
        token,
        data,
        notification: { title: 'MOMENT', body },
        android: {
          priority: 'high',
          ttl: Math.max(0, expiresAt.getTime() - Date.now()),
          notification: { channelId: 'moment_messages', tag: data.eventId },
        },
        apns: {
          headers: {
            'apns-expiration': String(Math.floor(expiresAt.getTime() / 1000)),
            'apns-collapse-id': data.eventId,
          },
          payload: { aps: { sound: 'default' } },
        },
      });
    } catch (error) {
      const code = (error as { code?: string }).code;
      if (
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token'
      )
        throw new PushFailure('invalid_registration');
      if (
        [
          'messaging/server-unavailable',
          'messaging/internal-error',
          'messaging/quota-exceeded',
          'app/network-error',
        ].includes(code ?? '')
      )
        throw new PushFailure('transient');
      throw new PushFailure('permanent');
    }
  }
}
