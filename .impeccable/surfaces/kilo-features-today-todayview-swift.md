---
version: 1
slug: "kilo-features-today-todayview-swift"
primary_target: "Kilo/Features/Today/TodayView.swift"
related_targets: []
---

# Surface: Today (Hoy, morning purchase list, Fase 4)

Mode: Operate. Platform: iOS only (iPhone 18 Pro class), SwiftUI, iOS 26+, native components with system Liquid Glass untouched.
Audience/job: owner or purchaser, 5-7am before the wholesale market; needs what to buy, how much, and which lot expires, and to trust the number.
Content: per supply the quantity to buy in its own unit, on-hand vs needed, "Kilo aún aprende" when under 28 real days; lot-expiry alert; supplies already covered. No soles on this screen (roles/privacy undecided).
Shell: native TabView Hoy · Insumos · Ahorro (sections); dictation is a persistent action in the tab view bottom accessory (Cierre at night, Compra otherwise, switchable in the sheet). Ajustes via a toolbar button top-right in Hoy.
Constraints: minimal text; serious, category-standard trust; food illustrations per supply (Fluent Emoji 3D, generic cart fallback); Dynamic Type; dark mode; fixed demo data (Doña Rosa, Fri 2026-10-30).
Unresolved: roles/permissions.

## Direction contract

THESIS: The purchase list read like a daily weather forecast: a familiar, trusted daily reading that tells you what's coming and how sure it is. Refuses the KPI dashboard and the local-folklore costume.
OWN-WORLD: Cool blue-gray ground, white inset-grouped modules (dark: deep navy ground, navy modules), one blue accent for "what's missing", soft red alert module like a severe-weather notice, SF system type with tabular figures, 3D food illustrations as the only imagery, system Liquid Glass bars.
STORY: The owner sees the one urgent lot first, then each supply's have-to-need bar and quantity, trusts it because Kilo says where it is still learning, ticks items while buying, and dictates the purchase when back.
FIRST VIEWPORT: Large title "Compra de hoy"; alert module (food icon, lot text, warning glyph); forecast module "Para los próximos 3 días" with rows icon · name · range bar (dot = on hand, blue = missing) · quantity; covered module with icons; native tab bar with the dictation accessory above it.
FORM: Pronóstico (forecast grammar), grounded candidate from the safer re-roll (user-picked after trying Chicha, Notebook, Standard, Scale), seed key 77a73095.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
