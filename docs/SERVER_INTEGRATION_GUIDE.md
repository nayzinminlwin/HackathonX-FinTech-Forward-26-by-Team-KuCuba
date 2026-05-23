# Server Integration Guide — Backend Testing with Physical Android Device

**Date:** May 23, 2026  
**Scope:** How to test the Dart backend server with a physical Android device using ADB reverse tunneling.

---

## Overview

The scam detector app can run in two modes:

| Mode | Use Case | Config |
|------|----------|--------|
| **Mock API** | Quick UI testing, no backend needed | `AppConfig.useMockApi = true` |
| **Live Backend** | Real analysis pipeline (Safe Browsing + Gemini) | `AppConfig.useMockApi = false` |

This guide covers **Live Backend** testing on a physical device.

---

## Prerequisites

- **Android device** with USB debugging enabled
- **Dart SDK** installed (for backend)
- **Flutter SDK** installed
- **ADB** installed and in PATH
- **Google Safe Browsing API key** (optional; backend gracefully skips if missing)
- **Gemini API key** (required for Gemini analysis; mock heuristics used if missing)

---

## Step-by-Step Setup

### 1. Enable USB Debugging on Android Device

1. Connect device via USB to PC
2. On device: Settings → About Phone → tap Build Number 7 times
3. Settings → Developer Options → enable USB Debugging
4. Accept the "Allow USB Debugging?" prompt

### 2. Verify ADB Connection

```bash
adb devices
```

Output should list your device:
```
List of attached devices
ABC123XYZ               device
```

### 3. Update App Config

**File:** [lib/config/app_config.dart](../lib/config/app_config.dart)

```dart
class AppConfig {
  /// Toggle to true to use mock responses (no backend needed).
  static const bool useMockApi = false;  // ← Change to FALSE

  /// Backend base URL (replace with your machine's IP or localhost via adb reverse).
  static const String backendBaseUrl = 'http://localhost:8080';  // ← Correct

  static const String analyzeEndpoint = '/analyze';
}
```

### 4. Set Up ADB Reverse Tunneling

```bash
adb reverse tcp:8080 tcp:8080
```

This command tells your device: *"When you connect to localhost:8080, send it to my host PC's port 8080"*.

**Verify the rule is active:**
```bash
adb reverse --list
```

Expected output:
```
tcp:8080 tcp:8080
```

### 5. Start the Backend Server

On your PC, in a new terminal:

```bash
cd backend
dart run bin/server.dart
```

Expected output:
```
[analyze] Server initialized.
[analyze] Listening on http://localhost:8080
```

**Keep this terminal open** while testing.

### 6. Deploy the App to Device

In another terminal:

```bash
flutter clean
flutter pub get
flutter run -d <device-id>
```

Replace `<device-id>` with the ID from `adb devices`. Example:
```bash
flutter run -d ABC123XYZ
```

The app should install and launch on the device.

---

## Testing the Integration

### Quick Test Flow

1. **Navigate to "Scan" tab** (bottom nav)
2. **Paste a suspicious text**, e.g.:
   ```
   Congratulations! You have won RM50,000 lottery prize.
   Send RM500 processing fee to this account to claim.
   ```
3. **Tap "Analyze"**
4. **Expected result:**
   - Meter animates to ~85-95% (high risk)
   - Badge shows "High Risk"
   - Message: *"Warning: This message contains..."* or *"...authority impersonation..."*

### View Backend Logs

```bash
# In the terminal where the backend is running, you should see:
[analyze] Extracted 0 URL(s): []
[analyze] Gemini result — risk_score: 92
```

### View App Logs

In a new terminal:

```bash
adb logcat | grep -i "analyze\|error\|dio"
```

This filters for analysis, errors, and Dio (HTTP client) logs.

---

## Troubleshooting

### Issue: "ProviderNotFoundException" or "Could not find AnalysisProvider"

**Cause:** The app's provider setup doesn't match the code changes.  
**Fix:**
1. Run `flutter clean`
2. Run `flutter pub get`
3. Rebuild: `flutter run -d <device-id>`

### Issue: "Connection refused" / "Could not reach backend"

**Checklist:**
1. Verify ADB reverse is active:
   ```bash
   adb reverse --list
   ```
   Should show `tcp:8080 tcp:8080`

2. Verify backend is running (check terminal for "Listening on...")

3. Verify firewall allows port 8080 on your PC

4. Test connectivity manually:
   ```bash
   adb shell curl -X POST http://localhost:8080/analyze \
     -H "Content-Type: application/json" \
     -d '{"text_payload": "test"}'
   ```
   Expected response: `{"risk_score": 8, "analysis_message": "..."}`

### Issue: Backend returns "Analysis temporarily unavailable" (riskScore = -1)

**Possible causes:**
- Gemini API key not set in backend environment
- Gemini API quota exhausted
- Gemini service error

**Workaround:** Set `useMockApi = true` to test UI with keyword heuristics.

### Issue: "Stats not updating" after scan

**Cause:** StatsProvider not included in MultiProvider setup.  
**Fix:**
1. Check [lib/main.dart](../lib/main.dart) uses `MultiProvider` with both providers:
   ```dart
   MultiProvider(
     providers: [
       ChangeNotifierProvider(create: (_) => AnalysisProvider(apiService)),
       ChangeNotifierProvider(create: (_) => StatsProvider()),
     ],
     child: const KuCubaApp(),
   );
   ```

2. Hot restart: `r` in Flutter terminal

---

## Configuration Reference

### AppConfig Modes

**Mock Mode** (Development/Demo):
```dart
static const bool useMockApi = true;
```
- Uses keyword-based heuristics (no backend needed)
- Fast responses
- Limited accuracy (only catches obvious patterns)

**Live Mode** (Production/Testing):
```dart
static const bool useMockApi = false;
```
- Calls backend → Safe Browsing + Gemini
- 5–15 second response time
- High accuracy (catches complex scams)

### Backend URL Patterns

| Device Type | Config | Notes |
|-------------|--------|-------|
| **Physical Device (ADB Reverse)** | `http://localhost:8080` | Used in this guide |
| **Emulator (default)** | `http://10.0.2.2:8080` | Special emulator IP |
| **Physical Device (Direct IP)** | `http://192.168.x.x:8080` | If ADB reverse fails |

### Environment Variables (Backend)

Set these before starting `bin/server.dart`:

```bash
export GOOGLE_SAFE_BROWSING_API_KEY="your-key-here"
export GOOGLE_GEMINI_API_KEY="your-gemini-key-here"
```

(On Windows PowerShell, use `$env:VARIABLE = "value"`)

---

## Cleanup

After testing, you can clean up:

```bash
# Remove ADB reverse rule
adb reverse --remove tcp:8080

# Or remove all reverse rules
adb reverse --remove-all
```

---

## See Also

- [ARCHITECTURE_DIAGRAM.md](ARCHITECTURE_DIAGRAM.md) — Provider setup & stats tracking
- [TECH_STACK_AND_PIPELINE.md](TECH_STACK_AND_PIPELINE.md) — Backend architecture
- [Phase_1_Core_App_Module.md](Phase_1_Core_App_Module.md) — Feature overview

---

**Last Updated:** May 23, 2026
