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

---

## ADDED Requirements (Friends & User Search)

### Requirement: User search endpoint
The backend API SHALL provide an authenticated endpoint to search for users by username for the purpose of sending friend requests.

#### Scenario: Search users by username
- **WHEN** an authenticated client sends `GET /users/search?query={q}&limit={N}` with a non-empty `query`
- **THEN** the system SHALL return a 200 OK response with a list of user records matching the query (excluding the current user)
- **AND** each record SHALL include at least `id`, `username`, and `avatar_url`.

#### Scenario: Enforce search limit
- **WHEN** the client includes a `limit` value greater than the maximum allowed
- **THEN** the system SHALL clamp the limit to the maximum configured value
- **AND** SHALL return at most that many records.

#### Scenario: Empty query rejected
- **WHEN** the client omits `query` or sends an empty/whitespace-only value
- **THEN** the system SHALL return a 400 Bad Request indicating that query is required.

### Requirement: Friend request lifecycle API
The backend API SHALL expose endpoints to manage the friend request lifecycle: send, accept, reject, cancel, and list requests.

#### Scenario: Send friend request
- **WHEN** an authenticated client sends `POST /friends/requests` with a valid target user identifier
- **THEN** the system SHALL create a pending friend request between the authenticated user and the target user
- **AND** SHALL return a representation of the request.

#### Scenario: List incoming requests
- **WHEN** an authenticated client sends `GET /friends/requests/incoming`
- **THEN** the system SHALL return all pending friend requests where the authenticated user is the addressee.

#### Scenario: List outgoing requests
- **WHEN** an authenticated client sends `GET /friends/requests/outgoing`
- **THEN** the system SHALL return all pending friend requests where the authenticated user is the requester.

#### Scenario: Accept friend request
- **WHEN** an authenticated client sends `PATCH /friends/requests/{id}/accept`
- **AND** the authenticated user is the addressee of the request
- **THEN** the system SHALL mark the friendship as accepted
- **AND** the users SHALL appear in each other’s confirmed friend lists.

#### Scenario: Reject friend request
- **WHEN** an authenticated client sends `PATCH /friends/requests/{id}/reject`
- **AND** the authenticated user is the addressee of the request
- **THEN** the system SHALL reject or remove the pending request
- **AND** the users SHALL NOT be considered friends.

#### Scenario: Cancel outgoing friend request
- **WHEN** an authenticated client sends `PATCH /friends/requests/{id}/cancel`
- **AND** the authenticated user is the requester of the pending request
- **THEN** the system SHALL cancel the request
- **AND** the addressee SHALL no longer see it as pending.

## ADDED Requirements

### Requirement: List friend conversations for authenticated user
The backend API SHALL provide an endpoint for listing the authenticated user’s direct friend conversations, suitable for powering the Messaging tab.

#### Scenario: List friend conversations with metadata
- **WHEN** the client calls the friend conversations listing endpoint as an authenticated user
- **THEN** the API returns only conversations where the user is a participant and the conversation type is `friend`
- **AND** each conversation item includes `id`, conversation type, the other participant’s user identifier, display name, and avatar URL (if available)
- **AND** each conversation item includes the last message text (or a suitable preview) and the last message timestamp
- **AND** results are ordered with the most recently active conversation first
- **AND** the endpoint supports pagination so the client can load additional conversations as needed

### Requirement: Create or reuse direct friend conversation
The backend API SHALL provide an endpoint that creates or reuses a direct `friend` conversation between two friends on demand.

#### Scenario: Reuse existing friend conversation
- **WHEN** the client calls the create-or-reuse friend conversation endpoint with a friend user identifier
- **AND** a `friend`-type conversation already exists between the authenticated user and that friend
- **THEN** the API responds with the existing conversation record instead of creating a new one
- **AND** the response includes the existing `conversation_id` that can be used to open ChatScreen

#### Scenario: Create new friend conversation when none exists
- **WHEN** the client calls the create-or-reuse friend conversation endpoint with a friend user identifier
- **AND** no `friend`-type conversation exists between the two users
- **THEN** the API creates a new `friend`-type conversation using the unified conversations model
- **AND** the new conversation is linked to both users as participants
- **AND** the API responds with the new conversation record including its `conversation_id`
