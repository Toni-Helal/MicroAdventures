# Micro Adventures (SwiftUI MVP)

Micro Adventures is a SwiftUI iOS app that surfaces one daily micro-adventure pick based on context and proximity.

## Current MVP Behavior

- One official daily pick is stored locally (`UserDefaults`).
- `Reroll Today` selects a different eligible adventure, replaces today’s official pick, and persists it.
- `Done` toggles completion state for the current adventure and persists it.
- A map view shows the active adventure pin and user position, with a center-on-user action.

## Recommendation Logic (Implemented)

Scoring currently combines:
- available time
- energy level
- weather
- novelty / no-repeat memory
- completion penalty
- distance from current user location (when location permission is available)

Fallback behavior:
- If a stored daily pick is no longer valid, the app falls back to the best eligible scored match.
- If no candidate reaches the minimum score threshold, the app shows an empty state with `Reset Filters`.

## Filters UX (Implemented)

- Filters open in a sheet with **draft state**.
- `Apply` commits draft values.
- `Close` dismisses without applying draft changes.

## MVP Sample Region

Seeded adventures are centered around **Colombes, France (92700)**.

## Project Structure

- `MicroAdventures/ContentView.swift` — screen composition, map camera behavior, and sheet wiring.
- `MicroAdventures/ContentViewModel.swift` — scoring, daily-pick lifecycle, persistence, filter application.
- `MicroAdventures/AdventureCardView.swift` — main card UI (`Why this?`, `Reroll Today`, `Done`).
- `MicroAdventures/AdventureFiltersView.swift` — draft filter sheet UI.
- `MicroAdventures/UserLocationManager.swift` — Core Location integration.
- `MicroAdventures/Adventure.swift` — domain model and seeded sample data.

## Run Locally

1. Open `MicroAdventures.xcodeproj` in Xcode.
2. Run scheme `MicroAdventures` on simulator or device.
3. Grant location permission to enable distance-aware scoring.

## Out of Scope (for this MVP)

- Backend/auth/cloud sync
- Remote content feed/CMS
- Social features or marketplace browsing
- Strava integration
