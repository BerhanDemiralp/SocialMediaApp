# MOMENT Backend + OpenSpec (Spec‑Driven Workflow)

This repo contains the **MOMENT** backend (NestJS + Prisma) and its **OpenSpec** change artifacts, implemented using a spec‑driven workflow.

The core feature currently implemented via OpenSpec is **1:1 match messaging (`message-v1`)**:

- Real‑time messaging over **Socket.io**.
- Persistent storage in the **`messages`** table.
- HTTP endpoint for **message history per match**.

---

## Repository Structure

- `backend/` – NestJS backend service
  - `src/`
    - `auth/` – Supabase‑backed auth (register, login, guards).
    - `users/` – User profile API + service + tests.
    - `events/` – WebSocket gateway (`EventsGateway`) with:
      - `joinMatch`, `leaveMatch`
      - `sendMessage` → persists + broadcasts `newMessage`
      - `typing` → broadcasts `userTyping`
    - `matches/` – HTTP message history for a match:
      - `GET /api/matches/:matchId/messages`
    - `prisma/` – Prisma client module/service.
    - `supabase/` – Supabase client wrapper.
  - `prisma/`
    - `schema.prisma` – DB schema (users, matches, messages, etc.).
  - `scripts/`
    - `test-socket.js` – Manual Socket.io test for messaging.
  - `README.md` – Backend‑specific docs (install, run, etc.).

- `openspec/` – OpenSpec change artifacts
  - `changes/message-v1/` *(now archived under `openspec/changes/archive/`)*:
    - `proposal.md` – Why + scope for 1:1 messaging.
    - `design.md` – Design decisions and architecture.
    - `specs/messages/spec.md` – Requirements & scenarios for messaging.
    - `tasks.md` – Implementation checklist used to drive changes.

---

## Tech Stack

- **Runtime:** Node.js, TypeScript
- **Framework:** NestJS (REST + WebSockets)
- **DB/ORM:** PostgreSQL + Prisma
- **Auth:** Supabase (JWT + user storage)
- **Real‑time:** Socket.io gateway
- **Specs/Workflow:** OpenSpec (`spec-driven` schema)

---

## Getting Started

### 1. Start PostgreSQL (Docker)

Example (already in use locally):

```bash
docker run -d \
  --name moment-dev \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=16582 \
  -e POSTGRES_DB=moment \
  postgres:16
```

> Adjust password/DB name as needed; keep `DATABASE_URL` in sync.

### 2. Configure backend environment

From `backend/`:

```bash
cp .env.example .env
```

Set at least:

- `DATABASE_URL` – Postgres connection string (e.g. `postgres://postgres:16582@localhost:5432/moment`)
- `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` – from your Supabase project.

### 3. Install dependencies

```bash
cd backend
npm install
```

### 4. Run Prisma migrations & generate client

```bash
cd backend
npx prisma migrate dev
npx prisma generate
```

### 5. Run the backend

```bash
cd backend
npm run start:dev
```

The app uses the global prefix `api`, so for port `3000`:

- Health: `GET http://localhost:3000/api/health` (or root `/`).
- Auth: `POST http://localhost:3000/api/auth/register|login|logout`
- Users: `GET/PATCH http://localhost:3000/api/users/me`

---

## 1:1 Messaging System Overview (`message-v1`)

### Data Model

Defined in `backend/prisma/schema.prisma`:

- `matches`
  - `id`, `user_a_id`, `user_b_id`, `match_type`, `status`, timestamps…
  - Represents a **1:1 match** (who is paired with whom).
- `messages`
  - `id`, `match_id`, `sender_id`, `content`, `created_at`
  - Represents a **single chat message** in a given match.

Every message is tied to one `match` and one `sender`.

### WebSocket Real‑Time Messaging

**Gateway:** `backend/src/events/events.gateway.ts`

- `joinMatch`
  - Event: `joinMatch`
  - Guard: `WsAuthGuard` (valid Supabase token required).
  - Action: socket joins room `match:<matchId>`.

