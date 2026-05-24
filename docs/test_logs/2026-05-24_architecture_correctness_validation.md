# 2026-05-24 — Architecture, Design, and Correctness Validation

**Branch:** dev0  
**Scope:** Optimization Plan implementation review and validation  
**Engineer:** Codex

## Architecture Review

| Area | Assessment | Notes |
|---|---|---|
| API surface | Pass | Backend still exposes the single planned `POST /analyze` route. |
| Pipeline order | Pass | Request flow remains parse → URL extraction → Safe Browsing → Gemini. Safe Browsing threat matches still short-circuit and skip Gemini. |
| Optimization design | Pass | Shortened URL expansion now runs concurrently with the original URL Safe Browsing check. Expanded URLs are checked only if the original short URL is not already flagged. |
| Caching | Pass after hardening | Safe Browsing and URL expansion caches are in-memory TTL caches only, so no user payloads or results are persisted. Threat-match cache handling was tightened during review to avoid caching false negatives if the threat URL cannot be parsed from the API response. |
| Privacy | Pass | Backend logs URL counts, stages, sources, and timing values, but does not log `text_payload`. |
| UI loading design | Pass | Loading stages are isolated inside `SkeletonMeterPlaceholder`, reused by home and overlay flows, and do not fake percentages. |
| Test harness | Pass | Widget test provider tree now mirrors the app tree with both `AnalysisProvider` and `StatsProvider`. |

## Correctness Review

| Check | Result | Notes |
|---|---|---|
| Error sentinel | Pass | Malformed JSON and empty input return HTTP 200 with `risk_score: -1`. |
| Known malicious URL | Pass | Safe Browsing returns `risk_score: 100`, `analysis_source: safe_browsing`, and skips Gemini. |
| Safe Browsing cache | Pass | Repeated known phishing URL returned in 4 ms with cache log evidence. |
| Gemini benign text | Pass | Benign text returned low risk from Gemini. |
| Shortened URL caution | Pass | Shortened URL case returned yellow risk (`35`) and `analysis_source: gemini`. |
| Timing logs | Pass | Logs include `extract_ms`, `expand_ms`, `safe_browsing_ms`, `gemini_ms`, and `total_ms`. |

## Commands Run

```powershell
cd backend
dart analyze

flutter test
flutter analyze lib test
flutter build apk --debug
flutter analyze
```

## Validation Results

| Test | Status | Evidence |
|---|---|---|
| Backend static analysis | Pass | `dart analyze` in `backend/` returned no issues. |
| Flutter tests | Pass | `flutter test` passed 5 tests. |
| Flutter app/test analysis | Pass | `flutter analyze lib test` returned no issues. |
| Debug APK build | Pass | `flutter build apk --debug` produced `build/app/outputs/flutter-apk/app-debug.apk`. |
| Full-root analysis | Known info findings | `flutter analyze` reports 49 backend info-level findings (`avoid_print`, doc-comment angle brackets). No Flutter `lib/` or `test/` issues were reported. |

## Backend HTTP Cases

| Case | HTTP | Score | Source | Time | Result |
|---|---:|---:|---|---:|---|
| Malformed JSON | 200 | -1 | backend | 16 ms | Pass |
| Empty payload | 200 | -1 | backend | 2 ms | Pass |
| Safe Browsing phishing URL, first call | 200 | 100 | safe_browsing | 138 ms | Pass |
| Safe Browsing phishing URL, cached repeat | 200 | 100 | safe_browsing | 4 ms | Pass |
| Benign Gemini text | 200 | 3 | gemini | 1074 ms | Pass |
| Shortened URL caution | 200 | 35 | gemini | 1735 ms | Pass |

## Timing Log Evidence

```text
[timing] source=safe_browsing extract_ms=0 expand_ms=0 safe_browsing_ms=132 gemini_ms=0 total_ms=135
[timing] source=safe_browsing extract_ms=0 expand_ms=0 safe_browsing_ms=0 gemini_ms=0 total_ms=1
[timing] source=gemini extract_ms=0 expand_ms=0 safe_browsing_ms=0 gemini_ms=1069 total_ms=1071
[timing] source=gemini extract_ms=0 expand_ms=634 safe_browsing_ms=53 gemini_ms=1095 total_ms=1731
```

## Observed External API Behavior

One readiness probe hit a transient Gemini `503` high-demand response. The backend handled it correctly by returning the standard error sentinel instead of crashing. Subsequent Gemini test cases passed.

## Residual Risks

- Full model-quality comparison between `gemini-2.5-flash-lite` and `gemini-2.5-flash` across the same 10-message set is still outstanding.
- Device-level visual validation of staged loading in the Android share overlay is still needed.
- Root `flutter analyze` includes backend scripts and still exits non-zero for info-level backend logging/doc-comment lints.
- The backend response still includes the existing `analysis_source` field; current Flutter tolerates it, but this should be reconciled with docs that describe only `risk_score` and `analysis_message` as the public contract.
