# Finova Progress

Last updated: 5 September 2026

## DONE

- [x] Indonesian onboarding, currency setup, light/dark theme
- [x] SQLite local-first database and migrations
- [x] Transactions, system/custom categories, budgets
- [x] Tasks, habits, real streak calculations
- [x] Debts and receivables with payment progress
- [x] Finance/productivity insights using local data
- [x] Task, habit, and debt reminder scheduling with notification settings
- [x] AdMob banner, capped interstitials, consent flow, and Premium-wide ad removal
- [x] Signed Android release build and external APK distribution
- [x] Landing page, privacy/terms, app-ads.txt and custom domain preparation
- [x] Supabase schema with RLS-protected profiles/payments
- [x] Google Cloud OAuth clients, Drive API/scope, Supabase Google provider
- [x] Native Google login tested successfully on physical Android device

## IN PROGRESS

- [ ] End-to-end real Lemon Squeezy payment test (deferred; requires an authorized transaction)

## DONE — UPGRADE 2.0

- [x] Schema-versioned Google Drive backup and transactional restore
- [x] Editable Google profile and real-time premium entitlement UI
- [x] Lemon Squeezy 30-day checkout with Supabase user custom data
- [x] HMAC-verified, idempotent Vercel webhook and atomic premium grant
- [x] Global premium state disables all banner and interstitial ads
- [x] Savings-goal CRUD, contribution history, and progress tracking
- [x] Debt/receivable installment history and remaining-balance tracking
- [x] Task, habit, and debt reminders synchronized with record changes
- [x] Modern seven-day spending chart on the dashboard
- [x] Privacy copy updated for account, Drive backup, and payment processing
- [x] Signed Finova 2.0.0 APK built and installed without startup crash
- [x] Login UI decoupled from optional profile query so valid sessions remain visible
- [x] Dashboard chart compares income and expenses for seven days
- [x] Insights filter ranks both largest expense and income categories
- [x] Insights chart compares income and expenses by selected period
- [x] Google Drive backup verified on a physical Android device
- [x] Vercel production webhook secrets configured and signature validation verified

## KNOWN ISSUES

- `flutter_timezone` currently emits a future Kotlin Gradle migration warning; builds still succeed.
- Google OAuth application is in Testing mode, so only registered test users can sign in.
- App is distributed from the website and is not yet registered in Google Play.

## NEXT ACTION

Install and smoke-test the signed 2.1.0 APK. A real Premium purchase can be tested later with explicit transaction authorization.
