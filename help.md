Given where we are, there are a few very natural “next changes” you could take on. At this point the backend is basically a clean platform; we can choose what slice of product to make real first.

Here are 4 strong candidates, in dependency order:

---

**1) Message Persistence & History**

Right now Socket.io broadcasts messages but doesn’t store them. This is the smallest “finish what we started” change.

- **Goal**: Persist chat messages to the `messages` table and add a simple history endpoint.
- **Scope**:
  - Extend the WebSocket `sendMessage` flow to write to `messages`.
  - Add `GET /matches/:matchId/messages` (or similar) to fetch history.
  - Basic tests to confirm DB writes + retrieval.
- **Why first**:
  - Tightens the loop on what you’ve already built (gateway + schema).
  - Very visible for debugging the app later (you can see chats in DB).

---

**2) Friendships & Groups Basics**

This unlocks the “social graph” that everything else depends on.

- **Goal**: CRUD for friendships + group membership.
- **Scope**:
  - Friend request / accept / reject endpoints using `friendships` table.
  - Basic groups: create group, join/leave via invite code.
  - List my friends / my groups.
- **Why**:
  - Daily questions, matching, and games all need a concept of who’s connected to whom.
  - Also surfaces more of your schema (`friendships`, `groups`, `group_members`).

---

**3) Daily Question + Answers MVP**

This is the core ritual of MOMENT and relatively self-contained.

- **Goal**: Endpoints to drive the “question of the day” flow.
- **Scope**:
  - Admin-ish endpoints to create daily questions (`daily_questions`).
  - User endpoints:
    - Get today’s question.
    - Submit answer → writes `user_answers`.
    - List my answers, maybe friends’ answers stubbed for now.
- **Why**:
  - Gives the app a daily heartbeat.
  - Uses more schema without needing matching logic yet.

---

**4) Matching Engine (Moment Scheduling)**

This is more complex but central to the product vision.

- **Goal**: Implement daily pairing logic and record matches.
- **Scope**:
  - A simple cron-like endpoint or job you can trigger manually:
    - For each user, pick a friend or group member and create a `matches` record.
  - Expose endpoints:
    - List my current/past matches.
    - Maybe “mark match as successful/expired” stub.
- **Why**:
  - Connects the social graph, messages, and daily ritual into a concrete “Moment”.

---

If we sketch the dependency graph:

```text
Auth + Users   (done)
      │
      ▼
Friendships/Groups ───► Matching (Moments)
      │                      │
      ▼                      ▼
Daily Questions + Answers  Messages + History (partially done)
```

Given that:

- If you want **small / close to current work** → do **Message Persistence & History** next.
- If you want to **unlock social features** → do **Friendships & Groups Basics** next.
- If you want to **feel the product ritual** quickly → do **Daily Question + Answers MVP** next.
- If you’re excited about **matching logic** → that comes best after friendships/groups.

Which of these feels most exciting / important to you right now? Once you pick one, we can stay in explore mode and sketch a concrete change outline (proposal + rough spec) for it, without writing any code yet.
