## Context

The MOMENT backend, data model, and domain concepts already exist, but there is no end-to-end Flutter client that exposes the daily ritual (daily question → Moment pairing → conversation) on iOS and Android. This change introduces a production-ready Flutter app implemented with Clean Architecture, connecting to the existing NestJS + PostgreSQL + Supabase stack.

The design must support:
- Friends mode and groups mode, each with its own matching behavior.
- Daily question flows that unlock friends’ answers only after the user answers.
- Time-bounded “Moment” pairings with clear status and completion behavior.
- Lightweight, safe chat centered on ongoing conversations, not feeds or discovery.

The Flutter client will follow a layered structure (presentation / domain / data) with repositories mediating between UI and backend APIs. State management will use Riverpod or Bloc (feature-level providers/cubits), and navigation will use a declarative router (e.g., `go_router`) to keep flows predictable.

## Goals / Non-Goals

**Goals:**
- Deliver a functional Flutter MVP for MOMENT covering auth, daily question, Moment matching, and chat.
- Align with existing project conventions: Clean Architecture, repository pattern, strongly typed models.
- Provide a cohesive app shell with navigation, theming, and basic settings/profile surfaces.
- Integrate Supabase Auth, real-time events, and push notifications (FCM/APNS) for key moments.
- Make it easy to iterate on future experiences (mini games, experiments) within the same architectural patterns.

**Non-Goals:**
- Offline-first support beyond basic in-memory caching and retry of transient failures.
- Fully custom design system beyond Material 3 theming and a small set of custom components.
- Rich media messaging (voice notes, images, reactions) in the initial MVP.
- Complex recommendation/algorithmic matching or public discovery of users/groups.
- Deep analytics instrumentation beyond a small set of high-signal events.

## Decisions

1. **Architecture: Clean Architecture with feature modules**
   - **Decision:** Organize the Flutter app into feature modules (auth, onboarding, daily-question, moment-matching, chat, notifications, profile/settings), each with `presentation`, `domain`, and `data` layers.
   - **Rationale:** Matches project conventions, keeps business logic isolated from UI, and allows backend contracts to evolve with minimal UI changes.

2. **State management: Riverpod (preferred) or Bloc per feature**
   - **Decision:** Use Riverpod for most stateful flows (auth state, daily question, current matches, chats). For more complex flows (e.g., multi-step onboarding), Bloc/Cubit is acceptable where a finite-state machine is clearer.
   - **Rationale:** Riverpod integrates cleanly with Flutter, scales well with feature modules, and is already a recommended pattern in the project context.

3. **Navigation: Declarative router (go_router) with guarded routes**
   - **Decision:** Use `go_router` (or similar) to define top-level routes: splash, auth, main shell (tabs for Home, Messages, Profile), and nested routes for question details, match details, and chat.
   - **Rationale:** Declarative routing keeps deep links, back behavior, and guarded routes (auth vs unauth) explicit and testable.

4. **Networking & data access: Repository pattern over generated API client**
   - **Decision:** Implement per-feature repositories (e.g., `AuthRepository`, `QuestionRepository`, `MomentRepository`, `ChatRepository`, `NotificationRepository`) that wrap HTTP/Socket.io/Supabase clients and expose domain-level methods.
   - **Rationale:** Repositories encapsulate transport details and allow backend changes without rewriting UI; they also support mocking in tests.

5. **Real-time behavior: Socket.io + Supabase subscriptions**
   - **Decision:** Use Socket.io (or compatible gateway) for chat and match state changes, with Supabase real-time or database polling as a fallback where needed.
   - **Rationale:** Aligns with backend tech choices; keeps UX responsive when new messages arrive or match status changes.

6. **Notifications: FCM/APNS integration via Flutter plugins**
   - **Decision:** Integrate FCM/APNS using a standard Flutter plugin, mapping notification types to in-app events (daily question reminder, new match, new message). Handle routing from notifications into the correct screen.
   - **Rationale:** Push notifications are critical for the daily habit loop; using well-supported plugins reduces complexity.

7. **Error handling & UX: Centralized patterns**
   - **Decision:** Define shared widgets for loading states, empty states, and error surfaces (snackbars/banners/dialogs). Repositories return typed error objects; presentation maps them to user-friendly messages.
   - **Rationale:** Ensures consistent, cozy UX and avoids ad-hoc error handling scattered across screens.

## Risks / Trade-offs

- **Real-time complexity:** Coordinating Socket.io events, Supabase subscriptions, and local state (e.g., read status, message order) can introduce race conditions and subtle bugs.  
  - *Mitigation:* Clearly define event contracts in specs, centralize event handling in a small number of classes, and add integration tests where possible.

- **Notification routing edge cases:** Users can tap notifications from cold start, background, or foreground states, leading to inconsistent navigation if routing is not carefully handled.  
  - *Mitigation:* Implement a single notification handler that normalizes payloads into navigation intents; test flows for each app lifecycle state.

- **Time zone and scheduling issues:** Daily questions and Moment windows depend on correct local time handling and may be confusing if time zones are mismanaged.  
  - *Mitigation:* Treat server time as source of truth, use consistent time libraries, and surface clear UI around active windows and expiration.

- **Scope creep in the initial app:** It will be tempting to add mini games, advanced personalization, or rich media before the core habit loop is robust.  
  - *Mitigation:* Keep the MVP focused on the daily question → Moment → chat loop; track potential extensions as separate changes.

- **Backend contract assumptions:** The frontend may assume certain API shapes or real-time events that don’t yet exist.  
  - *Mitigation:* Document assumptions in specs, collaborate with backend to close gaps, and design repositories to tolerate partial functionality with graceful degradation.

## Migration Plan

- Introduce the Flutter app behind feature flags or internal builds first (e.g., TestFlight/internal tracks).
- Start with friends mode and basic chat before enabling groups mode and more complex flows.
- Roll out notifications gradually: daily question reminder first, then match and message notifications.
- Monitor crash reports and key behavioral metrics; iterate before broad release.

## Open Questions

- Which backend endpoints and event contracts are already finalized vs still experimental?
- What minimum set of profile fields is required for an MVP (beyond username and avatar)?
- How strict should we be about enforcing the 1-hour Moment window in the client vs server?
- Which countries/time zones will be targeted initially (to test scheduling assumptions)?

