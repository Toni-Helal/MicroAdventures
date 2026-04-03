# Micro Adventures MVP Ship QA Checklist

## Scope
Core decision flow only: daily pick, reroll behavior, filters draft/apply/cancel, completion state, and no-pick fallback.

## Test Setup
1. Build and run on iPhone simulator (latest iOS supported by project).
2. Start from a clean install for first pass.
3. Run a second pass with existing local data (without deleting app).

## Pass 1: Fresh Install
1. Launch app.
2. Confirm one suggestion card appears quickly (no browsing list).
3. Confirm map pin and card content reference same adventure.
4. Tap `Reroll Today`.
5. Confirm card changes to a different adventure when alternatives exist.
6. Force-close app and relaunch.
7. Confirm the rerolled adventure persists as today's official pick.

## Pass 2: Filters Draft Flow
1. Open filters.
2. Change categories/effort/energy/weather/duration values.
3. While sheet is still open, confirm main pick does not change underneath.
4. Tap `Close`.
5. Reopen filters and confirm previous edits were discarded.
6. Change filters again.
7. Tap `Apply`.
8. Confirm all filter changes take effect together (single reselection behavior).

## Pass 3: Decision Actions
1. On current card, tap `Done` and confirm visual completed state updates.
2. Relaunch app and confirm completed state is persisted.
3. Tap `Reroll Today` after marking done.
4. Confirm reroll still updates today's official pick and app stays consistent.

## Pass 4: Edge Conditions
1. In filters, clear all categories and all efforts, then tap `Apply`.
2. Confirm no-pick card appears with reset action.
3. Tap reset action and confirm a valid pick returns.
4. Deny location permission and relaunch.
5. Confirm app still returns a pick and does not crash.

## Pass/Fail Criteria
1. No crashes or hangs.
2. Reroll always means replacing today's official pick.
3. Filter edits are draft-only until `Apply`.
4. `Close` always discards draft edits.
5. No mixed-region sample picks appear in current data set.
