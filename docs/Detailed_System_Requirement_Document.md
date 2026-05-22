# Detailed System Requirements Document (SRD)

**Project Name:** The "Everywhere Scam Detector" (Be U by Bank Islam Module)
**Target Platform:** Android MVP (Prioritized for OS share-sheet and notification flexibility)
**Team Allocation:** 2 Backend Developers, 1 Frontend Developer (Web to Mobile UI)

---

## 1. System Architecture: The Hybrid AI Engine

**Approach:** Hybrid Rule-Based + AI Method
**Objective:** Ensure low latency (< 2.5s), high accuracy, and minimal API token costs.

### 1.1 Backend Processing Flow & Logic

1. **Input Reception:** - The backend exposes a REST endpoint (`POST /analyze`) accepting a JSON payload: `{"text_payload": "<string>"}`.
   - The payload can be a single message, a multi-line copied conversation, or a URL.
2. **Step 1: Link Extraction (Regex):** - The backend runs a Regular Expression (e.g., matching `http://`, `https://`, and `www.`) to parse and extract any URLs from the `text_payload`.
3. **Step 2: Threat Database Lookup (Rule-Based):**
   - If URLs exist, make an asynchronous call to the Google Safe Browsing API (or equivalent).
   - _Condition A (Malicious):_ If the API returns a threat match, immediately halt further processing. Return a hardcoded response: `{"risk_score": 100, "analysis_message": "Warning: This link is a known malicious website flagged for phishing/malware."}`. (Bypasses LLM to save tokens/time).
4. **Step 3: Contextual Analysis (LLM API):**
   - _Condition B (Safe/No Link):_ If no links are found, or the API clears the links, send the full `text_payload` to the LLM API (e.g., Gemini).
   - **System Prompt Requirements (Few-Shot):** The prompt must use the **Few-Shot** technique to maximize accuracy. It must instruct the AI to act as a cybersecurity analyst, provide **at least 5 examples of known Malaysian scams and 5 safe messages** for context, read the user's text as a potential two-way conversation, and evaluate urgency, financial requests, and emotional manipulation.
   - **Enforced Output:** The LLM must be strictly constrained to output _only_ valid JSON.

5. **Standardized Output Format:** - The backend MUST always return this exact schema to the frontend:
   ```json
   {
     "risk_score": <Integer 1-100>,
     "analysis_message": "<String, max 2 sentences explaining the risk>"
   }
   ```

---

## 2. Detailed Functional Requirements (FR)

### Phase 1: Core App Module (The Sandbox / Chat-Based UI)

_The base testing ground and fallback application interface._

- **FR 1.1 Multi-line Input:** A main screen featuring a `TextInput` area capable of accepting multi-line strings (representing copied conversational blocks).
- **FR 1.2 Action Trigger:** An "Analyze" button to trigger the `POST /analyze` API call.
- **FR 1.3 Asynchronous UI States:** - _Idle:_ Empty input, meter at 0.
  - _Loading:_ A skeleton loader or spinner replaces the meter while awaiting the backend response. Button is disabled to prevent duplicate calls.
- **FR 1.4 Analog Meter UI Component:** A custom SVG or Canvas-based half-circle analog meter.
  - **Zones:** 1-30 (Green/Safe), 31-70 (Yellow/Caution), 71-100 (Red/Danger).
  - **Animation:** The needle must smoothly animate from 0 to the received `risk_score`.
- **FR 1.5 Analysis Display:** A readable text view directly below the meter to display the `analysis_message`.

### Phase 2: OS Share-Sheet Overlay (The Primary UX)

_The frictionless "Eternal Guardian" feature triggered natively from other apps._

- **FR 2.1 OS Intent Registration:** The Android `AndroidManifest.xml` must register an `<intent-filter>` for `ACTION_SEND` with `mimeType="text/plain"`. This ensures the app appears in the share menu of apps like WhatsApp.
- **FR 2.2 Overlay Architecture:** The activity handling the intent must use a `BottomSheet` or a Dialog theme with a transparent background so it renders _over_ the current app (e.g., WhatsApp) rather than opening a full-screen app window.
- **FR 2.3 Auto-Execution:** Upon receiving the `ACTION_SEND` text payload, the frontend must immediately trigger the `POST /analyze` API call without requiring the user to press an "Analyze" button.
- **FR 2.4 Reusable UI Components:** The overlay must render the exact same Analog Meter and Message components built in FR 1.4 and FR 1.5.
- **FR 2.5 Explicit Dismissal (Anti-Accident):** - Tap-to-dismiss on the background overlay MUST be disabled (`setCancelable(false)`).
  - A clear, prominent "X" Close button or "Done" button must be provided. Pressing this destroys the BottomSheet and returns control to the underlying app natively.

### Phase 3: Pinned Notification Banner (The Clipboard Fallback)

_For handling multiple copied messages when the OS "Share" option is restricted._

- **FR 3.1 Foreground Service:** Implement an Android Foreground Service to maintain a persistent, pinned notification in the system drawer.
- **FR 3.2 Custom Notification Layout (`RemoteViews`):** The notification must use a custom layout containing an "Analyze Copied Text" action button.
- **FR 3.3 Clipboard Access:** Tapping the action button must trigger the app to read the current system clipboard (`ClipboardManager`).
- **FR 3.4 Background Processing & Update:** The copied text is sent to the backend. The notification must show a "Scanning..." state.
- **FR 3.5 Horizontal Bar UI:** Once the response is received, the notification layout updates to display a horizontal segmented progress bar (Green/Yellow/Red) representing the `risk_score` percentage, alongside the `analysis_message`.

---

## 3. Non-Functional Requirements (NFR)

- **NFR 1 (Latency):** The end-to-end response time for Phase 2 (from OS Share to meter animating) must target < 2.5 seconds to maintain the "instant" UX feel.
- **NFR 2 (Cost Optimization):** Step 2 (Safe Browsing) must be strictly enforced before Step 3 (LLM) to prevent expensive token usage on obvious malicious URLs.
- **NFR 3 (Cross-Platform Framework):** To accommodate the web-developer transitioning to mobile, React Native or Flutter should be used. _Note:_ Native bridging packages will be required for `ACTION_SEND` intents and clipboard/notification management.
