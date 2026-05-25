# Production API mock-removal update

**Date:** 2026-05-25  
**Branch:** `dev0`  
**Scope:** Flutter API wiring, native Guardian Mode analysis path, production error handling, documentation alignment

## Goal

Remove runtime mock analysis paths from the released app behavior so analysis always comes from the configured backend. If the backend, Gemini, Safe Browsing, network, or response parsing fails, the app must show an error and retry affordance instead of presenting a low-risk or "safe" result.

## Documentation reviewed

- `docs/README.md`
- `docs/ARCHITECTURE_DIAGRAM.md`
- `docs/TECH_STACK_AND_PIPELINE.md`
- `docs/UI_ARCHITECTURE.md`
- `docs/dev_logs/README.md`
- Archived implementation guardrails:
  - `docs/bin/AI/rule.md`
  - `docs/bin/AI/SKILL.md`
  - `docs/bin/AI/backend_dev.md`

## Validation against architecture and flow

- The current source-of-truth docs in `docs/` define three client entry points: manual scan, share-sheet overlay, and Guardian Mode notification. The update preserves all three entry points.
- The update keeps the frozen backend contract unchanged:
  - request body: `{"text_payload": "<string>"}`
  - response keys consumed by clients: `risk_score`, `analysis_message`
  - unavailable sentinel: `risk_score < 0`
- The backend flow remains unchanged: URL extraction, Safe Browsing, short-link expansion, then Gemini only when no known threat is found.
- The Flutter flow still uses `AnalysisProvider` and the existing `idle`, `loading`, `complete`, and `error` states. Failed analysis now consistently goes to `error`.
- The native Guardian Mode flow still uses Kotlin `HttpAnalysisClient` and `HttpURLConnection`, matching the Phase 3 architecture.
- The Bank Islam visual theme was not changed. Existing `ErrorBanner`, risk meter, app colors, and Poppins-based theme remain in place.

## Documentation conflict found

The archived AI guardrails under `docs/bin/AI/` still describe hackathon demo/mock mode as mandatory. Those files are archived per `docs/README.md` and `docs/bin/README.md`, while the current production release decision is to remove mock runtime behavior. The production release requirement intentionally supersedes the old hackathon mock-mode rule.

To avoid future confusion, the current source-of-truth docs were updated to describe production API mode instead of mock/live switching.

## Files changed

- `lib/config/app_config.dart`
  - Removed `useMockApi`.
  - Kept `API_BASE_URL` as the runtime backend selector.
- `lib/main.dart`
  - Always injects `LiveApiService` into `AnalysisProvider`.
- `lib/services/api_service.dart`
  - Converts backend, network, timeout, TLS, malformed-response, and sentinel failures into `AnalysisUnavailableException`.
  - Preserves retryable UI behavior instead of falling back to any local score.
- `lib/providers/analysis_provider.dart`
  - Uses `AnalysisUnavailableException` messages directly for the error state.
- `lib/screens/home_screen.dart`
  - Removed the stale "local heuristic estimate" warning path.
- `lib/services/notification_service_controller.dart`
  - Stops passing `use_mock_api` to Android.
- `android/app/src/main/kotlin/com/kucuba/eternal_guardian/AnalyzeReceiver.kt`
  - Always calls `HttpAnalysisClient`.
  - Keeps graceful notification error messages for backend/network failures.
- `android/app/src/main/kotlin/com/kucuba/eternal_guardian/HttpAnalysisClient.kt`
  - Surfaces backend error messages from JSON when available.
- `android/app/src/main/kotlin/com/kucuba/eternal_guardian/MainActivity.kt`
  - Removed mock-mode extra handling.
- `android/app/src/main/kotlin/com/kucuba/eternal_guardian/ScamDetectorForegroundService.kt`
  - Removed persisted mock-mode preference.
- Deleted:
  - `lib/services/mock_api_service.dart`
  - `android/app/src/main/kotlin/com/kucuba/eternal_guardian/MockAnalysisClient.kt`
  - `test/mock_api_service_test.dart`
- Tests updated:
  - `test/support/test_analysis_api_service.dart`
  - `test/widget_test.dart`
  - `test/ui_overflow_test.dart`
  - `test/notification_service_controller_test.dart`
- Documentation updated:
  - `README.md`
  - `docs/ARCHITECTURE_DIAGRAM.md`
  - `docs/TECH_STACK_AND_PIPELINE.md`
  - `docs/UI_ARCHITECTURE.md`

## Verification

- `flutter analyze lib test` passed.
- `flutter test` passed.
- `dart analyze` from `backend/` passed.
- `flutter build apk --debug` passed.
- Local backend smoke check returned a high-risk score for a scam-like authority impersonation transfer message, confirming the path was using the real Gemini-backed backend instead of a local safe fallback.

## Production note

A released APK now requires a reachable backend URL. Build production APKs with:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://<your-production-backend>
```

If that backend is unavailable, the app should show an error and let the user retry. It should not classify the message as safe.
