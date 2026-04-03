# Micro Adventures (SwiftUI MVP)

Micro Adventures is a local-first SwiftUI iOS app that helps the user quickly choose one practical micro-adventure for today.

## Core UX Principle

Micro Adventures is designed to reduce decision friction.  
The goal is to help the user move from “I have some free time” to a realistic local activity with minimal browsing.

## Current MVP Behavior

- One official daily pick is stored in `UserDefaults`.
- Recommendation flow is context-aware and considers:
  - available time
  - energy level
  - weather
  - time of day
  - novelty / no-repeat memory
  - completion penalty
  - user distance (when location is available)
- `Reroll Today` replaces today’s official pick and persists the replacement.
- `Done` toggles completion state and persists it.
- If filters still leave candidates, the app falls back to the best available filtered match instead of failing.
- Empty state appears only when active filters reduce the candidate set to zero adventures.

## Filters (Draft + Apply)

- Filters open as a draft sheet.
- `Apply` commits draft values.
- `Close` dismisses without applying draft changes.

## Adventure Details (Actionable MVP)

- Tapping the current adventure card opens a detail screen.
- The detail screen shows:
  - title
  - description
  - effort
  - estimated duration
  - estimated distance
  - start point
  - end point
  - highlights
  - quick tips
- The detail map shows start/end markers and a lightweight line between points when start and end differ.
- `Start Adventure` opens native Apple Maps with a walking intent:
  - start → end when both points are distinct
  - or to the start point when the adventure is a loop
- `Open in Maps` opens the adventure start point in Apple Maps.

## MVP Sample Region

Seed adventures are centered around **Colombes, France (92700)**.

## Project Structure

- `MicroAdventures/ContentView.swift` — main screen composition, map camera, and sheet presentation
- `MicroAdventures/ContentViewModel.swift` — scoring, daily pick lifecycle, persistence, fallback behavior
- `MicroAdventures/AdventureCardView.swift` — current pick card (`Why this?`, `Reroll Today`, `Done`, tap-to-detail)
- `MicroAdventures/AdventureDetailView.swift` — actionable detail view and Apple Maps handoff
- `MicroAdventures/AdventureFiltersView.swift` — draft filter UI (`Apply` / `Close`)
- `MicroAdventures/NoPickCardView.swift` — no-match state when filters remove all options
- `MicroAdventures/Adventure.swift` — model and seeded MVP adventures
- `MicroAdventures/UserLocationManager.swift` — Core Location integration

## Run Locally

1. Open `MicroAdventures.xcodeproj` in Xcode.
2. Run the `MicroAdventures` scheme on simulator or device.
3. Allow location permission to enable distance-aware scoring.

## Known Limitations

- Adventure data is currently seed/sample data for the Colombes MVP region.
- Route visualization is lightweight and not a full navigation path.
- Recommendation quality depends on the small local dataset and current filter combinations.
- Persistence is local only (`UserDefaults`).

## Scope Limits

- No backend feed
- No social or marketplace layer
- No in-app turn-by-turn navigation engine
- No booking flow
- No advanced route optimization
