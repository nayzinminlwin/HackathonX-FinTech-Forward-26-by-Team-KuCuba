# App Modular Architecture — Visual Guide

**Created:** May 23, 2026  
**Purpose:** Show how the Flutter app is organized into independent, reusable modules.

---

## Directory Tree

```
lib/
├── main.dart
│   └── → Imports KuCubaApp from lib/app.dart
│       └── runApp(MultiProvider(
│           ├── AnalysisProvider (API communication)
│           ├── StatsProvider (scan tracking)
│           └── KuCubaApp
│       ))
│
├── app.dart
│   ├── Class: KuCubaApp (StatelessWidget)
│   ├── Creates: MaterialApp
│   ├── Applies: bankIslamTheme()
│   └── Sets Home: IntentRouter()
│
├── config/
│   ├── app_config.dart
│   │   ├── useMockApi (bool) — toggle mock vs. live backend
│   │   ├── backendBaseUrl (String) — http://localhost:8080
│   │   └── analyzeEndpoint (String) — /analyze
│   └── [theme files]
│
├── providers/
│   ├── analysis_provider.dart
│   │   ├── Class: AnalysisProvider (ChangeNotifier)
│   │   ├── Properties:
│   │   │   ├── _state (AnalysisState: idle, loading, complete, error)
│   │   │   ├── _result (AnalysisResult?)
│   │   │   └── _errorMessage (String?)
│   │   │
│   │   ├── Methods:
│   │   │   ├── analyze(String textPayload) → Future<void>
│   │   │   └── reset() → void
│   │   │
│   │   └── Getters: state, result, errorMessage, isLoading
│   │
│   └── stats_provider.dart
│       ├── Class: StatsProvider (ChangeNotifier)
│       ├── Properties:
│       │   ├── _totalScans (int)
│       │   └── _threatsBlocked (int)
│       │
│       ├── Methods:
│       │   ├── recordAnalysis(int riskScore) → void (risk ≥ 50 = threat)
│       │   └── reset() → void
│       │
│       └── Getters: totalScans, threatsBlocked
│
├── services/
│   ├── api_service.dart (abstract + LiveApiService)
│   └── mock_api_service.dart (keyword heuristics)
│
├── models/
│   ├── analysis_result.dart
│   │   └── Class: AnalysisResult
│   │       ├── riskScore (int 0–100, -1 = error sentinel)
│   │       ├── analysisMessage (String)
│   │       ├── isUnavailable getter
│   │       └── fromJson() factory
│   │
│   └── scam_demo_models.dart
│       ├── Class: QuickScanExample
│       └── const quickScanExamples (List<QuickScanExample>)
│
├── screens/
│   ├── home_screen.dart
│   │   ├── Class: ScamDetectorPage (StatefulWidget)
│   │   ├── Class: _ScamDetectorPageState
│   │   │   ├── _buildHomeScreen() — displays live stats (totalScans, threatsBlocked)
│   │   │   ├── _buildScanScreen() — text input + paste button + analyze button
│   │   │   └── _buildResultScreen() — meter + badge + message + report button
│   │   │
│   │   ├── Enums:
│   │   │   └── AppScreen { home, scan, result }
│   │   │
│   │   └── Stats Recording:
│   │       ├── Triggered when AnalysisState.complete
│   │       ├── Deduped by _lastRecordedRiskScore
│   │       └── Reset when new analysis starts or user taps "Scan Another Message"
│   │
│   ├── overlay_screen.dart (Phase 2 — Share Sheet integration)
│   ├── intent_router.dart (intent handling)
│   └── [future screens]
│
├── theme/
│   ├── app_colors.dart — meterGreen, meterYellow, meterRed, corporateRed, etc.
│   ├── app_typography.dart — TextStyle definitions
│   └── bank_islam_theme.dart — ThemeData builder
│
└── widgets/
    ├── analog_meter.dart
    │   ├── Class: AnalogMeter (StatefulWidget)
    │   │   ├── Props: riskScore, compact (bool)
    │   │   └── Builds: 7-segment gauge, needle animation, score label
    │   │
    │   └── Class: _GaugePainter (CustomPainter)
    │       ├── paint() — draws arcs, labels, needle, hub
    │       └── shouldRepaint() — triggers on value change
    │
    ├── risk_badge.dart
    │   └── Class: RiskBadge (StatelessWidget)
    │       ├── Props: riskScore
    │       ├── Builds: colored dot + risk label (Low/Medium/High)
    │       └── Animates: TweenAnimationBuilder on dot scale
    │
    ├── risk_utils.dart
    │   ├── Function: riskColor(int) → Color (green/yellow/red)
    │   ├── Function: riskTint(int) → Color (light 12% alpha)
    │   ├── Function: riskShade(int) → Color (dark variant)
    │   ├── Function: riskIcon(int) → IconData
    │   └── Function: riskLabel(int) → String (Low/Medium/High Risk)
    │
    ├── analysis_message_card.dart — message + reasoning display
    ├── analyze_button.dart — primary action button
    ├── error_banner.dart — error state UI
    ├── skeleton_meter_placeholder.dart — loading state
    ├── text_input_area.dart — TextField wrapper
    ├── scam_widgets.dart — GlassStatCard, BottomNavBar, etc.
    └── [future widgets]
```