- `sendMessage`
  - Event: `sendMessage`
  - Payload: `{ matchId: string; content: string }`
  - Flow:
    1. `WsAuthGuard` authenticates the socket; attaches `client.user`.
    2. Gateway loads the `match` by `id`.
    3. Validates that `client.user.id` is either `user_a_id` or `user_b_id`.
    4. Persists a row in `messages` via Prisma.
    5. Emits `newMessage` with the stored record to room `match:<matchId>`.
    6. Returns an ack `{ event: 'messageSent', data: <stored message> }`.
  - If user is not a participant:
    - Throws a `WsException` and **skips persistence + broadcast**.

- `typing`
  - Event: `typing`
  - Broadcasts `userTyping` with `{ userId, isTyping }` to the match room.

**Visual flow (authorized send):**

```text
Client (User A) -- sendMessage --> EventsGateway -- Prisma.messages.create --> DB
                      │                                     │
                      └----------- newMessage --------------┘
                              (to room "match:<matchId>")
```

### HTTP Message History

**Controller:** `backend/src/matches/matches-messages.controller.ts`

- Route: `GET /api/matches/:matchId/messages`
- Guard: `AuthGuard` (JWT via Supabase).
- Flow:
  1. `AuthGuard` validates token, sets `req.user`.
  2. Controller loads `match` by `matchId`.
  3. Ensures `req.user.id` is `user_a_id` or `user_b_id`.
  4. Reads messages from `messages`:
     - `where: { match_id: matchId }`
     - `orderBy: { created_at: 'asc' }`
     - `take: limit` (default 50, overrideable via `?limit=N`).
  5. Returns the array of messages.
  6. Non‑participant → `403 Forbidden`, no data leaked.

---

## OpenSpec Workflow (Spec‑Driven)

This repo uses OpenSpec to design and implement features as **changes**.

### Change lifecycle (example: `message-v1`)

1. **Status & instructions**
   - `openspec status --change "message-v1" --json`
   - `openspec instructions apply --change "message-v1" --json`

2. **Artifacts (spec‑driven)**
   - `proposal.md` – WHY + scope.
   - `design.md` – HOW (architecture, decisions).
   - `specs/**/*.md` – requirements and scenarios.
   - `tasks.md` – concrete implementation steps.

3. **Implementation**
   - Code changes in `backend/` driven by `tasks.md` (checklist).
   - Each completed task is marked `- [x]` in `tasks.md`.

4. **Verification & archive**
   - Once artifacts + tasks are complete, the change can be archived:
     - e.g. moved under `openspec/changes/archive/YYYY-MM-DD-message-v1/`.

---

## Testing

From `backend/`:

```bash
npm test
```

Current test coverage includes:

- `AppController` basics.
- `AuthService` behavior (register/login/logout/token validation).
- `UsersService` (profile read/update).
- Messaging:
  - `EventsGateway`:
    - Authorized `sendMessage` persists + emits.
    - Unauthorized user cannot send for another user’s match.
  - `MatchesMessagesController`:
    - Authorized user can read messages for their match (with `limit`).
    - Non‑participant gets `Forbidden`.

---

## Manual Messaging Verification

**WebSocket:**

- Use `backend/scripts/test-socket.js`:
  - Set `matchId` to a real match row.
  - Set `TOKEN` env var to a Supabase access token (`export TOKEN=...`).
  - Run: `node scripts/test-socket.js`.
  - Observe:
    - `joinMatch` ack.
    - `sendMessage` ack (`messageSent`).
    - `newMessage` events.

**HTTP:**

- `GET /api/matches/:matchId/messages`
  - Headers: `Authorization: Bearer <access_token>`
  - Query: `?limit=50` (optional).
  - Response: ordered list of messages for that match.

---

## Next Steps / Future Work

- Build a dedicated **matching system** that:
  - Automatically creates `matches` between compatible users.
  - Manages match lifecycle (active / expired / successful).
- Extend messaging:
  - Group chats (beyond 1:1).
  - Read receipts, typing indicators persistence.
  - Cursor‑based pagination for large histories.

All new work should ideally follow the **OpenSpec change** pattern (proposal → design → specs → tasks → implementation → archive).

