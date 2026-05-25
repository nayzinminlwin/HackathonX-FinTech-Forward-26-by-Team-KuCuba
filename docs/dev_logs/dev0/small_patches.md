# Small patches

## 2026-05-25 — Architecture Mermaid sequence syntax fix

- Branch: `dev0`
- Goal: Fix the backend sequence diagram parse error introduced while documenting the app-secret header gate.
- Files touched:
  - `docs/ARCHITECTURE_DIAGRAM.md`
  - `docs/dev_logs/dev0/small_patches.md`
- Change: Indented the accepted branch under the Mermaid `alt/else/end` block so the sequence diagram parses correctly.
- Verification:
  - Re-read the backend sequence diagram block and confirmed the nested `alt`, `par`, and `end` structure is balanced.

## 2026-05-25 — Public backend app-secret header gate

- Branch: `dev0`
- Goal: Add a lightweight request gate for the public Cloud Run backend so unauthenticated calls are rejected before analysis work starts.
- Files touched:
  - `backend/bin/server.dart`
  - `lib/config/app_config.dart`
  - `lib/services/api_service.dart`
  - `android/app/src/main/kotlin/com/kucuba/eternal_guardian/HttpAnalysisClient.kt`
  - `README.md`
  - `docs/ARCHITECTURE_DIAGRAM.md`
  - `docs/TECH_STACK_AND_PIPELINE.md`
  - `docs/UI_ARCHITECTURE.md`
  - `docs/Detailed_System_Requirement_Document.md`
  - `docs/dev_logs/dev0/small_patches.md`
- Change: Flutter Dio requests and native Kotlin notification requests now send the `x-app-secret` header. Backend middleware checks the header before `/analyze` processing and returns `403 Forbidden` for missing or mismatched values. CORS preflight allows the custom header.
- Security note: This is a lightweight app gate only; hardcoded APK values can be reverse engineered and should not be treated as strong authentication.
- Verification:
  - `flutter analyze lib test` — passed.
  - `flutter test` — passed.
  - `dart analyze` from `backend/` — passed.
  - Backend smoke checks — missing header returned `403`, wrong header returned `403`, correct header returned `200` and entered the analysis pipeline.
  - `flutter build apk --debug` — passed, built `build/app/outputs/flutter-apk/app-debug.apk`.

## 2026-05-25 — Android launcher icon replacement

- Branch: `dev0`
- Goal: Replace the default Flutter launcher icon in installed APKs with the Eternal Guardian logo.
- Files touched:
  - `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
  - `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
  - `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
  - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
  - `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
  - `docs/dev_logs/dev0/small_patches.md`
- Change: Generated density-specific launcher PNGs from `docs/assets/Eternal_Guardian_Logo_removedBg.png`. The manifest already points to `@mipmap/ic_launcher`, so no manifest change was required.
- Verification:
  - Previewed `mipmap-xxxhdpi/ic_launcher.png`.
  - `flutter build apk --debug` — passed, built `build/app/outputs/flutter-apk/app-debug.apk`.

## 2026-05-24 — Prize scam quick example mock scoring fix

- Branch: `dev0`
- Goal: Fix the main page `Prize scam pattern` quick example returning the mock safe score of 8%.
- Files touched:
  - `lib/services/mock_api_service.dart`
  - `android/app/src/main/kotlin/com/kucuba/eternal_guardian/MockAnalysisClient.kt`
  - `test/mock_api_service_test.dart`
  - `docs/dev_logs/dev0/small_patches.md`
- Change: Expanded mock scam keywords to catch prize/reward/claim/fee language, including the exact quick example text, before falling back to the normal conversation score. Mirrored the same keyword behavior in the native notification mock client.
- Verification:
  - `flutter test test/mock_api_service_test.dart` — passed.
  - `flutter analyze lib test` — passed.
  - `flutter test` — passed, 11 tests.
  - `flutter build apk --debug` — passed, built `build/app/outputs/flutter-apk/app-debug.apk`.

## 2026-05-24 — Guardian notification mock-mode parity

- Branch: `dev0`
- Goal: Fix notification banner submissions timing out or showing backend errors while the Flutter app is running in demo/mock mode.
- Files touched:
  - `lib/services/notification_service_controller.dart`
  - `android/app/src/main/kotlin/com/kucuba/eternal_guardian/MainActivity.kt`
  - `android/app/src/main/kotlin/com/kucuba/eternal_guardian/ScamDetectorForegroundService.kt`
  - `android/app/src/main/kotlin/com/kucuba/eternal_guardian/AnalyzeReceiver.kt`
  - `android/app/src/main/kotlin/com/kucuba/eternal_guardian/MockAnalysisClient.kt`
  - `test/notification_service_controller_test.dart`
  - `docs/dev_logs/dev0/small_patches.md`
- Change: Passed `AppConfig.useMockApi` through the notification MethodChannel into the native foreground service. The native notification analysis path now uses a local mock result provider when mock mode is enabled, matching the main Flutter app behavior, and only calls the live backend when mock mode is disabled.
- Verification:
  - `flutter test test/notification_service_controller_test.dart` — passed.
  - `flutter analyze lib test` — passed.
  - `flutter build apk --debug` — initially hit a stale Gradle daemon crash, then passed after `android/gradlew.bat --stop`.
  - `flutter test` — passed, 9 tests.

## 2026-05-24 — Analysis request timeout standardization

- Branch: `dev0`
- Goal: Make analysis calls wait up to 12 seconds instead of using mismatched or too-short request intervals.
- Files touched:
  - `lib/services/api_service.dart`
  - `android/app/src/main/kotlin/com/kucuba/eternal_guardian/HttpAnalysisClient.kt`
  - `docs/dev_logs/dev0/small_patches.md`
