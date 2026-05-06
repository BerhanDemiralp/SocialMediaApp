import { Injectable } from '@nestjs/common';
import { MomentMatchWithRelations } from './matching-engine.repository';

export abstract class MomentNotificationService {
  abstract notifyMatchStarted(match: MomentMatchWithRelations): Promise<void>;
  abstract notifyReminder(match: MomentMatchWithRelations): Promise<void>;
}

@Injectable()
export class NoopMomentNotificationService
  implements MomentNotificationService
{
  async notifyMatchStarted(): Promise<void> {
    return undefined;
  }

  async notifyReminder(): Promise<void> {
    return undefined;
  }
}