---

## Dependency Graph

### Internal Dependencies (Imports)

```
main.dart
  └── imports EternalGuardianApp from app/app.dart

app/app.dart
  ├── imports AppTheme from app/theme/app_theme.dart
  └── imports ScamDetectorPage from features/scam_detector/screens/

features/scam_detector/screens/scam_detector_page.dart
  ├── imports AnalysisService from services/
  ├── imports AnalysisResult, QuickScanExample from models/
  ├── imports AppTheme from app/theme/
  └── imports Widgets from widgets/

features/scam_detector/widgets/scam_widgets.dart
  ├── imports AnalysisResult, AnalysisService from services/
  ├── imports AppTheme from app/theme/
  └── imports risk_utils helpers

features/scam_detector/widgets/analog_meter.dart
  └── imports risk_utils for color helpers

features/scam_detector/services/analysis_service.dart
  ├── imports AnalysisResult from models/
  └── imports http package
```

### External Dependencies

```
Packages (pubspec.yaml):
├── flutter (core framework)
├── google_fonts (Poppins typography)
└── http (HTTP client for API calls)
```

---

## Data Flow: Analyze Text

```
User Input (Scan Screen)
  │
  └──▶ TextField (_textController)
       │
       └──▶ User taps "Analyze Now"
            │
            └──▶ _analyzeText() method
                 │
                 └──▶ Calls AnalysisService.analyzeText(text)
                      │
                      ├─ Try: HTTP POST /analyze
                      │  ├── Success (200, valid JSON)
                      │  │   └── Return AnalysisResult(isFallback: false)
                      │  │
                      │  └── Failure (timeout, 4xx/5xx, parse error)
                      │      └── Catch exception
                      │         └── Call _analyzeLocalHeuristic()
                      │            └── Keyword pattern matching
                      │               └── Return AnalysisResult(isFallback: true)
                      │
                      └──▶ setState() updates:
                           ├── _result = AnalysisResult
                           ├── _isLoading = false
                           └── _currentScreen = AppScreen.result
                               │
                               └──▶ Rebuild UI
                                    │
                                    └──▶ _buildResultScreen()
                                         ├── Show meter (animate to risk score)
                                         ├── Show badge (color based on risk)
                                         ├── Show analysis box (isFallback banner if needed)
                                         └── Show buttons (Report, Scan Again)
```

---

## Screen Navigation State Machine

