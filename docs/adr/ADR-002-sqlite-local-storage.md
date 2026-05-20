# ADR-002 — SQLite as Local Storage Engine

| Field      | Value                              |
|------------|------------------------------------|
| Status     | **Accepted**                       |
| Date       | 2026-05-20                         |
| Deciders   | Javi801                            |
| Issue      | #4 — tech: choose and set up local storage solution |

---

## Context

The app requires a local persistence engine that:

1. **Runs fully offline and embedded** — no server process, no internet connection.
2. **Has no Google or Firebase dependencies** — must work on Huawei/EMUI (no GMS).
3. **Provides ACID transactions** — session and break timestamps must never be partially written.
4. **Supports schema migrations** — the schema will evolve across MVP versions.
5. **Works on Android and iOS** without platform-specific storage code where possible.
6. **Handles relational queries** — the data model has foreign keys, soft deletes, and aggregation needs.

The data model (see [data-model.md](../data-model.md)) has six entities:
`Activity`, `Session`, `Break`, `Goal`, `CustomPeriod`, `TimeBlock` — all purely local.

---

## Decision

**SQLite is the chosen storage engine.**

SQLite is an embedded relational database. It runs in-process, requires no network,
has no Google dependencies, provides full ACID guarantees, and has mature migration tooling.
It ships as part of every Android and iOS device.

The **framework-specific adapter** will be chosen as part of issue #34
(tech: set up mobile framework and toolchain):

| Framework      | Recommended adapter  | Notes                                     |
|----------------|----------------------|-------------------------------------------|
| React Native   | `expo-sqlite`        | Official Expo module; WAL mode; no GMS    |
| React Native   | `op-sqlite`          | Community; fastest RN SQLite binding      |
| Flutter        | `drift` (with sqflite) | Type-safe ORM, migration support        |
| Flutter        | `sqflite`            | Simpler, less boilerplate, widely used    |

Regardless of adapter, the **schema and business rules are identical** — the adapter
is an implementation detail of the data layer.

### Initial schema

Defined in [`docs/schema.sql`](../schema.sql).
All timestamps are stored as UTC ISO 8601 strings (`TEXT`).
All booleans are stored as `INTEGER` (0/1).
All JSON arrays/maps are stored as `TEXT`.
All primary keys are UUID strings (`TEXT`).

### Migration strategy

- Migrations are numbered sequentially: `001`, `002`, …
- Each migration is an additive SQL script (new columns are `NULL`-able or have defaults).
- The current schema version is stored in `PRAGMA user_version` (SQLite built-in).
- The data layer runs pending migrations on app startup before any other DB access.

---

## Consequences

### Positive

- SQLite is battle-tested, with decades of production use on mobile.
- No additional runtime or server process required.
- ACID transactions protect against partial writes when the app is killed mid-session.
- Relational queries (joins, aggregations) are native; no custom query layer needed.
- The same schema file works across all framework adapters.
- Migrations via `user_version` are simple and portable.

### Negative / Trade-offs

- SQLite lacks some advanced types (e.g. native arrays, UUIDs, booleans);
  mitigated by storing as `TEXT` / `INTEGER` with application-layer validation.
- The concrete adapter introduces framework coupling, but it is **isolated to the data layer**
  by the repository pattern defined in the domain layer.
- MMKV+JSON would be simpler for key-value data but cannot express the relational structure
  of the data model (foreign keys, aggregations across sessions and breaks).

---

## Alternatives considered

| Option         | Reason rejected                                                                 |
|----------------|---------------------------------------------------------------------------------|
| Realm          | Requires MongoDB Atlas Sync for advanced features; local-only mode is less maintained; license risk |
| WatermelonDB   | React Native–specific; not usable if Flutter is chosen (issue #34 pending)       |
| Isar           | Flutter-native; unusable for React Native                                        |
| MMKV + JSON    | No relational queries, no joins, no referential integrity; unacceptable for this data model |

---

## References

- [docs/schema.sql](../schema.sql) — initial DDL
- [docs/data-model.md](../data-model.md) — logical data model
- [docs/architecture.md](../architecture.md) — data layer responsibilities
- Issue #34 — tech: set up mobile framework and toolchain (adapter to be decided there)
