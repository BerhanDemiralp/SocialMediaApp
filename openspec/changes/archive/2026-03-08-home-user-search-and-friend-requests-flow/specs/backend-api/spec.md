## ADDED Requirements

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

