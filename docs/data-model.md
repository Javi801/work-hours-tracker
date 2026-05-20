# Data Model — Time Balance App

> **Status:** Draft — framework and storage engine not yet selected.  
> Field types are described in logical terms. Concrete types (e.g. `Int64`, `UUID`, `ISO8601`) will be confirmed once the storage solution is chosen.

---

## Table of Contents

1. [Entities overview](#1-entities-overview)
2. [Activity](#2-activity)
3. [Session](#3-session)
4. [Break](#4-break)
5. [Goal](#5-goal)
6. [Custom Period](#6-custom-period)
7. [Time Block](#7-time-block)
8. [Relationships](#8-relationships)
9. [Computed values](#9-computed-values)
10. [Design constraints](#10-design-constraints)

---

## 1. Entities overview

```
Activity
  ├── Session (1..*)
  │     └── Break (0..*)
  ├── Goal (0..*)
  ├── CustomPeriod (0..*)
  └── TimeBlock (0..*)
```

All entities are local. No entity is ever synchronized, uploaded, or shared.

---

## 2. Activity

An activity is the top-level unit the user tracks time against.

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | UUID | ✅ | Unique identifier, generated on creation |
| `name` | String | ✅ | Display name (e.g. "Work", "Thesis") |
| `icon` | String | ❌ | Icon identifier or emoji |
| `color` | String | ❌ | Hex color code (e.g. `#4A90D9`) |
| `status` | Enum | ✅ | `active` · `archived` · `deleted` |
| `created_at` | Timestamp | ✅ | Creation date and time |
| `updated_at` | Timestamp | ✅ | Last modification date and time |

### Notes
- `status: deleted` is a soft-delete marker. Deleted activities are excluded from all views but retained until the user explicitly purges data.
- `name` must be non-empty and unique among active + archived activities.
- `color` defaults to a system-assigned palette color if not set.

### Relationships
- Has many **Sessions**
- Has many **Goals**
- Has many **CustomPeriods**
- Has many **TimeBlocks**

---

## 3. Session

A session is a single worked time block belonging to one activity.

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | UUID | ✅ | Unique identifier |
| `activity_id` | UUID | ✅ | Foreign key → Activity |
| `started_at` | Timestamp | ✅ | When the session began |
| `ended_at` | Timestamp | ❌ | When the session ended. `null` while active |
| `status` | Enum | ✅ | See states below |
| `created_at` | Timestamp | ✅ | Record creation time |
| `updated_at` | Timestamp | ✅ | Last modification time |

### Session states

| State | Description |
|---|---|
| `active` | Session is currently running (`ended_at` is null) |
| `closed_manual` | Stopped by the user |
| `closed_auto` | Closed automatically at a period boundary |
| `edited` | Manually edited after initial creation |

### Notes
- `ended_at` must always be greater than `started_at`.
- A session with `status: active` and no `ended_at` survives app restarts — duration is computed on read.
- Multiple sessions belonging to different activities may be `active` simultaneously.
- Two sessions belonging to the **same activity** may not overlap in time.

### Relationships
- Belongs to one **Activity**
- Has many **Breaks**

---

## 4. Break

A break is a pause within a session. Its duration is deducted from the session's worked time.

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | UUID | ✅ | Unique identifier |
| `session_id` | UUID | ✅ | Foreign key → Session |
| `started_at` | Timestamp | ✅ | When the break began |
| `ended_at` | Timestamp | ❌ | When the break ended. `null` while active |
| `name` | String | ❌ | Optional label (MVP 3: "Lunch", "Tea break") |
| `category` | String | ❌ | Optional category tag (MVP 3) |
| `created_at` | Timestamp | ✅ | Record creation time |

### Notes
- Only one break per session may be `active` (i.e. have `ended_at = null`) at any time. See FR-14.
- A break must be fully contained within its parent session:
  - `break.started_at >= session.started_at`
  - `break.ended_at <= session.ended_at` (when session is closed)
- Two breaks within the same session must not overlap.
- `name` and `category` are reserved for MVP 3 but the fields should be present from the start to avoid migrations.

### Relationships
- Belongs to one **Session**

---

## 5. Goal

A goal defines a time target for an activity over a specific period type.

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | UUID | ✅ | Unique identifier |
| `activity_id` | UUID | ✅ | Foreign key → Activity |
| `period_type` | Enum | ✅ | `daily` · `weekly` · `monthly` |
| `target_minutes` | Integer | ✅ | Target duration in minutes |
| `day_overrides` | JSON / Map | ❌ | Per-weekday overrides: `{ "MON": 540, "SAT": 0 }` (minutes). `0` means excluded. |
| `excluded_days` | Array | ❌ | Weekdays excluded from compliance: `["SAT", "SUN"]` |
| `created_at` | Timestamp | ✅ | Record creation time |
| `updated_at` | Timestamp | ✅ | Last modification time |

### Notes
- An activity may have at most one goal per `period_type` (one daily, one weekly, one monthly).
- `target_minutes` is the default for all days. `day_overrides` takes precedence for specific weekdays.
- A weekday in `excluded_days` generates no missing hours regardless of `target_minutes`.
- Deleting a goal does not alter historical session data.

### Weekday keys
`MON` · `TUE` · `WED` · `THU` · `FRI` · `SAT` · `SUN`

### Relationships
- Belongs to one **Activity**

---

## 6. Custom Period

A custom period is a named time window with its own hour target and optional repetition.

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | UUID | ✅ | Unique identifier |
| `activity_id` | UUID | ✅ | Foreign key → Activity |
| `name` | String | ✅ | Display name (e.g. "Sprint 12", "Exam week") |
| `started_on` | Date | ✅ | Start date, chosen manually by the user |
| `duration_days` | Integer | ✅ | Length of the period in days |
| `target_minutes` | Integer | ✅ | Total worked time target in minutes |
| `repeats` | Boolean | ✅ | Whether the period repeats automatically |
| `repeat_every_days` | Integer | ❌ | Repetition interval in days. Required when `repeats = true` |
| `created_at` | Timestamp | ✅ | Record creation time |
| `updated_at` | Timestamp | ✅ | Last modification time |

### Notes
- The end date is always computed: `started_on + duration_days - 1`.
- When `repeats = true`, the next period starts at `started_on + repeat_every_days`.
- Multiple custom periods for the same activity may coexist and overlap.

### Relationships
- Belongs to one **Activity**

---

## 7. Time Block

A time block defines a named intra-day window tied to specific weekdays.

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | UUID | ✅ | Unique identifier |
| `activity_id` | UUID | ✅ | Foreign key → Activity |
| `name` | String | ✅ | Display name (e.g. "Morning", "Workday") |
| `start_time` | Time | ✅ | Block start (e.g. `09:00`) |
| `end_time` | Time | ✅ | Block end (e.g. `18:00`) |
| `weekdays` | Array | ✅ | Applicable weekdays: `["MON", "TUE", "WED", "THU", "FRI"]` |
| `use_as_auto_close` | Boolean | ✅ | Whether `end_time` triggers automatic session closing |
| `created_at` | Timestamp | ✅ | Record creation time |

### Notes
- `end_time` must be greater than `start_time` (no overnight blocks in v1).
- Multiple time blocks per activity are allowed.
- When `use_as_auto_close = true`, any active session for this activity will be closed at `end_time` on applicable weekdays.

### Relationships
- Belongs to one **Activity**

---

## 8. Relationships

```
Activity  1 ──── * Session
                     Session  1 ──── * Break

Activity  1 ──── * Goal
Activity  1 ──── * CustomPeriod
Activity  1 ──── * TimeBlock
```

All relationships are local foreign keys. Referential integrity is enforced at the application layer (or by the storage engine if supported).

**Cascade rules:**
- Deleting an **Activity** → soft-deletes all its Sessions, Goals, CustomPeriods, TimeBlocks
- Deleting a **Session** → hard-deletes all its Breaks
- Archiving an **Activity** → no cascade; all data is preserved

---

## 9. Computed values

These values are never stored — they are always derived on read from the raw timestamps.

| Value | Formula |
|---|---|
| Session duration | `ended_at − started_at − sum(break durations)` |
| Break duration | `break.ended_at − break.started_at` |
| Daily worked time | `sum(session durations)` for sessions on a given calendar day |
| Missing hours | `goal.target_minutes − daily_worked` (when result > 0) |
| Extra hours | `daily_worked − goal.target_minutes` (when result > 0) |
| Weekly balance | `sum(daily_worked for week) − weekly_goal.target_minutes` |
| Monthly balance | `sum(daily_worked for month) − monthly_goal.target_minutes` |
| Period progress | `sum(session durations within period) ÷ custom_period.target_minutes` |

**Key invariant:** recomputing any value from the raw timestamps must always produce the same result. No derived value is ever the source of truth.

---

## 10. Design constraints

1. **All timestamps are stored in UTC.** Display is always converted to device local time.
2. **Durations are never stored.** They are always computed from `started_at` and `ended_at`.
3. **No floating-point arithmetic for time.** All durations are stored and computed in integer minutes (or seconds, TBD based on framework).
4. **Soft deletes for Activities.** Hard deletes only after explicit user confirmation in a data-management screen.
5. **No foreign data.** No entity contains data originating from outside the device.
6. **Schema migrations must be additive.** New fields are always nullable or have defaults, so older data remains valid.
