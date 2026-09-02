# Finova Blueprint

## Product direction

Finova is an Indonesian-first, local-first personal finance and productivity app. Core records work offline. Accounts are optional and unlock private Google Drive backup plus server-authoritative premium access.

## Architecture

- Flutter + Material 3 for Android, with Riverpod state and SQLite persistence.
- `FinovaDatabase` owns local records and schema migrations.
- Feature controllers expose typed application state; widgets do not issue SQL.
- Supabase Auth and `finova_profiles` hold identity, profile metadata, and premium entitlement only. Financial records are not silently uploaded to Supabase.
- Google Drive `appDataFolder` stores an explicit user-created JSON backup inaccessible to other Drive apps.
- Lemon Squeezy checkout carries the Supabase user UUID as custom data. A Vercel webhook verifies HMAC before granting 30 days of premium.
- Premium state is always read from Supabase. Clients cannot update entitlement fields. Premium disables all AdMob placements globally.

## Data safety

- Backup files are schema-versioned and include all user-created local tables and preferences.
- Restore is explicit, confirmed, transactional, and replaces local records.
- Secret keys exist only in Vercel environment variables. The APK contains only public OAuth/Supabase identifiers.
- Development builds use official Google test ads; release builds use the supplied production units.

## Main modules

Dashboard, transactions/categories, budgets, debts/receivables, tasks, habits, goals, insights, account/profile, backup/restore, premium, settings, notifications, and policy-conscious ads.

## Release flow

Analyze and test, build signed APK, install on a physical device, validate auth/backup/payment/ad behavior, copy the verified APK to the landing page, then deploy Vercel with webhook environment variables.
