import {
  ConflictException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { createHash } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';

export interface InstallationInput {
  id: string;
  secret: string;
  token: string;
  platform: 'android' | 'ios';
  version: number;
}

@Injectable()
export class InstallationService {
  constructor(private readonly prisma: PrismaService) {}

  async register(userId: string, input: InstallationInput) {
    const hash = createHash('sha256').update(input.secret).digest('hex');
    return this.prisma.$transaction(async (tx) => {
      // Serialize changes even when the installation does not exist yet.
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${input.id}))`;
      const previous = await tx.notification_installations.findUnique({
        where: { id: input.id },
      });
      if (previous && previous.secret_hash !== hash)
        throw new ForbiddenException();
      if (previous && previous.version !== input.version)
        throw new ConflictException('Stale installation version');
      const tokenOwner = await tx.notification_installations.findUnique({
        where: { token: input.token },
      });
      if (tokenOwner && tokenOwner.id !== input.id)
        throw new ConflictException('Registration already assigned');
      const changed =
        previous &&
        (previous.user_id !== userId ||
          previous.token !== input.token ||
          !previous.enabled);
      const device = await tx.notification_installations.upsert({
        where: { id: input.id },
        create: {
          id: input.id,
          secret_hash: hash,
          user_id: userId,
          token: input.token,
          platform: input.platform,
        },
        update: {
          user_id: userId,
          token: input.token,
          platform: input.platform,
          enabled: true,
          last_seen_at: new Date(),
          ...(changed ? { version: { increment: 1 } } : {}),
        },
      });
      return { id: device.id, version: device.version };
    });
  }

  async remove(userId: string, id: string, version: number) {
    // Version guard means late logout cannot disable a newly reassigned device.
    await this.prisma.notification_installations.updateMany({
      where: { id, user_id: userId, version },
      data: { enabled: false, version: { increment: 1 } },
    });
    return { ok: true };
  }
}
