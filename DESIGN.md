---
name: Kilo
description: The daily weather forecast for restaurant purchasing — a trusted native iOS reading, not a KPI dashboard.
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
    fontFamily: "SF Pro (system, .largeTitle)"
    fontWeight: 700
  headline:
    fontFamily: "SF Pro (system, .headline)"
    fontWeight: 600
  body:
    fontFamily: "SF Pro (system, .body)"
    fontWeight: 500
  numeric:
    fontFamily: "SF Pro (system, monospacedDigit)"
    fontWeight: 600
  caption:
    fontFamily: "SF Pro (system, .caption/.footnote)"
    fontWeight: 400
rounded:
  bar: "999px"
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

Kilo reads like a trusted morning weather report, not a business-intelligence dashboard and not a costume of Peruvian visual folklore. Every screen is built from native iOS grouped-list modules on a cool, quiet ground; the one accent color exists only to mark "what's missing," the way a forecast highlights the chance of rain and leaves the rest of the sky alone. Depth comes entirely from system Liquid Glass and iOS's own inset-grouped materials — Kilo adds no invented elevation, no custom chrome, no decorative flourish.

The system was arrived at deliberately: a chicha-poster direction and a school-notebook direction were both tried and rejected as "not serious" (see PRODUCT.md Brand Commitments) before landing on this restrained, category-standard reading. The palette, type, and shape choices below are what actually shipped in `Kilo/Features/Today/TodayView.swift` and `Kilo/DesignSystem/`.

**Key Characteristics:**
- One accent, spent only on what's missing (the range bar's unfilled portion, buy quantities, the "Comprar" total).
- Native iOS materials only: `.insetGrouped` lists, system Liquid Glass bars, no custom shadows or radii on containers.
- SF system type throughout, tabular figures on every quantity, no decorative or display face.
- Fluent Emoji 3D food illustrations are the only imagery; SF Symbols are the only iconography.
- Severe-weather framing for urgency: the alert module is a distinct soft-red banner, not a badge or kicker.

## Colors

Two ground/module pairs (day and night), one status pair for urgency, one for confirmation, and a single accent — each with a light and dark value taken directly from the shipped colorsets.

### Primary
- **Kilo Blue** (`#2F6FEB` light / `#5B9BFF` dark, `AccentColor`): the only accent. Used exclusively for what is still needed — the unfilled portion of the range bar, the buy quantity on a purchase row, and the "Comprar" total in the explain sheet. Never used for chrome, navigation, or decoration.

### Neutral
- **Forecast Sky** (`#EAF0F7` light / `#0B1422` dark, `KiloGround`): the screen background behind every list, applied by the shared `kiloScreen()` modifier.
- **Report Card** (`#FFFFFF` light / `#16233A` dark, `KiloModule`): the background of every list row/section — purchase rows, the covered grid, the explain sheet, the expiring list.
- **Gauge Track** (`#DCE3EC` light / `#24334D` dark, `KiloTrack`): the unfilled/"on hand" portion of the range bar and the unbought-state circle stroke.

### Status
- **Severe Weather** (`#B42318` light / `#FF8A80` dark, `KiloAlert`): the expiry-alert row's title, icon, and "ver todo lo que vence" link — the one place urgency is loud.
- **Severe Weather Ground** (`#FDECEC` light / `#3A1A1F` dark, `KiloAlertGround`): the background of the alert section only, never used elsewhere.
- **Clear Skies** (`#1E7F46` light / `#4ADE80` dark, `KiloGood`): confirmation state — "Comprado" label, the filled checkmark circle, the leading swipe action.

### Named Rules
**The One Accent Rule.** `AccentColor` marks only what's missing or unconfirmed. A screen with nothing left to buy shows no accent at all (`ContentUnavailableView`, plain system checkmark).
**The Status-Pair Rule.** `KiloAlert`/`KiloAlertGround` and `KiloGood` are semantic, not decorative — they appear only attached to their meaning (expiry urgency, purchase confirmation) and never as a general-purpose color choice.

## Typography

**Display/Body Font:** SF Pro (system default, Dynamic Type — no custom or downloaded font anywhere in the build).

**Character:** Plain and legible at arm's length in a noisy kitchen or market; weight and size carry hierarchy instead of color or case. No uppercase labels, no letter-spaced kickers, no small-caps eyebrows anywhere in the shipped screens.

### Hierarchy
- **Title** (`.largeTitle`, bold, e.g. `SupplyDetailView`; navigationTitle elsewhere): screen identity, one per view.
- **Headline** (`.headline`, semibold weight): row titles that need to lead — the expiry alert's title, a purchase-line supply name.
- **Body** (`.body`, medium/semibold weight): the primary readable line of a row — supply name and buy quantity in `PurchaseRow`.
- **Numeric** (`.body`/`.callout`/`.footnote` + `.monospacedDigit()`): every quantity, price, and day count. Tabular figures are non-negotiable wherever a number can change per row, so columns don't jitter.
- **Caption** (`.caption`/`.footnote`, secondary color): supporting text — "Kilo aún aprende," covered-item names, popover explanations.

### Named Rules
**The No-Kicker Rule.** No screen uses an uppercase eyebrow/kicker label above a title. Section identity comes from `InfoHeader`'s plain-weight title text and native `Section` headers only.
**The Tabular-Digit Rule.** Any number that can change (quantities, soles, day counts) is rendered with `.monospacedDigit()`.

