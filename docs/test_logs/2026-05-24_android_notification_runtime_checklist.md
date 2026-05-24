# 2026-05-24 — Android Notification Runtime Checklist

**Branch:** dev0  
**Scope:** Guardian Mode notification runtime rendering and contrast  
**Engineer:** Codex

## Environment Check

This workspace cannot complete the runtime notification drawer pass yet:

| Check | Result | Notes |
|---|---|---|
| `flutter devices` | Blocked | Only Chrome and Edge are connected. |
| `flutter emulators` | Blocked | No Android emulators are available. |
| Android SDK `adb` direct check | Blocked | `C:\Users\Alex Ceser\AppData\Local\Android\Sdk\platform-tools\adb.exe devices` returned an empty device list. |

## Automated Coverage Added

`test/notification_layout_contrast_test.dart` now checks that:

- `notification_idle.xml`, `notification_scanning.xml`, `notification_status.xml`, and `notification_result.xml` do not draw the hard black `#1A1A1A` box inside Android's notification card.
- Notification text uses Android `TextAppearance.Compat.Notification*` styles so Android can choose readable colors for the active notification theme.
- The Android manifest app label is `Eternal Guardian`.
- Each native custom notification layout includes visible `Eternal Guardian` naming.

## Commands Run

```powershell
flutter devices
flutter emulators
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
flutter test test/notification_layout_contrast_test.dart
flutter analyze lib test
flutter build apk --debug
```

## Results

| Check | Result | Notes |
|---|---|---|
| Android runtime target | Blocked | No connected Android device and no AVD available. |
| Notification contrast regression | Pass | 2 tests passed. |
| Flutter analyzer | Pass | `flutter analyze lib test` returned no issues. |
| Android debug build | Pass | APK built at `build/app/outputs/flutter-apk/app-debug.apk`. |

## Manual Device Checklist

Run these on an Android emulator or physical Android phone after installing the debug APK.

### Setup

1. Start the backend if testing live native analysis:

   ```powershell
   cd backend
   dart run bin/server.dart
   ```

2. For an emulator, run the app normally. The default backend URL is `http://10.0.2.2:8080`.
3. For a physical phone, install/run with a LAN backend URL:

   ```powershell
   flutter run --dart-define=API_BASE_URL=http://<computer-lan-ip>:8080
   ```

4. Enable Guardian Mode in the app and grant notification permission on Android 13+.

### Required Pass Criteria

| Case | Steps | Expected |
|---|---|---|
| Idle collapsed | Pull notification shade down partially after enabling Guardian Mode. | App name/title and idle helper text are readable. |
| Idle expanded | Expand the Guardian notification. | Custom dark layout, white/near-white text, and notification action are readable. |
| Scanning | Use the notification action, paste/type short suspicious text through Android RemoteInput, and submit. | Notification changes to the scanning state; title remains readable. |
| Result | Wait for backend response. | Risk bar, risk label, and analysis message are readable. |
| Status/error | Submit empty input or test with backend offline. | Status title and error message are readable. |
| Analyze Again | From result/error state, tap Analyze Again and submit a second input. | RemoteInput opens again and the notification can return to scanning/result. |
| Stop service | Disable Guardian Mode in the app. | Pinned notification disappears. |

### Visual Matrix

Capture screenshots for each of these combinations if time permits:

| Dimension | Values |
|---|---|
| Notification state | idle, scanning, result, status/error |
| Shade state | collapsed, expanded |
| System theme | light, dark |
| Android font size | default, large |
| Device type | emulator, target physical demo phone |

## Current Verdict

Notification layout contrast has automated XML-level regression coverage. Actual Android notification rendering remains pending until an Android emulator or physical device is connected.
