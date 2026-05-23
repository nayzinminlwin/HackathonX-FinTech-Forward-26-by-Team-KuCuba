# KuCuba Agent Guardrails — `rule.md`

> **Purpose:** This file defines the strict operating constraints for any AI agent deployed to implement the KuCuba "Everywhere Scam Detector" project. Agents MUST read and comply with every rule in this document before writing a single line of code.

> **Workflow entry point:** Start with [`docs/SOP_blueprint.md`](../SOP_blueprint.md) for the full read-order, dev/test logging, and copy-paste prompts. Then use this file for DO/DON'T details.

---

## 0. Core Principles

| # | Principle | Rationale |
|---|-----------|-----------|
| 1 | **Plan docs are the source of truth.** | Follow `docs/SOP_blueprint.md` for session workflow. Implementation decisions trace to `docs/Phase_1_*.md`, `Phase_2_*.md`, `Phase_3_*.md`, and `docs/Detailed_System_Requirement_Document.md`. Guardrails: this file. |
| 2 | **Respect phase dependencies (not strict 1→2→3).** | **Foundation:** Phase 1 **backend** (`POST /analyze`) must be verified before Phase 2 or Phase 3 client work. **Parallel:** Phase 2 (Share Sheet) and Phase 3 (Notification Banner) are **separate entry points** to the same backend — either may start once the backend is live; they do **not** block each other. Phase 2 still needs Phase 1 Flutter widgets (meter, message card). Phase 3 does **not** require Phase 2. Coordinate `android/` merges if both branches edit manifest/MainActivity. |
| 3 | **No scope creep.** | Do not add features, screens, or logic that are not in the plan documents. When in doubt, do less. |
| 4 | **Hackathon context.** | This is a 33-hour hackathon. Favour working, demonstrable code over architectural perfection. Never spend time on "nice-to-have" items if core functionality is not yet verified. |
| 5 | **Ask before inventing.** | If the plan is ambiguous or a specific decision is not documented, stop and surface the question. Do not silently make an assumption and code around it. |
| 6 | **Log dev work in `docs/dev_logs/<branch>/`.** | Use `dev0`, `dev1`, or `dev2` matching your git branch. Large work → new dated file; small fixes → append `small_patches.md` in that folder. See §12. |

### 0.1 Phase dependency model

```
Phase 1 — Foundation
├── Backend (dev0/dev1): POST /analyze pipeline     ← REQUIRED for Phase 2 & 3
└── Flutter core (dev2): sandbox UI, meter, API layer ← REQUIRED for Phase 2 overlay reuse

Phase 2 — Share Sheet (dev2)          ╮
    └── ACTION_SEND → overlay → POST /analyze     ├── May run IN PARALLEL
Phase 3 — Notification banner (dev2)    ╯
    └── Foreground service → Kotlin POST /analyze
```

| Phase | Depends on | Does not require |
|-------|------------|------------------|
| **1** | — | — |
| **2** | Phase 1 backend + Phase 1 Flutter widgets (`AnalogMeter`, `AnalysisMessageCard`, API layer) | Phase 3 |
| **3** | Phase 1 **backend** verified (`POST /analyze`); optional Phase 1 home toggle for Guardian Mode | Phase 2 (Share Sheet) |

---

## 1. Project Identity & Structure

### 1.1 DO ✅

- Place all Flutter/Dart source code under `lib/` following the exact folder layout specified in Phase 1 §1.2.
- Place all backend (Dart Shelf) code under `backend/` as a separate entry point.
- Place all native Android (Kotlin) code under `android/app/src/main/kotlin/com/kucuba/eternal_guardian/`.
- Place notification XML layouts under `android/app/src/main/res/layout/`.
- Place drawable resources (e.g., `ic_shield.xml`) under `android/app/src/main/res/drawable/`.
- Use the Android application ID `com.kucuba.eternal_guardian` and Flutter package name `eternal_guardian` exactly (see root `pubspec.yaml`).
- Keep `resources/` (brand assets) read-only; copy assets to `assets/` when needed by Flutter.

