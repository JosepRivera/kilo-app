---
version: 1
slug: "kilo-app-lib-features-today-today-screen-dart"
primary_target: "kilo-app/lib/features/today/today_screen.dart"
related_targets: []
---

# Surface: Today (Hoy, morning purchase list, Fase 4)

Mode: Operate. Platform: iOS (iPhone 18 Pro Max class), Flutter, native iOS feel; the same Flutter render ships to Android.
Audience/job: owner or purchaser, 5-7am before the wholesale market; needs what to buy, how much, and which lot expires, and to trust the number.
Content: per supply the quantity to buy in its own unit, on-hand vs needed, "Kilo aún aprende" when under 28 real days; lot-expiry alert; supplies already covered. No soles on this screen (roles/privacy undecided).
Shell: tabs Hoy · Insumos · Ahorro (places) in a floating glass capsule; a separate round mic button opens the dictation sheet (Cierre at night, Compra otherwise, switchable).
Constraints: minimal text; serious, category-standard trust; food illustrations per supply (Fluent Emoji 3D, generic cart fallback); Dynamic Type; dark mode.
Unresolved: roles/permissions; persistence of check-off during the market trip.

## Direction contract

THESIS: The purchase list read like a daily weather forecast: a familiar, trusted daily reading that tells you what's coming and how sure it is. Refuses the KPI dashboard and the local-folklore costume.
OWN-WORLD: Cool blue-gray ground, white rounded modules (dark: deep navy ground, navy modules), one blue accent for "what's missing", soft red alert module like a severe-weather notice, SF system type with tabular figures, 3D food illustrations as the only imagery.
STORY: The owner sees the one urgent lot first, then each supply's have-to-need bar and quantity, trusts it because Kilo says where it is still learning, ticks items while buying, and dictates the purchase when back.
FIRST VIEWPORT: Large title "Compra de hoy"; alert module (food icon, lot text, warning glyph); forecast module "PARA LOS PRÓXIMOS 3 DÍAS" with rows icon · name · range bar (dot = on hand, blue = missing) · quantity; covered module with icons; floating tab capsule + mic at the bottom.
FORM: Pronóstico (forecast grammar), grounded candidate from the safer re-roll (user-picked after trying Chicha, Notebook, Standard, Scale), seed key 77a73095.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
