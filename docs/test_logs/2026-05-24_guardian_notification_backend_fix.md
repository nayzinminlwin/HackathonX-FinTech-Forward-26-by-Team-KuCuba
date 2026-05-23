# 2026-05-24 — Guardian Notification Backend Fix Validation

**Branch:** dev0  
**Scope:** Phase 3 pinned notification analysis action  
**Engineer:** Codex

## Problem

The pinned notification action could render `Analysis unavailable` after tapping `Analyze Again`. The native path always calls the live backend, so it fails if the backend is not reachable from Android or if the app is running on a physical device while still using the emulator-only `http://10.0.2.2:8080` URL.

## Fix Summary

- `AppConfig.backendBaseUrl` now supports `--dart-define=API_BASE_URL=...`.
- Android manifest enables development cleartext HTTP for the local backend.
- Native `HttpAnalysisClient` validates backend URL and improves HTTP setup.
- `AnalyzeReceiver` now maps connection, timeout, host, cleartext, and backend errors to actionable messages.
- `NotificationHelper` now sets `contentText` and `BigTextStyle` so collapsed notifications show the useful error text.

## Commands Run

```powershell
flutter analyze lib test
flutter test
flutter build apk --debug
```

## Results

| Check | Result | Notes |
|---|---|---|
| Flutter analyzer | Pass | `flutter analyze lib test` returned no issues. |
| Flutter tests | Pass | 5 tests passed. |
| Android debug build | Pass | APK built at `build/app/outputs/flutter-apk/app-debug.apk`. |
| Runtime notification action | Not device-tested | No Android device/emulator runtime validation was available in this session. |

## Device Testing Notes

For emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

For physical Android device on the same Wi-Fi as the backend machine:

```bash
flutter run --dart-define=API_BASE_URL=http://<computer-lan-ip>:8080
```

The backend must be running separately:

```bash
cd backend
dart run bin/server.dart
```
