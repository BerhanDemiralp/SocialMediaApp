## 1. Backend data and models

- [ ] 1.1 Verify or add Prisma models for `friendships`, `groups`, and `group_members` aligned with existing PostgreSQL tables.
- [ ] 1.2 Add any necessary Prisma indexes and constraints for friendships (e.g., unique requester/addressee pair, status enum).
- [ ] 1.3 Generate and run Prisma migrations if schema changes are required.

## 2. Friendships API

- [ ] 2.1 Create `FriendsModule` with controller, service, and repository following existing NestJS conventions.
- [ ] 2.2 Implement friend request endpoints (send, accept, reject, cancel) using Supabase Auth user ID.
- [ ] 2.3 Implement list endpoints for confirmed friends and pending incoming/outgoing friend requests.
- [ ] 2.4 Add validation, error handling, and authorization checks for friendship operations.

## 3. Groups API

- [ ] 3.1 Create `GroupsModule` with controller, service, and repository following existing NestJS conventions.
- [ ] 3.2 Implement endpoints to create groups and generate invite codes.
- [ ] 3.3 Implement endpoints to join group via invite code and leave group.
- [ ] 3.4 Implement endpoint to list groups the current user belongs to.
- [ ] 3.5 Add validation, error handling, and authorization checks for group operations.

## 4. Integration and tests

- [ ] 4.1 Wire new modules into the main NestJS application module and routing.
- [ ] 4.2 Add unit and/or integration tests for friendship and group services/controllers.
- [ ] 4.3 Verify Supabase Auth guard integration and that all endpoints require authentication.
- [ ] 4.4 Update any relevant documentation or API reference to include friends and groups endpoints.

