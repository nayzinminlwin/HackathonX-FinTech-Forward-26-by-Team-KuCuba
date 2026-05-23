---
name: kucuba-scam-detector
description: >-
  Implements KuCuba ("Everywhere Scam Detector", Eternal Guardian by Bank Islam): an
  Android-only Flutter app with Bank Islam branding, Provider state, Dio API
  client, CustomPainter analog risk meter, mock/demo mode, Dart Shelf backend
  (POST /analyze with regex URL extraction, Google Safe Browsing, Gemini
  gemini-2.0-flash), Phase 2 share-sheet overlay via receive_sharing_intent,
  and optional Phase 3 native foreground-service notification with
  RemoteViews and Kotlin HttpURLConnection. Use when building or extending this
  hackathon project, scam-analysis UX, hybrid rule+LLM pipelines, or
  Flutter+Kotlin Android integrations. Always read docs/SOP_blueprint.md first,
  then docs/AI/rule.md and phase plans before coding. Apply only in-scope Phase 1–3 work.
---

# KuCuba — Everywhere Scam Detector

**Default**: analysis runs through a **local Shelf backend** on port 8080, with **mock mode** enabled so demos work without keys. **Phase 1 backend** is the foundation. **Phase 2 (Share Sheet) and Phase 3 (Notification)** are independent client surfaces to the same `POST /analyze` — they may be built **in parallel** after the backend is verified. Phase 2 still needs Phase 1 Flutter widgets; Phase 3 does not need Phase 2.

**Workflow:** `docs/SOP_blueprint.md` — status analysis, implementation order, dev/test logs, prompts.

**Source of truth** (in order):

1. `docs/AI/rule.md` — agent guardrails (mandatory)
2. `docs/Phase_1_Core_App_Module.md`
3. `docs/Phase_2_OS_Share_Sheet_Overlay.md`
4. `docs/Phase_3_Pinned_Notification_Banner.md`
5. `docs/Detailed_System_Requirement_Document.md`

On conflict between a plan detail and `rule.md`, stop and escalate — do not assume.

## Product shape

- **User (Phase 1)**: Pastes suspicious chat text on the home screen, taps **Analyze**, sees an animated **180° analog meter** (green/yellow/red zones) and a short **analysis message**.
- **User (Phase 2)**: From WhatsApp/SMS/etc., **Share → Scam Detector**; overlay opens over the sharing app, **auto-analyzes** shared text (no Analyze button), shows the same meter + card; dismiss only via **✕** / **Done** / back (identical behavior) — scrim tap does nothing.
- **User (Phase 3, stretch)**: Enables **Guardian Mode**; a **pinned notification** offers **Analyze Copied Text**; native Kotlin reads clipboard on button tap, calls backend, updates notification with risk bar + message.
- **Backend**: Single route `POST /analyze` — regex URLs → Safe Browsing (skip LLM if threat) → Gemini JSON `{risk_score, analysis_message}`.
- **Hackathon constraints**: No scan history, no local DB, no scope beyond plan docs. Prefer **working demo** over extra architecture.

## Hybrid analysis pipeline

**Principle**: Cheap/fast checks before LLM. Never call Gemini if Safe Browsing already flagged a URL.

```
text_payload
    → link_extractor (regex)
    → IF urls: safe_browsing.checkUrls
         → IF threat: return risk_score 100 (fixed message), STOP
    → gemini_service.analyzeText (few-shot, JSON-only)
    → validate risk_score 1–100, return
```

On any failure: `{"risk_score": -1, "analysis_message": "Analysis temporarily unavailable."}` — never empty 5xx body.

## Repository layout (current paths — do not rename)

