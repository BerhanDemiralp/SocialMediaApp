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

### Requirement: List user conversations
The backend API SHALL expose an endpoint that returns a unified list of conversations for the authenticated user, including friend and group match conversations.

#### Scenario: Fetch conversations list
- **WHEN** an authenticated client calls the conversations listing endpoint
- **THEN** the system SHALL return a paginated list of conversations where the user is a participant
- **AND** each item SHALL include `conversation_id`, conversation type, participant summary, last message snippet, and last message timestamp.

### Requirement: Fetch conversation messages
The backend API SHALL expose an endpoint to fetch paginated messages for a given `conversation_id`.

#### Scenario: Fetch paginated messages for conversation
- **WHEN** an authenticated client calls the messages endpoint for a specific `conversation_id` with pagination parameters
- **THEN** the system SHALL return messages scoped to that `conversation_id` only
- **AND** SHALL include pagination metadata so the client can request additional pages.

### Requirement: Real-time conversation channels
The backend API and real-time layer SHALL use `conversation:<id>` as the canonical channel naming scheme for chat-related events.

#### Scenario: Subscribe to conversation channel
- **WHEN** a client subscribes to `conversation:<id>` via Socket.io
- **THEN** the backend SHALL deliver new message events and relevant conversation updates for that `conversation_id` on that channel
- **AND** SHALL NOT require the client to know the underlying match identifier.

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
