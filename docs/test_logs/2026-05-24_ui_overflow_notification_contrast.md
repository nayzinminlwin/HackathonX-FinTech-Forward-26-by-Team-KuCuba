# 2026-05-24 — UI Overflow and Notification Contrast Validation

**Branch:** dev0  
**Scope:** Flutter app layouts and native notification banner contrast  
**Engineer:** Codex

## Problem

Flutter reported:

```text
A RenderFlex overflowed by 7.0 pixels on the bottom.
```

The notification banner also showed a low-contrast app label/title area on a dark system notification background.

## Fix Summary

- The share overlay panel now uses a fixed percentage-height bottom panel.
- Variable overlay content is inside a `SingleChildScrollView`.
- Compact overlay meter and staged loading placeholder were reduced slightly.
- The staged loading placeholder scales its internal label stack down within its fixed box.
- Added compact-viewport widget tests that fail on Flutter overflow exceptions.
- Native notification custom layouts now use a dark background with white/near-white text.
- Android app label changed from `eternal_guardian` to `Eternal Guardian`.

## Commands Run

```powershell
flutter test test/ui_overflow_test.dart
flutter analyze lib test
flutter test
flutter build apk --debug
```

## Results

| Check | Result | Notes |
|---|---|---|
| Compact UI overflow regression | Pass | Core app screens and share overlay passed at 320 px compact viewport sizes. |
| Flutter analyzer | Pass | `flutter analyze lib test` returned no issues. |
| Flutter tests | Pass | 7 tests passed. |
| Android debug build | Pass | APK built at `build/app/outputs/flutter-apk/app-debug.apk`. |
| Runtime visual notification check | Pending | Needs Android device/emulator screenshot validation. |

## Coverage Added

- `test/ui_overflow_test.dart`
  - Core app home → scan → loading/result path at compact viewport.
  - Share overlay loading/result path at compact 320x480 viewport.

## Remaining Manual Check

Open Guardian Mode on an Android device/emulator and confirm the notification header and custom content are readable in both collapsed and expanded notification states.