- Change: Added a shared Flutter `LiveApiService.analysisTimeout` of 12 seconds and applied it to Dio connect, send, and receive timeouts. Updated the native Kotlin notification analysis client to use a 12-second connect timeout and 12-second read timeout.
- Verification:
  - `flutter analyze lib test` — passed.
  - `flutter test test/notification_service_controller_test.dart test/notification_layout_contrast_test.dart` — passed.
  - `flutter test` — passed, 9 tests.
  - `flutter build apk --debug` — passed, built `build/app/outputs/flutter-apk/app-debug.apk`.

## 2026-05-24 — Notification runtime QA checklist and contrast guard

- Branch: `dev0`
- Goal: Continue the UI handoff's remaining notification readability work despite no Android runtime target being available in this workspace.
- Files touched:
  - `android/app/src/main/res/layout/notification_idle.xml`
  - `android/app/src/main/res/layout/notification_scanning.xml`
  - `android/app/src/main/res/layout/notification_status.xml`
  - `android/app/src/main/res/layout/notification_result.xml`
  - `test/notification_layout_contrast_test.dart`
  - `docs/test_logs/2026-05-24_android_notification_runtime_checklist.md`
  - `docs/dev_logs/dev0/small_patches.md`
- Change: Removed the hard black custom `RemoteViews` backgrounds that appeared as a black rectangle inside Android's notification card. The notification layouts now inherit the system notification surface and use Android notification text appearances for readable theme-aware title/body colors. Also kept visible `Eternal Guardian` naming, added XML-level regression coverage, and documented the Android device QA checklist plus the current no-device blocker.
- Verification:
  - `flutter test test/notification_layout_contrast_test.dart` — passed.
  - `flutter analyze lib test` — passed.
  - `flutter build apk --debug` — passed, built `build/app/outputs/flutter-apk/app-debug.apk`.
  - Android runtime notification drawer validation remains blocked because no Android device/emulator is connected.

## 2026-05-24 — Overlay overflow and notification contrast pass

- Branch: `dev0`
- Goal: Fix the `RenderFlex overflowed by 7.0 pixels on the bottom` warning and improve notification banner text contrast.
- Files touched:
  - `lib/screens/overlay_screen.dart`
  - `lib/widgets/analog_meter.dart`
  - `lib/widgets/skeleton_meter_placeholder.dart`
  - `test/ui_overflow_test.dart`
  - `android/app/src/main/AndroidManifest.xml`
  - `android/app/src/main/res/layout/notification_idle.xml`
  - `android/app/src/main/res/layout/notification_scanning.xml`
  - `android/app/src/main/res/layout/notification_status.xml`
  - `android/app/src/main/res/layout/notification_result.xml`
- Change: Made the overlay bottom panel height-bounded with a scrollable content area, compacted the overlay meter/loader, made the staged loader scale within its fixed box, and added compact-viewport overflow regression tests. Updated notification custom layouts to dark backgrounds with white/near-white text and changed the Android app label to `Eternal Guardian`.
- Verification:
  - `flutter test test/ui_overflow_test.dart` — passed, including compact overlay loading and result paths.
  - `flutter analyze lib test` — passed.
  - `flutter test` — passed, 7 tests.
  - `flutter build apk --debug` — passed, built `build/app/outputs/flutter-apk/app-debug.apk`.

## 2026-05-24 — Guardian notification backend error diagnostics

- Branch: `dev0`
- Goal: Fix the pinned notification analysis path falling into the generic "Analysis unavailable" state without a useful reason.
- Files touched:
  - `lib/config/app_config.dart`
  - `android/app/src/main/AndroidManifest.xml`
  - `android/app/src/main/kotlin/com/kucuba/eternal_guardian/AnalyzeReceiver.kt`
  - `android/app/src/main/kotlin/com/kucuba/eternal_guardian/HttpAnalysisClient.kt`
  - `android/app/src/main/kotlin/com/kucuba/eternal_guardian/NotificationHelper.kt`
- Change: Made `API_BASE_URL` configurable through `--dart-define`, enabled local cleartext HTTP for the development backend, improved native HTTP validation, and surfaced actionable notification error messages for connection, timeout, host, and backend-unavailable cases.
- Verification:
  - `flutter analyze lib test` — passed.
  - `flutter test` — passed, 5 tests.
  - `flutter build apk --debug` — passed, built `build/app/outputs/flutter-apk/app-debug.apk`.

## 2026-05-23 — Phase 2 share overlay transparent activity fix

- Branch: `dev0`
- Goal: Fix Phase 2 simulation where sharing to Eternal Guardian showed a black full-screen app window behind the bottom sheet instead of dimming the originating app.
- Files touched:
  - `android/app/src/main/kotlin/com/kucuba/eternal_guardian/MainActivity.kt`
  - `android/app/src/main/res/values/styles.xml`
  - `android/app/src/main/res/values-night/styles.xml`
  - `lib/screens/overlay_screen.dart`
  - `lib/theme/app_colors.dart`
- Change: Made `MainActivity` use Flutter transparent background mode and changed launch/normal Android themes to transparent translucent windows. Updated overlay colors to use `AppColors` tokens.
- Verification:
  - `flutter analyze lib` — passed with no issues.
  - `flutter build apk --debug` — passed, built `build/app/outputs/flutter-apk/app-debug.apk`.
  - Full `flutter analyze` still reports existing backend info-level `avoid_print` / doc-comment lints unrelated to this patch.
