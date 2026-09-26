# Unified User Presentation

## Purpose

Define shared user identity, relationship actions, and consistent conversation presentation across the app.

## Requirements

### Requirement: Shared user identity presentation
The app SHALL use a shared identity renderer for search and request cards, group members, direct conversation identities, message sender avatars, profile headers, and Moment participant identities. Layout variants SHALL share avatar interpretation and fallback behavior.

#### Scenario: Same preset across surfaces
- **WHEN** the same user's identity is shown in a group, a message, and a profile header
- **THEN** the configured preset SHALL show the same symbol and color on each surface
- **AND** a missing or failed image SHALL render a visible fallback instead of an empty circle

#### Scenario: Context remains visible
- **WHEN** identity is displayed in a conversation or Moment
- **THEN** the containing surface SHALL retain its preview, timing, permissions, and navigation metadata
- **AND** a group entity SHALL retain group-specific presentation

### Requirement: Consistent relationship action policy
All relationship cards SHALL derive actions from the same relationship state. Self SHALL have no social actions; unrelated users SHALL expose Add friend; outgoing requests SHALL expose close-icon cancellation; incoming requests SHALL expose Accept and a close-icon rejection action; friends SHALL open chat by tapping the card and expose Remove friend in an overflow menu, without a separate Message button.

#### Scenario: Incoming and outgoing cancellation use different operations
- **WHEN** the user selects the close icon on an incoming request
- **THEN** the app SHALL reject that incoming request using its request ID
- **AND** selecting close-icon cancellation on an outgoing request SHALL cancel that outgoing request using its request ID

#### Scenario: Rejected or cancelled request permits another request
- **WHEN** an incoming request is rejected or an outgoing request is cancelled successfully
- **THEN** all relationship cards for that target SHALL show Add friend without requiring a screen reload

#### Scenario: Unknown relationship is not treated as unrelated
- **WHEN** relationship data is loading or its initial fetch fails
- **THEN** cards SHALL NOT enable friendship mutations based on an assumed unrelated state
- **AND** failed loading SHALL expose a retry action

### Requirement: Central relationship state and mutation ownership
The app SHALL maintain one normalized relationship source per authenticated account and SHALL route social mutations through that source. A successful mutation SHALL update all local representations and relevant list projections.

#### Scenario: Accept in one surface updates another
- **WHEN** a request is accepted from a group member card
- **THEN** the incoming request SHALL disappear from Home's incoming list
- **AND** search/group cards SHALL expose friend actions
- **AND** Messages SHALL refresh its friend/conversation data

#### Scenario: Concurrent controls for the same person
- **WHEN** a social mutation is pending for a target user
- **THEN** conflicting actions for that target SHALL be disabled on every mounted card
- **AND** repeated taps SHALL NOT send duplicate requests
- **AND** actions for other users SHALL remain available

#### Scenario: Mutation fails
- **WHEN** the server rejects or fails a relationship mutation
- **THEN** the last confirmed relationship SHALL remain visible
- **AND** the user SHALL receive one non-blocking error notice and be able to retry

#### Scenario: Refresh fails after mutation succeeds
- **WHEN** a social mutation succeeds but its reconciliation fetch fails
- **THEN** the successful relationship transition SHALL remain visible
- **AND** the app SHALL NOT incorrectly report that the completed mutation failed

#### Scenario: Stale responses cannot undo a mutation
- **WHEN** a relationship fetch started before a successful mutation finishes afterward
- **THEN** its older data SHALL NOT overwrite the confirmed mutation result

#### Scenario: Account changes while requests are pending
- **WHEN** a user signs out or switches accounts during a fetch or mutation
- **THEN** old relationship state SHALL be cleared
- **AND** late responses SHALL NOT mutate the new account's state or navigate on its behalf

### Requirement: Shared conversation opening behavior
Friend card taps SHALL use a common guarded conversation-opening flow. Existing conversation rows SHALL navigate using their supplied conversation IDs and retain server-enforced access/writability rules.

#### Scenario: Friend card opens chat once
- **WHEN** the user taps a friend's card repeatedly while opening is pending
- **THEN** the app SHALL create or reuse that friend's conversation once and open one chat route

#### Scenario: Historical conversation remains accessible
- **WHEN** a conversation is listed by the backend after its friendship changes
- **THEN** tapping it SHALL open its existing conversation ID without attempting to establish a new friendship
- **AND** the chat SHALL honor its writable or read-only state

### Requirement: Accessible responsive user controls
Shared user presentation SHALL remain usable on a 320 logical-pixel-wide screen and with text scaled to 200 percent. Actions SHALL have at least 48 by 48 logical-pixel touch targets and descriptive labels or tooltips.

#### Scenario: Long name and incoming actions on narrow screen
- **WHEN** a long username and Accept / close-icon rejection controls appear at narrow width with large text
- **THEN** the layout SHALL keep controls to the right of the identity, wrapping within that area without overflow or hiding an action

#### Scenario: Feedback does not block interaction
- **WHEN** a user action produces informational or error feedback
- **THEN** the shared notice SHALL allow touches through to the screen and SHALL NOT take input focus
- **AND** rebuilding the card SHALL NOT show the notice again

#### Scenario: Immediate chat navigation
- **WHEN** a user taps a confirmed friend's card
- **THEN** the chat surface SHALL open without waiting on conversation creation or first refreshing the conversation list
- **AND** known conversation IDs SHALL be reused without an ensure call
- **AND** an unknown conversation ID SHALL resolve inside the chat surface with error and retry handling
- **AND** resolved IDs SHALL be isolated by authenticated account

#### Scenario: Standard card dimensions and compact actions
- **WHEN** user cards are displayed at the same available width and normal text scale
- **THEN** all relationship states SHALL share the same standard card dimensions
- **AND** Accept SHALL use a compact visual button with at least a 48-pixel touch target
- **AND** cancel/reject actions SHALL use close icons with descriptive tooltips
- **AND** large text SHALL be allowed to expand the layout without hiding actions

#### Scenario: Returning from chat retains the conversation list
- **WHEN** the conversation list refreshes after returning from chat within the same account
- **THEN** existing conversation rows SHALL stay visible until updated previews arrive
- **AND** the list SHALL NOT temporarily replace them with friend cards
- **AND** changing accounts SHALL still hide the previous account's conversations

### Requirement: Consistent compact chat message presentation
Direct, group, and Moment chats SHALL use shared content-sized message bubbles with timestamps to the right of the message text. Own messages SHALL omit sender name and avatar.

#### Scenario: Consecutive messages from another sender
- **WHEN** another user sends consecutive messages
- **THEN** only the first message in that sequence SHALL show their name and avatar
- **AND** continuation bubbles SHALL retain alignment with the first bubble
- **AND** adjacent messages in the sequence SHALL use a reduced 2-pixel gap

#### Scenario: Sender changes
- **WHEN** the sender changes between messages
- **THEN** the new sequence SHALL retain an 8-pixel separation
- **AND** only the first bubble of a sequence SHALL have a sharper sender-side upper corner
- **AND** other corners SHALL use an 8-pixel radius

#### Scenario: Message length varies
- **WHEN** a message is short or long
- **THEN** its bubble SHALL size to its content up to the available width
- **AND** longer text SHALL wrap while its timestamp stays on the right

### Requirement: Conversation timestamps align beside the preview
The Messages tab SHALL place each conversation's last-message time or date on the right side of the row, vertically centered beside its identity and preview.

#### Scenario: Direct and group conversation rows
- **WHEN** a conversation has a last-message timestamp
- **THEN** its formatted time or date SHALL appear beside the row rather than below it
