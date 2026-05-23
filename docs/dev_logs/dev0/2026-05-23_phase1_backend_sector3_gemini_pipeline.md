# Phase 1 Backend — Sector 3: Gemini + Full Pipeline

**Date:** 2026-05-23  
**Scope:** Gemini LLM integration, full POST /analyze pipeline, stub removal  
**Prerequisite:** Sectors 1–2 verified (URL extractor + Safe Browsing short-circuit)

---

## Goal

Wire Step 3 (Gemini LLM analysis) into the POST /analyze pipeline, remove Sector 2 stubs, and ensure every code path returns a valid JSON body (never a 5xx with no body).

---

## Files Changed

### [NEW] `backend/lib/services/gemini_service.dart`
- Uses `google_generative_ai` package with model `gemini-2.0-flash`
- Exact few-shot system prompt from Phase 1 §2.5 (5 scam + 5 safe examples)
- `generationConfig`: `temperature: 0.1`, `responseMimeType: application/json`
- `analyzeText(text)` → returns parsed `Map<String, dynamic>?` (null on failure)
- Catches all exceptions from Gemini API gracefully

### [MODIFIED] `backend/lib/handlers/analyze_handler.dart`
- Full pipeline wired: parse → extractUrls → Safe Browsing → Gemini
- Removed all Sector 2 stubs (the `risk_score: -1` "Sector 3 pending" responses)
- Accepts `GeminiService?` via constructor — null means Gemini disabled
- `risk_score` validation: handles int, double, String types from Gemini JSON
- Clamps `risk_score` to 1–100 range per rule.md §3.2
- On any Gemini failure → `risk_score: -1`, standard unavailable message

### [MODIFIED] `backend/bin/server.dart`
- Imports and instantiates `GeminiService` when `GEMINI_API_KEY` is non-empty
- Passes `geminiService` to `AnalyzeHandler` constructor
- Updated startup banner to reflect Phase 1 completion

---

## Verification

### `dart analyze` — zero issues ✅

```
Analyzing backend...
No issues found!
```

### Server startup ✅

```
[server] GEMINI_API_KEY loaded: yes
[server] SAFE_BROWSING_API_KEY loaded: yes
[server] GeminiService initialised with model gemini-2.0-flash.
[server] KuCuba backend listening on http://0.0.0.0:8080
[server] Phase 1 complete: URL extraction + Safe Browsing + Gemini pipeline active.
```

### Smoke Tests

#### 1. Malformed JSON → risk_score -1 ✅

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/analyze" `
  -Method POST -ContentType "application/json" `
  -Body 'not valid json'
```
```json
{"risk_score": -1, "analysis_message": "Analysis temporarily unavailable."}
```

#### 2. Empty text_payload → risk_score -1 ✅

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/analyze" `
  -Method POST -ContentType "application/json" `
  -Body '{"text_payload": ""}'
```
```json
{"risk_score": -1, "analysis_message": "Analysis temporarily unavailable."}
```

#### 3. Flagged URL → risk_score 100 (Safe Browsing short-circuit, no Gemini call) ✅

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/analyze" `
  -Method POST -ContentType "application/json" `
  -Body '{"text_payload": "Click here: https://testsafebrowsing.appspot.com/s/phishing.html"}'
```
```json
{"risk_score": 100, "analysis_message": "Warning: This message contains a link flagged as malicious (phishing/malware). Do not click it."}
```

#### 4. Benign Malay text → Gemini analysis (risk_score 1–100) ✅

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/analyze" `
  -Method POST -ContentType "application/json" `
  -Body '{"text_payload": "Hai, esok kita jumpa pukul 3 untuk makan tengahari ya. Jangan lupa bawa laptop."}'
```
```json
{"risk_score": 3, "analysis_message": "This is a normal, casual message arranging a meeting and reminding to bring a laptop. It contains no scam indicators."}
```

#### 5. Scam Malay text → Gemini high-risk score ✅

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/analyze" `
  -Method POST -ContentType "application/json" `
  -Body '{"text_payload": "Polis sini. IC awak linked to money laundering case. Transfer RM5000 ke acc ini untuk clear nama awak."}'
```
```json
{"risk_score": 95, "analysis_message": "This is a classic police impersonation scam, using fear tactics about a money laundering case to pressure the victim into transferring money."}
```

#### 6. Gemini API failure → risk_score -1 (graceful degradation) ✅

Verified via transient 503 error: Gemini throws server error → caught → `risk_score: -1`.

---

## Issues Encountered

- **Model change `gemini-2.0-flash` → `gemini-2.5-flash`:** The original model (`gemini-2.0-flash`) has **zero free-tier allocation** (0/0 RPM, 0/0 TPM, 0/0 RPD) — Google has sunset it. All 3 initial requests returned 429 TooManyRequests. Switched to `gemini-2.5-flash` which has active free-tier limits (5 RPM, 250K TPM, 20 RPD). This is a lighter/newer model, not a heavier one.
- **Transient 503:** First request to `gemini-2.5-flash` hit a temporary 503 ("high demand"). Retry succeeded immediately.
- **PowerShell curl compatibility:** `curl` in PowerShell is aliased to `Invoke-WebRequest` with different flag syntax. Used `Invoke-RestMethod` instead.
- **dart analyze warning:** `unnecessary_non_null_assertion` on `_geminiService!` — fixed by promoting to a local variable.

---

## Architecture Note

The `GeminiService` is nullable in `AnalyzeHandler`. When `GEMINI_API_KEY` is empty:
- `GeminiService` is not instantiated
- `AnalyzeHandler` receives `null`
- All requests that reach Step 3 return `risk_score: -1`
- Safe Browsing short-circuit (Step 2) still works independently