### 1.2 DO NOT ❌

- Do not rename any files or folders that are explicitly named in the plan docs.
- Do not place Dart files in `android/` or Kotlin files in `lib/`.
- Do not create a separate `features/` or `modules/` reorganization. The folder structure from Phase 1 §1.2 is final.
- Do not create a `test/` implementation unless explicitly requested. Test files that already exist must not be deleted.

---

## 2. Technology Stack

### 2.1 DO ✅

- **Flutter:** Use Flutter with Android-only platform target (`--platforms android`). Min SDK 24, Target SDK 35, Compile SDK 35.
- **State Management:** Use **Provider** (`provider: ^6.1.2`). This is the only allowed state management solution.
- **HTTP Client (Flutter):** Use **Dio** (`dio: ^5.7.0`) for all HTTP calls within the Flutter app.
- **Font:** Use **Poppins** from `google_fonts: ^6.2.1`. This is the only allowed font family.
- **Animations:** Use **`flutter_animate: ^4.5.2`** for widget-level micro-animations.
- **Backend Runtime:** Use **Dart Shelf** (`shelf: ^1.4.2`, `shelf_router: ^1.1.4`) for the backend server.
- **LLM:** Use the **`google_generative_ai: ^0.4.6`** Dart package, model `gemini-2.0-flash`.
- **Share Intent (Phase 2):** Use **`receive_sharing_intent: ^1.8.1`** for OS share-sheet integration.
- **Permissions (Phase 3):** Use **`permission_handler: ^11.3.1`** for runtime notification permission.
- **Native HTTP (Phase 3):** Use **`java.net.HttpURLConnection`** (stdlib) for Kotlin-side backend calls. Do not add `okhttp3` as a separate dependency unless `HttpURLConnection` is conclusively insufficient.

### 2.2 DO NOT ❌

- Do not use `Riverpod`, `Bloc`, `GetX`, `MobX`, or any other state management library.
- Do not use `http` package in the Flutter app — Dio is the mandated HTTP client.
- Do not use `flutter_local_notifications` — Phase 3 uses native `RemoteViews` and `NotificationCompat` directly from Kotlin.
- Do not use any CSS, React, Vue, or web technologies. This is a native Flutter + Kotlin project.
- Do not upgrade any package version beyond what is specified without explicitly noting it and checking for breaking changes.
- Do not add any dependency not listed in the plan documents without surfacing it as a decision point.

---

## 3. Backend Service Rules

### 3.1 DO ✅

- Expose exactly **one route: `POST /analyze`** on `0.0.0.0:8080`.
- Follow the **exact three-step processing flow**: (1) URL extraction via Regex → (2) Safe Browsing API check → (3) Gemini LLM call.
- Always return the **exact JSON schema**: `{"risk_score": <int 1-100>, "analysis_message": "<string, max 2 sentences>"}`.
- On any unhandled error, return `{"risk_score": -1, "analysis_message": "Analysis temporarily unavailable."}` — never crash or return a 5xx with no body.
- Enforce **Step 2 before Step 3**. If the Safe Browsing API detects a threat, immediately return `risk_score: 100` and **skip the LLM call entirely** to save tokens.
- If no `SAFE_BROWSING_API_KEY` is available in `.env`, guard with `if (apiKey.isEmpty) return false;` and proceed to Gemini.
- Load API keys **exclusively** from `.env` via `dotenv`. Never hardcode keys in source files.
- Use the **exact Few-Shot system prompt** from Phase 1 §2.5, including all 5 scam examples and 5 safe examples.
- Set Gemini generation config to `temperature: 0.1` and `responseMimeType: application/json`.

### 3.2 DO NOT ❌

