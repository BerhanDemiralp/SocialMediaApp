# Verification: unify-user-cards-and-relationships

## Summary

| Dimension | Result |
| --- | --- |
| Completeness | 21/21 tasks completed, including the explicitly documented live-verification limitation in task 5.4 |
| Correctness | Implementation found for all 7 requirements across the 3 delta specs; 45 frontend tests pass |
| Coherence | Shared Users feature, account-scoped normalized state, centralized actions/navigation, composable identity UI; old implementations removed |

## Baseline and migration

Before the refactor, the frontend suite had 25 passing tests and 3 failures in `home_messages_screen_test.dart` because Messages accessed an uninitialized Supabase singleton directly. Messages now obtains account/relationship data through shared providers; all three tests pass.

Preserved the working-tree fixes for group details access, friend chat navigation, preset/image avatar fallback, outgoing cancellation, group incoming responses, and non-blocking feedback. No backend endpoints or database schemas were changed.

Moved the existing user/search/friend/request/profile/conversation data clients and repositories into `frontend/lib/features/users/data/`. Removed `UserActionTile`, the Home-owned avatar implementation, separate Home friends/request providers, and the separate Messages friends fetch. Screens now compose shared cards and identity variants.

## Requirement evidence

| Requirement | Implementation | Verification |
| --- | --- | --- |
| Shared user identity presentation | `frontend/lib/features/users/presentation/user_identity_view.dart:16`, `app_avatar.dart:48`, `data/user_identity_adapters.dart`; adopted in Chat, Profile, Moments, Groups, Home, Messages | Preset/invalid/failed-image fallback tests; identity override propagation across avatar/compact/header/sender-name variants; inspected rendered cards |
| Consistent relationship action policy | `frontend/lib/features/users/presentation/user_card.dart:53` and `domain/user_relationship.dart:3` | Incoming accept/decline, outgoing cancel/resend, self/unknown states, overflow Remove friend, both-theme narrow-layout tests |
| Central relationship state and mutation ownership | `frontend/lib/features/users/presentation/user_relationships_controller.dart:15` | All transitions and request IDs, per-target locks, independent targets, refresh errors, missing request-ID retry, stale snapshots, account reset/disposal, multiple mounted cards and Messages updates |
| Shared conversation opening behavior | `frontend/lib/features/users/presentation/user_conversations.dart:24` | Repeated open requests call ensure once; account switch discards pending navigation; known read-only history bypasses ensure; group member -> chat -> back to group details |
| Accessible responsive user controls | `frontend/lib/features/users/presentation/user_card.dart:53`, `frontend/lib/core/widgets/app_notice.dart:9` | All relationship states at 320 px and 200% text scale in both app themes; minimum primary target size; touch-through notices preserve focus and replace rather than queue |
| Manage incoming and outgoing friend requests from Home | `frontend/lib/features/home/presentation/home_friends_screen.dart` | Search send/cancel/resend; shared request projections and operation locks; incoming/outgoing ID selection and transition tests |
| Group members use shared user cards | `frontend/lib/features/groups/presentation/group_members_screen.dart` | Group accept/decline/cancel/resend, failure retry, duplicate prevention, details/chat/back navigation; invite/leave controls retained by code inspection |

Profile editing publishes an identity override and invalidates identity-dependent projections in `frontend/lib/features/home/presentation/profile_screen.dart:238`. Account reloads deliberately hide retained conversation data in `frontend/lib/features/home/presentation/home_messages_screen.dart:28`; a dedicated test verifies that the old account's contact is absent while the next response is pending.

## Checks executed

- `flutter test --dart-define=CAPTURE_USER_CARDS=true`: 45 passed, including controller, screen, navigation, notice, registration, and opt-in visual-capture tests.
- `flutter analyze`: no issues.
- `flutter build web`: production JavaScript build succeeded; Wasm dry run succeeded. This is a compile check, not a configured deployment or live login test.
- `git diff --check`: no whitespace errors.
- `openspec validate unify-user-cards-and-relationships --strict`: valid.
- Visual review: opened `frontend/build/verification/user-cards.png`, rendered at 390 logical pixels using the app's light theme. Verified visible names/presets, all action labels, overflow entry, spacing, and self state. Automated layout checks additionally cover the dark theme and larger text. The screenshot is an ignored build artifact and can be regenerated with the opt-in test.

## Issues and limits

### Critical

None found.

### Warning: live authenticated acceptance checks not executed

No dedicated live test accounts or authenticated device session were used. Search -> request -> group response -> Messages/chat, cancel -> resend, error recovery, and back navigation were exercised with deterministic repository doubles in widget tests. The group invite/leave backend interaction and real cross-device state refresh remain unverified against a running backend.

Before a release, run the app with two test accounts and exercise those flows, including leaving a group and editing a profile. This is the explicit live-verification limitation recorded for task 5.4; the implementation and local automated verification are complete.

### Suggestions

None required for this change. Cross-device real-time friendship subscriptions and full public profile screens remain outside the approved scope.

## Assessment

Implementation is complete and locally verified. Ready for archive with the live-backend/device verification limit noted above. Archived after the final local verification below; not deployed.

## User review follow-up (2026-09-26)

- Shared cards now place controls to the right of identity; narrow screens wrap only the action area. Rendered `frontend/build/verification/user-cards.png` reviewed in the actual light theme.
- The Home shell preloads the account-scoped conversation list. Known-ID card taps skip ensure and pre-navigation reload. New conversations open the friend-chat route immediately, resolve there with retry, and cache the ID per account. Chat routes have no transition animation; authentication boolean selection avoids unnecessary router recreation. No profile route is invoked by this flow.
- Tests cover horizontal geometry, zero ensure/reload for known IDs, immediate chat surface while ensure is pending, duplicate taps, late-response isolation after account change, ID caching/reset, and group-details -> chat -> back.
- Full frontend suite: 48 passing; live authenticated device/network timing remains unverified. First message retrieval still requires a backend response.

## Return-from-chat flash regression

Reproduced with a delayed conversation-list response after popping chat: the existing preview disappears and friend cards replace conversation rows. The revision dependency was marking same-account refreshes as reloads, triggering the account-isolation display guard. Revision updates now invalidate the provider as refreshes; account changes still reload and hide old data. Background refreshes no longer insert a progress bar that shifts the rows. A frame-by-frame regression test checks retained previews, absence of replacement cards/progress bars, and eventual updated previews. The test failed before the fix.

Compact-action review: cancellation/rejection tests now use close icons and verify disabled state during requests; friend-state tests verify overflow availability and absence of a Message button. Shared card taps still open the existing chat route.

## Final archive verification (2026-09-26)

- Full frontend suite: 53 tests passed.
- Flutter analysis: no issues.
- Final UI includes compact close-icon request controls, card-tap chat navigation, Friends list, grouped sender identities, own-message identity omission, inline timestamps, content-sized bubbles, reduced sequence spacing, 8px rounded corners, and right-aligned conversation dates.
- Card dimensions are equal at normal text scale across relationship states at widths 320, 390, and 600. Large text may increase height for accessibility.
- Delta specs were updated to the final user-approved behavior and synced into three main capabilities. The touched Home/Friends main spec's old ADDED Requirements header was normalized to Requirements.
- Global spec validation also found legacy failures in 11 untouched capabilities; these files are outside this change.
- Live backend/device verification remains unperformed; no backend schema or migration changes.

- Production Flutter web build completed successfully (including Wasm dry run).
