# Detailed System Requirements Document

**Project:** Eternal Guardian - Everywhere Scam Detector  
**Team:** KuCuba  
**Target platform:** Android MVP  
**Status:** Development complete / demo-ready prototype  
**Last updated:** 2026-05-24

## 1. Product Scope

Eternal Guardian helps users check suspicious messages and links at the moment of risk. The Android MVP provides three entry points:

| Entry point | Requirement | Implementation status |
|-------------|-------------|-----------------------|
| Core app scan | User pastes or types suspicious text, taps Analyze, and receives a risk score plus explanation. | Implemented |
| Android share sheet | User shares text from another app into Eternal Guardian, which opens an overlay and analyzes automatically. | Implemented |
| Guardian Mode notification | User starts a persistent notification and submits text through the notification action. | Implemented |

The backend exposes a single analysis contract used by all three entry points.

## 2. System Architecture

Eternal Guardian uses a hybrid rule-based and AI pipeline:

1. Client submits `POST /analyze` with the app-secret header and `{"text_payload": "<message>"}`.
2. Backend extracts URLs from the submitted text.
3. Safe Browsing checks original URLs immediately.
4. Shortened URLs are expanded with tight timeouts and checked again after expansion.
5. If Safe Browsing flags any URL, the backend returns `risk_score: 100` and skips Gemini.
6. If no known threat is found, Gemini analyzes the complete message context.
7. Backend returns a normalized JSON result to Flutter or Kotlin.

The backend never stores scan history and does not persist user messages.

## 3. Functional Requirements

### FR1 - Core App Scan

| ID | Requirement | Status |
|----|-------------|--------|
| FR1.1 | Provide a multi-line input for suspicious messages, conversations, or URLs. | Implemented |
| FR1.2 | Provide an Analyze button that submits text to the configured analysis service. | Implemented |
| FR1.3 | Disable duplicate analysis while loading and show a loading state. | Implemented |
| FR1.4 | Display an animated analog risk meter for successful results. | Implemented |
| FR1.5 | Display a short analysis explanation below the score. | Implemented |
| FR1.6 | Provide demo-safe mock responses when `AppConfig.useMockApi` is true. | Implemented |
| FR1.7 | Track simple in-session stats for total scans and threats blocked. | Implemented |

### FR2 - Android Share-Sheet Overlay

| ID | Requirement | Status |
|----|-------------|--------|
| FR2.1 | Register Android `ACTION_SEND` for `text/plain`. | Implemented |
| FR2.2 | Route shared text through `IntentRouter`. | Implemented |
| FR2.3 | Open a bottom-aligned overlay instead of the normal home screen. | Implemented |
| FR2.4 | Auto-analyze shared text without requiring a button press. | Implemented |
| FR2.5 | Reuse the same risk meter, loading placeholder, error, and message components. | Implemented |
| FR2.6 | Disable tap-outside dismissal and provide explicit close/done actions. | Implemented |
| FR2.7 | Return control to the source app using native dismissal behavior. | Implemented |

### FR3 - Guardian Mode Notification

| ID | Requirement | Status |
|----|-------------|--------|
| FR3.1 | Start and stop a native Android foreground service from Flutter. | Implemented |
| FR3.2 | Request Android notification permission before starting Guardian Mode. | Implemented |
| FR3.3 | Show a persistent custom notification. | Implemented |
| FR3.4 | Accept suspicious text through notification `RemoteInput`. | Implemented |
| FR3.5 | Show scanning, result, and error notification states. | Implemented |
| FR3.6 | Call the same `/analyze` contract from native Kotlin when live mode is enabled. | Implemented |
| FR3.7 | Use a native mock client when app mock mode is enabled. | Implemented |

## 4. Backend Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| BR1 | Expose exactly one analysis endpoint: `POST /analyze`. | Implemented |
| BR2 | Accept JSON with `text_payload`. | Implemented |
| BR3 | Return HTTP 200 with a JSON result for normal and analysis-unavailable cases. | Implemented |
| BR4 | Return `risk_score: -1` for malformed input, unavailable Gemini, or unparseable model output. | Implemented |
| BR5 | Check Safe Browsing before calling Gemini. | Implemented |
| BR6 | Skip Gemini when a known malicious URL is detected. | Implemented |
| BR7 | Expand shortened URLs with bounded redirects and timeouts. | Implemented |
| BR8 | Cache URL expansion and Safe Browsing results in memory for repeated demo/test inputs. | Implemented |
| BR9 | Support `GEMINI_MODEL` in `.env`, defaulting to `gemini-2.5-flash-lite`. | Implemented |
| BR10 | Include `analysis_source` in backend JSON for internal transparency. | Implemented |

## 5. API Contract

### Request

```json
{
  "text_payload": "Suspicious message or link"
}
```

### Response

```json
{
  "risk_score": 42,
  "analysis_message": "Short explanation in at most two sentences.",
  "analysis_source": "gemini"
}
```

`analysis_source` may be `gemini`, `safe_browsing`, or `backend`. Flutter and Kotlin currently consume `risk_score` and `analysis_message`; the source field is safe to ignore on clients.

## 6. Score Semantics

| Score | Meaning | UI treatment |
|-------|---------|--------------|
| `1-30` | Low risk | Green / safe |
| `31-70` | Caution | Yellow / caution |
| `71-100` | High risk | Red / danger |
| `100` | Known malicious URL from Safe Browsing | Red / danger |
| `-1` | Analysis unavailable or invalid request | Error state |

Shortened links that cannot be expanded must not be treated as safe. The backend keeps unresolved-shortener results at least in the caution range.

## 7. Non-Functional Requirements

| ID | Requirement | Implementation |
|----|-------------|----------------|
| NFR1 | Keep common demo flows responsive. | Safe Browsing short-circuit, Flash Lite default, in-memory caches, staged loading UI. |
| NFR2 | Avoid unnecessary AI token use. | Safe Browsing runs before Gemini and known threats skip Gemini. |
| NFR3 | Keep API keys out of the mobile app. | Keys live only in `backend/.env`. |
| NFR4 | Avoid persisting user scan content. | No database, no scan history, no text payload logging. |
| NFR5 | Keep demos reliable without live services. | Flutter and native notification mock clients are available through `AppConfig.useMockApi`. |
| NFR6 | Preserve Android-first behavior. | Share intent, transparent activity background, foreground service, and notification `RemoteViews`. |

## 8. Verification Evidence

Formal validation notes are stored in [test_logs/](test_logs/). The final development pass includes Flutter widget/unit tests, UI overflow checks, backend validation, architecture review, notification checklist, and Android debug build evidence.

Remaining validation risk: full Guardian Mode behavior should still be checked on the exact physical demo device because Android notification behavior can vary by OS version and OEM settings.
