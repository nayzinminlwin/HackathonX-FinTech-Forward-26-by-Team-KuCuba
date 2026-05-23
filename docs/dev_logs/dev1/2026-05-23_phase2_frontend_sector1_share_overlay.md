# Phase 2 Frontend — Sector 1: OS Share-Sheet Overlay

**Date:** 2026-05-23 10:00  
**Branch:** `dev1`  
**Engineer:** Backend/Integration Lead  
**Scope:** Android manifest injection, intent routing, overlay screen, provider wiring, emulator simulation  
**Prerequisite:** Phase 1 backend pipeline operational (Sector 1 of this branch)  
**Status:** ✅ Architecturally complete — awaiting UI styling handoff

---

## Goal

Wire Phase 2's OS-level share-sheet integration: register the app as an Android `ACTION_SEND` target, route shared text through `IntentRouter`, render a transparent overlay bottom sheet, and connect it to the Phase 1 backend via `AnalysisProvider`.

---

## Environment Notes

### Dependency Patch (Kotlin JVM Mismatch)
- **Issue:** The `receive_sharing_intent` package on `pub.dev` contains a known Java 1.8 vs. Kotlin 21 mismatch bug, causing fatal Android build failures.
- **Resolution:** Bypassed the official package and linked the dependency directly to a patched GitHub commit in `pubspec.yaml`. Added `kotlin.jvm.target.validation.mode=warning` to `gradle.properties` to suppress strict JVM checks.
- **Action Required:** Developers **MUST** run `flutter clean` followed by `flutter pub get` immediately after pulling this branch to clear broken caches and fetch the custom GitHub patch.

### Dart SDK Version
- **Final version:** `sdk: ^3.6.0` (aligned across all branches). Teammates must update their local environment to match.

### Native OS Testing Restrictions
- Phase 2 logic relies entirely on native Android OS hooks (`ACTION_SEND` and `PROCESS_TEXT`) injected into `android/app/src/main/AndroidManifest.xml`.
- The application **CANNOT** be tested on Google Chrome (Web) or Windows Desktop. Testing must strictly be conducted on an **Android Emulator** or a **Physical Android Device**.

---

## Files Changed

### [MODIFIED] `android/app/src/main/AndroidManifest.xml`
- Added `<intent-filter>` for `ACTION_SEND` (`text/plain`) to register the app in the Android Share-Sheet.
- Added `<intent-filter>` for `PROCESS_TEXT` to handle highlighted text actions.

### [NEW] `lib/screens/intent_router.dart`
- Implemented `receive_sharing_intent` to listen for cold and warm state text payloads.
- Routes between `HomeScreen` (normal launch) and `OverlayScreen` (share intent launch).

### [NEW] `lib/screens/overlay_screen.dart`
- Transparent `Scaffold` that renders a bottom sheet over the host app (e.g., WhatsApp).
- Auto-triggers `AnalysisProvider.analyze()` in `initState` via `addPostFrameCallback` — no manual button tap required.
- Reuses Phase 1 widgets (`AnalogMeter`, `AnalysisMessageCard`).
- `PopScope` prevents accidental back-button exit.

### [NEW] `lib/providers/analysis_provider.dart`
- Wired Flutter UI to the Dart backend via HTTP POST to `http://10.0.2.2:8080/analyze`.
- State machine: `initial` → `loading` → `complete` / `error`.
- Parses `risk_score` and `analysis_message` from backend JSON response.

### [MODIFIED] `lib/main.dart`
- Added `MultiProvider` with `AnalysisProvider`.
- Set `IntentRouter` as app home to catch shared text on startup.
- Bank Islam Red (`#ED2321`) primary color.

### [CREATED — placeholder] `lib/widgets/analog_meter.dart`
- Structural placeholder: `Icon(Icons.speed)` + risk score text with color coding.
- **Pending:** `CustomPainter` arc gauge with animated needle and Bank Islam branding.

### [CREATED — placeholder] `lib/widgets/analysis_message_card.dart`
- Structural placeholder: grey container with message text.
- **Pending:** Bank Islam styled card with red/white theme and typography.

### [CREATED — placeholder] `lib/screens/home_screen.dart`
- Minimal scaffold with placeholder text.
- **Pending:** Full Phase 1 UI (text input, Analyze button, state-driven display).

---

## Simulation Protocol

Because the application intercepts Android OS intents, it does not function like a standard app. To simulate a real-world scam interception:

1. **Start the Backend:** Terminal 1 → `cd backend` → `dart run bin/server.dart`.
2. **Start the App:** Terminal 2 → `flutter run` (ensure Android Emulator is active).
3. **Hide the App:** When the app opens showing the placeholder screen, send it to the background via the Android Home button.
4. **Trigger the Intercept:**
   - Open Google Chrome or SMS Messages on the emulator.
   - Highlight a target sentence (e.g., *"Click here to claim RM10,000"*).
   - Tap **Share** from the Android popup menu.
   - Select **Eternal Guardian** from the app list.
5. **Expected Result:** The transparent `OverlayScreen` slides up directly over Chrome/Messages, instantly triggering `AnalysisProvider` to fetch the AI risk score from the backend.

---

## Verification

- ✅ **Android OS Hook:** `AndroidManifest.xml` intercepts `ACTION_SEND` and `PROCESS_TEXT` intents.
- ✅ **Intent Routing:** `IntentRouter` catches shared text payloads from external apps without crashing.
- ✅ **Backend Connection:** `AnalysisProvider` transmits shared text to the backend and correctly parses the Gemini risk score JSON.
- ✅ **Overlay Architecture:** `OverlayScreen` renders as a transparent bottom sheet over host apps.
- See `docs/test_logs/Phase_1_and_2_Test_Results.md` for formal test results.

---

## Pending Tasks (Frontend Handoff)

- ⏳ **UI/Styling:** Core widgets (`analog_meter.dart` and `analysis_message_card.dart`) currently render as basic structural placeholders. They require:
  - Bank Islam brand styling (red/white theme)
  - `CustomPainter` arc gauge with animated needle
  - Poppins typography via `google_fonts`
  - Micro-animations via `flutter_animate`
- ⏳ **HTTP client:** `analysis_provider.dart` currently uses `package:http` — must migrate to `package:dio` per `rule.md`.
- ⏳ **Mock mode:** `AppConfig.useMockApi` toggle + `MockApiService` not yet implemented.