| Path | Role |
|------|------|
| `pubspec.yaml` | Flutter package `eternal_guardian` |
| `lib/main.dart` | App entry (extend per phase plans) |
| `lib/` | Flutter UI, Provider, Dio/mock, theme, widgets (add subdirs in Phase 1) |
| `backend/` | Dart Shelf server (create in Phase 1) |
| `android/app/src/main/kotlin/com/kucuba/eternal_guardian/` | `MainActivity.kt`; Phase 3 Kotlin here |
| `android/app/src/main/res/layout/` | Phase 3 `notification_*.xml` |
| `android/app/src/main/res/drawable/` | e.g. `ic_shield.xml` |
| `resources/` | Brand JSON + logo (read-only) |
| `docs/AI/rule.md`, `docs/AI/SKILL.md` | Agent guardrails |
| `docs/Phase_*.md`, `docs/Detailed_System_Requirement_Document.md` | Plans + SRD |
| `docs/dev_logs/dev0/`, `dev1/`, `dev2/` | Per-branch dev/debug notes (required after coding; see `docs/dev_logs/README.md`) |
| `docs/test_logs/` | Test run write-ups (separate from dev logs) |

- **Application ID:** `com.kucuba.eternal_guardian`
- **Phase 2:** set `MainActivity` `launchMode` to **`singleTask`** on the existing activity only
- Do not invent alternate layouts (`features/`, `modules/`) or rename the Flutter package

## Technology stack (allowed only)

| Layer | Choice | Notes |
|-------|--------|-------|
| Mobile | Flutter, **Android only** | minSdk 24, target/compileSdk 35 |
| State | **Provider** `^6.1.2` | Only state management |
| HTTP (Flutter) | **Dio** `^5.7.0` | Not `http` package |
| Fonts | **Poppins** via `google_fonts` `^6.2.1` | Only font |
| Animations | `flutter_animate` `^4.5.2` | Micro-animations |
| Share (Phase 2) | `receive_sharing_intent` `^1.8.1` | |
| Permissions (Phase 3) | `permission_handler` `^11.3.1` | `POST_NOTIFICATIONS` on API 33+ |
| Backend | Shelf `^1.4.2`, shelf_router, dotenv, `google_generative_ai` `^0.4.6` | Separate `backend/pubspec.yaml` |
| LLM | `gemini-2.0-flash` | `temperature: 0.1`, `responseMimeType: application/json` |
| Phase 3 HTTP (Kotlin) | `java.net.HttpURLConnection` | Default; `okhttp3` only if HttpURLConnection is insufficient |
| Notifications (Phase 3) | Native `NotificationCompat` + `RemoteViews` | **Not** `flutter_local_notifications` |

**Forbidden**: Riverpod, Bloc, GetX, web/React Native, `flutter_local_notifications`, `http` in Flutter app, `Colors.*` / hardcoded hex in Dart outside `AppColors`, `showModalBottomSheet` for Phase 2 overlay, extra API routes, scan history, local DB, iOS, cloud-only features outside phase plans.

**Colors:** Flutter uses `AppColors` only; native `res/` and Kotlin may use matching hex tokens (see `docs/AI/rule.md` §4).

## API contract (frozen)

**Request** `POST /analyze`:

```json
{"text_payload": "<string>"}
```

**Success response**:

```json
{"risk_score": <int 1-100>, "analysis_message": "<string, max 2 sentences>"}
```

**Error sentinel**: `risk_score: -1` with the standard unavailable message.

Flutter `AnalysisResult` and Kotlin `AnalysisResult` must mirror these keys. No caching or persistence of payloads or results.

## Backend (`backend/`)

### Server

- Listen `0.0.0.0:8080`
- Load `.env` via `dotenv`: `GEMINI_API_KEY`, `SAFE_BROWSING_API_KEY`
- CORS for Flutter dev
- **Exactly one route**: `POST /analyze`

### Link extractor

Regex (conceptual): `(https?:\/\/|www\.)[^\s<>"{}|\\^`\[\]]+` → `List<String>`

### Safe Browsing

- POST `https://safebrowsing.googleapis.com/v4/threatMatches:find?key=...`
- Threat types: `MALWARE`, `SOCIAL_ENGINEERING`, `UNWANTED_SOFTWARE`
- If `SAFE_BROWSING_API_KEY` empty: `return false` and proceed to Gemini

