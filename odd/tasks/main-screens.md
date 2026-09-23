# Feature: main-screens

Locator: kilo-app/odd/tasks/main-screens.md · Engram mirror: odd/main-screens/tasks (project kilo)
Branch: feature/mobile-screens

## Objective
Implement Kilo's primary mobile screens in the approved Impeccable "Pronóstico" direction, iOS-first, reviewed in the iPhone 18 Pro Max simulator.

## Problem / why
Only "Hoy" exists; the other tabs are empty and the mic sheet leads nowhere. The daily cycle (Fases 2-5) needs its screens to be evaluable.

## Scope (authorized 2026-09-23)
- Insumos tab: catalog by category + supply detail.
- Ahorro tab: month-over-month waste (owner-facing; roles pending).
- Dictation flows: stock-close review (Fase 2) and purchase review with lots (Fase 5).
Out of scope: onboarding/Fase 1 setup, login/account, notifications, real API/voice.

## Constraints
- Code identifiers, comments, files in English; on-screen text in Spanish.
- Forecast palette, SF type, Fluent Emoji 3D icons (generic fallback), light + dark, 44pt targets, Dynamic Type.
- Demo data only (Doña Rosa), marked with ponytail comments.
- No APK builds; verify in simulator.

## Tasks
- [x] T1 Insumos list + supply detail (7-day forecast, lots, unit/conversions, crítico/secundario) — route: inline
- [ ] T2 Ahorro screen — route: inline
- [ ] T3 Stock-close review (editable remaining stock, "revisar" anomaly, suggested correction, "hoy no hubo consumo") — route: inline
- [ ] T4 Purchase review (lots with prefilled expiry, price flag, ambiguous supply picker) — route: inline
- [ ] T5 Simulator pass light/dark + Impeccable finish review + DESIGN.md — route: delegated (finish reviewer, documenter)

Route rationale: each screen is one Flutter file built on shared palette/panel helpers already understood in the parent; delegation would re-derive the design context. Finish review and documentation use Impeccable's shipped subagents.

## Acceptance criteria
- All tabs and both dictation flows navigable in the simulator, light and dark, no overflow.
- flutter analyze clean; widget tests cover navigation into each screen.

## Checks
- TDD: off (no project/session configuration enables it); runner: `flutter test`.
- `flutter analyze`, `flutter test`, simulator screenshots.
- RDD: on (global). Last reviewed boundary: 2d674cc (declined by user for the scaffold slice).

## Delivery
Forecast: ~1,400 authored lines (>400). Strategy: ask-on-risk; chain strategy to be asked before PR creation. No push/PR without user decision.

## Progress
- 25d9a39 feat(supplies) T1 · analyze clean, 7 tests pass
- 2d674cc feat(today) · 75fcc08 assets · 4375215 scaffold (pre-feature baseline)

## Next step
T1.