- Do not add additional routes (e.g., `/history`, `/health`, `/status`) unless explicitly requested.
- Do not log or store any user-provided `text_payload` to disk or any database. No persistent data collection.
- Do not change the LLM model from `gemini-2.0-flash` to a heavier model. Cost and latency are critical.
- Do not call the Gemini API if the Safe Browsing API has already confirmed a threat. This wastes tokens.
- Do not allow the backend to return a `risk_score` outside the range 1–100 (except the error sentinel `-1`). Validate and clamp before returning.

---

## 4. Flutter App — Theme & Branding

### 4.1 DO ✅

- Apply `bankIslamTheme()` at the root `MaterialApp` level — every screen inherits it automatically.
- Use only the **canonical color tokens** from `theme/app_colors.dart`:

  | Token | Hex |
  |---|---|
  | `corporateRed` | `#ED2321` |
  | `background` | `#FFFFFF` |
  | `textPrimary` | `#1A1A1A` |
  | `textSecondary` | `#757575` |
  | `meterGreen` | `#2ECC71` |
  | `meterYellow` | `#F1C40F` |
  | `meterRed` | `#E74C3C` |
  | `surfaceCard` | `#F8F9FA` |
  | `divider` | `#E0E0E0` |

- Use `useMaterial3: true` in `ThemeData`.
- Use `Poppins` in the exact text style sizes specified in Phase 1 §3.2.

### 4.2 DO NOT ❌

- Do not hardcode hex color strings in Flutter/Dart outside `lib/theme/app_colors.dart`. Always reference `AppColors.*` tokens.
- Native `android/app/src/main/res/` (layouts, drawables) and Kotlin may use the same hex values as `AppColors` (e.g. `#ED2321`); Flutter must use `AppColors` only.
- Do not use `Colors.red`, `Colors.blue`, or any `Colors.*` constants directly. Use `AppColors.*`.
- Do not change the brand color from `#ED2321`. This is Bank Islam's Corporate Red.
- Do not use any font other than Poppins.
- Do not use `Material 2` widgets that conflict with `useMaterial3: true`.

---

## 5. Mock / Demo Mode

### 5.1 DO ✅

- Control mock mode exclusively via `AppConfig.useMockApi` (a single `const bool` in `config/app_config.dart`).
- When `useMockApi == true`, use `MockApiService`; when `false`, use `LiveApiService`. This switch happens **only in `main.dart`**.
- The `MockApiService` must simulate a 1500ms delay to realistically represent the async UX.
- Default `useMockApi` to `true` so the app is always demo-ready without a live backend.

### 5.2 DO NOT ❌

- Do not scatter `if (isMock)` conditionals throughout widgets or providers. The abstraction interface `AnalysisApiService` must hide this detail completely.
- Do not remove or alter the `MockApiService` keyword-matching logic — it powers the hackathon demo for specific test phrases.
- Do not change `backendBaseUrl` from `http://10.0.2.2:8080` (Android emulator → localhost) without documenting the reason.

---

## 6. Phase 1 — Core App Module

### 6.1 DO ✅

- Build the `AnalogMeter` widget using `CustomPainter` on a `CustomPaint` widget. This is the mandated approach.
- The meter must render a **180° half-circle arc** with three colored zones:
  - Green (0°–54°): score 1–30
  - Yellow (54°–126°): score 31–70
  - Red (126°–180°): score 71–100
- Animate the needle using `AnimationController` + `Tween<double>` + `CurvedAnimation(curve: Curves.easeOutBack)` over **1200ms**.
- Display four distinct `AnalysisState` UI states: `idle`, `loading` (skeleton), `complete` (meter + card), `error` (red banner).
- The **Analyze button must be disabled** whenever: (a) the input is empty, or (b) `AnalysisState.loading` is active.
- Use `ChangeNotifierProvider` wrapping the entire widget tree from `main.dart`. The provider must receive the `AnalysisApiService` via constructor injection.

### 6.2 DO NOT ❌

