# Architecture Diagrams

**Project:** Eternal Guardian  
**Status:** Current implementation  
**Last updated:** 2026-05-24

## 1. Application Module Map

```text
lib/
|-- main.dart
|   `-- creates providers and launches KuCubaApp
|-- app.dart
|   `-- MaterialApp with Bank Islam theme and IntentRouter home
|-- config/
|   `-- app_config.dart
|-- models/
|   |-- analysis_result.dart
|   `-- scam_demo_models.dart
|-- providers/
|   |-- analysis_provider.dart
|   `-- stats_provider.dart
|-- screens/
|   |-- home_screen.dart
|   |-- intent_router.dart
|   `-- overlay_screen.dart
|-- services/
|   |-- api_service.dart
|   |-- mock_api_service.dart
|   `-- notification_service_controller.dart
|-- theme/
|   |-- app_colors.dart
|   |-- app_typography.dart
|   `-- bank_islam_theme.dart
`-- widgets/
    |-- analog_meter.dart
    |-- analysis_message_card.dart
    |-- analyze_button.dart
    |-- error_banner.dart
    |-- risk_badge.dart
    |-- risk_utils.dart
    |-- scam_widgets.dart
    |-- skeleton_meter_placeholder.dart
    `-- text_input_area.dart
```

## 2. Android Native Module Map

```text
android/app/src/main/
|-- AndroidManifest.xml
|-- kotlin/com/kucuba/eternal_guardian/
|   |-- MainActivity.kt
|   |-- ScamDetectorForegroundService.kt
|   |-- AnalyzeReceiver.kt
|   |-- NotificationHelper.kt
|   |-- HttpAnalysisClient.kt
|   `-- MockAnalysisClient.kt
`-- res/layout/
    |-- notification_idle.xml
    |-- notification_scanning.xml
    |-- notification_result.xml
    `-- notification_status.xml
```

## 3. Backend Module Map

```text
backend/
|-- bin/
|   |-- server.dart
|   `-- run_tests.dart
`-- lib/
    |-- handlers/
    |   `-- analyze_handler.dart
    |-- models/
    |   `-- analysis_result.dart
    `-- services/
        |-- gemini_service.dart
        |-- link_extractor.dart
        |-- safe_browsing.dart
        `-- url_expander.dart
```

## 4. Runtime Architecture

```mermaid
flowchart TB
  subgraph FlutterApp["Flutter app"]
    Main["main.dart"]
    Providers["Provider tree"]
    App["KuCubaApp"]
    Router["IntentRouter"]
    Home["ScamDetectorPage"]
    Overlay["OverlayScreen"]
    AnalysisProvider["AnalysisProvider"]
    StatsProvider["StatsProvider"]
    LiveApi["LiveApiService"]
    MockApi["MockApiService"]
  end

  subgraph AndroidNative["Android native"]
    Manifest["AndroidManifest ACTION_SEND + service"]
    MainActivity["MainActivity MethodChannel"]
    Service["ScamDetectorForegroundService"]
    Receiver["AnalyzeReceiver"]
    Notification["NotificationHelper RemoteViews"]
    NativeHttp["HttpAnalysisClient"]
    NativeMock["MockAnalysisClient"]
  end

  subgraph Backend["Dart Shelf backend"]
    Server["server.dart"]
    Handler["AnalyzeHandler"]
    Extractor["LinkExtractor"]
    Expander["UrlExpander"]
    SafeBrowsing["SafeBrowsing"]
    Gemini["GeminiService"]
  end

  Main --> Providers --> App --> Router
  Router --> Home
  Router --> Overlay
  Home --> AnalysisProvider
  Overlay --> AnalysisProvider
  AnalysisProvider --> LiveApi
  AnalysisProvider --> MockApi
  Home --> StatsProvider

  Manifest --> Router
  Home --> MainActivity
  MainActivity --> Service
  Service --> Notification
  Notification --> Receiver
  Receiver --> NativeHttp
  Receiver --> NativeMock

  LiveApi --> Server
  NativeHttp --> Server
  Server --> Handler
  Handler --> Extractor
  Extractor --> Expander
  Extractor --> SafeBrowsing
  Expander --> SafeBrowsing
  Handler --> Gemini
