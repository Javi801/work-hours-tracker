# Architecture — Time Balance App

> **Status:** Accepted — layered architecture adopted (see [ADR-001](adr/ADR-001-layered-architecture.md)).  
> Framework not yet selected (see open issue: "tech: set up mobile framework and toolchain").  
> Implementation details will be filled in once the framework decision is made.

---

## Table of Contents

1. [Guiding principles](#1-guiding-principles)
2. [Layered architecture](#2-layered-architecture)
3. [Layer responsibilities](#3-layer-responsibilities)
4. [Folder structure](#4-folder-structure)
5. [Data flow](#5-data-flow)
6. [Local storage strategy](#6-local-storage-strategy)
7. [Background processing](#7-background-processing)
8. [Widget architecture](#8-widget-architecture)
9. [Framework decision](#9-framework-decision)
10. [What this architecture explicitly excludes](#10-what-this-architecture-explicitly-excludes)

---

## 1. Guiding principles

These principles shape every architectural decision:

- **No network layer.** The app has no HTTP client, no API calls, no sockets. If a library brings a network dependency, it is rejected.
- **Timestamps are the source of truth.** No duration or balance is stored — everything is computed from `started_at` / `ended_at`. See [data-model.md](data-model.md).
- **Survive process death.** Any feature that requires the app to be running continuously (e.g. a polling timer) is a design smell. State must be recoverable from persisted timestamps alone.
- **Thin UI layer.** Screens and components contain no business logic. They only render state and dispatch user intent.
- **Testable domain.** The domain layer has zero UI dependencies. It can be tested with plain unit tests and no emulator.
- **One source of state.** A single state container (store or equivalent) is the only source of truth for UI. Local DB is the source of truth for persistence.

---

## 2. Layered architecture

```
┌─────────────────────────────────────────┐
│              Presentation               │  Screens, components, navigation
│  (framework-specific UI + state mgmt)   │
├─────────────────────────────────────────┤
│               Domain                    │  Business logic, use cases, entities
│         (pure, no I/O, no UI)           │
├─────────────────────────────────────────┤
│                Data                     │  Local DB, repositories, CSV I/O
│       (persistence + mapping)           │
└─────────────────────────────────────────┘
         ▲                  ▲
    System services    Platform APIs
  (notifications,      (widgets, OS
   background tasks)    time, locale)
```

Each layer only depends on the layer below it. The domain layer depends on nothing.

---

## 3. Layer responsibilities

### Presentation layer
- Renders UI from state
- Translates user gestures into domain actions (start session, stop break, etc.)
- Subscribes to state changes and re-renders
- Owns navigation logic
- Contains no business rules and no direct DB access

### Domain layer
- Defines entities: `Activity`, `Session`, `Break`, `Goal`, `CustomPeriod`, `TimeBlock`
- Contains use cases: `StartSession`, `StopSession`, `StartBreak`, `ComputeDailyBalance`, etc.
- Computes all derived values (durations, missing/extra hours, period progress)
- Defines repository interfaces (contracts) — implementations live in the data layer
- No framework imports, no I/O, fully unit-testable

### Data layer
- Implements repository interfaces defined by domain
- Manages the local database schema and migrations
- Handles CSV serialization and deserialization
- Maps between DB rows/records and domain entities
- Handles soft deletes, referential integrity, and cascade rules

---

## 4. Folder structure

```
app/mobile/src/
├── components/       # Reusable UI primitives (Button, Card, TimeDisplay, etc.)
├── navigation/       # Route definitions and navigation containers
├── screens/          # One folder per screen (ActivityList, SessionDetail, etc.)
│   └── [screen]/
│       ├── index.tsx         # Screen component
│       └── [screen].test.tsx # Screen-level tests
├── domain/           # ← to be created in Phase 2
│   ├── entities/     # Activity, Session, Break, Goal, etc.
│   ├── usecases/     # StartSession, StopSession, ComputeBalance, etc.
│   └── repositories/ # Repository interfaces (contracts only)
├── services/         # Data layer: DB implementation, CSV, repositories
│   ├── db/           # Schema, migrations, query helpers
│   ├── csv/          # Import and export logic
│   └── notifications/# Local notification scheduling
├── state/            # Global UI state (store slices, selectors, actions)
└── utils/            # Shared utilities: time formatting, date helpers, etc.
```

> `domain/` does not exist yet — it will be created during Phase 2 (core domain design).  
> `services/db/`, `services/csv/` and `services/notifications/` do not exist yet — they will be created during Phase 2/3 as each feature is implemented. Currently `services/` contains only a placeholder.

---

## 5. Data flow

### Starting a session (example)

```
User taps "Start"
    │
    ▼
Screen dispatches StartSessionAction
    │
    ▼
State calls StartSessionUseCase (domain)
    │
    ├─ Validates: activity exists and is active
    ├─ Creates Session entity with started_at = now()
    │
    ▼
SessionRepository.save(session)     ← data layer writes to DB
    │
    ▼
State updated → screen re-renders with active session
```

### Computing elapsed time (example)

```
Screen needs to display elapsed time
    │
    ▼
Reads session.started_at from state
    │
    ▼
Calls formatElapsed(now() - started_at - sumBreaks)
    │                           ↑
    └── Pure computation, no DB call, no timer
```

No timer runs continuously. The UI re-reads and recomputes on each render cycle or on a low-frequency tick (e.g. once per minute) purely for display purposes.

---

## 6. Local storage strategy

> **Decision pending.** The storage engine will be chosen during Phase 1.

### Requirements the storage engine must meet

- Fully offline and embedded (no server process)
- No Google or Firebase dependencies
- Reliable ACID transactions
- Supports migrations for schema evolution
- Works on Android, Huawei/EMUI, and iOS without platform-specific code where possible

### Candidates under consideration

| Option | Notes |
|---|---|
| SQLite (via framework adapter) | Mature, reliable, widely supported |
| Realm | Good mobile ergonomics, local-only mode available |
| WatermelonDB | Designed for React Native, lazy loading |
| Isar | Fast, Flutter-native |
| MMKV + JSON | Simple but limited for relational queries |

The chosen option will be documented here and reflected in `docs/roadmap.md`.

---

## 7. Background processing

The app must avoid continuous background processes to preserve battery (NFR-03).

### Automatic session closing

Sessions are not closed by a background timer polling every second. Instead:

1. When a session starts, a **one-shot local alarm** is scheduled for the closing boundary (midnight or custom day-end).
2. When the alarm fires, the OS wakes the app (or a background task) briefly to write `ended_at = boundary_time` to the DB.
3. A local notification is sent immediately after.

If the alarm fires while the app is killed, the closing is handled on next app launch by checking for sessions with `status: active` and `started_at` before the last closing boundary.

### Widget refresh

The widget reads from the local DB directly. It refreshes:
- When the user opens the app
- When a session starts or stops
- On a low-frequency OS-scheduled interval (platform-dependent minimum)

No background service runs continuously to push updates to the widget.

---

## 8. Widget architecture

The home screen widget is a separate, lightweight surface that shares the local DB with the main app.

```
Main app ──writes──▶ Local DB ◀──reads── Widget
```

- The widget reads session state directly from the DB on each refresh
- Quick actions (start/stop) in the widget write to the DB and request a widget update
- The widget does not maintain its own state — it is always derived from the DB

Platform considerations:
- **Android:** App Widget (XML-based or Jetpack Glance)
- **iOS:** WidgetKit with App Groups for shared DB access

---

## 9. Framework decision

> **Not yet decided.** See issue: "tech: set up mobile framework and toolchain"

### Evaluation criteria

| Criterion | Weight | Notes |
|---|---|---|
| Android + iOS support | Required | Must ship on both |
| Huawei/EMUI compatibility | Required | Cannot depend on Google Play Services |
| Widget support | Required | Both Android and iOS widgets |
| Local DB options | High | Must have a mature, offline-capable option |
| Background task support | High | Needed for auto-close scheduling |
| No forced Google/Firebase deps | Required | Core privacy requirement |
| Community and long-term support | Medium | |
| Developer experience | Medium | |

### Decision record

| Date | Decision | Rationale |
|---|---|---|
| — | Pending | — |

Once decided, this section will be updated with the chosen framework, rejected alternatives, and the rationale.

---

## 10. What this architecture explicitly excludes

The following will never be part of this architecture:

- **HTTP client or network layer** — no requests of any kind
- **Remote database** or any cloud-backed storage
- **Authentication or session tokens**
- **Analytics SDK** (Firebase Analytics, Mixpanel, Amplitude, etc.)
- **Crash reporting that phones home** (Crashlytics, Sentry cloud, etc.)
- **Push notifications** — only local, scheduled notifications
- **Google Play Services APIs** — including Maps, Auth, Drive, GCM/FCM
- **Ad networks or tracking SDKs**
- **Background sync services**
