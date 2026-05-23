# App Modular Architecture — Visual Guide

**Created:** May 23, 2026  
**Purpose:** Show how the Flutter app is organized into independent, reusable modules.

---

## Directory Tree

```
lib/
├── main.dart
│   └── → Imports EternalGuardianApp from lib/app/app.dart
│       └── void main() { runApp(const EternalGuardianApp()); }
│
├── app/
│   ├── app.dart
│   │   ├── Class: EternalGuardianApp (StatelessWidget)
│   │   ├── Creates: MaterialApp
│   │   ├── Applies: AppTheme.lightTheme
│   │   └── Sets Home: ScamDetectorPage()
│   │
│   └── theme/
│       └── app_theme.dart
│           ├── Class: AppTheme (static methods & constants)
│           ├── Constants: Color tokens (primaryBrand, textPrimary, etc.)
│           ├── TextTheme: Poppins typography definitions
│           ├── CardTheme, InputDecorationTheme, FilledButtonTheme
│           └── Getter: lightTheme → ThemeData
│
└── features/
    └── scam_detector/
        ├── screens/
        │   └── scam_detector_page.dart
        │       ├── Class: ScamDetectorPage (StatefulWidget)
        │       ├── Class: _ScamDetectorPageState
        │       │   ├── Properties:
        │       │   │   ├── _textController (TextField input)
        │       │   │   ├── _analysisService (AnalysisService instance)
        │       │   │   ├── _currentScreen (enum AppScreen)
        │       │   │   ├── _isLoading (bool)
        │       │   │   └── _result (AnalysisResult?)
        │       │   │
        │       │   ├── Lifecycle:
        │       │   │   ├── initState() [inherited, not overridden here]
        │       │   │   └── dispose() → _textController.dispose()
        │       │   │
        │       │   ├── Methods:
        │       │   │   ├── _analyzeText() → calls _analysisService
        │       │   │   ├── _openBottomSheetDemo()
        │       │   │   ├── _pasteFromClipboard()
        │       │   │   ├── _setScreenFromNav(int)
        │       │   │   │
        │       │   │   ├── Build Methods:
        │       │   │   ├── _buildHomeScreen() → 3 sections + bottom nav
        │       │   │   ├── _buildScanScreen() → text input + buttons
        │       │   │   ├── _buildResultScreen() → meter + badge + analysis
        │       │   │   │
        │       │   │   └── Helper Methods:
        │       │   │       ├── _buildQuickScanButton()
        │       │   │       ├── _buildQuickExampleCard()
        │       │   │       └── _screenHeader()
        │       │   │
        │       │   ├── Enums:
        │       │   │   └── AppScreen { home, scan, result }
        │       │   │
        │       │   └── build() → Scaffold + switch on _currentScreen
        │
        ├── services/
        │   └── analysis_service.dart
        │       ├── Class: AnalysisService
        │       ├── HTTP Client: uses http package
        │       │
        │       ├── Public Methods:
        │       │   ├── analyzeText(String text) → Future<AnalysisResult>
        │       │   │   ├── Tries: POST {API_BASE_URL}/analyze
        │       │   │   ├── Timeout: 12 seconds
        │       │   │   ├── On Success: return AnalysisResult(isFallback: false)
        │       │   │   └── On Failure: return _analyzeLocalHeuristic(text)
        │       │   │
        │       │   └── previewBottomSheetResult() → AnalysisResult
        │       │
        │       └── Private Methods:
        │           └── _analyzeLocalHeuristic(String text) → AnalysisResult
        │               └── Pattern matching: keywords, URLs, urgency
        │
        ├── models/
        │   ├── analysis_result.dart
        │   │   └── Class: AnalysisResult
        │   │       ├── riskScore (int 0–100)
        │   │       ├── analysisMessage (String explanation)
        │   │       └── isFallback (bool)
        │   │
        │   └── scam_demo_models.dart
        │       ├── Class: QuickScanExample
        │       │   ├── text (String)
        │       │   └── preview (String label)
        │       │
        │       └── const quickScanExamples (List<QuickScanExample>)
        │           └── 3 pre-built examples (suspicious link, prize scam, normal)
        │
        └── widgets/
            ├── analog_meter.dart
            │   ├── Enum: MeterSize { small, medium, large }
            │   ├── Class: AnalogMeter (StatelessWidget)
            │   │   ├── Props: riskScore, size
            │   │   └── Builds: Animated gauge using CustomPaint
            │   │
            │   └── Class: _MeterPainter (CustomPainter)
            │       ├── paint(): draws gauge arcs, needle, scale markings
            │       └── shouldRepaint(): detects score/color changes
            │
            ├── risk_badge.dart
            │   └── Class: RiskBadge (StatelessWidget)
            │       ├── Props: riskScore
            │       └── Builds: colored badge with icon + label
            │
            ├── risk_utils.dart
            │   ├── Function: riskColor(int) → Color
            │   ├── Function: riskTint(int) → Color (light bg)
            │   ├── Function: riskShade(int) → Color (dark variant)
            │   ├── Function: riskIcon(int) → IconData
            │   └── Function: riskLabel(int) → String
            │
            └── scam_widgets.dart
                ├── Class: GlassStatCard (StatelessWidget)
                │   ├── Props: value, label
                │   └── Builds: frosted glass card with stats
                │
                ├── Class: SpinningLoader (StatelessWidget)
                │   ├── Props: size
                │   └── Builds: circular progress indicator
                │
                ├── Class: BottomSheetOverlayDemo (StatefulWidget)
                │   ├── Props: result (AnalysisResult)
                │   ├── State: _isLoading, _result
                │   └── Builds: Full-screen bottom sheet with analysis
                │
                └── Class: BottomNavBar (StatelessWidget)
                    ├── Props: selectedIndex, onSelect callback
                    └── Builds: Custom nav with Home + Scan tabs
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

## Notes for Developers

1. **Single Responsibility:** Each file handles one domain (theme, service, screen, widget).
2. **Stateless Where Possible:** Most widgets are stateless (AnalogMeter, RiskBadge, etc.). Only `ScamDetectorPage` needs mutable state.
3. **No Global State Yet:** If complexity grows, introduce Provider pattern in a new `lib/providers/` folder.
4. **Theme Consistency:** Always use `AppTheme` constants or `Theme.of(context)` instead of hardcoded colors.
5. **Testing:** Keep widgets small and pure; test AnalysisService and helpers independently once test infrastructure expands.

---

**Last Updated:** May 23, 2026  
**Maintainers:** @KuCuba Team
