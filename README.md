# KB Predictor AI

A fully **offline** Flutter (Android) app for recording result history — grouped by
device, browser, and time — and generating predictions using a **local, fully
editable rule engine**. There is no AI API, cloud service, or internet connection
anywhere in this codebase.

## Features

- **Dashboard** — total wins, total losses, win rate, recent history, Predict button
- **History Input** — device, browser, minute, match 1/2/3 (3 optional), result (B/K), score
- **Local SQLite database** (`sqflite`) for all history and rules
- **Editable Rules page** — Time Rules, Browser Rules (Google/Safari), Fresh Device
  Rules, and Streak Pattern rules — all add/edit/delete/reset/import/export
- **Device page** — wins, losses, win rate, history and next prediction per device
- **Modular prediction engine** (`lib/predictor/predictor.dart`) with the priority
  cascade: Device Rule → Browser Rule → Time Rule → Device History (LW) → Streak
  Pattern, each with a confidence score and full rule-by-rule analysis
- **History Viewer** — search, filter (device / browser / result / date), sort
- **Statistics** — win-rate pie chart, device/browser performance bar charts, and
  device/browser/win-rate rankings (`fl_chart`)
- **Export** — CSV and JSON export of history, shared via the OS share sheet
- **Backup & Restore** — full SQLite database file backup/restore
- **Light & Dark** Material 3 themes
- **100% offline** — no `internet` permission in the release manifest, no HTTP
  client package is used anywhere in the app

## Project Structure

```
lib/
 ├── models/        # HistoryEntry, TimeRule, DeviceRule, StreakRule
 ├── database/       # DBHelper — the only file with raw SQL
 ├── predictor/       # predictor.dart — the whole rule engine lives here
 ├── services/       # Repository, Providers (state mgmt), Export/Backup services
 ├── screens/        # Dashboard, History, Devices, Statistics, Rules, Settings
 ├── widgets/        # Reusable UI (StatCard, HistoryTile, PredictionResultView, ...)
 ├── utils/          # Theme + default/seed data constants
 └── main.dart
```

## Getting Started

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) — **Flutter 3.27 or newer** is required (the UI code uses `Color.withValues`, `CardThemeData`, and other modern Material 3 APIs).
2. From the project root:

   ```bash
   flutter pub get
   flutter run
   ```

   The first `flutter pub get` will auto-generate `android/local.properties` with your
   SDK paths if it doesn't already exist.

3. To build a release APK:

   ```bash
   flutter build apk --release
   ```

## Editing the Prediction Rules

Everything under **Settings → Editable Rules** is stored in SQLite and can be
changed at runtime — no code changes or app rebuild required. You can also
export your rule set to JSON and re-import it later (or share it with another
device) from the same screen.

The prediction algorithm itself lives entirely in `lib/predictor/predictor.dart`.
To add a brand-new rule type:

1. Add a new value to the `PredictionPriority` enum.
2. Write a new `Future<RuleAnalysis> _evaluateYourRule(...)` method.
3. Add it to the `analyses` list inside `PredictionEngine.predict()`.

No other file needs to change.

## Notes

- Result codes `B` and `K` are treated as a Win/Loss UI convention only — the
  engine's logic does not depend on which one "means" a win.
- App icons in `android/app/src/main/res/mipmap-*` are simple generated
  placeholders; swap them for your own branding before publishing.