```
┌──────────┐
│   Home   │◀─────────────────────────────────┐
│ _home()  │                                   │
│          │                                   │
└────┬─────┘                                   │
     │                                         │
     │ "Quick Scan" / Example tap              │
     │                                         │
     ▼                                         │
┌──────────┐        ┌─────────────┐            │
│  Scan    │        │    (Back)   │            │
│ _scan()  │◀───────┤  or Home    │────────────┤
│          │        │    button   │            │
└────┬─────┘        └─────────────┘            │
     │                                         │
     │ "Analyze Now" (text not empty)          │
     │                                         │
     ▼                                         │
┌──────────────┐                               │
│   Result     │─── "Scan Another Message" ───┘
│ _result()    │
│              │
└──────────────┘
     │
     │ "Home" button
     │
     └──────────────────────────────────────────┘
```

---

## Theme Application Flow

```
AppTheme.lightTheme (getter)
  │
  ├── 1. Base ThemeData
  │   └── ColorScheme.fromSeed(seedColor: primaryBrand)
  │
  ├── 2. Text Theme (Poppins)
  │   ├── displaySmall, headlineLarge, titleLarge
  │   ├── bodyLarge, bodyMedium
  │   └── labelLarge
  │
  ├── 3. Component Themes
  │   ├── CardTheme (border, elevation, radius)
  │   ├── InputDecorationTheme (focus border color)
  │   └── FilledButtonTheme (padding, border radius)
  │
  └── 4. Applied in EternalGuardianApp
      └── MaterialApp(theme: AppTheme.lightTheme)
          └── All child widgets inherit theme via Theme.of(context)
```

---

## Testing Entry Points

```
test/widget_test.dart
  │
  └── testWidgets('Scam detector home renders', ...)
      └── Builds: const EternalGuardianApp()
          ├── Checks: find.text('Eternal Guardian') findOne
          └── Checks: find.text('Quick Scan') findOne
```

---

## Data Flow: Stats Tracking (StatsProvider)

```
User completes analysis
  │
  ├── AnalysisProvider sets state → complete
  │   └── _result populated with AnalysisResult
  │
  └──▶ _buildResultScreen() calls widget.watch(AnalysisProvider)
       │
       └──▶ Detects state.complete && result != null
            │
            └──▶ Compares riskScore vs _lastRecordedRiskScore
                 │
                 ├── If different (first time or new analysis):
                 │   │
                 │   └──▶ WidgetsBinding.addPostFrameCallback(...)
                 │        └──▶ stats.recordAnalysis(riskScore)
                 │             │
                 │             ├── _totalScans++
                 │             │
                 │             ├── if (riskScore ≥ 50):
                 │             │   └── _threatsBlocked++
                 │             │
                 │             └──▶ notifyListeners()
                 │                  │
                 │                  └──▶ _buildHomeScreen() rebuilds
                 │                       ├── watch(StatsProvider)
                 │                       └── Display live: totalScans, threatsBlocked
                 │
                 └── If same (duplicate):
                     └── Silently skip (dedupe prevents double-counting)

Dedup Reset Triggers:
  ├── When _analyzeText() starts (new analysis):
  │   └── _lastRecordedRiskScore = null
  │
  ├── When user taps "Scan Another Message":
  │   └── _lastRecordedRiskScore = null (in setState)
  │
  └── When user navigates via bottom nav:
      └── _lastRecordedRiskScore = null
```

---

## Provider Setup (main.dart → MultiProvider Pattern)

```
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = AppConfig.useMockApi
      ? MockApiService()
      : LiveApiService();

  runApp(
    MultiProvider(                           // ← Provides multiple ChangeNotifiers
      providers: [
        ChangeNotifierProvider(
          create: (_) => AnalysisProvider(apiService),  // Manages API calls + results
        ),
        ChangeNotifierProvider(
          create: (_) => StatsProvider(),              // Manages scan counts
        ),
      ],
      child: const KuCubaApp(),
    ),
  );
}

Why MultiProvider?
  ├── Separates concerns: AnalysisProvider (analysis) vs. StatsProvider (tracking)
  ├── Both providers outlive individual screens
  ├── Home screen can watch StatsProvider for live updates
  └── Result screen uses both AnalysisProvider (results) + StatsProvider (recording)
```

