# App Modular Architecture — Visual Guide

**Created:** May 23, 2026  
**Purpose:** Show how the Flutter app is organized into independent, reusable modules.

---

## Directory Tree

```
lib/
├── main.dart
│   ├── Initializes Flutter bindings
│   ├── Creates API service (MockApiService or LiveApiService)
│   └── Runs MultiProvider + KuCubaApp
│
├── app.dart
│   └── Class: KuCubaApp (StatelessWidget)
│       ├── Applies: bankIslamTheme()
│       └── Sets Home: IntentRouter()
│
├── config/
│   └── app_config.dart
│
├── models/
│   ├── analysis_result.dart
│   └── scam_demo_models.dart
│
├── providers/
│   ├── analysis_provider.dart
│   │   └── Class: AnalysisProvider (ChangeNotifier)
│   └── stats_provider.dart
│       └── Class: StatsProvider (ChangeNotifier)
│
├── screens/
│   ├── intent_router.dart
│   │   ├── Class: IntentRouter
│   │   └── Routes to OverlayScreen or ScamDetectorPage
│   ├── home_screen.dart
│   │   ├── Class: ScamDetectorPage (StatefulWidget)
│   │   └── Enum: AppScreen { home, scan, result }
│   └── overlay_screen.dart
│
├── services/
│   ├── api_service.dart
│   │   ├── Interface: AnalysisApiService
│   │   └── Class: LiveApiService (Dio HTTP client)
│   └── mock_api_service.dart
│
├── theme/
│   ├── app_colors.dart
│   ├── app_typography.dart
│   └── bank_islam_theme.dart
│       └── Function: bankIslamTheme() → ThemeData
│
└── widgets/
    ├── analog_meter.dart
    ├── analysis_message_card.dart
    ├── analyze_button.dart
    ├── error_banner.dart
    ├── risk_badge.dart
    ├── risk_utils.dart
    ├── scam_widgets.dart
    ├── skeleton_meter_placeholder.dart
    └── text_input_area.dart
```

---

## Dependency Graph

### Internal Dependencies (Imports)

```
main.dart
  ├── imports KuCubaApp from app.dart
  ├── imports AnalysisProvider + StatsProvider
  └── imports MockApiService + LiveApiService

app.dart
  ├── imports bankIslamTheme from theme/bank_islam_theme.dart
  └── imports IntentRouter from screens/intent_router.dart

screens/intent_router.dart
  ├── imports ScamDetectorPage from screens/home_screen.dart
  └── imports OverlayScreen from screens/overlay_screen.dart

screens/home_screen.dart
  ├── imports AnalysisProvider + StatsProvider
  ├── imports models + reusable widgets
  └── imports OverlayScreen for share-sheet demo

providers/analysis_provider.dart
  └── imports AnalysisApiService from services/api_service.dart

services/api_service.dart
  ├── imports Dio package
  └── imports AnalysisResult from models/analysis_result.dart
```

### External Dependencies

```
Packages (pubspec.yaml):
├── flutter
├── provider
├── dio
├── google_fonts
├── flutter_animate
└── receive_sharing_intent (git dependency)
```

---

## Data Flow: Analyze Text

```
User Input (Scan screen)
  │
  └──▶ ScamDetectorPage._analyzeText()
       │
       └──▶ AnalysisProvider.analyze(text)
            │
            ├── Sets state: loading
            ├── Calls AnalysisApiService.analyze(text)
            │     ├── LiveApiService: Dio POST /analyze
            │     └── MockApiService: local demo result
            │
            └── Updates state:
                  ├── complete + AnalysisResult
                  └── or error + message
```

---

## Screen Navigation State Machine

```
IntentRouter
  ├── Shared intent present  ──▶ OverlayScreen
  └── No shared intent       ──▶ ScamDetectorPage

ScamDetectorPage AppScreen:
  home ──▶ scan ──▶ result
   ▲                 │
   └────── back/home ┘
```

---

## Theme Application Flow

```
bankIslamTheme()
  │
  ├── ColorScheme.fromSeed (AppColors.corporateRed)
  ├── appTextTheme() typography
  ├── AppBarTheme / ElevatedButtonTheme / InputDecorationTheme
  │
  └── Applied in KuCubaApp
      └── MaterialApp(theme: bankIslamTheme())
```

---

## Testing Entry Points

```
test/widget_test.dart
  └── currently pumps KuCubaApp with AnalysisProvider
```

---

## Notes for Developers

1. **Provider-based state:** `AnalysisProvider` and `StatsProvider` are app-level state.
2. **Router entrypoint:** `IntentRouter` is the home entry to handle share intents.
3. **Service abstraction:** `AnalysisApiService` allows switching between live and mock backends.
4. **Theme consistency:** Use `AppColors` + `bankIslamTheme()` tokens instead of hardcoded theme values.

---

**Last Updated:** May 23, 2026  
**Maintainers:** @KuCuba Team
