# Micro Adventures

Micro Adventures is a decision engine that suggests short, realistic, and location-aware experiences based on the user's current context (time, energy, weather, and novelty).

---

## Vision

Turn free time into meaningful micro-experiences without browsing, filtering, or overthinking.

---

## Problem

Most activity apps are marketplaces.
They overwhelm users with options, filters, and categories.

People don’t want to search.
They want a decision.

---

## Solution

A daily contextual pick powered by:
- Available time
- Energy level
- Weather conditions
- Novelty logic
- (Soon) distance scoring

The system prioritizes instant action over exploration.

---

## Core UX Principle

Less browsing.
More deciding.

The app should deliver a relevant suggestion in under 40 seconds.

---

## Current Architecture (MVP)

- SwiftUI-based app
- ContentViewModel handles scoring and filtering
- Daily pick logic with no-repeat memory
- Context-based scoring system

---

## Roadmap

### Phase 1 (Current)
- Improve scoring accuracy
- Add distance weighting
- Stabilize filter application flow

### Phase 2
- Replace filter form with decision chips
- Add "Another Pick" quick swap
- Introduce soft fallback when no match found

### Phase 3
- Live Adventure Mode
- Context-aware suggestions (sunset, weather shift)
- Passive recommendation trigger

---

## Non-Goals

- Marketplace browsing
- Social feed
- Over-customization
- Complex trip planning
