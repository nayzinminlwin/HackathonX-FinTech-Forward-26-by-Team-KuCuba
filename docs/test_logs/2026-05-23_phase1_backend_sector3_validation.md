# Phase 1 Backend — Live Validation Test Report

**Date:** 2026-05-22T18:05:28.241428Z UTC
**Server:** Dart Shelf on `http://localhost:8080`
**Endpoint:** `POST /analyze`
**Model:** `gemini-2.5-flash` (Live High-Tier API Key)
**Static Analysis:** `dart analyze` → **No issues found** ✅

---

## Test Summary

| Category | Tests | Passed | API Errors | Other Failures | Status |
|---|---|---|---|---|---|
| Error Handling | 7 | 7 | 0 | 0 | ✅ PASS |
| Safe Browsing Short-Circuit | 2 | 2 | 0 | 0 | ✅ PASS |
| Gemini: Benign Text | 3 | 3 | 0 | 0 | ✅ PASS |
| Gemini: Scam Text | 5 | 5 | 0 | 0 | ✅ PASS |
| Edge Cases | 3 | 3 | 0 | 0 | ✅ PASS |
| **Total** | **20** | **20** | **0** | **0** | **✅ PASS** |

> [!NOTE]
> All tests completed successfully with zero transient API errors! The new high-tier API key works beautifully.

---

## Detailed Results

### ERROR HANDLING

| # | Test | Score | Time | Status | Message / Note |
|---|---|---|---|---|---|
| T01 | Malformed JSON | `-1` | 107ms | ✅ PASS | Analysis temporarily unavailable. |
| T02 | Empty body | `-1` | 4ms | ✅ PASS | Analysis temporarily unavailable. |
| T03 | Empty text_payload | `-1` | 9ms | ✅ PASS | Analysis temporarily unavailable. |
| T04 | Null text_payload | `-1` | 4ms | ✅ PASS | Analysis temporarily unavailable. |
| T05 | Missing text_payload key | `-1` | 2ms | ✅ PASS | Analysis temporarily unavailable. |
| T06 | Whitespace only text_payload | `-1` | 3ms | ✅ PASS | Analysis temporarily unavailable. |
| T07 | Numeric payload | `-1` | 5ms | ✅ PASS | Analysis temporarily unavailable. |

### SAFE BROWSING SHORT-CIRCUIT

| # | Test | Score | Time | Status | Message / Note |
|---|---|---|---|---|---|
| T08 | Phishing URL in text | **100** | 228ms | ✅ PASS | Warning: This message contains a link flagged as malicious (phishing/malware). Do not click it. |
| T09 | Malware URL in text | **100** | 149ms | ✅ PASS | Warning: This message contains a link flagged as malicious (phishing/malware). Do not click it. |

### GEMINI: BENIGN TEXT

| # | Test | Score | Time | Status | Message / Note |
|---|---|---|---|---|---|
| T10 | Benign lunch arrangement (Malay) | **3** | 2966ms | ✅ PASS | This is a normal, casual message arranging a meeting and reminding to bring a laptop. It contains no scam indicators or suspicious elements. |
| T11 | Benign birthday greeting (Malay) | **1** | 1950ms | ✅ PASS | This is a standard and harmless birthday greeting. There are no indicators of a scam, financial requests, or suspicious links. |
| T12 | Benign Grab delivery update (English) | **5** | 2444ms | ✅ PASS | This is a standard delivery notification from a legitimate service (GrabFood). It contains no scam indicators like suspicious links, financial requests, or impersonation. |

### GEMINI: SCAM TEXT

| # | Test | Score | Time | Status | Message / Note |
|---|---|---|---|---|---|
| T13 | PDRM authority impersonation scam (Malay) | **95** | 2785ms | ✅ PASS | This is a classic impersonation scam, using 'Polis' to induce fear about a money laundering case. The demand for an immediate transfer of RM5000 to 'clear your name' is a high-pressure financial request typical of scams. |
| T14 | LHDN tax refund / TAC theft scam (Malay) | **98** | 3373ms | ✅ PASS | This message impersonates LHDN and falsely claims outstanding tax. It then requests a TAC number, which LHDN would never ask for, indicating a clear attempt to defraud. |
| T15 | Shopee lottery voucher scam (Malay) | **88** | 3392ms | ✅ PASS | The message promises a prize from Shopee and includes a suspicious link that is not the official Shopee domain, indicating a phishing attempt. This is a common 'lucky draw' scam tactic. |
| T16 | Macau job task deposit scam (Malay) | **92** | 3225ms | ✅ PASS | This is a classic 'task scam' or 'job scam' often linked to Macau Scams, promising high commissions for simple tasks but requiring an upfront 'initial capital' (modal awal). Such schemes are designed to defraud victims of their initial investment. |
| T17 | Maybank account frozen phishing (Malay/English) | **95** | 3306ms | ✅ PASS | This is a classic phishing scam impersonating Maybank, using urgency to trick users into clicking a fake link. The URL 'maybank-secure-login.com' is not the official Maybank website and is designed to steal your banking credentials. |

### EDGE CASES

| # | Test | Score | Time | Status | Message / Note |
|---|---|---|---|---|---|
| T18 | Safe URL (google.com search) | **5** | 1636ms | ✅ PASS | This is a normal request to check the weather using a legitimate Google search link. There are no scam indicators present. |
| T19 | Text with raw www link (www.google.com) | **18** | 5462ms | ✅ PASS | The message directs to Google.com, which is not a malicious link. However, it is unusual for a company to direct users to Google for 'more information' about 'their website' instead of their actual company domain. |
| T20 | Extremely short text | **2** | 2113ms | ✅ PASS | This is a simple, affirmative response with no scam indicators. There are no suspicious requests or pressure tactics. |

---

## Selected Scam Analyses

#### T13 — PDRM authority impersonation scam (Malay) (Score: 95)
> *"This is a classic impersonation scam, using 'Polis' to induce fear about a money laundering case. The demand for an immediate transfer of RM5000 to 'clear your name' is a high-pressure financial request typical of scams."*

#### T14 — LHDN tax refund / TAC theft scam (Malay) (Score: 98)
> *"This message impersonates LHDN and falsely claims outstanding tax. It then requests a TAC number, which LHDN would never ask for, indicating a clear attempt to defraud."*

#### T15 — Shopee lottery voucher scam (Malay) (Score: 88)
> *"The message promises a prize from Shopee and includes a suspicious link that is not the official Shopee domain, indicating a phishing attempt. This is a common 'lucky draw' scam tactic."*

#### T16 — Macau job task deposit scam (Malay) (Score: 92)
> *"This is a classic 'task scam' or 'job scam' often linked to Macau Scams, promising high commissions for simple tasks but requiring an upfront 'initial capital' (modal awal). Such schemes are designed to defraud victims of their initial investment."*

#### T17 — Maybank account frozen phishing (Malay/English) (Score: 95)
> *"This is a classic phishing scam impersonating Maybank, using urgency to trick users into clicking a fake link. The URL 'maybank-secure-login.com' is not the official Maybank website and is designed to steal your banking credentials."*

---

## Conclusion

The backend pipeline is **fully validated and operational**.
Using the new API key, all tests successfully execute with zero defects. The pipeline correctly handles validation, threat intelligence via Google Safe Browsing, and advanced LLM reasoning via Gemini.
