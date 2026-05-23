# Phase 3 Sector Allocation Document Plan

## Summary
Create `docs/Phase_3_Sector_Allocation_and_Deliveries.md` as a docs-only handoff for building Phase 3 in three sequential sectors on **`dev0`**.

Important override: Phase 3 will **not** read clipboard text from the notification. Because Android clipboard access from background notification actions is likely restricted, the notification will provide a direct user input flow instead: the user taps an action, pastes/types text into the notification input using Android `RemoteInput`, and submits it for analysis.

## Key Changes
- Add a new Markdown allocation file under `docs/`.
- State branch allocation clearly:
  - **Implementation branch:** `dev0`
  - **Phase 3 logs:** `docs/dev_logs/dev0/`
  - **Formal validation logs:** `docs/test_logs/`
- State requirement override clearly:
  - Replace “Analyze Copied Text” clipboard behavior with **manual paste/type input in the notification**.
  - Do not use `ClipboardManager` for Phase 3.
  - Do not passively or automatically read clipboard content.

## Three Phase 3 Sectors

1. **Sector 1: Native Notification Foundation**
   - Add Android permissions and manifest registration.
   - Implement `ScamDetectorForegroundService`.
   - Create notification channel with `IMPORTANCE_LOW`.
   - Build idle pinned notification with an action like **Paste Text to Analyze**.
   - Add Flutter MethodChannel start/stop/isRunning bridge.
   - Delivery gate: Guardian service starts, shows pinned notification, and stops cleanly.

2. **Sector 2: Notification Text Input + Backend Call**
   - Implement notification input using Android `RemoteInput`.
   - Add `AnalyzeReceiver` to receive submitted text from the notification action.
   - Validate empty input and show a friendly error state.
   - Use Kotlin `HttpAnalysisClient` with `HttpURLConnection`.
   - Send exact backend body: `{"text_payload":"..."}`.
   - Show scanning state while waiting for `POST /analyze`.
   - Delivery gate: pasted/typed notification input reaches backend and handles success/failure.

3. **Sector 3: Result Notification UI + Guardian Mode QA**
   - Build result `RemoteViews` layout.
   - Show horizontal risk bar with green/yellow/red score zones.
   - Show risk score label and `analysis_message`.
   - Add Analyze Again action that reopens the notification input flow.
   - Add Guardian Mode toggle and Android 13+ notification permission handling.
   - Run final Phase 3 verification.
   - Delivery gate: Phase 3 checklist passes, adjusted for manual notification input instead of clipboard read.

## Document Content Requirements
- Reference source docs:
  - `docs/SOP_blueprint.md`
  - `docs/Detailed_System_Requirement_Document.md`
  - `docs/Phase_3_Pinned_Notification_Banner.md`
  - `docs/AI/rule.md`
  - `docs/AI/SKILL.md`
- Include explicit deviations from the mother Phase 3 document:
  - `ClipboardManager` is removed from implementation scope.
  - `AnalyzeReceiver` receives `RemoteInput` text instead of reading clipboard.
  - Acceptance criteria should test notification input submission, not clipboard access.
- Preserve existing constraints:
  - Phase 1 backend `POST /analyze` must be verified first.
  - Phase 2 is not required.
  - No `BOOT_COMPLETED`.
  - No `SYSTEM_ALERT_WINDOW`.
  - No `flutter_local_notifications`.
  - No secrets, `.env` values, or raw user payloads in docs/logs.

## Test Plan
- Confirm the Markdown file exists at `docs/Phase_3_Sector_Allocation_and_Deliveries.md`.
- Confirm it contains exactly three sectors.
- Confirm it states Phase 3 is assigned to `dev0`.
- Confirm it explicitly forbids automatic clipboard grabbing.
- Confirm it uses notification `RemoteInput` / manual paste-text flow instead.
- Confirm it does not claim implementation is already complete.

## Assumptions
- The “input text box there” means an Android notification inline input using `RemoteInput`.
- If the target Android device does not support a usable inline notification input UX, the documented fallback will be opening the app to a paste box, not reading clipboard in the background.
- This turn is still planning only; no file is created until implementation mode resumes.
