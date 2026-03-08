## ADDED Requirements

### Requirement: Friend relationships map to reusable direct conversations
The system SHALL support reusable direct conversations between friends that are independent of daily matching windows.

#### Scenario: Start conversation with friend outside daily matching
- **WHEN** two users are in an accepted friend relationship
- **AND** one user chooses to start a conversation with the other from any flow (for example Home/Friends or the Messaging tab)
- **THEN** the system either finds an existing `friend`-type conversation between those two users or creates a new one
- **AND** future entries into that friendship chat reuse the same `conversation_id`

#### Scenario: Daily friends matching reuses the same conversation
- **WHEN** two friends are paired via the daily friends matching (“Moment”) flow
- **AND** a `friend`-type conversation already exists between them
- **THEN** the matching flow uses the existing `conversation_id` for the chat instead of creating a new one
- **AND** messages sent during the daily match are added to the same conversation history

