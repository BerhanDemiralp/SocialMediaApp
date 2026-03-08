// Migration script for conversations-backend-foundation (Task 2.2)
// Backfill conversations and conversation_id on messages from existing matches.
//
// Usage (from backend/):
//   node scripts/backfill-conversations.js
//
// Requirements:
//   - DATABASE_URL is set and points to the target Postgres DB
//   - Prisma schema has been migrated so that:
//       - conversations and conversation_participants tables exist
//       - messages.conversation_id column exists
//
/* eslint-disable no-console */

require('dotenv/config');

const { PrismaClient, ConversationType } = require('@prisma/client');
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

async function ensureConversationForMatch(match) {
  const isFriendMatch = match.match_type === 'friends';
  const isGroupMatch = match.match_type === 'groups';

  const type =
    isFriendMatch || isGroupMatch
      ? isFriendMatch
        ? ConversationType.friend
        : ConversationType.group_pair
      : ConversationType.friend;

  // Try to find an existing conversation linked to this match.
  const existingWhere = isFriendMatch
    ? { friend_match_id: match.id }
    : isGroupMatch
      ? { group_match_id: match.id }
      : {};

  const existing = await prisma.conversations.findFirst({
    where: existingWhere,
  });

  if (existing) {
    return existing;
  }

  const participantIds = [match.user_a_id, match.user_b_id].filter(
    (id, index, arr) => !!id && arr.indexOf(id) === index,
  );

  const participantsCreate = participantIds.map((userId) => ({
    user: { connect: { id: userId } },
  }));

  const data = {
    type,
    title: null,
    friend_match_id: isFriendMatch ? match.id : null,
    group_match_id: isGroupMatch ? match.id : null,
    participants: {
      create: participantsCreate,
    },
  };

  return prisma.conversations.create({ data });
}

async function backfill() {
  console.log('DATABASE_URL:', databaseUrl);
  console.log('Starting conversations/messages backfill...');

  // Only consider matches that actually have messages.
  const matches = await prisma.matches.findMany({
    include: {
      messages: true,
    },
  });

  let updatedMessages = 0;
  let createdConversations = 0;

  for (const match of matches) {
    if (!match.messages.length) {
      continue;
    }

    console.log(
      `Processing match ${match.id} (type=${match.match_type}), messages=${match.messages.length}`,
    );

    const conversation = await ensureConversationForMatch(match);

    if (match.messages.some((m) => !m.conversation_id)) {
      const result = await prisma.messages.updateMany({
        where: {
          match_id: match.id,
          conversation_id: null,
        },
        data: {
          conversation_id: conversation.id,
        },
      });

      if (result.count > 0) {
        console.log(
          `  Linked ${result.count} message(s) to conversation ${conversation.id}`,
        );
        updatedMessages += result.count;
      }
    }

    // Rough heuristic: if conversation was just created it won't have created_at yet in memory,
    // but we can track via a local counter.
    // Since ensureConversationForMatch either finds or creates, we treat any run as idempotent.
    if (conversation.created_at && conversation.created_at === conversation.updated_at) {
      createdConversations += 1;
    }
  }

  console.log('Backfill complete.');
  console.log('Total messages updated with conversation_id:', updatedMessages);
  console.log('Note: conversations are created only when needed per match.');
}

async function main() {
  try {
    await backfill();
  } catch (e) {
    console.error('Error in backfill-conversations:', e);
  } finally {
    await prisma.$disconnect();
    await pool.end();
  }
}

main();
