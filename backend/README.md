## MOMENT Backend (NestJS + Prisma)

This is the backend service for **MOMENT**, a cozy conversation habit app for friends and small social groups.
It is built with **NestJS**, **Prisma**, **PostgreSQL**, and **Supabase Auth/Storage**.

### Tech Stack

- Node.js + TypeScript
- NestJS (REST API + WebSockets)
- Prisma ORM + PostgreSQL
- Supabase (Auth + Storage)
- Socket.io (real-time messaging)

---

## Getting Started

### 1. Install dependencies

From the `backend` directory:

```bash
npm install
```

### 2. Configure environment variables

Create a `.env` file in `backend` based on `.env.example`:

```bash
cp .env.example .env
```

Then update the values:

- `DATABASE_URL` – PostgreSQL connection string (including `connection_limit=1`).
- `SUPABASE_URL` – Your Supabase project URL.
- `SUPABASE_ANON_KEY` – Supabase anon public key (for client/session operations).
- `SUPABASE_SERVICE_ROLE_KEY` – Supabase service role key (for privileged operations if needed).
- `PORT` (optional) – HTTP port for the Nest app (defaults to `3000`).

### 3. Database setup (Prisma + PostgreSQL)

Make sure your PostgreSQL instance is running and `DATABASE_URL` is correct, then run:

```bash
npx prisma migrate dev
npx prisma generate
```

This will create/update the database schema defined in `prisma/schema.prisma` and generate the Prisma client.

---

## Running the app

From the `backend` directory:

```bash
# development
npm run start

# watch mode
npm run start:dev

# production build + run
npm run build
npm run start:prod
```

The app uses the global prefix `api`, so for a local dev server on port `3000`:

- Health check: `GET http://localhost:3000/api/health`
- Auth endpoints: `POST http://localhost:3000/api/auth/register|login|logout`
- User profile: `GET/PATCH http://localhost:3000/api/users/me`

---

## Tests

```bash
# unit tests
npm run test

# e2e tests (if/when added)
npm run test:e2e

# coverage
npm run test:cov
```

Unit tests currently cover:

- `AppController` health/hello routes
- `AuthService` (register/login/logout/validateToken)
- `UsersService` (profile read/update)
- Feature modules as they are added (e.g., friends, groups, daily-questions)

---

## Linting and Formatting

```bash
# run ESLint
npm run lint

# run Prettier
npm run format
```

Please ensure lint passes and code is formatted before committing changes.

---

## WebSocket Gateway

The backend exposes a Socket.io gateway for real-time messaging:

- Namespace: default
- Events:
  - `joinMatch` / `leaveMatch`
  - `sendMessage` (broadcasts `newMessage`)
  - `typing` (broadcasts `userTyping`)

Clients must provide a valid Supabase access token via:

- `socket.handshake.auth.token` **or**
- `Authorization: Bearer <token>` header

Authentication is enforced by `WsAuthGuard`.

---

## API Overview (MVP)

- `POST /api/auth/register` – Email/password + username registration via Supabase + Prisma.
- `POST /api/auth/login` – Email/password login, returns session + user profile.
- `POST /api/auth/logout` – Ends the current session.
- `GET /api/users/me` – Returns the authenticated user’s profile.
- `PATCH /api/users/me` – Updates username / avatar URL (with username uniqueness checks).
