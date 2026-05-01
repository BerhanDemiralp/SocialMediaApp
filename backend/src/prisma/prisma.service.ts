import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import * as dotenv from 'dotenv';

dotenv.config();

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  // eslint-disable-next-line no-console
  console.error('DATABASE_URL is not set in environment');
}

const pool = new Pool({
  connectionString: databaseUrl,
});

const adapter = new PrismaPg(pool);
const enableTimingLogs = process.env.ENABLE_TEMP_TIMING_LOGS !== '0';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  constructor() {
    super({
      adapter,
      log: enableTimingLogs ? [{ emit: 'event', level: 'query' }] : [],
    });

    if (enableTimingLogs) {
      (this as any).$on('query', (event: {
        duration: number;
        query: string;
        target?: string;
      }) => {
        const target = event.target ? ` ${event.target}` : '';
        console.warn(`[db-time] ${event.duration}ms${target} ${event.query}`);
      });
    }
  }

  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
