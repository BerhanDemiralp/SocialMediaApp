## Why

MOMENT requires foundational infrastructure before any features can be built. Without user authentication, database schema, and basic API structure, the team cannot implement core features like Daily Questions, Mini Games, or Scheduled Matching. Starting with infrastructure enables iterative feature development.

The project context is defined in `openspec/config.yaml` which includes:
- Tech stack: Flutter (frontend), Node.js + TypeScript + NestJS (backend), PostgreSQL (database)
- Non-Goals: Public group discovery, algorithmic matching, media-rich chat, video/audio calls, etc.
- Goals: User auth, profiles, friends, groups, daily questions, mini games, scheduled matching, real-time messaging

## What Changes

- Set up NestJS project with modular architecture
- Set up PostgreSQL database with Prisma ORM
- Implement user authentication (Supabase Auth)
- Create core database schema (users, friendships, groups, messages, daily_questions, games, matches)
- Configure real-time infrastructure (Socket.io Gateway)
- Create basic API endpoints for auth and health checks
- Configure connection pooling (connection_limit=1 for Supabase)

## Capabilities

### New Capabilities

- `user-auth`: User registration, login, logout, and session management via Supabase Auth
- `database-schema`: Core data models including users, friendships, groups_questions, games, and, messages, daily matches
- `backend-api`: NestJS server with modular architecture, guards, interceptors, and Socket.io Gateway

### Modified Capabilities

- None yet - this is the initial infrastructure change

## Impact

- New directory: `backend/` with NestJS application
- New directory: `database/` with Prisma schema and migrations
- Dependencies added: @nestjs/core, @nestjs/common, @prisma/client, @nestjs/websockets, socket.io, @supabase/supabase-js
- New environment variables required for Supabase connection
- Connection pooling configured with connection_limit=1
