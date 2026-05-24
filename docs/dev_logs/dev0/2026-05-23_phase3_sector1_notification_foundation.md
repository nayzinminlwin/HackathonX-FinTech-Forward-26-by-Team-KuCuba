# Phase 3 Sector 1 Notification Foundation

**Date:** 2026-05-23  
**Branch:** dev0  
**Scope:** Phase 3 Sector 1 - native notification foundation

## Goal

Implement the foundation for Guardian Mode pinned notifications without adding clipboard reads, RemoteInput, backend calls, or result rendering yet.

## Files touched

- `android/app/src/main/AndroidManifest.xml`
- `android/app/build.gradle.kts`
- `android/app/src/main/kotlin/com/kucuba/eternal_guardian/MainActivity.kt`
- `android/app/src/main/kotlin/com/kucuba/eternal_guardian/ScamDetectorForegroundService.kt`
- `android/app/src/main/kotlin/com/kucuba/eternal_guardian/NotificationHelper.kt`
- `android/app/src/main/res/layout/notification_idle.xml`
- `android/app/src/main/res/drawable/ic_shield.xml`
- `lib/services/notification_service_controller.dart`

## What changed

- Added foreground-service and notification permissions required for Phase 3.
- Registered `ScamDetectorForegroundService` with `specialUse` foreground service type.
- Added a native foreground service that creates an `IMPORTANCE_LOW` notification channel and returns `START_STICKY`.
- Added an idle custom `RemoteViews` notification layout with a `Paste Text to Analyze` action.
- Added `NotificationHelper` to build the idle pinned notification using `NotificationCompat`.
- Added a Flutter `MethodChannel('com.kucuba/notification_service')` bridge for `startService`, `stopService`, and `isRunning`.
- Added a Dart `NotificationServiceController` wrapper for future Guardian Mode UI integration.

## Notes

- Sector 1 intentionally does not use `ClipboardManager`.
- Sector 1 intentionally does not implement `RemoteInput`; that belongs to Sector 2.
- The idle notification action currently reopens the app. Sector 2 should replace this with the real notification text input submission flow.

## Verification

- `flutter analyze` completed with 42 existing info-level findings in backend files (`avoid_print`, doc-comment angle bracket warnings). No new Sector 1 Dart issues were reported.
- `flutter build apk --debug` passed and produced `build/app/outputs/flutter-apk/app-debug.apk`.
