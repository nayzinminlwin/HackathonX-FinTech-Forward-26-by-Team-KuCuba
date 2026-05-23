# Small patches

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
