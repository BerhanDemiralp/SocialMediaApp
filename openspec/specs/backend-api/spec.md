## ADDED Requirements

### Requirement: NestJS Server Setup
The system SHALL run a NestJS server with proper configuration.

#### Scenario: Server starts successfully
- **WHEN** backend application starts
- **THEN** NestJS application bootstraps
- **AND** all modules are initialized
- **AND** ValidationPipe is enabled globally

#### Scenario: Health check endpoint
- **WHEN** client makes GET request to /health
- **THEN** system returns 200 OK with status: healthy

---

### Requirement: Authentication API Endpoints
The system SHALL provide REST endpoints for auth operations via NestJS controllers.

#### Scenario: POST /auth/register
- **WHEN** client sends POST to /auth/register with email and password
- **THEN** new user account is created in Supabase Auth
- **AND** user record is created in users table
- **AND** session token is returned

#### Scenario: POST /auth/login
- **WHEN** client sends POST to /auth/login with credentials
- **THEN** user is authenticated via Supabase
- **AND** session token is returned

#### Scenario: POST /auth/logout
- **WHEN** client sends POST to /auth/logout with valid token
- **THEN** session is invalidated

---

### Requirement: Error Handling
The system SHALL handle errors consistently using NestJS exception filters.

#### Scenario: Validation error response
- **WHEN** client sends invalid input to any endpoint
- **THEN** ValidationPipe returns 400 Bad Request with error details

#### Scenario: Authentication error response
- **WHEN** client makes request without valid token
- **THEN** AuthGuard returns 401 Unauthorized

#### Scenario: Not found endpoint
- **WHEN** client requests non-existent endpoint
- **THEN** NestJS returns 404 Not Found

#### Scenario: Internal server error
- **WHEN** unexpected error occurs in handler
- **THEN** system returns 500 Internal Server Error
- **AND** error is logged (without exposing details to client)

---

### Requirement: Real-time Socket.io Gateway
The system SHALL configure Socket.io Gateway for real-time communication using @nestjs/websockets.

#### Scenario: Socket connection
- **WHEN** client connects via Socket.io
- **THEN** connection is established
- **AND** user session is authenticated

#### Scenario: Socket authentication
- **WHEN** client attempts to connect without valid token
- **THEN** connection is rejected

#### Scenario: Join match room
- **WHEN** authenticated user joins a match room
- **THEN** user receives real-time messages for that match

#### Scenario: Send message
- **WHEN** user sends message via Socket.io
- **THEN** message is broadcast to the match room
- **AND** message is stored in database

---

### Requirement: User Profile API
The system SHALL provide endpoints for profile management via NestJS controllers.

#### Scenario: GET /users/me
- **WHEN** authenticated user requests their profile
- **THEN** user data is returned (username, avatar_url, created_at)

#### Scenario: PATCH /users/me
- **WHEN** authenticated user updates profile fields
- **THEN** changes are persisted
- **AND** updated profile is returned

---

## Conventions

All API design follows conventions from `openspec/config.yaml`:
- REST: Resource-oriented URLs (/api/v1/users, /api/v1/friends)
- Response format: { success: boolean, data: T, error?: { code: string, message: string } }
- Pagination: cursor-based with limit/after or page/per_page
- Versioning: /api/v1/ prefix
- Error handling: NestJS exception filters with HTTP status codes
- Validation: class-validator with DTOs
- Modules: Modular architecture (auth, users, matches, messages modules)
