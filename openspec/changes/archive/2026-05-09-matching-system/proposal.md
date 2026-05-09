## Why

MOMENT needs a reliable scheduled pairing ritual that turns friendships and group membership into timely, low-pressure conversations. This change defines the daily "Moment" matching behavior so users can see active pairings on Home, receive timely nudges, and keep conversation history after the active window ends.

## What Changes

- Add a daily scheduled pairing system that pairs eligible users at a predefined time, such as 5:00 PM.
- Notify both matched users when a Moment starts and send one reminder if a participant remains inactive during the active period.
- Keep each Moment active for 1 hour from the scheduled time.
- Track Moment success using message activity within the 1-hour window: at least 10 total combined messages and at least one message from each participant.
- Expire unsuccessful Moments after the 1-hour window while keeping the chat accessible from Messages.
- Add Friends Daily Pairing, which selects one friend per day and uses a permanent, writable conversation automatically.
- Add Group Daily Pairing, which selects a random non-friend group member, starts as temporary, and becomes permanent writable only when both users opt in after the window.
- Make non-opted-in group match history read-only after the active window.
- Show active pairings prominently on the Home page while the Moment is active.

## Capabilities

### New Capabilities

- `moment-matching`: Daily scheduled pair creation, active-window lifecycle, notifications, reminders, success/expiration rules, friends pairing behavior, group pairing behavior, opt-in permanence, and Home visibility for active pairings.

### Modified Capabilities

- `messages`: Add requirements for writable versus read-only conversation states after Moment expiration, and ensure expired Moment chats remain accessible in Messages.
- `friends-and-groups`: Add requirements for selecting eligible friend and group pairing candidates, excluding friends from group discovery matches, and applying mutual opt-in rules for group match permanence.
- `database-schema`: Add or refine data requirements for scheduled Moment records, active/expired/successful status tracking, reminder state, per-user opt-in state, and links to reusable conversations.
- `backend-api`: Add API requirements for exposing active Home pairings, match state, opt-in actions, and Moment lifecycle data to clients.

## Impact

- Backend scheduling or worker process for daily pair creation, expiration checks, and inactivity reminders.
- NestJS modules/services/controllers for matching lifecycle, candidate selection, opt-in handling, and Home/Messages API surfaces.
- Prisma schema and migrations for Moment lifecycle records, notification/reminder state, participant state, and conversation associations.
- Socket.io and notification integration for active Moment updates, new match notifications, and reminders.
- Flutter Home page updates to display active pairings and current Moment state.
- Flutter Messages updates to respect writable/read-only states while preserving expired match history.
- Push notification integrations through FCM/APNS for match start and reminder delivery.