### Gemini

Use the **exact few-shot system prompt** from Phase 1 §2.5 (5 scam + 5 safe Malaysian examples, JSON-only output). Model **`gemini-2.0-flash`**.

### Environment (backend)

| Variable | Purpose |
|----------|---------|
| `GEMINI_API_KEY` | Gemini API |
| `SAFE_BROWSING_API_KEY` | Optional; empty skips step 2 |
| `DATABASE_URL` | N/A — no database |

`.env` must be in `.gitignore`. Never log `text_payload`.

### Backend checklist

- [ ] Three-step flow with Safe Browsing **before** Gemini
- [ ] Threat match → `risk_score: 100`, skip LLM
- [ ] Clamp/validate `risk_score` 1–100 (except -1)
- [ ] Malformed Gemini JSON → error sentinel, not crash
- [ ] No extra routes, no disk logging of user text

## Flutter app (`lib/`)

### Folder structure (Phase 1 §1.2)

```
lib/
├── main.dart
├── app.dart
├── config/          app_config.dart, api_endpoints.dart
├── theme/           app_colors.dart, app_typography.dart, bank_islam_theme.dart
├── models/          analysis_result.dart
├── services/        api_service.dart, mock_api_service.dart
├── providers/       analysis_provider.dart
├── screens/         home_screen.dart (+ intent_router.dart, overlay_screen.dart in Phase 2)
└── widgets/         analog_meter.dart, analysis_message_card.dart,
                     text_input_area.dart, analyze_button.dart
```

### Mock / live switch

- Single flag: `AppConfig.useMockApi` in `config/app_config.dart` (default **`true`**)
- Wire **only in `main.dart`**: `MockApiService` vs `LiveApiService` implementing `AnalysisApiService`
- Mock: **1500ms** delay; keyword rules for demo phrases (do not remove)
- Live base URL: `http://10.0.2.2:8080` (emulator → host localhost)

### Branding

Apply `bankIslamTheme()` at root `MaterialApp`. Colors **only** via `AppColors` tokens:

| Token | Hex |
|-------|-----|
| `corporateRed` | `#ED2321` |
| `background` | `#FFFFFF` |
| `textPrimary` | `#1A1A1A` |
| `textSecondary` | `#757575` |
| `meterGreen` | `#2ECC71` |
| `meterYellow` | `#F1C40F` |
| `meterRed` | `#E74C3C` |
| `surfaceCard` | `#F8F9FA` |
| `divider` | `#E0E0E0` |

Reference brand JSON: `resources/bank_islam_theme.json`. Copy logo to `assets/images/bank_islam_logo.png`.

### State: `AnalysisProvider`

```dart
enum AnalysisState { idle, loading, complete, error }
```

- **idle**: hide meter (`SizedBox.shrink()`)
- **loading**: skeleton, disable Analyze button
- **complete**: meter + message card
- **error**: red banner + retry
- Disable Analyze when input empty or `loading`
- No duplicate in-flight requests

### `AnalogMeter` (mandated)

- `CustomPainter` + `CustomPaint` — no chart packages
- 180° arc; zones: green 1–30 (0°–54°), yellow 31–70 (54°–126°), red 71–100 (126°–180°)
- Needle: `AnimationController` + `Tween` + `Curves.easeOutBack`, **1200ms**

### Phase 1 Flutter checklist

- [ ] Provider wraps tree from `main.dart`
- [ ] Home screen: input, button, conditional meter states
- [ ] `flutter analyze` clean; `flutter build apk --debug` succeeds
- [ ] No scan history / SQLite / shared_preferences for results

## Phase 2 — Share-sheet overlay

### AndroidManifest

On **existing** `MainActivity` (not a second activity):

- `android:launchMode="singleTask"`
- Intent filter: `ACTION_SEND`, `text/plain`

