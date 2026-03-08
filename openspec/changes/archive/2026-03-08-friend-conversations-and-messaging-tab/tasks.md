## 1. Backend friend conversations API

- [x] 1.1 Add or update conversations service helper to create or reuse a `friend`-type conversation between two confirmed friends
- [x] 1.2 Expose friend conversation creation/reuse via HTTP (new endpoint or parameterized existing endpoint) consistent with the conversations specs
- [x] 1.3 Ensure all existing friend-related flows (e.g., Moments, Home/Friends) use the centralized helper for creating or reusing friend conversations
- [x] 1.4 Extend the conversations listing endpoint to support returning only `friend`-type conversations with metadata needed for the Messaging tab
- [x] 1.5 Add or update backend tests covering friend conversation creation, reuse, and listing behavior

## 2. Flutter messaging tab implementation

- [x] 2.1 Add or extend a conversations repository in Flutter to fetch friend conversations (using the backend friend conversations listing contract)
- [x] 2.2 Implement a Messaging tab screen that displays the list of friend conversations with name, avatar, last message snippet, and time
- [x] 2.3 Implement empty, loading, and error states for the Messaging tab according to existing app patterns
- [x] 2.4 Wire navigation so tapping a conversation row opens `ChatScreen(conversationId, ...)`
- [x] 2.5 Add or update Flutter tests (widget/unit as appropriate) for the Messaging tab and navigation

## 3. Integration and cleanup

- [x] 3.1 Integrate the Messaging tab into the main app shell or navigation structure
- [ ] 3.2 Verify that friend conversations created from all flows (Home/Friends, Moments, Messaging) reuse the same `conversation_id`
- [x] 3.3 Update any relevant documentation or comments to reference the Messaging tab and friend conversations behavior
- [ ] 3.4 Perform manual QA for friend conversations across flows and adjust as needed

