# Privacy Principles — Time Balance App

> This document defines the privacy commitments of Time Balance App.  
> It is a binding reference for all technical and product decisions.  
> When a proposed feature or dependency conflicts with these principles, the principles win.

---

## Core commitment

**Time Balance App is 100% local. Your data never leaves your device.**

No server receives your data. No company stores it. No third party can access it. Not even the developers.

---

## What this means in practice

### No network access
The app has no internet permission. It makes zero network requests — not during setup, not during use, not in the background. There is no telemetry, no "phone home" on first launch, no version-check ping.

### No accounts
There are no user accounts, no registration, no login, no email address, no username. The app does not know who you are.

### No cloud
There is no cloud backup, no cloud sync, no cloud storage. Data lives exclusively in the device's local storage.

### No analytics
The app collects no usage data. No event tracking, no session recording, no heatmaps, no A/B testing infrastructure. The developers have no visibility into how the app is used.

### No advertising
The app contains no ad networks, no tracking pixels, no advertising identifiers (IDFA, GAID, or equivalent).

### No third-party SDKs that transmit data
Any dependency that sends data to an external server — regardless of purpose — is prohibited. This includes:
- Firebase (all products)
- Google Analytics / Google Tag Manager
- Crashlytics, Sentry (cloud-hosted), Bugsnag
- Mixpanel, Amplitude, Segment
- Any social login SDK (Google Sign-In, Sign in with Apple used for auth, etc.)

### No Google Play Services dependency
The app must function on devices without Google Play Services (Huawei/EMUI, de-Googled Android). No feature may require Google Play Services.

---

## What data is stored locally

The app stores only what the user explicitly creates:

| Data | Where | Purpose |
|---|---|---|
| Activity names, icons, colors | Local DB | Display and tracking |
| Session timestamps | Local DB | Duration calculation |
| Break timestamps | Local DB | Break deduction |
| Goals and periods | Local DB | Progress tracking |
| App settings | Local storage | User preferences |

No data is stored anywhere else. Uninstalling the app removes all data.

---

## Export and import

CSV export and import are provided so users can own their data:

- Export creates a file on the **device's local storage** only.
- Import reads a file from the **device's local storage** only.
- Neither operation uses the network.
- The user controls where exported files go and what happens to them.

---

## Crash handling

If crash reporting is added in the future, it must be:
- **Local only** — logs written to a file on the device, never uploaded
- **Opt-in** — the user explicitly enables it
- **Inspectable** — the user can read and delete crash logs

Cloud-hosted crash reporting services are prohibited.

---

## Device security assumption

The app does not implement its own authentication (no PIN, no biometrics, no passcode). It assumes the device itself is secured by the user. This is a deliberate design choice — adding authentication would create complexity without meaningful additional privacy protection beyond what the OS already provides.

---

## Reviewing new dependencies

Before adding any new library or SDK, answer these questions:

1. **Does it make network requests?**  
   If yes → prohibited, unless network access is completely opt-out and disabled by default with no background activity.

2. **Does it require Google Play Services?**  
   If yes → prohibited.

3. **Does it collect or transmit any data?**  
   If yes → prohibited.

4. **Does it store data outside the device?**  
   If yes → prohibited.

If the answer to all four is no, the dependency may be considered.

---

## Relationship to requirements

These principles are the foundation of the following requirements in [requirements.md](requirements.md):

- Section 1.1 — Privacy First
- Section 1.2 — Offline First
- Section 1.3 — Cross-Platform Compatibility (Huawei/no Google Play)
- NFR-01 — Fully offline
- Section 7 — Explicitly Out of Scope

In case of conflict between this document and any other document, this document takes precedence on privacy matters.