### Dart routing

```
main.dart → KuCubaApp → IntentRouter
  ├── share intent + text → OverlayScreen(sharedText, onDismiss)
  └── else → HomeScreen
```

- `receive_sharing_intent`: `getInitialMedia()` (cold) + `getMediaStream()` (warm)
- For text shares, content is in `SharedMediaFile.path` (text body)
- **Auto-analyze** in `OverlayScreen.initState` via `addPostFrameCallback` — no Analyze button

### Overlay UX (critical)

- Bottom-sheet-**style** panel via transparent full-screen `Scaffold` + manual bottom container — **not** `showModalBottomSheet`
- Full-screen `Scaffold`, transparent; bottom white panel + **non-dismissible** scrim (`GestureDetector` no-op)
- `PopScope`: back button = same as ✕ / Done
- Dismiss: `ReceiveSharingIntent.instance.reset()` then **`SystemNavigator.pop()`** — not `Navigator.pop()`
- Reuse `AnalogMeter` + `AnalysisMessageCard` (optional `compact` param)

### Phase 2 checklist

- [ ] App in share menu (WhatsApp, SMS)
- [ ] Overlay over sharing app; auto-scan; scrim tap ignored
- [ ] ✕ and hardware back behave identically

**Escalation**: If `receive_sharing_intent` fails on device, stop and report — fallback is ~30 lines `MethodChannel` in `MainActivity.kt` (see Phase 2 doc).

## Phase 3 — Pinned notification (stretch)

**Do not start** until the Phase 1 **backend** gate passes (`POST /analyze`). Phase 2 is **not** required first. May run in parallel with Phase 2 on separate tasks/branches. If **< 8 hours** remain in hackathon, skip Phase 3 (slide/mockup instead).

### Native components

| File | Role |
|------|------|
| `ScamDetectorForegroundService.kt` | `START_STICKY`, `IMPORTANCE_LOW` channel |
| `AnalyzeReceiver.kt` | Clipboard on button tap → HTTP analyze → update notification |
| `NotificationHelper.kt` | `RemoteViews` idle / scanning / result |
| `HttpAnalysisClient.kt` | `POST /analyze` via `HttpURLConnection` (okhttp3 fallback only if needed) |
| `notification_idle.xml` | Analyze button → `PendingIntent` |
| `notification_scanning.xml` | Indeterminate progress |
| `notification_result.xml` | Horizontal risk bar + message |

### Flutter bridge

- `MethodChannel('com.kucuba/notification_service')` — exact name
- `NotificationServiceController`: `startService`, `stopService`, `isRunning`
- Pass `backend_url` from `AppConfig.backendBaseUrl`
- Guardian toggle on home/settings; request notification permission before start

### Manifest permissions

`FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SPECIAL_USE`, `POST_NOTIFICATIONS`; register service + receiver. **No** `BOOT_COMPLETED`, **no** `SYSTEM_ALERT_WINDOW`.

### Phase 3 rules

- Clipboard read **only** on explicit button tap — no passive monitoring
- Analysis from notification runs in **Kotlin**, not Flutter engine
- Do not use `flutter_local_notifications`

**Fallback** (documented): If clipboard from `BroadcastReceiver` fails, open HomeScreen with paste-from-clipboard flow (~15 min change).

## Security & privacy

- API keys only in `backend/.env` via dotenv
- Treat `text_payload` as sensitive; no file logging
- Backend for hackathon: LAN/local only, not public internet without auth
- No hardcoded secrets in Dart/Kotlin/XML

## Verification gates

Copy checklists from `docs/AI/rule.md` §11 before marking a phase complete.

**Phase 1**: analyze + APK build + mock meter zones + empty input disables button + error retry.

**Phase 2**: share menu + overlay + auto-trigger + dismiss rules + warm/cold share.

**Phase 3** (if built): persistent notification, clipboard button, result bar, clean stop, permission on API 33+.

## Build order (this repo)

