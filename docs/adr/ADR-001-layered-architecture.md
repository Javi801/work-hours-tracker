# ADR-001 — Layered Architecture (Presentation / Domain / Data)

| Field      | Value                        |
|------------|------------------------------|
| Status     | **Accepted**                 |
| Date       | 2026-05-20                   |
| Deciders   | Javi801                      |
| Issue      | #3 — tech: define initial architecture |

---

## Context

The app is a fully offline, privacy-first mobile application with no backend.
It needs to:

- Run on Android (including Huawei/EMUI) and iOS without cloud dependencies.
- Survive process death: all state must be recoverable from persisted timestamps.
- Be testable without an emulator (domain logic must be pure).
- Avoid over-engineering for an MVP while leaving room to grow.

---

## Decision

Adopt a **three-layer architecture** with strict one-directional dependency:

```
Presentation  →  Domain  →  Data
```

| Layer        | Responsibility                                                   | I/O  |
|--------------|------------------------------------------------------------------|------|
| Presentation | Render UI, dispatch user intent, own navigation                  | Yes  |
| Domain       | Entities, use cases, repository contracts, computed values       | None |
| Data         | Repository implementations, local DB, CSV, migrations            | Yes  |

**Key rules enforced by this decision:**

1. The **domain layer has zero UI and zero I/O dependencies**. It is always unit-testable with no emulator.
2. The **presentation layer never accesses the database directly**; it always goes through domain use cases.
3. **No duration or balance is stored** — all derived values are computed from `started_at` / `ended_at` timestamps on read.
4. A **single state container** (store or equivalent) is the only source of truth for UI rendering.
5. The **domain layer defines repository interfaces**; the data layer provides the concrete implementations.

---

## Consequences

### Positive

- Domain logic can be developed and tested before a UI framework is chosen.
- Swapping the storage engine or UI framework does not require rewriting business logic.
- Clear module boundaries make it straightforward to onboard contributors.
- Timestamp-based computation means no derived state goes stale after app restarts.

### Negative / Trade-offs

- More boilerplate than a single-layer approach (repository interfaces, use case classes).
- Accepted consciously: the app's offline-first constraints make correctness more important than brevity.

---

## Alternatives considered

| Alternative         | Reason rejected                                                       |
|---------------------|-----------------------------------------------------------------------|
| Single-layer (all logic in screens) | Unacceptable — business rules would be impossible to unit-test |
| Full Clean Architecture (with DTOs between every layer) | Over-engineering for an MVP; 3 layers are sufficient |
| MVVM without explicit domain layer | No clear home for use cases; leads to bloated ViewModels |

---

## References

- [docs/architecture.md](../architecture.md) — full specification of the chosen architecture
- [docs/data-model.md](../data-model.md) — entity definitions and computed values
- [docs/requirements.md](../requirements.md) — non-functional requirements driving this decision (NFR-01 to NFR-05)
