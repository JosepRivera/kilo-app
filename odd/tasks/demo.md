# Feature: demo

## Objective
A 5-minute academic presentation of Kilo on the iPhone simulator where every important product case (Starlight `producto`) appears reliably, with the restaurant already running for months.

## Problem / why
The current seed is random (`Random(7)`), persisted in shared_preferences, and dated relative to the real clock, so cases may or may not show up on presentation day, and data drifts between runs.

## Decisions (user, 2026-09-24)
- Demo starts with "Doña Rosa" already using Kilo (~4 months); onboarding / day 0 is optional and last.
- Ajustes: circular button top-right in Hoy (not a tab).
- No reset button: data resets on every launch, changes persist only within the session.
- Presentation script: Hoy → ¿por qué? → compra → cierre → pasar al día siguiente → Ahorro.

## Platform change (user, 2026-09-24)
The app moves from Flutter to **SwiftUI, iOS only**, keeping every native iOS UI/UX behavior (Liquid Glass included). Flutter code is preserved in git: `feature/mobile-screens` (last Flutter state) and `wip/flutter-demo-scenario` (interrupted T1 attempt). Work continues on `feature/ios-swiftui`; Xcode project `Kilo.xcodeproj` (targets Kilo, KiloTests; iOS 26+, Swift 6, synchronized folders).

## Constraints
English code, Spanish UI, no code comments, tests only for important things, work-unit commits on `feature/ios-swiftui`, no push/PR. Simulation only; logic moves to the server later.
TDD: off (no project/session config); runner `xcodebuild test` (Swift Testing), compile check `xcodebuild build-for-testing -destination 'generic/platform=iOS Simulator'`.
RDD: disabled globally by the user → delivery `disabled/unmanaged`.

## Tasks
- [x] T0 SwiftUI scaffold: Xcode project, asset catalog (AppIcon, AccentColor, Fluent Emoji supplies), Flutter files removed. Route: inline (mechanical). Evidence: TEST BUILD SUCCEEDED (generic iOS Simulator).
- [x] T1 Port domain to Swift (models, engine rules, in-memory store) + scripted demo scenario (fixed Friday 2026-10-30, no RNG, reset on launch) + one case-matrix test. Route: delegated writer (writer trigger: 4+ non-trivial files).
- [x] T1b SwiftUI shell + screens (Impeccable Pronóstico contract, brief repointed to Kilo/Features/Today/TodayView.swift): native TabView Hoy · Insumos · Ahorro, dictation in tabViewBottomAccessory + sheet (medium detent), Hoy (grouped expiry alerts, forecast rows with range bar and check-off, ya alcanza), Insumos (search, Por vencer, categories), supply detail (stock, learning progress, Swift Charts week, lots, registro), Ahorro (month vs previous, 4-month chart, top wasted). Route: inline (user asked for visible progress). Evidence: BUILD SUCCEEDED, verified on simulator iPhone 18 Pro (DeviceHub).
- [ ] T1c Demo data realism: waste must come from perishables (rice/menestras currently top the wasted list); remove lots bought on demoDay before the market run (fish 'lote de hoy vence mañana'); check tab-switch responsiveness.
- [ ] T2 "¿Por qué comprar esto?" sheet + recent days real/estimado/cerrado in supply detail.
- [ ] T3 Close review: "¿trece o tres?" suggestion, resume interrupted draft, discard-changes guard, dictation listening/processing states.
- [ ] T4 Supply resolution in purchase: "¿cuál limón?" picker, create supply, "medio balde" conversion.
- [ ] T5 Ajustes: pasar al día siguiente, ver como dueño/encargado, crítico/secundario bulk review, Tu restaurante (intervals, spend, closed days).
- [ ] T6 (optional) Onboarding: Bienvenida + day-0 dictation.

## T1 acceptance (case matrix, asserted by one test)
- Pollo (Friday, protein due): demand Fri+Sat ≈ 30 kg, error ≈ 4 kg → buffer ≈ 8.9 kg, stock ≈ 12 kg → buy ≈ 27 kg (mirrors Fase 4 doc example). Mature (≥28 real days).
- Pollo: two lots bought Tuesday at different unit prices; the Tuesday lot expires today ("vence hoy"). Another perishable lot expires tomorrow ("vence mañana").
- Pescado: learning, exactly 12 real days.
- Res: after buying the recommendations, a close implying 13 kg used vs usual ≈ 4 kg is flagged.
- Culantro: >3× usual but excess < S/10 → not flagged.
- Cebolla: unit price 1.6× usual is flagged; usual price is not.
- Papa: produce due, but nothing to buy ("ya alcanza").
- Granos y abarrotes, condimentos: not due today.
- Tomate: forgotten close this week → estimated days (only tomato has the gap).
- Sundays closed (real zero), plus one exceptional open Sunday with a real close outside the last 28 days.
- Monthly waste ≈ S/380 (Jul), then falling, Sep ≈ S/250, Oct ≈ S/200 (±10%).

## Progress / evidence
- T1 evidence (writer report): macOS harness all case checks pass; TEST BUILD SUCCEEDED; `xcodebuild test` on simulator TEST SUCCEEDED, 21 tests (8 engine + 13 scenario). Derived: pollo demand 30.0, error 3.93, buffer 8.71, stock 12.0, buy 27.0; pescado 12 real days; lots expiring today (pollo x2, 8.5 and 9.6 S/kg) and tomorrow (pescado); waste Jul 353 / Aug 322 / Sep 259 / Oct 205.
- Simulator note (resolved by creating a simulator in DeviceHub): iOS 27 runtime 24A434 installed but not listed after a reboot (SDK expects 24A430; cryptex mount permission denied). Tests compile but cannot run until fixed.

## Next step
T2 (app shell + screens in SwiftUI).
