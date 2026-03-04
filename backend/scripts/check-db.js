// Quick Prisma script to inspect DB state for Task 8.5
// Usage (PowerShell from backend/):
//   $env:EMAIL = "moment.test.002@gmail.com"
//   node scripts/check-db.js

/* eslint-disable no-console */

require('dotenv/config');

const { PrismaClient } = require('@prisma/client');
const { PrismaPg } = require('@prisma/adapter-pg');
const { Pool } = require('pg');

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  console.error('DATABASE_URL is not set in environment');
  process.exit(1);
}

const pool = new Pool({
  connectionString: databaseUrl,
});

const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  const email = process.env.EMAIL;

  console.log('DATABASE_URL:', databaseUrl);
  console.log('Filter email:', email || '(none, showing all users)');

  const users = await prisma.users.findMany(
    email ? { where: { email } } : undefined,
  );

  console.log(`Found ${users.length} user(s):`);
  for (const u of users) {
    console.log({
      id: u.id,
      email: u.email,
      username: u.username,
      avatar_url: u.avatar_url,
      created_at: u.created_at,
      updated_at: u.updated_at,
    });
  }
}

main()
  .catch((e) => {
    console.error('Error in check-db:', e);
  })
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });

