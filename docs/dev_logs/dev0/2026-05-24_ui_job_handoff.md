# 2026-05-24 - UI Job Handoff

**Branch:** dev0  
**App:** Eternal Guardian  
**Group:** KuCuba  
**Scope:** Share overlay overflow fix, native notification contrast, and compact viewport regression coverage

## User Request

Fix the UI overflow warning seen while running the app:

```text
A RenderFlex overflowed by 7.0 pixels on the bottom.
```

Also improve the Android notification banner so the app name and notification text are readable against the notification background.

## What Was Done

### Share Overlay Layout

- Updated `lib/screens/overlay_screen.dart`.
- Changed the overlay bottom panel to use a bounded height based on the viewport.
- Moved variable-height overlay content into a scrollable body.
- Kept the primary action button outside the scrollable area so it remains stable.
- Reduced vertical spacing in the compact overlay state.

### Compact Meter and Loader

- Updated `lib/widgets/analog_meter.dart`.
- Reduced compact meter dimensions so it fits inside small overlay panels.
- Updated `lib/widgets/skeleton_meter_placeholder.dart`.
- Reduced compact loading placeholder dimensions.
- Wrapped the staged loading label stack in a scaling container so the loader does not overflow its fixed compact area.

### Notification Contrast

- Updated `android/app/src/main/AndroidManifest.xml`.
- Changed the Android app label from `eternal_guardian` to `Eternal Guardian`.
- Updated native notification custom layouts:
  - `android/app/src/main/res/layout/notification_idle.xml`
  - `android/app/src/main/res/layout/notification_scanning.xml`
  - `android/app/src/main/res/layout/notification_status.xml`
  - `android/app/src/main/res/layout/notification_result.xml`
- Set notification custom layout backgrounds to dark colors.
- Set important notification text to white or near-white colors.
- Updated visible notification title text to use `Eternal Guardian` naming.

### Regression Tests

- Added `test/ui_overflow_test.dart`.
- Added a compact viewport test for the core app flow.
- Added a compact 320x480 viewport test for the share overlay loading and result states.
- The test captures Flutter framework exceptions and fails on layout overflow errors.

## Validation Performed

Commands run:

```powershell
flutter test test/ui_overflow_test.dart
flutter analyze lib test
flutter test
flutter build apk --debug
```

Results:

| Check | Result | Notes |
|---|---|---|
| Compact overflow regression test | Pass | The reproduced overflow is now covered by `test/ui_overflow_test.dart`. |
| Flutter analyzer | Pass | `flutter analyze lib test` completed without issues. |
| Full Flutter test suite | Pass | 7 tests passed. |
| Android debug build | Pass | APK built successfully at `build/app/outputs/flutter-apk/app-debug.apk`. |

Detailed test log:

- `docs/test_logs/2026-05-24_ui_overflow_notification_contrast.md`

Rolling dev log entry:

- `docs/dev_logs/dev0/small_patches.md`

## What Still Needs To Be Done

### Required Manual Runtime Check

- Run the app on an Android emulator or physical Android phone.
- Enable Guardian Mode.
- Trigger the persistent notification.
- Confirm the notification is readable in:
  - collapsed notification state
  - expanded notification state
  - idle state
  - scanning state
  - status/error state
  - result state

### Suggested Visual Checks

- Test the share overlay on a very small Android viewport.
- Test with large Android system font size enabled.
- Test both light and dark Android system themes.
- Capture screenshots of the notification banner after install to confirm OEM/system notification styling does not override the custom contrast in an unexpected way.

### Possible Follow-Up Improvements

- Add golden tests for the share overlay once the visual design is stable.
- Add a small Android instrumentation/manual QA checklist for notification rendering because Flutter widget tests cannot fully validate native notification UI.
- Consider moving notification colors into Android resource values if more notification themes are added.

## Notes For Next Chat

- Do not revert unrelated dirty files in `test/`; there are local/generated test artifacts and user files there.
- Full-root `flutter analyze` may still report existing backend info-level lint findings. For this UI job, the relevant analyzer command is `flutter analyze lib test`, which passed.
- Guardian Mode notification analysis depends on the backend being reachable. On an emulator the default backend URL is `http://10.0.2.2:8080`; on a physical phone it should be passed with `--dart-define=API_BASE_URL=http://<computer-lan-ip>:8080`.