- Do not implement Scan History, saved results, or any form of local database. This feature was explicitly **removed** from scope.
- Do not use a web chart library or any third-party package for the analog meter. It must be a pure `CustomPainter` implementation.
- Do not allow duplicate API calls (button must be disabled while a request is in-flight).
- Do not show the meter or message card in the `idle` state. They must be hidden (`SizedBox.shrink()`).

---

## 7. Phase 2 — OS Share-Sheet Overlay

### 7.1 DO ✅

- Add the `ACTION_SEND` / `text/plain` intent filter to the **existing `MainActivity`** entry in `AndroidManifest.xml` (not a new activity). Use `android:launchMode="singleTask"`.
- Use `receive_sharing_intent` to capture the shared text in Dart via both `getInitialMedia()` (cold start) and `getMediaStream()` (warm start).
- Route the app via `IntentRouter` as the root widget, not directly to `HomeScreen`.
- **Auto-trigger** analysis immediately in `OverlayScreen.initState()` using `addPostFrameCallback`. No "Analyze" button is shown in the overlay.
- **Reuse** `AnalogMeter` and `AnalysisMessageCard` widgets from Phase 1 without duplicating logic. Add a `compact` boolean parameter to both if size adjustments are needed.
- The overlay must be a **full-screen `Scaffold` with a manual bottom-aligned container**, NOT a `showModalBottomSheet` call (which cannot disable tap-to-dismiss).
- Wrap the overlay `Scaffold` in `PopScope` to intercept the physical Android back button.
- **Both** the "✕" button and the physical back button must call **the exact same dismissal method**: `ReceiveSharingIntent.instance.reset()` followed by `SystemNavigator.pop()`.
- Tapping the dark scrim (background outside the sheet) must do **nothing** — tap-to-dismiss is disabled per FR 2.5.

### 7.2 DO NOT ❌

- Do not use `showModalBottomSheet` — it has uncontrollable tap-to-dismiss behavior.
- Do not call `Navigator.pop()` or `Navigator.maybePop()` to dismiss the overlay — use `SystemNavigator.pop()` to cleanly return to the originating app.
- Do not open the overlay as a full-screen app takeover. The WhatsApp/SMS app must remain visible in the back stack.
- Do not add an "Analyze" button to the overlay. Analysis is always automatic (FR 2.3).
- Do not allow different dismiss behaviors between the "✕" button and the physical back button. They must be identical.
- Do not use `setCancelable(false)` Android API directly; achieve the same effect via the Flutter `PopScope` + non-reactive scrim `GestureDetector`.

---

## 8. Phase 3 — Pinned Notification Banner

> [!IMPORTANT]
> Phase 3 is a **stretch goal** and may run **in parallel with Phase 2** once the Phase 1 **backend** is verified. It does **not** require the Share Sheet (Phase 2) to be complete. If fewer than 8 hours remain in the hackathon, **do not implement Phase 3**. Prepare a slide/mockup instead.

### 8.1 DO ✅

- Implement the foreground service in Kotlin as `ScamDetectorForegroundService.kt` extending `Service`.
- Use `IMPORTANCE_LOW` for the notification channel (no sound, persistent) as specified in Phase 3 §2.1.1.
- Use `RemoteViews` for all three notification layout states: `notification_idle.xml`, `notification_scanning.xml`, `notification_result.xml`.
- Implement `AnalyzeReceiver` as a `BroadcastReceiver` triggered by `PendingIntent` from the notification button.
- Make the `AnalyzeReceiver` call the backend **directly in Kotlin** using `HttpAnalysisClient` (stdlib `HttpURLConnection`). Do not wake the Flutter engine from a notification tap.
- Use `MethodChannel('com.kucuba/notification_service')` as the exact channel name for Flutter ↔ native communication.
- Request `POST_NOTIFICATIONS` permission at runtime on Android 13+ (API 33) before starting the service.
- Declare in `AndroidManifest.xml`: `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SPECIAL_USE`, and `POST_NOTIFICATIONS` permissions.
- If clipboard access from `BroadcastReceiver` fails on the test device, fall back to opening the `HomeScreen` with a paste-from-clipboard action (the documented 15-minute fallback).
- Always show the service's `START_STICKY` return to ensure the OS restarts it if killed.

