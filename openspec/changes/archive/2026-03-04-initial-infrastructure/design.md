## Context

MOMENT is a new social app requiring backend infrastructure before feature development can begin. The current state has no code - only product specifications exist in `openspec/config.yaml`. This design establishes the foundational layer: database, authentication, API, and real-time communication.

**Stakeholders:** Flutter mobile app developers, backend developers

## Goals / Non-Goals

**Goals:**

- Establish PostgreSQL database with Prisma ORM following the defined schema
- Implement Supabase Auth for user authentication
- Create NestJS REST API with proper error handling, guards, and interceptors
- Configure Socket.io Gateway for real-time messaging
- Set up project structure following NestJS modular architecture conventions

**Non-Goals:**

- Business logic features (Daily Questions, Games, Matching) - these are core MVP features to be implemented separately
- Frontend Flutter implementation
- Push notification infrastructure (FCM/APNS)
- Production deployment automation
- Public group discovery
- Algorithmic matching
- Media-rich chat (images, videos)
- Video or audio calls
- End-to-end encryption
- Offline message support

## Decisions

### 1. Supabase over self-hosted PostgreSQL

**Decision:** Use Supabase for PostgreSQL, Auth, Storage, and Real-time subscriptions.

**Rationale:**

- Faster MVP development with managed services
- Built-in authentication reduces custom auth code
- Real-time subscriptions can leverage Supabase's Postgres changes feed
- Free tier sufficient for early development

**Alternative considered:** Self-hosted PostgreSQL + custom auth + Socket.io - rejected due to higher operational complexity

**Implementation note (development environment):**

- For local development, a Dockerized PostgreSQL instance (`localhost:5432/moment`) is used as the Prisma datasource because the current network cannot reach the Supabase Postgres host/port directly.
- The Prisma schema is identical to what will run on Supabase Postgres; only the `DATABASE_URL` differs between dev and hosted environments.
- In production/staging environments, Supabase Postgres SHOULD be used as the primary database once connectivity is available.

---

### 2. Prisma ORM over raw SQL / query builders

**Decision:** Use Prisma with TypeScript for database operations.

**Rationale:**

- Type-safe database access with full TypeScript support
- Automatic migrations and schema management
- Clear schema definition in `schema.prisma`
- Active community and good documentation

**Alternative considered:** Knex.js - rejected for less type safety; raw SQL - rejected for maintainability

**Implementation note (Prisma 7 adapter):**

- Prisma 7 requires either an `adapter` or an `accelerateUrl` when constructing a `PrismaClient`. The backend uses the official `@prisma/adapter-pg` with a shared `pg.Pool` built from `DATABASE_URL`.
- `PrismaService` extends `PrismaClient` and passes the `adapter` into the constructor. This keeps the rest of the application code unchanged while satisfying Prisma’s new initialization requirements.

---

### 3. NestJS for backend framework

**Decision:** Use NestJS for the backend framework.

**Rationale:**

- Modular architecture with built-in dependency injection
- Built-in support for guards, interceptors, filters - great for cross-cutting concerns
- Excellent integration with Socket.io via @nestjs/platform-socket.io
- Built-in testing utilities with Jest
- Swagger/OpenAPI documentation support
- Strong TypeScript support out of the box
- Follows the same conventions as config.yaml

**Alternative considered:** Express.js - rejected in favor of NestJS for better structure

---

### 4. class-validator for request validation

**Decision:** Use class-validator + class-transformer for validating incoming API requests.

**Rationale:**

- Native NestJS integration via ValidationPipe
- Decorator-based validation - clean and readable
- Works seamlessly with DTOs (Data Transfer Objects)
- Already in project conventions (from config.yaml)

**Alternative considered:** Zod - rejected in favor of class-validator for better NestJS integration

---

### 5. Socket.io for real-time communication

**Decision:** Use Socket.io with NestJS Gateway for real-time messaging.

**Rationale:**

- Native NestJS integration via @nestjs/websockets
- More control over connection handling
- Better documented for chat use cases
- Room-based architecture maps well to match conversations
- Can integrate with Supabase later if needed

**Alternative considered:** Supabase Realtime - would require Supabase Pro for reliable delivery

**Implementation note (message persistence):**

- The initial gateway implementation handles connection, authentication, room join/leave, and message/typing events. Messages are broadcast in real time but are not yet persisted to the `messages` table.
- A follow-up change SHOULD extend the gateway to write messages via Prisma so that chat history is stored according to the database schema spec.

---

### 6. Connection Pooling with Prisma

**Decision:** Configure Prisma connection pooling for Supabase.

**Rationale:**

- Supabase uses PgBouncer internally - requires connection_limit=1 to avoid pool conflicts
- Prevents "too many connections" errors
- Works seamlessly with NestJS PrismaService

---

### 7. UUID for user-facing IDs

**Decision:** Use UUID v4 for all user-facing ID fields.

**Rationale:**

- Follows project convention (from config.yaml)
- No enumeration attacks
- Works well with Supabase

---

## Risks / Trade-offs

| Risk                                | Impact | Mitigation                                                |
| ----------------------------------- | ------ | --------------------------------------------------------- |
| Supabase rate limits on free tier   | Medium | Plan for migration to self-hosted if needed               |
| Socket.io + Supabase dual real-time | Medium | Evaluate consolidating to one solution post-MVP           |
| Schema changes requiring migrations | High   | Use Prisma migrations carefully; version control schema   |
| Authentication coupling to Supabase | Medium | Abstract auth behind service interface for potential swap |
| NestJS learning curve               | Low    | Team has experience with NestJS; use official docs        |

---

## Migration Plan

1. Create NestJS project with `nest new backend`
2. Install dependencies: @prisma/client, @nestjs/prisma, @nestjs/websockets, @nestjs/platform-socket.io, socket.io
3. Create initial Prisma schema and run migrations
4. Set up Supabase project and configure environment variables
5. Implement NestJS modules (auth, users, messages, matches)
6. Add Socket.io Gateway for real-time messaging
7. Create auth guard using Supabase
8. Add ValidationPipe with class-validator
9. Test locally with Flutter mock client

**Rollback:** Schema changes can be reverted via Prisma migration files. Supabase provides point-in-time restore.

---

## Open Questions

- Should we use Supabase client directly on Flutter instead of custom REST API for some operations?
- What's the expected message volume to size Socket.io accordingly?
- Should we use Supabase Realtime instead of Socket.io for message delivery?
