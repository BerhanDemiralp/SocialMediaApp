## 1. Project Setup

- [x] 1.1 Create NestJS project: `nest new backend`
- [x] 1.2 Install dependencies (@nestjs/prisma, @prisma/client, @nestjs/websockets, @nestjs/platform-socket.io, socket.io, @supabase/supabase-js, class-validator, class-transformer, cors, dotenv)
- [x] 1.3 Install devDependencies (prisma, @types/*, eslint, prettier)
- [x] 1.4 Configure TypeScript (tsconfig.json) - follow NestJS conventions
- [x] 1.5 Configure ESLint and Prettier (follows config.yaml conventions)

## 2. Database Setup

- [x] 2.1 Initialize Prisma: `npx prisma init`
- [x] 2.2 Create Prisma schema with all tables (users, friendships, groups, group_members, messages, matches, daily_questions, user_answers, games)
- [x] 2.3 Configure database connection in schema.prisma with connection_limit=1
- [x] 2.4 Run initial migration: `npx prisma migrate dev`
- [x] 2.5 Generate Prisma client: `npx prisma generate`
- [x] 2.6 Create PrismaModule and PrismaService

## 3. Supabase Configuration

- [x] 3.1 Create Supabase project
- [x] 3.2 Configure environment variables (.env)
- [x] 3.3 Set up Supabase client in backend (create supabase.service.ts)
- [x] 3.4 Configure connection pooling (connection_limit=1)

## 4. NestJS Server Setup

- [x] 4.1 Create main.ts with app bootstrap
- [x] 4.2 Set up ValidationPipe with class-validator
- [x] 4.3 Enable CORS for Flutter app
- [x] 4.4 Create health check controller (GET /health)
- [x] 4.5 Set up global exception filter
- [x] 4.6 Test server starts successfully

## 5. Authentication Module

- [x] 5.1 Create auth module: `nest g module auth`
- [x] 5.2 Create auth controller (src/auth/auth.controller.ts)
- [x] 5.3 Create auth service (src/auth/auth.service.ts)
- [x] 5.4 Implement register endpoint (POST /auth/register)
- [x] 5.5 Implement login endpoint (POST /auth/login)
- [x] 5.6 Implement logout endpoint (POST /auth/logout)
- [x] 5.7 Create auth guard using Supabase
- [x] 5.8 Add request validation with class-validator DTOs

## 6. Users Module

- [x] 6.1 Create users module: `nest g module users`
- [x] 6.2 Create users controller (src/users/users.controller.ts)
- [x] 6.3 Create users service (src/users/users.service.ts)
- [x] 6.4 Implement get current user endpoint (GET /users/me)
- [x] 6.5 Implement update profile endpoint (PATCH /users/me)
- [x] 6.6 Create users repository

## 7. Socket.io Gateway

- [x] 7.1 Create events gateway: `nest g gateway events`
- [x] 7.2 Configure Socket.io with @nestjs/websockets
- [x] 7.3 Implement WebSocket authentication guard
- [x] 7.4 Implement connection/disconnection handlers
- [x] 7.5 Create match room join/leave functionality
- [x] 7.6 Set up message event handlers (send, receive, typing)

## 8. Testing

- [x] 8.1 Write unit tests for auth service
- [x] 8.2 Write unit tests for users service
- [x] 8.3 Test API endpoints with Postman/curl
- [x] 8.4 Test Socket.io connection
- [x] 8.5 Verify database operations

## 9. Documentation & Final Setup

- [x] 9.1 Add README with setup instructions
- [x] 9.2 Document environment variables
- [x] 9.3 Create .env.example file
- [x] 9.4 Verify lint passes
- [x] 9.5 Test full stack integration (backend + database)