### 8.2 DO NOT ❌

- Do not use `flutter_local_notifications` or any Flutter notification plugin. All notification construction is native Kotlin with `NotificationCompat` and `RemoteViews`.
- Do not register `BOOT_COMPLETED` or auto-start the service on device reboot. This is explicitly out of scope.
- Do not use `SYSTEM_ALERT_WINDOW` permission. The overlay effect is achieved via a transparent-themed Activity, not a system overlay.
- Do not implement Phase 3 before the Phase 1 **backend** gate passes (`POST /analyze` working). Phase 2 completion is **not** a prerequisite.
- Do not implement the foreground service before the backend `POST /analyze` contract is confirmed working (curl or `HttpAnalysisClient` smoke test).
- Do not read clipboard content unless the "Analyze Copied Text" button is explicitly tapped. No passive/automatic clipboard monitoring.

---

## 9. API & Data Contract

### 9.1 DO ✅

- Always use the `AnalysisResult` model (`models/analysis_result.dart` and its Kotlin equivalent) as the data contract between all layers.
- Always validate that `risk_score` is a valid integer between 1 and 100 before rendering. If out of range or `-1`, show the error state.
- Send exactly `{"text_payload": "<string>"}` in the request body to `POST /analyze`.

### 9.2 DO NOT ❌

- Do not change the JSON key names (`risk_score`, `analysis_message`, `text_payload`). They are the contract between frontend and backend.
- Do not add extra fields to the request or response schema without updating all consuming code simultaneously.
- Do not cache or locally store `risk_score` or `analysis_message` results. Every analysis is ephemeral.

---

## 10. Security & Privacy

### 10.1 DO ✅

- Store `GEMINI_API_KEY` and `SAFE_BROWSING_API_KEY` exclusively in a `.env` file loaded by `dotenv` at backend startup.
- Add `.env` to `.gitignore` immediately. Never commit API keys.
- Treat all `text_payload` values as sensitive PII. Process in-memory only; never log to file or console in production mode.

### 10.2 DO NOT ❌

- Do not hardcode any API key, URL, or secret in any Dart, Kotlin, or XML source file.
- Do not log the contents of `text_payload` at any log level in the backend.
- Do not make the backend publicly accessible without authentication beyond local/WiFi LAN for the hackathon demo.

---

## 11. Verification Gates

Before handing off any phase to the next agent or marking it complete, the following gates **must pass**:

### Phase 1 Gate ✅

- [ ] `flutter analyze` returns zero errors
- [ ] `flutter build apk --debug` completes successfully
- [ ] App launches with Bank Islam branding (red AppBar, Poppins font)
- [ ] Multi-line text input accepts pasted text
- [ ] Analyze button shows spinner and disables during analysis
- [ ] Mock mode returns results and the needle animates correctly
- [ ] Meter zones show correct colors (green ≤30, yellow 31–70, red ≥71)
- [ ] Empty input disables the Analyze button
- [ ] Error state shows retry banner

### Phase 2 Gate ✅

- [ ] App appears in the Android share menu from WhatsApp and SMS
- [ ] Overlay renders over the sharing app (not full-screen)
- [ ] Analysis auto-triggers without any user button press
- [ ] Tapping the background scrim does NOT dismiss the overlay
- [ ] "✕" button returns to WhatsApp/SMS cleanly
- [ ] Physical Android back button produces identical behavior to "✕" button
- [ ] Sharing while app is already open is handled correctly

### Phase 3 Gate ✅ *(if implemented)*

