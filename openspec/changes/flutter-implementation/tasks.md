## 1. Flutter app shell and foundation

- [x] 1.1 Scaffold Flutter app structure (packages, main entry, environment config)
- [x] 1.2 Implement Clean Architecture folder layout (presentation/domain/data) and feature module boundaries
- [x] 1.3 Set up routing with guarded routes for auth vs main shell
- [x] 1.4 Implement shared theming, typography, and basic components for loading, empty, and error states

## 2. Authentication and session management

- [ ] 2.1 Integrate Supabase Auth SDK and configure environments
- [ ] 2.2 Implement sign up, login, logout, and password reset flows
- [ ] 2.3 Implement persistent session handling and token refresh
- [ ] 2.4 Wire auth state into app shell routing (unauth → auth flow, auth → main shell)

## 3. Daily question experience

- [ ] 3.1 Implement repositories and DTOs for fetching the daily question and submitting answers
- [ ] 3.2 Build UI for presenting today’s question and capturing the user’s answer
- [ ] 3.3 Enforce “answer before viewing friends’ answers” rule in the UI
- [ ] 3.4 Implement friends’ answers card list, including empty states and navigation into chat

## 4. Moment matching experience

- [ ] 4.1 Implement APIs and repositories for retrieving Moment schedule and current match state
- [ ] 4.2 Build UI to display upcoming, active, and expired Moment states (friends and groups)
- [ ] 4.3 Implement navigation from Moment entry points into the relevant chat view
- [ ] 4.4 Handle success and expiration states in the UI according to specs

## 5. Chat and real-time messaging

- [ ] 5.1 Implement chat repositories and data models for messages, threads, and participants
- [ ] 5.2 Integrate Socket.io (and/or Supabase real-time) for receiving new messages and status updates
- [ ] 5.3 Build chat UI (message list, composer, send status indicators)
- [ ] 5.4 Implement handling for temporary vs permanent chats, including visual indicators and state transitions

## 6. Notifications and engagement

- [ ] 6.1 Integrate FCM/APNS via Flutter plugins and configure platform-specific projects
- [ ] 6.2 Implement notification handling and deep linking for daily question, matches, and messages
- [ ] 6.3 Implement in-app engagement surfaces that respect cozy, low-pressure constraints (no infinite feeds)
- [ ] 6.4 Add soft streak-style reinforcement where appropriate without harsh penalties or public metrics

## 7. Safety, moderation, and polish

- [ ] 7.1 Add block and report entry points within chats and route actions to backend APIs
- [ ] 7.2 Implement global error handling, logging, and basic crash reporting hooks
- [ ] 7.3 Add basic analytics/telemetry events for key flows (answer question, start chat, complete Moment)
- [ ] 7.4 Perform UX polish pass for empty states, loading states, and accessibility basics
