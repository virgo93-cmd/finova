# Finova Blueprint

## Product and architecture

Finova is a local-first personal finance and productivity application. Flutter and Material 3 provide the client, Riverpod owns reactive state, and SQLite (`sqflite`) is the durable source of truth. The application is feature-oriented, with shared domain models, calculation services, database repository, theme, and monetization infrastructure under `core`.

Money is stored as integer minor units. For IDR the UI treats the integer as whole rupiah. Dates are stored as ISO-8601 strings. Database schema version 1 includes categories, transactions, budgets, tasks, habits, habit logs, goals, and settings. Default categories are protected by a `is_system` flag.

## Navigation and state

The login-free flow is onboarding/setup followed by a four-destination shell: Home, Transactions, Productivity, and Insights. A central quick-action button opens expense, income, task, and habit entry. Riverpod exposes one controller coordinating repositories and immutable snapshots; calculation logic remains in pure services for testability.

## Monetization and privacy

AdMob is centralized in configuration, a service, and reusable ad widgets. Debug/profile builds always use Google's official Android test ad IDs. Release IDs are centrally configured and may be overridden with `--dart-define`. Interstitial eligibility is frequency-capped. Rewarded ads are user-initiated and unlock an extra insight; Finova does not use rewarded-interstitial, native, or app-open ads. Core records remain on-device.

## Release configuration

Required external values remaining: privacy policy URL, Play signing key, and store metadata. Production Android AdMob App, Banner, and Interstitial IDs are configured. Never commit secrets.

## Release checklist

- [ ] Set production AdMob app/ad-unit IDs
- [ ] Verify UMP consent flow for release regions
- [ ] Publish and configure privacy policy and terms URLs
- [ ] Generate and configure release signing key
- [ ] Create Play Store listing and final launcher assets
- [ ] Test signed release build and policy-compliant ads
- [ ] Review permissions, offline behavior, accessibility, and data reset
