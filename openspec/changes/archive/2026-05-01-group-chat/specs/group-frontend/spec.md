## ADDED Requirements

### Requirement: Group chat access from group surfaces
The mobile app SHALL let current group members open the persistent group chat for a group from appropriate group surfaces.

#### Scenario: Open group chat from group details
- **WHEN** an authenticated user views a group they currently belong to
- **THEN** the app SHALL provide an action to open that group's chat
- **AND** activating the action SHALL navigate to the chat screen using the group's persistent `conversation_id`

### Requirement: Leave group clears frontend group chat state
The mobile app SHALL remove local access to a group's chat when the authenticated user leaves that group.

#### Scenario: Leave group removes cached chat entry
- **WHEN** the user leaves a group successfully from the Group Management surface
- **THEN** the app SHALL remove the group from the displayed groups list
- **AND** SHALL remove that group's chat conversation from local conversation state
- **AND** SHALL prevent navigation to that group chat from stale UI state