## Layout

Every screen in `Kilo/Features/` is built on a native `List` with `.listStyle(.insetGrouped)` and the shared `kiloScreen()` background modifier — there is no custom grid or container system. Sections group by moment (urgent alert, what to buy, already covered) rather than by data type, matching PRODUCT.md's "cycle, not the form" principle. Row internal spacing is consistently a 14pt horizontal gap between icon and text (`HStack(spacing: 14)`) with 4-6pt vertical stacks inside; the covered-items grid uses an adaptive `LazyVGrid` with a 72pt minimum tile and 8-12pt gutters. Tap targets on icon-only controls (info button, bought toggle) are fixed at 44×44pt.

## Elevation & Depth

Kilo uses no custom shadows, no elevation tokens, and no manual corner radii on containers anywhere in the shipped code — depth is conveyed entirely by system Liquid Glass (tab bar, navigation bars) and iOS's own `.insetGrouped` list material (module-on-ground contrast via `KiloModule`/`KiloGround`, not a shadow). The only `cornerRadius` calls in the build (`SavingsView`, `SupplyDetailView`) are 4pt on Chart bar marks and small inline elements, not container chrome.

### Named Rules
**The System-Depth Rule.** Depth and separation come from native materials and background-color contrast only. Don't introduce a custom shadow, blur, or glass effect; Liquid Glass is the ceiling, not a starting point to extend.

## Shapes

Corner language is inherited entirely from native components: `.insetGrouped` list rows and sections use the system's own corner radius, and the range bar is a full `Capsule()` (pill) shape for both track and fill. There is no other custom shape vocabulary in the build — no card borders, no custom clip shapes, no hard offset shadows.

## Components

### Range Bar (signature component)
The one custom shape in the system: a horizontal capsule track (`KiloTrack`) with an accent-filled capsule (`AccentColor`) growing from the right to mark what's still needed, and an 8pt `Color.primary` dot marking on-hand quantity — read left-to-right like a forecast gauge, not a progress bar. Fixed 6pt height, `accessibilityHidden` (the row's accessibility label carries the meaning in words).

### Purchase Row
- **Shape:** native list row, no custom radius or border.
- **Layout:** `SupplyIcon` (36pt) leading, name + buy quantity on a first-baseline `HStack`, `RangeBar` beneath, optional "Kilo aún aprende" caption.
- **Color assignment:** buy quantity in `AccentColor` (or `.secondary` once bought, with strikethrough on the name).
- **Trailing control:** a plain 44×44pt button toggling a system `circle`/`checkmark.circle.fill` icon, colored `KiloTrack` unbought / `KiloGood` bought, with `.sensoryFeedback(.selection)`.
- **Swipe action:** leading swipe reveals "Comprado"/"Pendiente" tinted `KiloGood`/`gray`.

### Alert Row (Expiry)
- **Shape:** native list row on a distinct `KiloAlertGround` section background — the section boundary itself is the "banner," not a border or badge.
- **Color assignment:** title, supporting line, and `exclamationmark.triangle.fill` icon all in `KiloAlert`.
- **Behavior:** only the single most urgent lot surfaces on Today; a "ver todo lo que vence (N)" link opens the full `ExpiringView` list.

### Info Header (signature component)
A section header pattern: title text plus a trailing 44×44pt `info.circle` button that opens a `.popover` with a plain-language explanation. Used whenever a number needs a "why" without adding on-screen text (PRODUCT.md: minimal text, explainable rules).

### Covered Grid
- **Shape:** adaptive `LazyVGrid`, no card chrome per item — icon over two-line caption name, `.secondary` color.
- **Purpose:** low-emphasis confirmation list; explicitly no accent color, no numbers, nothing actionable.

### Navigation
Native `TabView` with three visible tabs (Hoy/Insumos/Ahorro, SF Symbol + label) plus a fourth `role: .search` tab that intercepts selection to present the dictation sheet instead of navigating — the dictation control lives as a persistent bottom accessory, never as a fourth peer destination. Toolbar actions (Ajustes, Listo) use plain system toolbar buttons with SF Symbols, no custom icon set.

## Do's and Don'ts

### Do:
- **Do** spend `AccentColor` only on what's missing or unconfirmed (range bar fill, buy quantities, the "Comprar" total).
- **Do** use `.monospacedDigit()` on every quantity, price, and day count.
- **Do** build every screen on `List` + `.insetGrouped` + `kiloScreen()`; let Liquid Glass and inset-grouped materials carry all depth.
- **Do** use SF Symbols for every icon and Fluent Emoji 3D illustrations for every food/supply image; never mix in a custom icon set.
- **Do** keep the alert module visually distinct via `KiloAlertGround` background, not a badge, pill, or kicker label.

### Don't:
- **Don't** add a custom shadow, blur, glass effect, or manual container corner radius — none exist in the shipped screens, and Liquid Glass already supplies elevation.
- **Don't** introduce uppercase kicker/eyebrow labels above titles or section headers; the build carries none, and `InfoHeader`'s plain title is the section-identity pattern.
- **Don't** show soles or money-related figures outside `SavingsView`'s owner-gated screen — Today and Insumos never surface currency (PRODUCT.md: roles/privacy undecided, money stays owner-only).
- **Don't** promote the dictation control to a fifth ordinary tab destination; it must stay the intercepted `role: .search` bottom accessory.