1. Read `docs/AI/rule.md` + Phase 1 plan end-to-end
2. Extend existing `eternal_guardian` — theme, config, models, mock service, provider
3. Widgets + home screen; refactor `lib/main.dart` + `app.dart`
4. Add `backend/` Shelf server + `.env.example` (not real keys)
5. Integration: flip `useMockApi` to `false`, test `curl` + emulator — **Phase 1 gate**
6. **Then in parallel (either order, or split across developers):**
   - Phase 2: manifest (`singleTask` + `ACTION_SEND`), `IntentRouter`, `OverlayScreen` — **Phase 2 gate**
   - Phase 3: foreground service, `AnalyzeReceiver`, Kotlin `POST /analyze` — **Phase 3 gate** (if time remains)

## Commands (reference)

```bash
# Flutter
flutter pub get
flutter analyze
flutter build apk --debug
flutter run

# Backend (from repo root)
cd backend && dart pub get && dart run bin/server.dart

# Smoke test
curl -X POST http://localhost:8080/analyze \
  -H "Content-Type: application/json" \
  -d '{"text_payload":"Your Maybank account will be frozen. Click maybank-secure-login.com"}'
```

## Escalation — stop and report

Do not silently workaround:

1. `receive_sharing_intent` cannot read shared text on test device
2. Clipboard blocked from `BroadcastReceiver` on target Android version
3. Gemini returns non-JSON
4. `flutter build apk` fails after phase completion
5. `pubspec.lock` conflicts requiring unapproved version bumps
6. Benign input returns `risk_score` outside 1–100 (prompt regression)

## In scope (apply this skill only to)

| Phase | Deliverables |
|-------|----------------|
| **1** | `lib/` app (home, meter, mock/live API), `backend/` Shelf `POST /analyze`, Bank Islam theme |
| **2** | Share intent on `MainActivity`, `IntentRouter`, overlay (transparent `Scaffold` bottom panel), auto-analyze |
| **3** | Guardian Mode toggle, foreground service, `RemoteViews` notifications, Kotlin `HttpURLConnection` analyze |

Do not implement items outside the phase plans, SRD, or `docs/AI/rule.md` (e.g. scan history, iOS, splash, cloud deploy, extra API routes, `BOOT_COMPLETED`).

## Development logs (`docs/dev_logs/<branch>/`)

After implementation or debugging, **write a dev log in the folder for your git branch** (`dev0`, `dev1`, or `dev2`). See `docs/AI/rule.md` §12 and `docs/dev_logs/README.md`.

| Change size | Where to write |
|-------------|----------------|
| **Large** — new module, major feature, big refactor, long debug session | New file: `docs/dev_logs/<branch>/YYYY-MM-DD_<topic>.md` |
| **Small** — few files, quick fix, short debug | Append to `docs/dev_logs/<branch>/small_patches.md` (newest entry at top) |

| Branch folder | Typical work |
|---------------|----------------|
| `dev0/` | **Backend** — Shelf, Safe Browsing, Gemini |
| `dev1/` | **Backend** — parallel backend branch (same scope as `dev0`) |
| `dev2/` | **Frontend** — Flutter app, share overlay, theme, Dio → backend |

Include: branch name, what changed, why, debug steps if any, verification (`flutter analyze`, `dart analyze`, tests, manual checks). No secrets or raw user message payloads.

## Agent workflow summary

1. Confirm which **phase** the user is targeting; do not skip Phase 1 **backend** foundation; Phase 2 and 3 may proceed in parallel once backend is verified.
2. Re-read `docs/AI/rule.md` for DO/DON'T in that phase.
3. Use existing paths (`eternal_guardian`, `docs/AI/`); minimal diff; no scope creep.
4. If plan is ambiguous, **ask** — do not assume.
5. Run verification gate commands before claiming done.
6. **Document** the session in `docs/dev_logs/<branch>/` (new file or append to `small_patches.md` in that folder).
