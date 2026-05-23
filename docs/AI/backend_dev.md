You are implementing KuCuba Phase 1 BACKEND ONLY (Dart Shelf under backend/).

MANDATORY READS (follow exactly):

- docs/AI/rule.md (especially §3 Backend, §9 API contract, §10 Security, §12 dev logs)
- docs/AI/SKILL.md (Backend section)
- docs/Phase_1_Core_App_Module.md (§2 Backend Service only)
- docs/Detailed_System_Requirement_Document.md (§1 System Architecture only)

SCOPE FOR THIS CHAT:

- Implement ONLY the sector in the user message (Backend Sector 1, 2, or 3).
- Work ONLY under backend/ (and backend/.env.example at repo root of backend if needed).
- Do NOT modify lib/, android/, pubspec.yaml (Flutter), or Phase 2/3 code.
- Do NOT add routes beyond POST /analyze.
- Do NOT log or persist text_payload to disk.

TECH (fixed):

- shelf ^1.4.2, shelf_router ^1.1.4, http ^1.3.0 (backend only), dotenv ^4.2.0, google_generative_ai ^0.4.6
- Listen 0.0.0.0:8080
- Model gemini-2.0-flash, temperature 0.1, responseMimeType application/json
- Keys from .env only: GEMINI_API_KEY, SAFE_BROWSING_API_KEY
- Response schema: {"risk_score": int, "analysis_message": string}; errors: risk_score -1

PIPELINE ORDER (never reorder):

1. Regex URL extract → 2. Safe Browsing (if URLs) → 3. Gemini (only if step 2 did not flag threat)

WHEN DONE:

- From repo root: cd backend && dart pub get && dart analyze (if applicable) && dart run bin/server.dart
- Smoke test with curl (sector-appropriate; see sector prompt)
- Log to docs/dev_logs/dev0/ or docs/dev_logs/dev1/ (whichever branch you are on): new file YYYY-MM-DD_phase1_backend_sectorN.md
- Stop. Do not start the next sector unless the user asks.
