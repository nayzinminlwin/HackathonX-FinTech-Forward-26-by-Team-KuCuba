# 2026-05-24 — Optimization Plan Backend and Loading UX

**Branch:** dev0  
**Scope:** Performance tightening plan from `docs/Optimization_Plan.md`

## Goal

Reduce avoidable backend latency and improve perceived loading during analysis while preserving the existing `POST /analyze` contract and scam-detection behavior.

## Files touched

- `backend/.env.example`
- `backend/bin/server.dart`
- `backend/lib/handlers/analyze_handler.dart`
- `backend/lib/services/gemini_service.dart`
- `backend/lib/services/safe_browsing.dart`
- `backend/lib/services/url_expander.dart`
- `lib/widgets/skeleton_meter_placeholder.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/overlay_screen.dart`
- `test/widget_test.dart`

## What changed

- Added `GEMINI_MODEL` support with `gemini-2.5-flash-lite` as the default model and `maxOutputTokens: 160` for compact JSON responses.
- Kept `gemini-2.5-flash` available through `.env` without code changes.
- Started shortened URL expansion in parallel with Safe Browsing checks on the original URLs.
- Reduced URL expansion worst case to 3 redirects with 1.5s request timeouts.
- Added in-memory TTL caches for URL expansion and Safe Browsing results.
- Hardened Safe Browsing threat-cache handling so it does not cache false negatives if a match response cannot expose the matched threat URL.
- Added per-request timing logs for `extract_ms`, `expand_ms`, `safe_browsing_ms`, `gemini_ms`, and `total_ms`.
- Kept hidden-link caution behavior: unresolved shortened links force at least yellow risk and add a caution note.
- Replaced the single loading placeholder text with staged loading labels shared by home and overlay flows.
- Updated the widget test harness to include `StatsProvider`, matching the app's real provider tree.

## Notes

- The current branch is `dev0`; the optimization plan also included a small Flutter loading-state change. This was kept narrow and tied directly to the plan.
- `backend/lib/models/analysis_result.dart` already had local edits at session start and was preserved.
- `test/test_cases.json` also shows local changes that were not part of this implementation.
- The backend still logs timings and status through `print`, matching the existing backend logging style.
- Full response JSON still includes `analysis_source` because the existing backend model already exposed it.

## Verification

- `dart analyze` from `backend/` — passed with no issues.
- Backend smoke test against local `POST /analyze` — passed; Flash Lite returned a benign score and timing log.
- Architecture/correctness HTTP validation — passed 6 cases (error sentinel, Safe Browsing, cache repeat, benign Gemini, shortened-link caution).
- `flutter test` — passed, 5 tests.
- `flutter analyze lib test` — passed with no issues.
- `flutter build apk --debug` — passed.
- Full-root `flutter analyze` still reports existing backend info-level lint findings (`avoid_print`, doc-comment angle brackets) because it analyzes backend scripts too.
