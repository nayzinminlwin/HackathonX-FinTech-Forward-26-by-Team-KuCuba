# Phase 1 Backend – Sector 2: Safe Browsing

**Date:** 2026-05-23  
**Sector:** 2 of 3  
**Status:** ✅ Complete  

---

## What Was Done

### New File: `backend/lib/services/safe_browsing.dart`

- `SafeBrowsing` class with constructor injection of `apiKey`.
- `checkUrls(List<String> urls)` → `Future<bool>`:
  - **Guard:** If `apiKey.isEmpty`, prints log and returns `false` (no crash).
  - POSTs to `https://safebrowsing.googleapis.com/v4/threatMatches:find?key=...`
  - Threat types: `MALWARE`, `SOCIAL_ENGINEERING`, `UNWANTED_SOFTWARE`
  - Platform: `ANY_PLATFORM`, entry type: `URL`
  - Returns `true` if `matches` array is non-empty; `false` otherwise.
  - Fail-open on HTTP errors or network failures (logs and returns `false`).

### Modified: `backend/lib/handlers/analyze_handler.dart`

- Constructor now requires `SafeBrowsing` instance (DI from server).
- After Step 1 (URL extraction): if URLs exist → `_safeBrowsing.checkUrls(urls)`.
- **If threat detected:** returns immediately with:
  ```json
  {"risk_score": 100, "analysis_message": "Warning: This link is a known malicious website flagged for phishing/malware."}
  ```
- **Gemini is NOT called** when threat is detected (Step 3 skipped).
- If no threat or no URLs: returns `-1` stub (Gemini pending for Sector 3).

### Modified: `backend/bin/server.dart`

- Imports `safe_browsing.dart`.
- Extracts `SAFE_BROWSING_API_KEY` from `.env` into a variable accessible outside the `if` block.
- Creates `SafeBrowsing(apiKey: safeBrowsingKey)` and injects into `AnalyzeHandler`.
- Updated startup message to reflect Sector 2 status.

---

## Curl Test Results

All tests run on `http://localhost:8080/analyze` via `Invoke-RestMethod` (PowerShell).

### Test 1: Known-bad phishing URL (with valid API key)

```
POST /analyze
Body: {"text_payload": "Check this site https://testsafebrowsing.appspot.com/s/phishing.html for me"}
```

**Result:** ✅
```json
{"risk_score": 100, "analysis_message": "Warning: This link is a known malicious website flagged for phishing/malware."}
```

Server log: `[safe_browsing] ⚠ Threat detected! 1 match(es) found.`

### Test 2: Safe URL (google.com, with valid API key)

```
POST /analyze
Body: {"text_payload": "Visit https://www.google.com for info"}
```

**Result:** ✅
```json
{"risk_score": -1, "analysis_message": "Safe Browsing: no threat detected for 1 URL(s). Gemini analysis not yet connected (Sector 3 pending)."}
```

Server log: `[safe_browsing] No threats detected.`

### Test 3: No URLs in input

```
POST /analyze
Body: {"text_payload": "Hello there, no links here"}
```

**Result:** ✅
```json
{"risk_score": -1, "analysis_message": "No URLs detected. Gemini analysis not yet connected (Sector 3 pending)."}
```

### Test 4: Empty text_payload

```
POST /analyze
Body: {"text_payload": ""}
```

**Result:** ✅
```json
{"risk_score": -1, "analysis_message": "Analysis temporarily unavailable."}
```

### Test 5: Empty SAFE_BROWSING_API_KEY (key set to empty string in .env)

```
POST /analyze
Body: {"text_payload": "Check https://testsafebrowsing.appspot.com/s/phishing.html"}
```

**Result:** ✅ No crash, graceful skip.
```json
{"risk_score": -1, "analysis_message": "Safe Browsing: no threat detected for 1 URL(s). Gemini analysis not yet connected (Sector 3 pending)."}
```

Server log: `[safe_browsing] API key is empty — skipping Safe Browsing check.`

---

## Static Analysis

```
> dart analyze
Analyzing backend...
No issues found!
```

---

## What's Next (Sector 3)

- Implement `gemini_service.dart` — call Gemini 2.0 Flash for text analysis.
- Wire Step 3 into `analyze_handler.dart` (only runs if Step 2 did NOT flag threat).
- Replace `-1` stubs with real Gemini responses.
