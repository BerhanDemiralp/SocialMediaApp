## 1. Backend data and models

- [x] 1.1 Verify or add Prisma models for `friendships`, `groups`, and `group_members` aligned with existing PostgreSQL tables.
- [x] 1.2 Add any necessary Prisma indexes and constraints for friendships (e.g., unique requester/addressee pair, status enum).
- [x] 1.3 Generate and run Prisma migrations if schema changes are required.

## 2. Friendships API

- [x] 2.1 Create `FriendsModule` with controller, service, and repository following existing NestJS conventions.
- [x] 2.2 Implement friend request endpoints (send, accept, reject, cancel) using Supabase Auth user ID.
- [x] 2.3 Implement list endpoints for confirmed friends and pending incoming/outgoing friend requests.
- [x] 2.4 Add validation, error handling, and authorization checks for friendship operations.

## 3. Groups API

- [x] 3.1 Create `GroupsModule` with controller, service, and repository following existing NestJS conventions.
- [x] 3.2 Implement endpoints to create groups and generate invite codes.
- [x] 3.3 Implement endpoints to join group via invite code and leave group.
- [x] 3.4 Implement endpoint to list groups the current user belongs to.
- [x] 3.5 Add validation, error handling, and authorization checks for group operations.

## 4. Integration and tests

- [x] 4.1 Wire new modules into the main NestJS application module and routing.
- [x] 4.2 Add unit and/or integration tests for friendship and group services/controllers.
- [x] 4.3 Verify Supabase Auth guard integration and that all endpoints require authentication.
- [x] 4.4 Update any relevant documentation or API reference to include friends and groups endpoints.