- [ ] Foreground service persists when the app is swiped away from recents
- [ ] "Analyze Copied Text" button reads clipboard and shows "Scanning..." state
- [ ] Notification updates with risk bar and analysis message after result arrives
- [ ] Service stops cleanly when the toggle is disabled
- [ ] Notification permission dialog appears on Android 13+

---

## 12. Development & Debug Logs (`docs/dev_logs/<branch>/`)

Agents **must** document implementation work and debugging under the **branch subfolder** that matches the current git branch. Do not skip logging because a change “seems small.”

### 12.0 Branch folders

| Subfolder | Git branch | Typical scope |
|-----------|------------|----------------|
| `docs/dev_logs/dev0/` | `dev0` | **Backend** — `backend/`, `POST /analyze`, Safe Browsing, Gemini |
| `docs/dev_logs/dev1/` | `dev1` | **Backend** — same as `dev0` (second backend developer / branch) |
| `docs/dev_logs/dev2/` | `dev2` | **Frontend** — `lib/`, Flutter UI, Android share overlay, Dio; Phase 3 UI/native as assigned |

Do **not** place dated logs or `small_patches.md` at `docs/dev_logs/` root (except updates to `docs/dev_logs/README.md`).

### 12.1 When to create a **new file** (large work)

Create a dedicated markdown file **inside your branch folder** for:

- New modules or major features (e.g. entire `backend/`, Phase 2 overlay, Phase 3 foreground service)
- Large refactors touching many files
- Multi-step debug investigations (build failures, intent/share issues, API integration)
- Anything that would exceed ~30 lines in a log entry

**Path:** `docs/dev_logs/<branch>/YYYY-MM-DD_<short-topic>.md` (e.g. `docs/dev_logs/dev0/2026-05-22_phase1_backend.md`).

**Suggested sections:** goal, branch, files changed, approach, issues/debug steps, resolution, verification commands run.

### 12.2 When to **append** to the branch small-patches log (small work)

Append to `docs/dev_logs/<branch>/small_patches.md` for:

- Single-file or few-line fixes
- Dependency bumps, lint fixes, copy/theme tweaks
- Quick config or manifest edits
- Short debug notes (one root cause + fix)

Add a dated entry at the **top** of the file (newest first). Keep each entry concise (bullet list is fine).

### 12.3 DO ✅

- Log after completing a meaningful chunk of work, or when handing off to another agent.
- Use the subfolder for **your** branch only (`dev0`, `dev1`, or `dev2`).
- Include **what** changed, **why**, and **how you verified** (e.g. `flutter analyze`, manual test).
- Record failed attempts and fixes during debugging — not only the final solution.
- Reference related phase doc sections when relevant (e.g. Phase 2 §3.4).

### 12.4 DO NOT ❌

- Do not put API keys, `.env` values, or full `text_payload` samples in dev logs.
- Do not create a new file for every one-line change — use your branch’s `small_patches.md`.
- Do not write another developer’s logs into your folder (avoid cross-branch edits in `docs/dev_logs/`).
- Do not leave your branch folder without a log entry after a coding session that changed project behavior.

---

## 13. Escalation Rules

If any of the following situations arise, **stop and report immediately** — do not attempt to silently work around:

1. `receive_sharing_intent` fails to capture shared text on the test device.
2. Clipboard access from `BroadcastReceiver` is blocked by the Android version.
3. The Gemini API returns malformed JSON or a non-JSON response.
4. `flutter build apk --debug` fails with a compilation error after phase completion.
5. A package version conflict is detected in `pubspec.lock` that cannot be resolved without upgrading or downgrading a specified dependency.
6. The backend returns a `risk_score` outside 1–100 for a clearly benign input (indicates a system prompt issue).

---

*Last updated: 2026-05-23 | Project: KuCuba — Everywhere Scam Detector (Be U by Bank Islam) | Dev logs: `docs/dev_logs/dev0|dev1|dev2/`*
