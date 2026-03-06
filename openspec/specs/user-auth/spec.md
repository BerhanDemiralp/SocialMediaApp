## ADDED Requirements

### Requirement: User Registration
The system SHALL allow new users to register with email and password through Supabase Auth.

#### Scenario: Successful registration
- **WHEN** user submits valid email and password (min 8 characters)
- **THEN** user account is created in Supabase Auth
- **AND** user record is created in the users table with default avatar
- **AND** session token is returned to client

#### Scenario: Registration with duplicate email
- **WHEN** user submits an email that already exists
- **THEN** system returns an error indicating email is already registered

#### Scenario: Registration with invalid email format
- **WHEN** user submits an improperly formatted email
- **THEN** system returns validation error for invalid email format

---

### Requirement: User Login
The system SHALL allow registered users to authenticate with email and password.

#### Scenario: Successful login
- **WHEN** user submits correct email and password
- **THEN** system returns valid session token
- **AND** user profile data is accessible

#### Scenario: Login with incorrect password
- **WHEN** user submits correct email but wrong password
- **THEN** system returns authentication error

#### Scenario: Login with non-existent email
- **WHEN** user submits email that has no account
- **THEN** system returns authentication error

---

### Requirement: User Session Management
The system SHALL maintain user sessions and handle token refresh.

#### Scenario: Valid session
- **WHEN** user makes request with valid session token
- **THEN** request is processed with user context

#### Scenario: Expired session
- **WHEN** user makes request with expired token
- **THEN** system returns 401 unauthorized
- **AND** client is prompted to re-authenticate

#### Scenario: Token refresh
- **WHEN** session token is near expiration (within 5 minutes)
- **THEN** system automatically refreshes the token
- **AND** new token is provided to client

---

### Requirement: User Logout
The system SHALL allow users to end their session.

#### Scenario: Successful logout
- **WHEN** user initiates logout
- **THEN** session is invalidated in Supabase Auth
- **AND** client clears stored token

---

### Requirement: User Profile
The system SHALL store and retrieve user profile information.

#### Scenario: Get own profile
- **WHEN** authenticated user requests their profile
- **THEN** system returns username, avatar_url, created_at

#### Scenario: Update username
- **WHEN** authenticated user updates their username
- **THEN** username is updated in the users table
- **AND** new username is reflected immediately

#### Scenario: Update avatar
- **WHEN** authenticated user uploads a new avatar
- **THEN** avatar is stored in Supabase Storage
- **AND** avatar_url is updated in users table

---

## Conventions

All code follows the conventions defined in `openspec/config.yaml`:
- TypeScript: camelCase for variables, PascalCase for classes
- API responses: { success: boolean, data: T, error?: { code: string, message: string } }
- Validation: Zod for request validation
- Database: snake_case naming, UUID for user-facing IDs
