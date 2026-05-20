-- =============================================================================
-- Time Balance App — SQLite Schema
-- Version: 1 (stored in PRAGMA user_version)
-- =============================================================================
-- Conventions:
--   • All primary keys are UUIDs stored as TEXT.
--   • All timestamps are UTC ISO 8601 strings (e.g. "2026-05-20T14:30:00Z").
--   • All dates are ISO 8601 date strings (e.g. "2026-05-20").
--   • All times are HH:MM strings (e.g. "09:00").
--   • Booleans are INTEGER: 0 = false, 1 = true.
--   • JSON arrays/maps are TEXT (e.g. '["MON","TUE"]', '{"MON":540}').
--   • Weekday keys: MON | TUE | WED | THU | FRI | SAT | SUN
--   • Soft deletes: status = 'deleted' — rows are never hard-deleted from activities.
-- =============================================================================

PRAGMA journal_mode = WAL;      -- Write-Ahead Logging for concurrency + crash safety
PRAGMA foreign_keys = ON;       -- Enforce referential integrity
PRAGMA user_version = 1;        -- Schema version — increment on each migration

-- =============================================================================
-- activities
-- Top-level unit the user tracks time against.
-- =============================================================================

CREATE TABLE IF NOT EXISTS activities (
    id         TEXT    NOT NULL PRIMARY KEY,
    name       TEXT    NOT NULL,
    icon       TEXT,
    color      TEXT,
    -- 'active' | 'archived' | 'deleted'
    status     TEXT    NOT NULL DEFAULT 'active'
                       CHECK (status IN ('active', 'archived', 'deleted')),
    created_at TEXT    NOT NULL,
    updated_at TEXT    NOT NULL
);

-- name must be unique among non-deleted activities
CREATE UNIQUE INDEX IF NOT EXISTS ux_activities_name_non_deleted
    ON activities (name)
    WHERE status != 'deleted';

-- =============================================================================
-- sessions
-- A single worked time block belonging to one activity.
-- ended_at is NULL while the session is active.
-- =============================================================================

CREATE TABLE IF NOT EXISTS sessions (
    id          TEXT    NOT NULL PRIMARY KEY,
    activity_id TEXT    NOT NULL REFERENCES activities (id),
    started_at  TEXT    NOT NULL,
    ended_at    TEXT,
    -- 'active' | 'closed_manual' | 'closed_auto' | 'edited'
    status      TEXT    NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active', 'closed_manual', 'closed_auto', 'edited')),
    created_at  TEXT    NOT NULL,
    updated_at  TEXT    NOT NULL,
    CHECK (ended_at IS NULL OR ended_at > started_at)
);

CREATE INDEX IF NOT EXISTS ix_sessions_activity_id  ON sessions (activity_id);
CREATE INDEX IF NOT EXISTS ix_sessions_started_at   ON sessions (started_at);
CREATE INDEX IF NOT EXISTS ix_sessions_status       ON sessions (status);

-- =============================================================================
-- breaks
-- A pause within a session. Duration is deducted from session worked time.
-- ended_at is NULL while the break is active.
-- =============================================================================

CREATE TABLE IF NOT EXISTS breaks (
    id         TEXT    NOT NULL PRIMARY KEY,
    session_id TEXT    NOT NULL REFERENCES sessions (id) ON DELETE CASCADE,
    started_at TEXT    NOT NULL,
    ended_at   TEXT,
    -- MVP 3 fields: present from the start to avoid schema migrations later
    name       TEXT,
    category   TEXT,
    created_at TEXT    NOT NULL,
    CHECK (ended_at IS NULL OR ended_at > started_at)
);

CREATE INDEX IF NOT EXISTS ix_breaks_session_id ON breaks (session_id);

-- Enforce: only one active break per session at a time
CREATE UNIQUE INDEX IF NOT EXISTS ux_breaks_one_active_per_session
    ON breaks (session_id)
    WHERE ended_at IS NULL;

