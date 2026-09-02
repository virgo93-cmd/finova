# Finova Progress

Last updated: 2 September 2026

## DONE

- [x] Indonesian onboarding, currency setup, light/dark theme
- [x] SQLite local-first database and migrations
- [x] Transactions, system/custom categories, budgets
- [x] Tasks, habits, real streak calculations
- [x] Debts and receivables with payment progress
- [x] Finance/productivity insights using local data
- [x] Notification foundation and settings
- [x] AdMob banner, interstitial frequency manager, rewarded infrastructure and consent flow
- [x] Signed Android release build and external APK distribution
- [x] Landing page, privacy/terms, app-ads.txt and custom domain preparation
- [x] Supabase schema with RLS-protected profiles/payments
- [x] Google Cloud OAuth clients, Drive API/scope, Supabase Google provider
- [x] Native Google login tested successfully on physical Android device

## IN PROGRESS

- [ ] Physical-device QA for Google Drive backup and restore
- [ ] End-to-end real Lemon Squeezy payment test

## DONE — UPGRADE 2.0

- [x] Schema-versioned Google Drive backup and transactional restore
- [x] Editable Google profile and real-time premium entitlement UI
- [x] Lemon Squeezy 30-day checkout with Supabase user custom data
- [x] HMAC-verified, idempotent Vercel webhook and atomic premium grant
- [x] Global premium state disables banner, interstitial, and rewarded ads
- [x] Savings-goal CRUD and progress tracking
- [x] Modern seven-day spending chart on the dashboard
- [x] Privacy copy updated for account, Drive backup, and payment processing
- [x] Signed Finova 2.0.0 APK built and installed without startup crash
- [x] Login UI decoupled from optional profile query so valid sessions remain visible
- [x] Dashboard chart compares income and expenses for seven days
- [x] Insights filter ranks both largest expense and income categories

## NOT STARTED — EXTERNAL CONFIGURATION

- [ ] Add production webhook environment variables to Vercel
- [ ] Register the deployed `/api/webhook` URL in Lemon Squeezy

## KNOWN ISSUES

- `flutter_timezone` currently emits a future Kotlin Gradle migration warning; builds still succeed.
- Google OAuth application is in Testing mode, so only registered test users can sign in.
- App is distributed from the website and is not yet registered in Google Play.

## NEXT ACTION

Test Backup and Pulihkan on the connected phone, configure Vercel secrets, then complete one Lemon Squeezy test-mode purchase.
