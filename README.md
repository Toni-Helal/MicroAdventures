# Micro Adventures (SwiftUI MVP)

Micro Adventures is a SwiftUI iOS app that gives one daily micro-adventure suggestion based on current context and nearby location.

## MVP Status (Implemented Today)

- Single daily pick, persisted locally in `UserDefaults`.
- `Reroll Today` chooses a different eligible adventure and replaces today’s official pick (also persisted).
- Context scoring combines:
  - time available
  - energy level
  - weather
  - novelty/no-repeat window
  - completion penalty
  - distance from current user location (when location access is available)
- Filters use draft state inside a sheet, with explicit `Apply` and `Close` actions.
- Map shows the selected adventure and user location, with a center-on-user action.
- If a stored pick is no longer valid, the app falls back to the best eligible scored match.
- If no candidate reaches the score threshold, an empty state is shown with `Reset Filters`.

## Sample Region

The seeded MVP adventures are centered around **Colombes, France (92700)**.

## Project Structure

- `MicroAdventures/ContentView.swift` — screen composition and map camera behavior.
- `MicroAdventures/ContentViewModel.swift` — scoring, daily-pick logic, filter application, persistence.
- `MicroAdventures/AdventureCardView.swift` — main adventure card (`Done`, `Reroll Today`).
- `MicroAdventures/AdventureFiltersView.swift` — draft filter UI and apply/close flow.
- `MicroAdventures/UserLocationManager.swift` — Core Location integration.
- `MicroAdventures/Adventure.swift` — domain model and sample data.

## Run Locally

1. Open `MicroAdventures.xcodeproj` in Xcode.
2. Run the `MicroAdventures` scheme on simulator or device.
3. Grant location permission to enable distance-aware scoring.

## Current MVP Boundaries

- Local-only (no backend, no authentication, no cloud sync).
- Sample-data driven (no remote content feed/CMS).
- No social features, no marketplace browsing, no Strava integration yet.
