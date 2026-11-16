---
name: Kilo
description: The daily weather forecast for restaurant purchasing — a trusted native reading on iOS and Android, not a KPI dashboard.
colors:
  ground: "#EAF0F7"
  ground-dark: "#0B1422"
  module: "#FFFFFF"
  module-dark: "#16233A"
  track: "#DCE3EC"
  track-dark: "#24334D"
  alert: "#B42318"
  alert-dark: "#FF8A80"
  alert-ground: "#FDECEC"
  alert-ground-dark: "#3A1A1F"
  good: "#1E7F46"
  good-dark: "#4ADE80"
  accent: "#2F6FEB"
  accent-dark: "#5B9BFF"
typography:
  title:
    fontFamily: "Platform system font (SF Pro on iOS, Roboto on Android)"
    fontWeight: 700
  headline:
    fontFamily: "Platform system font (titleMedium)"
    fontWeight: 600
  body:
    fontFamily: "Platform system font (bodyLarge)"
    fontWeight: 500
  numeric:
    fontFamily: "Platform system font, FontFeature.tabularFigures()"
    fontWeight: 600
  caption:
    fontFamily: "Platform system font (bodySmall)"
    fontWeight: 400
rounded:
  bar: "999px"
  module: "12px"
components:
  purchase-row:
    backgroundColor: "{colors.module}"
    textColor: "{colors.accent}"
  alert-row:
    backgroundColor: "{colors.alert-ground}"
    textColor: "{colors.alert}"
  covered-chip:
    backgroundColor: "{colors.module}"
    textColor: "{colors.accent}"
---

# Design System: Kilo

## Overview

**Creative North Star: "The Daily Forecast"**

Kilo reads like a trusted morning weather report, not a business-intelligence dashboard and not a costume of Peruvian visual folklore. Every screen is built from grouped modules on a cool, quiet ground; the one accent color exists only to mark "what's missing," the way a forecast highlights the chance of rain and leaves the rest of the sky alone. Depth comes from the contrast between module and ground, never from invented elevation or decorative flourish.

The system was arrived at deliberately: a chicha-poster direction and a school-notebook direction were both tried and rejected as "not serious" before landing on this restrained, category-standard reading. It was first shipped as a SwiftUI demo and is now implemented in Flutter (Material 3 widgets restyled with these tokens) so the same reading runs on iOS and Android. The tokens live in `lib/core/theme/kilo_colors.dart` (a `ThemeExtension`) and `lib/core/theme/kilo_theme.dart`; the signature components live in `lib/core/widgets/`.

**Key Characteristics:**
- One accent, spent only on what's missing (the range bar's unfilled portion, buy quantities, the "Comprar" total).
- Grouped modules on a ground: `SectionCard` (module color, 12px radius, hairline dividers) on the screen's ground color. No shadows, no surface tint.
- The platform's system font throughout, tabular figures on every quantity, no decorative or display face.
- Fluent Emoji 3D food illustrations are the only imagery; Material Icons are the only iconography.
- Severe-weather framing for urgency: the alert module is a distinct soft-red banner, not a badge or kicker.

## Colors

Two ground/module pairs (day and night), one status pair for urgency, one for confirmation, and a single accent — each with a light and dark value. `KiloColors.light` and `KiloColors.dark` carry them; `KiloColors.of(context)` reads the active pair, and the app follows the system theme.

### Primary
- **Kilo Blue** (`#2F6FEB` light / `#5B9BFF` dark, `accent`, also the `ColorScheme.primary`): the only accent. Used for what is still needed — the unfilled portion of the range bar, the buy quantity on a purchase row, and the "Comprar" total in the explain sheet. Material controls that inherit `primary` (focused fields, switches, progress) are the only other place it appears.

### Neutral
- **Forecast Sky** (`#EAF0F7` light / `#0B1422` dark, `ground`): the scaffold and app bar background behind every list.
- **Report Card** (`#FFFFFF` light / `#16233A` dark, `module`): every `SectionCard`, the navigation bar and the search bar.
- **Gauge Track** (`#DCE3EC` light / `#24334D` dark, `track`): the unfilled/"on hand" portion of the range bar, the unbought-state circle, dividers and progress tracks.

### Status
- **Severe Weather** (`#B42318` light / `#FF8A80` dark, `alert`): the expiry-alert row's title, icon and "Ver todo lo que vence" link, the "Revisar" label, and missing data on a purchase line — the one place urgency is loud.
- **Severe Weather Ground** (`#FDECEC` light / `#3A1A1F` dark, `alertGround`): the background of the alert module and of `ReviewNotice`, never used elsewhere.
- **Clear Skies** (`#1E7F46` light / `#4ADE80` dark, `good`): confirmation state — "Comprado" label, the filled check circle, "menos que el mes pasado".

### Named Rules
**The One Accent Rule.** `accent` marks only what's missing or unconfirmed. A screen with nothing left to buy shows no accent at all (an `EmptyState` with a plain check icon).
**The Status-Pair Rule.** `alert`/`alertGround` and `good` are semantic, not decorative — they appear only attached to their meaning (expiry urgency, values to review, purchase confirmation) and never as a general-purpose color choice.

## Typography

**Display/Body Font:** the platform's system font (SF Pro on iOS, Roboto on Android), scaled with the user's text size setting. No custom or downloaded font.

**Character:** Plain and legible at arm's length in a noisy kitchen or market; weight and size carry hierarchy instead of color or case. Letter spacing is reset to 0 across the `TextTheme` so it reads native on iOS. No uppercase labels, no letter-spaced kickers, no small-caps eyebrows.

