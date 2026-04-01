# Micro Adventures (SwiftUI MVP)

Micro Adventures is a SwiftUI iOS app that gives one daily micro-adventure suggestion from local sample data.

## What The MVP Does

- Stores one official daily pick locally in `UserDefaults`.
- `Reroll Today` selects a different eligible adventure, replaces today’s official pick, and persists it.
- `Done` toggles completion for the current adventure and persists it.
- Shows the selected adventure on a map, with user location and a center-on-user action.

## Recommendation Logic

Scoring currently uses:
- available time
- energy level
- weather
- novelty / no-repeat memory
- completion penalty
- distance from user location (when location permission is available)

## Filters (Draft Apply Flow)

- Filters open in a sheet with draft values.
- `Apply` commits the draft to active filters.
- `Close` dismisses without applying draft changes.

## Fallback Behavior

- If the stored daily pick is no longer valid, the app falls back to the best eligible scored match when available.
- If no candidate clears the score threshold, an empty state is shown.
- If active filters exclude all adventures, the empty state explains that and suggests loosening filters.

## MVP Sample Region

Seeded adventures are centered around **Colombes, France (92700)**.

## Project Structure

- `MicroAdventures/ContentView.swift` — screen composition, map camera behavior, sheet wiring.
- `MicroAdventures/ContentViewModel.swift` — scoring, daily pick lifecycle, persistence, filter application.
- `MicroAdventures/AdventureCardView.swift` — main card UI (`Why this?`, `Reroll Today`, `Done`).
- `MicroAdventures/AdventureFiltersView.swift` — draft filter sheet UI (`Apply` / `Close`).
- `MicroAdventures/UserLocationManager.swift` — Core Location integration.
- `MicroAdventures/NoPickCardView.swift` — empty-state card.
- `MicroAdventures/Adventure.swift` — domain model and seeded sample data.

## Run Locally

1. Open `MicroAdventures.xcodeproj` in Xcode.
2. Run scheme `MicroAdventures` on simulator or device.
3. Grant location permission to enable distance-aware scoring.

## Current MVP Scope

- Local-only (no backend, auth, or cloud sync)
- Sample-data driven (no remote CMS/feed)
- No social features
- No Strava integration
