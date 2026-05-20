# Requirements Specification — Time Balance App

> **Version:** 1.0  
> **Status:** Active  
> **Scope:** Complete specification for MVP 1, MVP 2 and MVP 3.

---

## Table of Contents

1. [Core Principles](#1-core-principles)
2. [Main Concepts](#2-main-concepts)
3. [Functional Requirements](#3-functional-requirements)
   - [3.1 Activities](#31-activities)
   - [3.2 Sessions](#32-sessions)
   - [3.3 Breaks](#33-breaks)
   - [3.4 Session Management](#34-session-management)
   - [3.5 Widget](#35-widget)
   - [3.6 Goals](#36-goals)
   - [3.7 Custom Periods](#37-custom-periods)
   - [3.8 Missing and Extra Hours](#38-missing-and-extra-hours)
   - [3.9 Automatic Session Closing](#39-automatic-session-closing)
   - [3.10 Statistics](#310-statistics)
   - [3.11 Import and Export](#311-import-and-export)
   - [3.12 Notes](#312-notes)
   - [3.13 Timezone](#313-timezone)
4. [UI and UX Requirements](#4-ui-and-ux-requirements)
5. [Non-Functional Requirements](#5-non-functional-requirements)
6. [MVP Scope](#6-mvp-scope)
7. [Explicitly Out of Scope](#7-explicitly-out-of-scope)

---

## 1. Core Principles

### 1.1 Privacy First

The application must be completely local. No data ever leaves the device.

- No internet usage
- No cloud services
- No backend
- No user accounts or login
- No synchronization
- No analytics or telemetry
- No advertising or data collection
- No Google services, Firebase, or Google Play Services

All data belongs exclusively to the user and is stored only on the device.

---

### 1.2 Offline First

The app must work fully without internet access. All major features must operate offline:

- Session tracking
- Statistics
- CSV import/export
- Widgets
- Notifications

---

### 1.3 Cross-Platform Compatibility

The app must support:

- Android
- EMUI / Huawei-compatible Android devices
- iOS

Dependencies tightly coupled to Google infrastructure must be avoided.

---

### 1.4 Simplicity

The app must prioritize low friction, fast interactions, minimal taps, clarity, and reliability.

The main interaction is: **quickly starting and stopping activities.**

---

### 1.5 Performance

- Launch quickly
- Consume minimal battery
- Avoid unnecessary background processing
- Compute time from timestamps rather than a continuously running timer

---

## 2. Main Concepts

### 2.1 Activity

An activity represents something the user wants to track time for.

**Examples:** work, university, thesis, study, freelance, personal projects.

Each activity may contain:

| Field | Description |
|---|---|
| Name | Required identifier |
| Icon | Visual identifier |
| Color | Visual distinction |
| Sessions | Tracked time blocks |
| Goals | Time targets |
| Periods | Custom time frames |
| Statistics | Aggregated data |

**Possible states:** active · archived · deleted

---

### 2.2 Session

A session is a worked time block within an activity.

| Field | Description |
|---|---|
| Activity | Associated activity |
| Start timestamp | When the session began |
| End timestamp | When the session ended |
| Duration | Computed from timestamps minus breaks |
| Breaks | List of pause intervals |
| State | Current session state |

**Possible states:** active · manually closed · automatically closed · manually edited

---

### 2.3 Break

A break is a pause within an active session (e.g. bathroom break, tea break).

Each break stores:
- Start timestamp
- End timestamp

Break duration is always subtracted from total worked time.

> **Future:** Break names and categories may be added in MVP 3.

---

## 3. Functional Requirements

### 3.1 Activities

#### FR-01 — Create activity

The user must be able to create activities.

- **Required:** name
- **Optional:** icon, color

---

#### FR-02 — Edit activity

The user must be able to edit: name, color, icon, goals, and periods.

Historical sessions must remain unchanged after edits.

---

#### FR-03 — Archive activity

The user must be able to archive activities.

Archived activities:
- Disappear from the main workflow
- Preserve all historical data
- Remain available in statistics

---

#### FR-04 — Delete activity

The user must be able to permanently delete an activity. Confirmation is required before deletion.

---

#### FR-05 — Duplicate activity

The user must be able to duplicate an activity. The copy inherits: name, icon, color, goals, and periods. **Historical sessions are not copied.**

---

### 3.2 Sessions

#### FR-06 — Start session

The user must be able to start a session. The app stores: activity, start timestamp, date, active state.

---

#### FR-07 — Stop session

The user must be able to stop a session. The app stores: end timestamp, computed duration (minus breaks), updated state.

---

#### FR-08 — Multiple active sessions

Multiple sessions may be active simultaneously and independently.

**Example:** work + study + reading sessions all active at once.

---

#### FR-09 — Display active sessions

The main screen must show all active sessions with:

- Elapsed time
- Activity name
- Quick stop action
- Break controls

---

#### FR-10 — Timestamp-based calculation

Duration must not rely on a continuously running timer. It must be computed as:

```
duration = end_timestamp - start_timestamp - sum(breaks)
```

This calculation must remain correct after: app restart, device restart, and OS process termination.

---

#### FR-11 — Time format

Time must be displayed in clock format.

| Input | Display |
|---|---|
| 90 minutes | 1 h 30 min |
| 45 minutes | 0 h 45 min |
| 435 minutes | 7 h 15 min |

Decimal time must not be the primary format.

---

### 3.3 Breaks

#### FR-12 — Start break

The user must be able to start a break during any active session.

---

#### FR-13 — Stop break

The user must be able to stop a break. Break duration is stored and deducted from total worked time.

---

#### FR-14 — Prevent overlapping breaks

The app must prevent:
- Overlapping breaks within a session
- Multiple simultaneously active breaks in the same session

---

### 3.4 Session Management

#### FR-15 — Edit session

The user must be able to edit: activity, date, start time, end time, and breaks. Durations must be recalculated automatically after any edit.

---

#### FR-16 — Delete session

The user must be able to delete sessions. Confirmation is required before deletion.

---

#### FR-17 — Add past session

The user must be able to manually register a session in the past.

**Example:** "Yesterday I worked from 15:00 to 17:30."

---

### 3.5 Widget

#### FR-18 — Widget support

The app must provide a home screen widget displaying:
- Active activities
- Elapsed time per activity
- Quick actions

---

#### FR-19 — Widget actions

The widget must allow starting and stopping activities directly.

---

#### FR-20 — Widget customization

Users must be able to configure:
- Which activities are visible
- Which activities are marked as favorites
- Which summaries are shown

---

### 3.6 Goals

#### FR-21 — Daily goals

Activities may define a daily hour goal. Example: 9 hours per day.

---

#### FR-22 — Weekly goals

Activities may define a weekly goal. Example: 40 hours per week.

---

#### FR-23 — Monthly goals

Activities may define a monthly goal.

---

#### FR-24 — Multiple simultaneous goals

An activity may have daily, weekly, and monthly goals active at the same time.

---

#### FR-25 — Day-specific goals

The user must be able to define different goals per weekday.

**Example:**

| Day | Goal |
|---|---|
| Monday | 9 h |
| Tuesday | 4 h |
| Saturday | No goal |

---

#### FR-26 — Day exclusions

The user must be able to exclude specific weekdays from goal tracking.

**Example:** Monday to Friday, except Tuesday.

---

### 3.7 Custom Periods

#### FR-27 — Custom periods

The user must be able to define custom time periods. Each period contains:

- Name
- Start date
- Duration
- Target hours
- Repetition rules

---

#### FR-28 — Custom period start date

The user must be able to choose the initial date of a custom period manually.

---

#### FR-29 — Custom blocks

Users must be able to define time blocks (e.g. morning, afternoon, workday), each with:

- Start hour
- End hour
- Applicable weekdays

---

### 3.8 Missing and Extra Hours

#### FR-30 — Missing hours

The app must calculate and display missing hours.

```
missing = target - worked   (when worked < target)
```

---

#### FR-31 — Extra hours

The app must calculate and display extra hours.

```
extra = worked - target   (when worked > target)
```

---

#### FR-32 — Daily deficits do not carry forward automatically

A missed daily target does not inflate the next day's target.

**Example:** Missing 3 h on Monday → Tuesday's target remains 9 h.

---

#### FR-33 — Deficits affect larger periods

Daily deficits do still count against weekly, monthly, and custom period totals.

---

#### FR-34 — Per-activity calculations

All calculations (missing, extra, totals) are independent per activity.

---

#### FR-35 — Global totals

The app may display aggregated totals across all activities.

---

### 3.9 Automatic Session Closing

#### FR-36 — Automatic closing

If a session is left open, the app must close it automatically at the earliest applicable period boundary: midnight, custom day end, or custom block end.

---

#### FR-37 — Default closing hour

If no custom value is configured, the app must close open sessions at `00:00`.

---

#### FR-38 — Custom day end

The user must be able to define when their workday ends.

**Example:** "My workday ends at 20:00."

---

#### FR-39 — Automatic closing without confirmation

Sessions must be closed automatically without requiring user interaction.

---

#### FR-40 — Notification after automatic closing

The app must send a local notification after auto-closure.

**Example:** *"Session 'Work' was automatically closed at 00:00."*

---

#### FR-41 — Editable auto-closed sessions

Automatically closed sessions must remain fully editable.

---

### 3.10 Statistics

#### FR-42 — Daily statistics

Displayed data:
- Total hours worked today
- Hours per activity
- Missing hours
- Extra hours
- Break time

---

#### FR-43 — Weekly statistics

Displayed data:
- Total weekly hours
- Weekly compliance rate
- Most active days
- Least active days

---

#### FR-44 — Monthly statistics

Displayed data:
- Total monthly hours
- Average daily hours
- Average weekly hours
- Activity distribution

---

#### FR-45 — Trends

The app must provide trend insights, such as:

- Worked more/less than previous week or month
- Most productive weekday
- Most common working hours

---

#### FR-46 — Period comparison

The app must support comparing:

- Current week vs previous week
- Current month vs previous month
- Current custom period vs previous custom period

---

#### FR-47 — Only time is analyzed

The app must not analyze sleep, mood, health, productivity quality, or any data outside worked time.

---

### 3.11 Import and Export

#### FR-48 — CSV export

The app must support exporting data as CSV for backups, debugging, and external analysis.

---

#### FR-49 — CSV import

The app must support importing CSV data. The import process must validate: structure, timestamps, and duplicate entries.

---

#### FR-50 — Local-only operations

All CSV import/export operations must remain fully local. No network access is used.

---

### 3.12 Notes

#### FR-51 — Session notes *(future)*

Future versions may allow attaching notes to sessions.

**Example:** "Worked on chapter 2."

---

### 3.13 Timezone

#### FR-52 — Device local time

The app must use device local time for all calculations and display.

---

#### FR-53 — Timezone migration out of scope

Handling timezone changes or migration is out of scope for MVP versions.

---

## 4. UI and UX Requirements

| ID | Requirement |
|---|---|
| UX-01 | Main screen must prioritize active sessions, current progress, and quick interactions |
| UX-02 | Empty states must be defined for: no activities, no sessions |
| UX-03 | Starting/stopping sessions must require minimal taps |
| UX-04 | Activities must be visually distinguishable via colors and icons |
| UX-05 | App must provide readable text, adequate contrast, large touch targets, and one-handed usability |
| UX-06 | Dark mode is planned for MVP 3 |

---

## 5. Non-Functional Requirements

| ID | Requirement |
|---|---|
| NFR-01 | The app must operate entirely offline |
| NFR-02 | Data must survive app close, app restart, device reboot, and OS process termination |
| NFR-03 | The app must avoid unnecessary background activity to preserve battery |
| NFR-04 | The app must feel responsive and launch quickly |
| NFR-05 | No internal authentication (PIN, biometrics, login) is required — device security is assumed |

---

## 6. MVP Scope

### MVP 1 — Core Local Time Tracking

**Focus:** foundational time tracking, fully functional offline.

**Included:**

- Activities (create, edit, archive, delete, duplicate)
- Sessions (start, stop, edit, delete, add past sessions)
- Breaks
- Multiple simultaneous active sessions
- Home screen widget
- Automatic midnight closing with local notifications
- CSV import/export
- Daily and weekly summaries
- Local persistence
- Offline functionality

**Not included:** advanced statistics, trends, notes, advanced customization.

---

### MVP 2 — Goals, Periods and Basic Analytics

**Focus:** time goals, custom periods, and basic analytics.

**Included:**

- Daily, weekly, and monthly goals
- Multiple simultaneous goals per activity
- Day-specific goals and day exclusions
- Custom periods and custom blocks
- Missing and extra hour calculations
- Configurable automatic session closing (custom day end)
- Daily and weekly statistics
- Widget customization

---

### MVP 3 — Advanced Analysis and UX Polish

**Focus:** analytics depth and visual quality.

**Included:**

- Monthly statistics
- Trends and period comparisons
- Graphs and visual analytics
- Session notes
- Break names and stacked break graphs
- Dark mode
- Accessibility improvements
- Improved visual design
- Calendar view *(possible)*

---

## 7. Explicitly Out of Scope

The following are permanently excluded from this project:

- Backend or server of any kind
- Cloud synchronization
- User accounts or authentication
- Online collaboration
- Analytics or telemetry
- Advertising
- GPS or location tracking
- Google services or Firebase
- Productivity scoring
- Sleep, health, or mood analysis
- Any form of invasive monitoring
