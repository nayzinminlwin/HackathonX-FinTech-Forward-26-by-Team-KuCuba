# Phase 3 Sector 2 Notification Input and Backend Call

**Date:** 2026-05-23  
**Branch:** dev0  
**Scope:** Phase 3 Sector 2 - notification text input, backend call, scanning/error states

## Goal

Add the notification-side analysis path using Android `RemoteInput`, without using clipboard access and without implementing the final Sector 3 risk bar UI.

## Files touched

- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/kucuba/eternal_guardian/ScamDetectorForegroundService.kt`
- `android/app/src/main/kotlin/com/kucuba/eternal_guardian/NotificationHelper.kt`
- `android/app/src/main/kotlin/com/kucuba/eternal_guardian/AnalyzeReceiver.kt`
- `android/app/src/main/kotlin/com/kucuba/eternal_guardian/HttpAnalysisClient.kt`
- `android/app/src/main/res/layout/notification_scanning.xml`
- `android/app/src/main/res/layout/notification_status.xml`

## What changed

- Added `AnalyzeReceiver` to receive text submitted from Android notification `RemoteInput`.
- Added `HttpAnalysisClient` using `java.net.HttpURLConnection` to call `POST /analyze`.
- Added the `INTERNET` permission for the native Kotlin backend call.
- Added scanning and status/error `RemoteViews` layouts.
- Updated the idle notification to expose an inline notification action for manual paste/type input.
- Persisted the backend base URL passed from Flutter so the receiver can use the same endpoint after notification action taps.

## Notes

- This sector intentionally does not use `ClipboardManager`.
- User text is processed in-memory and is not logged.
- Successful analysis currently updates a simple status notification with the received risk score. The final horizontal risk bar and analysis-message presentation are reserved for Sector 3.

## Verification

- `flutter analyze` completed with the same 42 existing info-level findings in backend files (`avoid_print`, doc-comment angle bracket warnings). No new Sector 2 Dart issues were reported.
- `flutter build apk --debug` passed and produced `build/app/outputs/flutter-apk/app-debug.apk`.
