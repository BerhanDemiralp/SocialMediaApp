## ADDED Requirements

### Requirement: Account-owned mobile registrations
The system SHALL register Android installations for this MVP (existing iOS support is retained but its setup and acceptance are deferred) through authenticated APIs and associate each provider registration with at most one current account.

#### Scenario: Register and refresh
- **WHEN** an authenticated user grants permission or the provider registration changes
- **THEN** the installation SHALL be upserted for that account without duplicate active ownership

#### Scenario: Logout or account switch
- **WHEN** an installation logs out or switches accounts
- **THEN** its previous registration SHALL be detached or superseded
- **AND** late callbacks and notification taps SHALL NOT operate as the previous account
- **AND** removal SHALL NOT delete another account's installation

### Requirement: Non-blocking permission and configuration handling
The app SHALL request notification permission deliberately and remain usable when permission is denied or mobile push is unconfigured. Browser push SHALL be outside this change.

#### Scenario: Permission unavailable
- **WHEN** permission is denied or the platform is unsupported/unconfigured
- **THEN** authentication, chat and matching SHALL remain available without repeated prompts or startup failure

### Requirement: Moment notification events
The system SHALL durably schedule a start event for each participant on Moment activation and reminder events according to existing due-time and zero-message eligibility.

#### Scenario: Activation or reminder retries
- **WHEN** an activation or eligible reminder is processed again
- **THEN** no duplicate logical event SHALL be created for the same Moment, kind and recipient
- **AND** activation/reminder state and event persistence SHALL remain consistent after process failure

#### Scenario: Reminder becomes stale
- **WHEN** a queued reminder's Moment expires or receives messages before dispatch
- **THEN** that reminder SHALL be suppressed

### Requirement: New-message notification events
The system SHALL schedule notifications for authorized participants other than the sender after message persistence in direct, group-pair and persistent group chats.

#### Scenario: Successful or failed message creation
- **WHEN** a message is committed through a supported HTTP or socket path
- **THEN** corresponding notification intents SHALL be committed durably
- **AND** the sender SHALL NOT receive their own message notification
- **WHEN** message creation is rejected or rolled back
- **THEN** no notification intent for that message SHALL remain

#### Scenario: Access changes before delivery
- **WHEN** a recipient leaves a group or otherwise loses conversation access before dispatch
- **THEN** delivery to that recipient SHALL be skipped

### Requirement: Resilient bounded delivery
External push calls SHALL execute outside message/matching transactions through a worker with atomic claims, bounded retries, expiry and per-installation delivery tracking.

#### Scenario: Partial or transient failure
- **WHEN** the provider temporarily fails for one installation
- **THEN** accepted message and matching operations SHALL remain successful
- **AND** only unfinished eligible deliveries SHALL be retried within configured bounds
- **AND** exhausted or expired work SHALL be recorded without infinite retries

#### Scenario: Invalid registration or worker restart
- **WHEN** the provider confirms an invalid registration
- **THEN** that registration SHALL be disabled without treating unrelated payload errors as invalid registrations
- **WHEN** a worker stops during an attempt
- **THEN** unfinished work SHALL become claimable after its lease expires
- **AND** delivery metrics SHALL NOT equate provider acceptance with device receipt

### Requirement: Safe notification content and interaction
Notifications SHALL use generic lock-screen text and versioned destination data. Notification data SHALL NOT bypass account identity or server authorization.

#### Scenario: Open from background or terminated state
- **WHEN** a user taps a notification
- **THEN** the app SHALL wait for auth/router readiness, require the intended account and resolve authorized conversation metadata
- **AND** it SHALL open the existing conversation with its current writable/read-only state
- **AND** duplicate events or an already-visible destination SHALL NOT stack duplicate routes

#### Scenario: Missing access or wrong account
- **WHEN** a destination is unavailable or the current account is not the intended recipient
- **THEN** the app SHALL NOT open or create a replacement conversation
- **AND** it SHALL provide safe non-blocking feedback as appropriate

#### Scenario: Foreground conversation
- **WHEN** a notification arrives while its conversation is visible
- **THEN** no redundant foreground alert SHALL be shown
- **WHEN** a different conversation receives a foreground notification
- **THEN** at most one in-app notice SHALL appear per event
- **AND** background OS notifications SHALL NOT be duplicated by local display logic

### Requirement: Verifiable mobile rollout
The change SHALL include configuration and migration guidance, automated tests and separately tracked Android device acceptance results; iOS acceptance is outside this MVP.

#### Scenario: Delivery acceptance
- **WHEN** notification readiness is evaluated
- **THEN** foreground, background, cold-start taps, denied permission, account switching, revoked access and provider failures SHALL be covered
- **AND** unavailable credentials or device checks SHALL remain explicitly incomplete
