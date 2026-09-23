# Feature: local-daily-cycle

Locator: kilo-app/odd/tasks/local-daily-cycle.md · Engram mirror: odd/local-daily-cycle/tasks (project kilo)
Branch: feature/mobile-screens

## Objective
Make the app behave like the real product without a server: data persists on the device and the daily cycle (close → consumption → recommendation → purchase → lots) is computed with the rules in the Starlight docs.

## Problem / why
Every screen shows hard-coded demo values; nothing is saved or computed, so the product cannot be evaluated end to end.

## Scope (authorized 2026-09-23, "punto 1")
- Pure-Dart domain: business date (06:00 cut), consumption = previous stock + purchases in window − current stock, gap spreading marked estimated, closed days as real zero, FIFO lots with expiry and waste, weekday-average forecast with error estimate and cold-start estimate from declared category spend, recommendation = demand + buffer − stock (z=1.28, buffer 10–60%), anomaly rule (3× median of 14 days, per weekday once 4 samples, S/10 floor), unit-price flag, monthly waste.
- On-device persistence (shared_preferences JSON) with a deterministic seeded history (Doña Rosa, ~60 days).
- Screens read/write the store: Hoy, Insumos + detail (critical toggle persists), Ahorro, stock-close review, purchase review.
Out of scope (later points): Fase 1 onboarding, Holt-Winters (point 3), real voice (point 4), roles (point 5), server.

## Constraints
- English code, Spanish UI, no comments (user preference).
- Voice stays simulated: the "heard" values are generated from the model; one simulated mishearing may be injected to exercise the real anomaly rule.
- Store API shaped like future server calls so screens survive the backend swap.

## Tasks
- [x] T1 Domain models + engine + unit tests — route: inline
- [ ] T2 Store with persistence + seeded history — route: inline
- [ ] T3 Wire Hoy, Insumos, detail, Ahorro to the store — route: inline
- [ ] T4 Wire stock-close and purchase reviews (save updates the model) — route: inline
- [ ] T5 Simulator pass + APK for the user's Android check — route: inline

Route rationale: the parent already holds the domain and design context from the previous feature; a single coherent writer keeps rules and screens consistent.

## Acceptance criteria
- Closing the app keeps check-offs, closes and purchases.
- Saving a close changes consumption, recommendations and lots; saving a purchase creates lots and reduces "to buy".
- Unit tests cover every rule above; widget tests still pass; analyze clean.

## Checks
- TDD: off (no project/session configuration); runner: `flutter test`.
- `flutter analyze`, `flutter test`, simulator pass.
- RDD: disabled globally by the user (disabled/unmanaged).

## Delivery
Forecast ~1,500 authored lines. Strategy ask-on-risk; no push/PR without the user.

## Progress
- a0b0c2f fix(android): transparent system bars (pre-feature request)

## Next step
T1.
