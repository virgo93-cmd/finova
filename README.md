# Finova

**Track Money. Track Life.** Finova is a local-first Flutter app for personal finance, tasks, and habits.

## Features

- One-time onboarding with currency and opening balance
- SQLite-backed transaction/category CRUD, monthly and category budgets
- Task CRUD, habit check-ins, real current/longest streak calculations
- Finance and productivity insights from on-device records
- Material 3 light/dark/system themes, empty states, data reset, privacy/about
- Policy-conscious AdMob foundation with resilient banners, capped interstitials, and optional rewarded insights

## Architecture

Feature-oriented Flutter UI uses Riverpod for state and `sqflite` as the durable source of truth. Money is stored as integers. Pure calculation services cover financial totals, budgets, date ranges, tasks, and habit streaks. See `docs/FINOVA_BLUEPRINT.md`.

## Run locally

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Debug/profile builds use Google's official test App ID and test ad-unit IDs. Do not click ads during testing.

## Production AdMob configuration

Before release, replace the sample App ID in the Android manifest and iOS Info.plist. Supply real units without committing them:

```sh
flutter build appbundle --release --dart-define=ADMOB_BANNER_ID=... --dart-define=ADMOB_INTERSTITIAL_ID=... --dart-define=ADMOB_REWARDED_ID=...
```

Release mode suppresses ads if IDs are absent. The publisher must configure a real privacy-policy URL, regional consent/UMP behavior, store listing, and release signing.

## Project structure

- `lib/app`: application root
- `lib/core`: database, models, calculations, theme, ads, shared widgets
- `lib/features`: onboarding, shell, screens, and Riverpod controller
- `test`: deterministic business-logic tests
- `docs`: blueprint and implementation progress
- `assets/branding`: original Finova visual identity masters
- `assets/store`: Play Store icon and feature graphic

## Release checklist

- Set production AdMob App ID and all ad-unit IDs
- Verify UMP consent flow and publish privacy policy/terms
- Generate release signing key and configure Play signing
- Add final launcher/store assets and listing
- Test signed release, ads policy compliance, permissions, and offline mode