```

## 5. Client Entry Points

```mermaid
flowchart LR
  User1["User pastes text in app"] --> Home["ScamDetectorPage"]
  User2["User shares text from another app"] --> Share["Android ACTION_SEND"]
  User3["User submits text in notification"] --> Notify["RemoteInput action"]

  Home --> Provider["AnalysisProvider"]
  Share --> Router["IntentRouter"]
  Router --> Overlay["OverlayScreen"]
  Overlay --> Provider

  Provider --> Mode{"Mock mode?"}
  Mode -->|yes| Mock["MockApiService"]
  Mode -->|no| Live["LiveApiService"]
  Live --> Backend["POST /analyze"]

  Notify --> Receiver["AnalyzeReceiver.kt"]
  Receiver --> NativeMode{"Mock mode?"}
  NativeMode -->|yes| NativeMock["MockAnalysisClient.kt"]
  NativeMode -->|no| NativeHttp["HttpAnalysisClient.kt"]
  NativeHttp --> Backend
```

## 6. Backend Sequence

```mermaid
sequenceDiagram
  participant Client as Flutter/Kotlin client
  participant Server as Shelf POST /analyze
  participant Handler as AnalyzeHandler
  participant Links as LinkExtractor
  participant Expander as UrlExpander
  participant Safe as SafeBrowsing
  participant Gemini as GeminiService

  Client->>Server: {"text_payload":"..."}
  Server->>Handler: request body
  Handler->>Handler: parse JSON and validate text_payload
  Handler->>Links: extractUrls(text)
  Links-->>Handler: original URLs

  par Original URL check
    Handler->>Safe: checkUrls(original URLs)
  and Short URL expansion
    Handler->>Expander: expandAll(shortened URLs)
  end

  Safe-->>Handler: threat or clear
  alt Original URL threat
    Handler-->>Client: risk_score 100, analysis_source safe_browsing
  else No original threat
    Expander-->>Handler: expanded URLs or unresolved shorteners
    Handler->>Safe: checkUrls(expanded URLs)
    Safe-->>Handler: threat or clear
    alt Expanded URL threat
      Handler-->>Client: risk_score 100, analysis_source safe_browsing
    else No known threat
      Handler->>Gemini: analyzeText(text, urlContext)
      Gemini-->>Handler: JSON map or null
      Handler-->>Client: normalized AnalysisResult
    end
  end
```

## 7. Flutter State Flow

```mermaid
stateDiagram-v2
  [*] --> idle
  idle --> loading: analyze(text)
  loading --> complete: result 1..100
  loading --> error: unavailable or network error
  complete --> idle: reset / new scan
  error --> loading: retry
  error --> idle: reset
```

## 8. Notification Flow

```mermaid
flowchart TD
  Toggle["Guardian Mode switch in HomeScreen"] --> Permission["Request POST_NOTIFICATIONS"]
  Permission --> Channel["MethodChannel com.kucuba/notification_service"]
  Channel --> Service["Start ScamDetectorForegroundService"]
  Service --> Idle["Show idle RemoteViews notification"]
  Idle --> Input["User enters text in RemoteInput"]
  Input --> Receiver["AnalyzeReceiver"]
  Receiver --> Scanning["Update scanning notification"]
  Receiver --> Mode{"use_mock_api?"}
  Mode -->|true| Mock["MockAnalysisClient"]
  Mode -->|false| Http["HttpAnalysisClient POST /analyze"]
  Mock --> Result["Result or error RemoteViews"]
  Http --> Result
```

## 9. Important Boundaries

| Boundary | Rule |
|----------|------|
| Flutter to backend | Only `POST /analyze` is required. |
| Kotlin to backend | Uses the same body and response contract as Flutter. |
| Flutter to Kotlin | MethodChannel starts/stops the foreground service and passes backend/mock settings. |
| Backend to external services | Safe Browsing and Gemini keys stay server-side. |
| User data | Text is analyzed ephemerally and is not stored by the app or backend. |
