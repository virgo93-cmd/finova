# Finova Progress

## DONE

- Flutter Android/iOS scaffold created on Flutter 3.44.4
- Architecture and storage decisions recorded
- Production dependencies resolved
- SQLite schema with protected categories, transactions, budgets, tasks, habits/logs, goals, settings, indexes, and reset
- Riverpod state/repository boundary and integer-money calculations
- Onboarding/setup, dashboard, quick entry, transaction/category CRUD and filters
- Monthly/category budgets, task CRUD, habit CRUD/check-ins, real streak logic
- Finance/productivity insights, themes, currency preferences, privacy/about/licenses
- AdMob test configuration, resilient banners, capped interstitial, and UMP consent request
- Original Finova logo, generated Android/iOS launcher icons, Play Store icon, and feature graphic
- Publisher-ready Privacy Policy, Terms of Use, store listing, and Play declaration drafts
- Contextual notification permission and a real 7:00 PM daily local reminder
- Android application ID finalized as `com.finova.app`
- Production Android AdMob App ID configured; debug builds continue using official Google test ad units
- Production Banner, Interstitial, and Rewarded unit IDs configured centrally; debug builds use official test units
- Six deterministic business-logic tests
- `flutter analyze`: no issues found
- `flutter test`: all tests passed
- Android debug APK built successfully
- Signed Android release App Bundle (`app-release.aab`) built successfully with production AdMob configuration
- Release-only WorkManager/R8 startup crash reproduced on a physical Vivo device and fixed by disabling shrinking for the first production release
- Corrected release APK installed and verified running on physical device with no AndroidRuntime crash
- Vercel-ready Finova landing page completed under `landing-page/` with signed APK download, checksum, Privacy Policy, Terms, SEO/social metadata, sitemap, robots, and app-ads.txt

## IN PROGRESS

- None for the repository-deliverable MVP.

## NOT STARTED

- Publisher-owned Play Store release configuration and signing

## KNOWN ISSUE

- Production AdMob IDs, privacy URLs, and signing material are intentionally external.
- The `flutter_timezone` plugin currently emits a future Flutter/Kotlin migration warning but builds successfully.

## NEXT ACTION

- Supply production identifiers/policies/signing, verify consent on regional test devices, and test the signed release build.
