## Why

MOMENT already has a well-defined backend and domain model, but there is no production-ready mobile client that makes the daily ritual feel effortless. Without a polished Flutter implementation, users cannot reliably experience daily questions, pair matching, and lightweight chats in a cohesive, habit-forming way. This change introduces the first end‑to‑end Flutter app experience so that real users can use MOMENT on iOS and Android.

## What Changes

- Build a Flutter mobile app using the existing tech stack conventions (Clean Architecture, repository pattern, Riverpod/Bloc for state).
- Implement authentication flows wired to Supabase Auth (sign up, login, logout, session handling).
- Create the core app shell: navigation, theming, error/loading states, and basic settings/profile surfaces.
- Implement the daily question experience: answer flow, viewing friends’ answers as cards, and replying from a card into chat.
- Implement the daily “Moment” pairing experience for friends and groups, including countdown/active window UI.
- Implement the core chat experience: message list, composer, read-only vs writable states, and basic safety affordances (block/report entry points).
- Integrate real-time updates via Socket.io and Supabase where appropriate (new messages, match status).
- Integrate push notifications using FCM/APNS for key events (new match, new message, daily question reminder).
- Establish analytics/telemetry hooks for key behavioral events (answer question, start chat, complete Moment).

## Capabilities

### New Capabilities
- `mobile-app-shell`: Overall Flutter app shell including routing, navigation, theming, auth gating, and error/loading handling.
- `daily-question-experience`: User flow for receiving, answering, and reviewing the daily question, including cards for friends’ answers and entry into chats.
- `moment-matching-experience`: UX for scheduled pair matching (“Moment”) in friends and groups modes, including timers, status states, and match outcomes.
- `chat-messaging-experience`: Core chat UI and client behavior, including message list, composer, temporary vs permanent chats, and basic moderation entry points.
- `notification-and-engagement`: Push notifications and lightweight in-app nudges that reinforce the daily ritual without creating infinite scroll or high-pressure streaks.

### Modified Capabilities
- `<existing-name>`: <what requirement is changing>

## Impact

- **Flutter codebase**
  - Introduces a new Flutter app package (or substantially expands the existing one) following Clean Architecture with presentation/domain/data layers.
  - Adds Riverpod/Bloc state management setup for auth, daily question, matching, and chat features.
  - Adds routing/navigation configuration, theming, and app‑wide error/loading UX patterns.
- **Backend & APIs**
  - Uses existing NestJS endpoints for auth, daily questions, matching, and chat where available; may require minor adjustments for mobile‑friendly usage (pagination, batching, error codes).
  - Validates that real-time channels (Socket.io/Supabase) expose the events needed by the app; future backend changes might be required if gaps are discovered.
- **Supabase & Notifications**
  - Integrates Supabase Auth and Storage from the mobile client (sessions, profile, avatars).
  - Connects FCM/APNS for push delivery and defines which events trigger notifications.
- **Product & UX**
  - Establishes the baseline mobile experience for the habit loop (daily question → Moment pairing → conversation).
  - Provides a foundation for future experiments such as mini games and additional prompts while respecting constraints (no infinite feeds, cozy/non‑dating tone).

