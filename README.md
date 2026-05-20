# Time Balance App

> A privacy-first, fully offline mobile app to track work time by activity.

Time Balance App helps you track how much time you spend on each activity — work, study, freelance, personal projects — using timestamps instead of a continuous timer. It compares your tracked hours against configurable goals and gives you clear summaries and trends, all without ever connecting to the internet.

---

## Key principles

- **Privacy first** — no internet, no cloud, no accounts, no analytics, no Google services. Your data stays on your device.
- **Offline first** — every feature works without network access.
- **Timestamp-based** — durations are computed from stored timestamps, so tracking survives app restarts and device reboots.
- **Minimal friction** — the main interaction is quickly starting and stopping activities.
- **Cross-platform** — targets Android (including Huawei/EMUI) and iOS.

---

## Features (planned by MVP)

### MVP 1 — Core tracking
- Create, edit, archive, and delete activities
- Start and stop sessions with automatic duration calculation
- Multiple sessions active simultaneously
- Breaks within sessions (deducted from worked time)
- Edit and delete sessions; add past sessions manually
- Home screen widget with quick start/stop
- Automatic session closing at midnight with local notification
- CSV export and import (fully local)
- Daily and weekly summaries

### MVP 2 — Goals and analytics
- Daily, weekly, and monthly time goals per activity
- Day-specific goals and day exclusions
- Custom periods and time blocks
- Missing and extra hour calculations
- Configurable day-end hour for automatic closing
- Daily and weekly statistics
- Widget customization

### MVP 3 — Polish and advanced analysis
- Monthly statistics, trends, and period comparisons
- Graphs and visual analytics
- Session notes and break names
- Dark mode and accessibility improvements

---

## Project structure

```
work-hours-tracker/
├── app/
│   └── mobile/
│       ├── android/          # Android platform
│       ├── ios/              # iOS platform
│       ├── src/
│       │   ├── components/   # Shared UI components
│       │   ├── navigation/   # Navigation structure
│       │   ├── screens/      # App screens
│       │   ├── services/     # Local data services
│       │   ├── state/        # State management
│       │   └── utils/        # Utility functions
│       ├── assets/
│       │   ├── fonts/
│       │   └── images/
│       └── tests/            # Test suite
└── docs/
    ├── requirements.md       # Functional and non-functional requirements
    ├── data-model.md         # Domain entities and relationships
    ├── architecture.md       # Architecture decisions
    ├── privacy-principles.md # Privacy commitments
    └── roadmap.md            # Development roadmap
```

---

## Documentation

| Document | Description |
|---|---|
| [docs/requirements.md](docs/requirements.md) | Complete functional and non-functional requirements (FR-01–FR-53) |
| [docs/data-model.md](docs/data-model.md) | Domain entities, fields, relationships and computed values |
| [docs/architecture.md](docs/architecture.md) | Layered architecture, data flow, storage and background strategy |
| [docs/privacy-principles.md](docs/privacy-principles.md) | Privacy commitments and dependency review checklist |
| [docs/roadmap.md](docs/roadmap.md) | Development phases and progress |

---

## Current status

**Phase 0 — Foundation (completed)**

Repository structure and documentation are in place. No app logic or framework selected yet.

**Next:** Phase 1 — select mobile framework, initialize app skeleton, add development scripts.

---

## Explicitly out of scope

This app will never include: backend, cloud sync, user accounts, analytics, advertising, GPS tracking, Firebase, Google services, or any form of external data collection.

---

## License

[MIT](LICENSE)