-- =============================================================================
-- goals
-- A time target for an activity over a specific period type.
-- An activity may have at most one goal per period_type.
-- =============================================================================

CREATE TABLE IF NOT EXISTS goals (
    id             TEXT     NOT NULL PRIMARY KEY,
    activity_id    TEXT     NOT NULL REFERENCES activities (id) ON DELETE CASCADE,
    -- 'daily' | 'weekly' | 'monthly'
    period_type    TEXT     NOT NULL
                            CHECK (period_type IN ('daily', 'weekly', 'monthly')),
    target_minutes INTEGER  NOT NULL CHECK (target_minutes > 0),
    -- JSON map of per-weekday overrides: {"MON": 540, "SAT": 0}
    -- 0 means excluded for that day. NULL means no overrides.
    day_overrides  TEXT,
    -- JSON array of excluded weekdays: ["SAT", "SUN"]
    -- NULL means no exclusions.
    excluded_days  TEXT,
    created_at     TEXT     NOT NULL,
    updated_at     TEXT     NOT NULL,
    UNIQUE (activity_id, period_type)
);

CREATE INDEX IF NOT EXISTS ix_goals_activity_id ON goals (activity_id);

-- =============================================================================
-- custom_periods
-- A named time window with its own hour target and optional repetition.
-- =============================================================================

CREATE TABLE IF NOT EXISTS custom_periods (
    id                TEXT     NOT NULL PRIMARY KEY,
    activity_id       TEXT     NOT NULL REFERENCES activities (id) ON DELETE CASCADE,
    name              TEXT     NOT NULL,
    started_on        TEXT     NOT NULL,   -- ISO 8601 date (e.g. "2026-05-01")
    duration_days     INTEGER  NOT NULL CHECK (duration_days > 0),
    target_minutes    INTEGER  NOT NULL CHECK (target_minutes > 0),
    repeats           INTEGER  NOT NULL DEFAULT 0 CHECK (repeats IN (0, 1)),
    -- Required when repeats = 1; ignored when repeats = 0
    repeat_every_days INTEGER,
    created_at        TEXT     NOT NULL,
    updated_at        TEXT     NOT NULL,
    CHECK (repeats = 0 OR repeat_every_days IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS ix_custom_periods_activity_id ON custom_periods (activity_id);

-- =============================================================================
-- time_blocks
-- A named intra-day window tied to specific weekdays.
-- =============================================================================

CREATE TABLE IF NOT EXISTS time_blocks (
    id                TEXT     NOT NULL PRIMARY KEY,
    activity_id       TEXT     NOT NULL REFERENCES activities (id) ON DELETE CASCADE,
    name              TEXT     NOT NULL,
    start_time        TEXT     NOT NULL,   -- HH:MM (e.g. "09:00")
    end_time          TEXT     NOT NULL,   -- HH:MM (e.g. "18:00")
    -- JSON array of weekday keys: ["MON","TUE","WED","THU","FRI"]
    weekdays          TEXT     NOT NULL,
    -- When 1, sessions for this activity auto-close at end_time on applicable weekdays
    use_as_auto_close INTEGER  NOT NULL DEFAULT 0 CHECK (use_as_auto_close IN (0, 1)),
    created_at        TEXT     NOT NULL,
    CHECK (end_time > start_time)
);

CREATE INDEX IF NOT EXISTS ix_time_blocks_activity_id ON time_blocks (activity_id);

-- =============================================================================
-- schema_migrations (internal)
-- Tracks which migration scripts have been applied.
-- Used by the data layer on startup.
-- =============================================================================

CREATE TABLE IF NOT EXISTS schema_migrations (
    version     INTEGER  NOT NULL PRIMARY KEY,   -- e.g. 1, 2, 3 …
    applied_at  TEXT     NOT NULL                -- UTC ISO 8601
);

INSERT OR IGNORE INTO schema_migrations (version, applied_at)
    VALUES (1, strftime('%Y-%m-%dT%H:%M:%SZ', 'now'));
