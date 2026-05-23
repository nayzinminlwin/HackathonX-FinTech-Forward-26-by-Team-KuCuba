# 2026-05-22 — Phase 1 Backend Sector 1: Scaffold, Server, Link Extractor

## Goal

Create the `backend/` directory with a functioning Dart Shelf server on `:8080`, a single `POST /analyze` route that parses `{"text_payload": "..."}`, extracts URLs via regex (Step 1 of the pipeline), and returns a stub JSON response. Steps 2–3 (Safe Browsing, Gemini) are deferred to Sectors 2 and 3.

## Files Created

| File | Purpose |
|------|---------|
| `backend/pubspec.yaml` | Package `kucuba_backend` with shelf, shelf_router, http, dotenv, google_generative_ai |
| `backend/bin/server.dart` | Shelf server entry — loads `.env`, CORS middleware, mounts router, listens 0.0.0.0:8080 |
| `backend/lib/models/analysis_result.dart` | Response model: `{risk_score, analysis_message}` with `toJson`, `fromJson`, `.error()` factory |
| `backend/lib/services/link_extractor.dart` | Static `extractUrls(text)` using regex `(https?://\|www\.)[^\s<>"{}|\\\^` \[\]]+` |
| `backend/lib/handlers/analyze_handler.dart` | POST /analyze handler — parses body, runs Step 1, returns stub (risk_score: -1) |
| `backend/.env.example` | Template with `GEMINI_API_KEY=` and `SAFE_BROWSING_API_KEY=` |

## Files Modified

| File | Change |
|------|--------|
| `.gitignore` | Added `.env` and `backend/.env` to prevent accidental key commits |

## Approach

- Followed Phase 1 §1.4 for `pubspec.yaml` dependencies exactly
- Used `package:` imports from `bin/server.dart` → `lib/` (Dart convention)
- Relative imports within `lib/` (handler → services/models)
- CORS middleware returns `Access-Control-Allow-Origin: *` for Flutter dev
- Server gracefully handles missing `.env` file (prints warning, continues)
- Analyze handler uses try/catch at every level — never crashes, always returns valid JSON
- Stub response uses `risk_score: -1` sentinel with descriptive message including found URLs
- `LinkExtractor` is a static utility — trivially unit-testable

## Verification

```bash
cd backend && dart pub get && dart run bin/server.dart
```

**Server starts successfully:**
```
[server] No .env file found — running with empty keys (OK for Sector 1).
[server] KuCuba backend listening on http://0.0.0.0:8080
[server] Sector 1: URL extraction active. Steps 2–3 (Safe Browsing, Gemini) pending.
```

**Smoke tests (all pass):**

| Test | Input | Result |
|------|-------|--------|
| URLs found | `{"text_payload":"Visit https://evil.com and www.test.com"}` | `risk_score: -1`, lists 2 URLs |
| No URLs | `{"text_payload":"Hello, normal message"}` | `risk_score: -1`, "No URLs detected" |
| Malformed JSON | `not json at all` | `risk_score: -1`, "Analysis temporarily unavailable." |
| Empty payload | `{"text_payload":""}` | `risk_score: -1`, "Analysis temporarily unavailable." |

## TODO (Next Sectors)

- **Sector 2**: Implement `safe_browsing.dart` — POST to Google Safe Browsing v4 API
- **Sector 3**: Implement `gemini_service.dart` — Few-shot Gemini analysis with JSON output
