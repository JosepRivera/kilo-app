# Kilo app

Kilo is the phone app restaurant buyers use to know what to buy each morning
and to record what they have and what they bought. It is a thin Flutter client
(iOS and Android) of the Kilo API in `../kilo-server`: every quantity,
forecast, recommendation, alert and review threshold comes from the server.
The app only shows them, collects the nightly stock count and the purchases,
and sends them back.

## Screens

- **Hoy**: the most urgent expiry alert, the purchase list with its range bar
  and a "bought" check, what is already covered, and why each quantity was
  recommended.
- **Insumos**: supplies grouped by category, with search, learning progress,
  the week's expected use, lots and recent days.
- **Ahorro**: soles lost to expired stock this month against the previous one.
- **Dictar**: record the night close or a purchase by voice (`POST /voice`) and
  review it before saving; "Registrar a mano" opens the same review without
  voice, so the app keeps working when dictation is unavailable.
- **Ajustes**: restaurant name, recurring closed days, purchase interval and
  monthly spend per category, which supplies are counted nightly, and "Hoy no
  hubo consumo".

On first launch the app registers the restaurant (`POST /restaurants`) and
keeps the device token in the platform's secure storage.

## Running against the local API

Start the API from `../kilo-server` (it listens on `http://localhost:3001`),
then:

```bash
flutter pub get
flutter run
```

The app uses `http://localhost:3001` on iOS and `http://10.0.2.2:3001` on the
Android emulator. Point it elsewhere with
`flutter run --dart-define=API_URL=http://192.168.1.20:3001`. Plain HTTP is
allowed only for local addresses: iOS allows local networking, and Android
allows cleartext to `localhost` and `10.0.2.2` in debug builds only.

To see a restaurant with history, register it in the app and then, from
`../kilo-server`, run `bun run db:seed-demo "<restaurant name>"`.

## Testing

```bash
flutter analyze
dart format --output=none --set-exit-if-changed .
flutter test
```

Tests cover the JSON models against the API contract, the formatters, the
HTTP client and every repository (with `package:http/testing.dart`), each
view model and review rule with in-memory fakes, and widget tests for Hoy, the
close review and the purchase review.

iOS uses CocoaPods (`cd ios && pod install`); `flutter build ios --simulator
--debug` builds without signing.

## Structure

```
lib/main.dart          wires the real HTTP client, secure storage and preferences
lib/app/               app widget, session gate, tabs, navigation and dependencies
lib/core/              API client, formatters, business day, theme tokens, shared widgets
lib/data/              models, one repository per API area, local stores
lib/features/<name>/   view model, screen and leaf widgets of each feature
```

The supply illustrations in `assets/supplies` are Microsoft Fluent Emoji (MIT,
see `assets/supplies/LICENSE-fluentui-emoji.txt`).