### Hierarchy
- **Title** (app bar title, 22pt bold; `headlineLarge` bold for the stock figure on a supply): screen identity, one per view.
- **Headline** (`titleMedium`, semibold): row titles that need to lead — the expiry alert's title, a purchase-line supply name.
- **Body** (`bodyLarge`, medium/semibold): the primary readable line of a row — supply name and buy quantity in `PurchaseRow`.
- **Numeric**: every text style in the theme carries `FontFeature.tabularFigures()`, so every quantity, price and day count is tabular by default.
- **Caption** (`bodySmall`/`bodyMedium`, `onSurfaceVariant`): supporting text — "Kilo aún aprende," covered-item names, explanations.

### Named Rules
**The No-Kicker Rule.** No screen uses an uppercase eyebrow/kicker label above a title. Section identity comes from `SectionCard` headers and `InfoHeader`'s plain title only.
**The Tabular-Digit Rule.** Any number that can change (quantities, soles, day counts) is rendered with tabular figures; the theme guarantees it, so never override `fontFeatures`.

## Layout

Every screen is a `Scaffold` on the ground color with a `ListView` (or `CustomScrollView` with slivers when the list is long) of `SectionCard`s — there is no custom grid system. Sections group by moment (urgent alert, what to buy, already covered) rather than by data type. Cards sit 16px from the screen edge with 8px between them; rows use a 14px gap between icon and text and 4-6px vertical stacks inside; the covered grid wraps 72px tiles with 8-12px gutters. Long lists use builders (`ListView.builder`, `SliverList.builder`).

The material tap target size is `padded`, so icon-only controls (info button, bought toggle, steppers) are at least 48×48.

## Elevation & Depth

Kilo uses no shadows, no elevation tokens and no surface tint: app bar, navigation bar, sheets and cards all set `surfaceTintColor` to transparent and elevation 0. Depth is conveyed by module-on-ground contrast only. The only radii are the 12px module corner, 4px on chart bars, and the pill shape of the range bar and Material buttons.

### Named Rules
**The System-Depth Rule.** Depth and separation come from background-color contrast only. Don't introduce a custom shadow, blur or glass effect.

## Shapes

The range bar is a full pill for both track and fill. Modules have a 12px radius. There is no other custom shape vocabulary — no card borders, no custom clip shapes, no hard offset shadows.

## Components

### Range Bar (signature component)
`RangeBar` paints, with a `CustomPainter`, a horizontal pill track (`track`) with an accent-filled pill (`accent`) growing from the right to mark what's still needed, and an 8px dot in `onSurface` marking on-hand quantity — read left-to-right like a forecast gauge, not a progress bar. 6px bar height; excluded from semantics because the row's semantic label carries the meaning in words.

### Purchase Row
- **Layout:** `SupplyIcon` (36px) leading, name + buy quantity on a baseline-aligned row, `RangeBar` beneath, optional "Kilo aún aprende" caption.
- **Color assignment:** buy quantity in `accent` (or `onSurfaceVariant` once bought, with strikethrough on the name).
- **Trailing control:** an `IconButton` toggling `circle_outlined`/`check_circle`, colored `track` unbought / `good` bought, with a selection haptic. A row the server already reports as bought cannot be unchecked.
- **Tap:** opens the "¿Por qué …?" sheet built from `GET /supplies/:id`.

### Alert Row (Expiry)
- **Shape:** a `SectionCard` with `alertGround` background — the module itself is the "banner," not a border or badge.
- **Color assignment:** title, supporting line and warning icon all in `alert`.
- **Behavior:** only the most urgent supply surfaces on Hoy; "Ver todo lo que vence (N)" opens the full list.

### Review Notice
The "Revisar" block under a row whose value the server's thresholds mark as unusual (a close below `closeCheck.reviewBelow`, a unit price outside `priceCheck.low..high`): `alertGround` background, an `alert` "Revisar" label, the explanatory sentence, and two actions — "Sí, es correcto" and "Corregir". A voice suggestion ("¿Quisiste decir 3 kg?") uses the same shape on the ground color and is never applied without a tap.

### Info Header (signature component)
A section header pattern: title text plus a trailing 48×48 `info_outline` icon that shows a tap-triggered `Tooltip` with a plain-language explanation. Used whenever a number needs a "why" without adding on-screen text.

### Covered Grid
- **Shape:** a `Wrap` of 72px tiles, no card chrome per item — icon over a two-line caption name in `onSurfaceVariant`.
- **Purpose:** low-emphasis confirmation list; no accent color, no numbers, nothing actionable.

### Navigation
A Material 3 `NavigationBar` with Hoy, Insumos and Ahorro, plus a fourth "Dictar" destination that never becomes selected: tapping it opens the dictation bottom sheet over the current tab, so dictation stays a persistent control rather than a peer destination. Reviews (Cierre de hoy, Compra) open as full-screen dialogs with a close button and a single confirm action in the app bar. Ajustes is an app bar action on Hoy.

## Do's and Don'ts

### Do:
- **Do** spend `accent` only on what's missing or unconfirmed (range bar fill, buy quantities, the "Comprar" total).
- **Do** rely on the theme's tabular figures for every quantity, price and day count.
- **Do** build every screen from `SectionCard`s on the ground color, in both light and dark.
- **Do** use Material Icons for every icon and Fluent Emoji 3D illustrations for every food/supply image; never mix in a custom icon set.
- **Do** keep the alert module visually distinct via the `alertGround` background, not a badge, pill or kicker label.
- **Do** show review flags from the server's thresholds; never recompute them in the client.

### Don't:
- **Don't** add a custom shadow, blur, glass effect or surface tint.
- **Don't** introduce uppercase kicker/eyebrow labels above titles or section headers.
- **Don't** show soles outside Ahorro and the purchase review — Hoy and Insumos never surface currency.
- **Don't** promote dictation to an ordinary tab destination; it stays the intercepted fourth item that opens a sheet.
