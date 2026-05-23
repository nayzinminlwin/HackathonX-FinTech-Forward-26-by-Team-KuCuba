# Performance Tightening Plan

## Summary
Use a balanced-fast approach: keep response quality, but reduce avoidable backend waiting and improve perceived loading. Current tests show Safe Browsing is fast (`149-228 ms`), while Gemini dominates (`~1.6-5.5 s`). Google lists `gemini-2.5-flash-lite` as optimized for low latency/high throughput, so make it the MVP default while keeping `gemini-2.5-flash` configurable as a fallback/reference model: [Gemini models](https://ai.google.dev/gemini-api/docs/models).

## Key Changes
- Backend model config:
  - Add `GEMINI_MODEL` env support.
  - Default to `gemini-2.5-flash-lite`.
  - Keep `gemini-2.5-flash` available by changing `.env`, no code change.
  - Cap Gemini output length to a small JSON response, around 2 sentences.

- Backend pipeline:
  - Run short URL expansion and Safe Browsing checks concurrently where possible.
  - For shortened URLs, check original short URL immediately while expansion runs.
  - Reduce URL expansion worst-case delay: max 3 redirects, tighter per-request timeout around `1.2-1.5s`.
  - If expansion fails, continue to Gemini with hidden-link caution context and keep score at least yellow.
  - Add in-memory TTL caching for URL expansion and Safe Browsing results to make repeated demo/test links near-instant.
  - Add backend timing logs per stage: `extract_ms`, `expand_ms`, `safe_browsing_ms`, `gemini_ms`, `total_ms`.

- Prompt/process efficiency:
  - Keep the current analysis style, but tighten the system prompt wording.
  - Preserve the five phishing-link types and Malaysian scam context.
  - Avoid adding large URL anatomy text to each request.
  - Pass compact URL context only when relevant, especially expanded/failed shortener data.

- Loading UI:
  - Replace the single “Analyzing risk...” skeleton with staged loading states:
    - `Checking links...`
    - `Verifying hidden links...` only when shortened URLs exist.
    - `Analyzing message context...`
    - `Almost done...` after ~2.5 seconds.
  - Keep the meter skeleton, but make it feel active: scan line, pulsing shield, or staged checklist.
  - In overlay mode, keep layout height stable so results do not jump.
  - Do not fake completion percentages; use honest stage labels.

## Test Plan
- Re-run the existing backend validation report before and after changes.
- Add timed cases:
  - Safe Browsing known phishing URL should stay under `500 ms`.
  - Normal Gemini text should target lower median latency than current `~2-3.5 s`.
  - Short URL that expands should include expanded URL context and avoid long blocking.
  - Short URL that fails expansion should still return JSON, yellow-or-higher score, and hidden-link caution message.
  - Repeated same URL should be faster due to cache.
- Compare `gemini-2.5-flash-lite` vs `gemini-2.5-flash` on the same 10-message set for score quality, message quality, median latency, and p95 latency.
- UI acceptance:
  - Loading state appears immediately.
  - Stage text updates during long calls.
  - Fast Safe Browsing results do not flicker awkwardly.
  - Overlay and home screen both use the same loading experience.

## Assumptions
- Prioritize “Balanced fast”: improve speed without sacrificing the response quality you liked.
- Successful `analysis_source` remains only `safe_browsing` or `gemini`; backend timing details stay in logs, not the public JSON.
- No local low-risk auto-return yet, because skipping Gemini for “safe-looking” text could weaken trust.