---

## Server Integration: ADB Reverse Tunneling

### Setup for Physical Android Device

```
Step 1: Update AppConfig
  └── lib/config/app_config.dart
      ├── useMockApi = false  (enable live backend)
      └── backendBaseUrl = 'http://localhost:8080'

Step 2: Set up ADB Reverse
  └── Terminal command (Windows):
      adb reverse tcp:8080 tcp:8080
      
      What it does:
        └── Forwards device localhost:8080 requests to PC localhost:8080

Step 3: Start Backend Server
  └── On your PC:
      cd backend
      dart run bin/server.dart
      
      Should output: Server running on http://localhost:8080

Step 4: Deploy App to Device
  └── flutter run -d <device-id>
      
      Get device ID: adb devices

Step 5: Test Communication
  └── In app:
      ├── Go to "Scan" tab
      ├── Paste text with scam keywords or link
      ├── Tap "Analyze"
      └── Watch logcat:
          adb logcat | grep -i "analyze\|error\|dio"

Troubleshooting:
  ├── Verify ADB reverse active:
  │   adb reverse --list    (should show: tcp:8080 tcp:8080)
  │
  ├── Test manually:
  │   adb shell curl -X POST http://localhost:8080/analyze \
  │     -H "Content-Type: application/json" \
  │     -d '{"text_payload": "test"}'
  │
  └── If connection fails:
      ├── Check PC firewall allows port 8080
      ├── Verify backend is actually running
      ├── Check backend logs for errors
      └── Fall back to useMockApi = true to test UI
```

---

## Testing: Widget Test Updates

```
test/widget_test.dart now uses MultiProvider:

testWidgets('Scam detector home renders', (WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(                    // ← Both providers must be present
      providers: [
        ChangeNotifierProvider(create: (_) => AnalysisProvider(MockApiService())),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
      ],
      child: const KuCubaApp(),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('Eternal Guardian'), findsOneWidget);
  expect(find.text('Quick Scan'), findsOneWidget);
  expect(find.text('0'), findsWidgets);  // Stats start at 0
});

Why MultiProvider in tests?
  ├── home_screen.dart calls context.watch<StatsProvider>()
  ├── If only AnalysisProvider provided → ProviderNotFoundException
  └── Tests must match main.dart provider setup exactly
```

---

## Mock API Service: Keyword Heuristics

```
MockApiService (lib/services/mock_api_service.dart)

Pattern-based scoring:

  Tier 1 (Score: 88) — Authority Impersonation + Financial
    └── Contains: 'transfer' OR 'tac' OR 'polis' OR 'lhdn'
        └── Example: "Polis here. Transfer RM5,000..."

  Tier 2 (Score: 65) — Suspicious Link/Action
    └── Contains: 'http' OR 'www' OR 'click'
        └── Example: "Click link to claim..."

  Tier 3 (Score: 8) — Safe/Normal
    └── Default fallback
        └── Example: "How are you today?"

Enhancement Opportunity:
  └── Current limitation: "Congratulations! You won RM50,000..." → 8 (should be ~88)
      └── Need to add patterns for: 'won', 'claim', 'fee', 'prize' + money amount
```

---

## Notes for Developers

1. **Provider Scope:** Both AnalysisProvider and StatsProvider live for the entire app lifecycle (not widget-scoped).
2. **Stats Dedup:** Uses `_lastRecordedRiskScore` to avoid double-counting when same analysis completes.
3. **Mock vs. Live:** Toggle `AppConfig.useMockApi` — no other changes needed.
4. **ADB Reverse:** Required for physical device testing; emulator uses `10.0.2.2:8080` instead.
5. **Error Sentinel:** `riskScore = -1` indicates backend unavailable; UI shows banner warning.
6. **Risk Threshold:** Threat = `riskScore ≥ 50` (medium/high); tracked separately from raw scores.

---

**Last Updated:** May 23, 2026  
**Maintainers:** @KuCuba Team
