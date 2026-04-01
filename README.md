# Micro Adventures (SwiftUI MVP)

Micro Adventures is a local-first SwiftUI iOS app that selects one practical micro-adventure for today.

## Current MVP Behavior

- One official daily pick is stored in `UserDefaults`.
- Recommendation flow is context-aware: time available, energy, weather, time of day, novelty/no-repeat memory, completion penalty, and user distance (when location is available).
- `Reroll Today` replaces today’s official pick and persists the replacement.
- `Done` toggles completion state and persists it.
- If filters still leave candidates, the app falls back to the best available filtered match instead of failing.
- Empty state is used when active filters truly exclude all adventures.

## Filters (Draft + Apply)

- Filters open as a draft sheet.
- `Apply` commits draft values.
- `Close` dismisses without applying draft changes.

## Adventure Details (Actionable MVP)

- Tapping the current adventure card opens a detail screen.
- Detail shows: title, description, effort, estimated duration, estimated distance, start point, end point, highlights, and quick tips.
- Detail map shows start/end markers and a lightweight line between points when start and end differ.
- `Start Adventure` opens native Apple Maps with a walking intent (start → end when available, otherwise to start point).
- `Open in Maps` opens the adventure start point in Apple Maps.

## MVP Sample Region

Seed adventures are centered around **Colombes, France (92700)**.

## Project Structure

- `MicroAdventures/ContentView.swift` — main screen composition, map camera, sheets.
- `MicroAdventures/ContentViewModel.swift` — scoring, daily pick lifecycle, persistence, fallback behavior.
- `MicroAdventures/AdventureCardView.swift` — current pick card (`Why this?`, `Reroll Today`, `Done`, tap-to-detail).
- `MicroAdventures/AdventureDetailView.swift` — actionable detail view and Apple Maps handoff.
- `MicroAdventures/AdventureFiltersView.swift` — draft filter UI (`Apply` / `Close`).
- `MicroAdventures/NoPickCardView.swift` — no-match state when filters remove all options.
- `MicroAdventures/Adventure.swift` — model + seeded MVP adventures.
- `MicroAdventures/UserLocationManager.swift` — Core Location integration.

## Run Locally

1. Open `MicroAdventures.xcodeproj` in Xcode.
2. Run scheme `MicroAdventures` on simulator or device.
3. Allow location permission to enable distance-aware scoring.

## Scope Limits

- Local-only persistence (`UserDefaults`)
- Seed/sample adventure dataset (no backend feed)
- No in-app turn-by-turn navigation engine (uses Apple Maps handoff)
