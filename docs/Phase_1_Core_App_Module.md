# Phase 1: Core App Module — Implementation Plan

> **Scope:** Project scaffolding, backend service, Bank Islam theming, chat-based input screen, animated analog meter, analysis message display, and mock/demo mode.
> **Estimated Time:** ~12 hours (of the 33-hour hackathon window)

---

## 0. High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App (Android)                 │
│                                                         │
│  ┌─────────────┐   ┌──────────────┐   ┌──────────────┐  │
│  │  UI Layer   │──▶│ State Mgmt   │──▶│ Service Layer│  │
│  │ (Screens +  │   │ (Provider)   │   │ (Repository) │  │
│  │  Widgets)   │◀──│              │◀──│              │  │
│  └─────────────┘   └──────────────┘   └──────┬───────┘  │
│                                              │          │
│                               ┌──────────────┴───────┐  │
│                               │  API Client (Dio)    │  │
│                               │  + Mock Interceptor  │  │
│                               └──────────┬───────────┘  │
└──────────────────────────────────────────┼──────────────┘
                                           │ HTTPS
                               ┌───────────▼───────────┐
                               │   Backend (Dart shelf) │
                               │   POST /analyze        │
                               │   ┌─────────┐          │
                               │   │ Regex   │──▶ Safe  │
                               │   │ Extract │   Browse │
                               │   └────┬────┘          │
                               │        │               │
                               │   ┌────▼────┐          │
                               │   │ Gemini  │          │
                               │   │ LLM API │          │
                               │   └─────────┘          │
                               └────────────────────────┘
```

---

## 1. Project Scaffolding

### 1.1 Flutter Project Creation

The Flutter app already exists at the repo root (`pubspec.yaml` → `name: eternal_guardian`, `com.kucuba.eternal_guardian`). Extend this project in place — do not create a second Flutter app or rename the package.

- **Min SDK:** 24 (Android 7.0) — balances modern API access with broad coverage
- **Target SDK:** 35
- **Compile SDK:** 35

### 1.2 Folder Structure

**Repository root (current + Phase 1 targets):**

```
KuCuba_Project/                       # repo root — Flutter package: eternal_guardian
├── pubspec.yaml                      # exists
├── lib/
│   ├── main.dart                     # exists — refactor per Phase 1
│   ├── app.dart
│   ├── config/                       # app_config.dart, api_endpoints.dart
│   ├── theme/                        # app_colors.dart, app_typography.dart, bank_islam_theme.dart
│   ├── models/                       # analysis_result.dart
│   ├── services/                     # api_service.dart, mock_api_service.dart
│   ├── providers/                    # analysis_provider.dart
│   ├── screens/                      # home_screen.dart (+ Phase 2 screens later)
│   └── widgets/                      # analog_meter, analysis_message_card, etc.
├── assets/images/                    # bank_islam_logo.png (copy from resources/)
├── backend/                          # create in Phase 1 — Dart Shelf
│   ├── bin/server.dart
│   ├── lib/handlers/, lib/services/, lib/models/
│   └── pubspec.yaml
├── android/app/src/main/kotlin/com/kucuba/eternal_guardian/
│   └── MainActivity.kt               # exists
├── resources/                        # exists — read-only brand reference
├── docs/AI/rule.md, docs/AI/SKILL.md, docs/Phase_*.md
├── docs/dev_logs/                    # per-branch dev logs (see README.md)
│   ├── README.md
│   ├── dev0/                       # git branch dev0 — backend (dev 1)
│   ├── dev1/                       # git branch dev1 — backend (dev 2)
│   └── dev2/                       # git branch dev2 — frontend
├── docs/test_logs/                 # test run write-ups
├── hackathon/
└── test/
```

### 1.3 Dependencies (`pubspec.yaml` — Flutter App)

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2          # State management
  dio: ^5.7.0               # HTTP client
  google_fonts: ^6.2.1      # Poppins only
  flutter_animate: ^4.5.2   # Micro-animations

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

### 1.4 Dependencies (`pubspec.yaml` — Backend)

```yaml
name: kucuba_backend
environment:
  sdk: ^3.6.0

dependencies:
  shelf: ^1.4.2
  shelf_router: ^1.1.4
  http: ^1.3.0
  dotenv: ^4.2.0           # .env for API keys
  google_generative_ai: ^0.4.6  # Gemini SDK
```

---

## 2. Backend Service (`backend/`)

### 2.1 Server Entry — `bin/server.dart`

- Initialize a `shelf` HTTP server on `0.0.0.0:8080`
- Mount router with single route: `POST /analyze`
- Load `.env` file for `GEMINI_API_KEY` and `SAFE_BROWSING_API_KEY`
- Add CORS middleware for Flutter dev

### 2.2 Analyze Handler — `handlers/analyze_handler.dart`

**Request:** `POST /analyze` with body `{"text_payload": "<string>"}`

**Processing Flow:**

```
1. Parse JSON body → extract text_payload
2. Call link_extractor.extractUrls(text_payload)
3. IF urls found:
   a. Call safe_browsing.checkUrls(urls)
   b. IF threat match → return {risk_score: 100, analysis_message: "Warning: ..."}
4. Call gemini_service.analyzeText(text_payload)
5. Parse Gemini JSON response → validate schema
6. Return {risk_score: <int>, analysis_message: "<string>"}
```

**Error handling:** Return `{risk_score: -1, analysis_message: "Analysis temporarily unavailable."}` on any failure.

### 2.3 Link Extractor — `services/link_extractor.dart`

```dart
// Regex pattern:
// (https?:\/\/|www\.)[^\s<>"{}|\\^`\[\]]+
// Returns List<String> of extracted URLs
```

### 2.4 Safe Browsing Client — `services/safe_browsing.dart`

- POST to `https://safebrowsing.googleapis.com/v4/threatMatches:find?key=API_KEY`
- Check against `MALWARE`, `SOCIAL_ENGINEERING`, `UNWANTED_SOFTWARE` threat types
- Returns `bool isThreat`

> [!NOTE]
> If no Safe Browsing API key is available, this step should gracefully skip and proceed to Gemini. A simple `if (apiKey.isEmpty) return false;` guard is sufficient.

### 2.5 Gemini Service — `services/gemini_service.dart`

- Use `google_generative_ai` Dart package
- **System Prompt** (Few-Shot, enforced JSON output):

```
You are an expert Malaysian cybersecurity analyst specializing in scam detection.
Analyze the following text message or conversation. Evaluate for:
- Urgency tactics and pressure language
- Financial requests (bank transfers, e-wallet top-ups, TAC/OTP sharing)
- Emotional manipulation (fear, greed, sympathy)
- Impersonation of authorities (PDRM, LHDN, Bank Negara, Pos Malaysia)
- Suspicious links or requests to install apps

EXAMPLES OF KNOWN MALAYSIAN SCAMS:
1. "Polis here. Your IC linked to money laundering case. Transfer RM5,000 to this acc to clear your name." → risk_score: 95
2. "Tahniah! You won RM10,000 Shopee voucher. Click link to claim: bit.ly/xy123" → risk_score: 88
3. "Hi, I'm from LHDN. You have unpaid taxes. Share your TAC number to verify." → risk_score: 92
4. "Saya agent Macau Scam task job. Setiap task RM50-RM300. Modal awal RM500." → risk_score: 90
5. "Your Maybank account will be frozen. Update details at maybank-secure-login.com" → risk_score: 85

EXAMPLES OF SAFE MESSAGES:
1. "Hey, are we still on for lunch tomorrow?" → risk_score: 3
2. "Your Grab order has arrived at the lobby." → risk_score: 5
3. "Meeting at 3pm in Room A confirmed. Bring the quarterly report." → risk_score: 2
4. "Happy Birthday! Wishing you all the best 🎂" → risk_score: 1
5. "Mak, I'll be home late tonight. Dinner without me." → risk_score: 2

RESPOND WITH ONLY VALID JSON IN THIS EXACT FORMAT:
{"risk_score": <integer 1-100>, "analysis_message": "<max 2 sentences explaining why>"}
```

- **Model:** `gemini-2.0-flash` (fast, cheap — ideal for hackathon)
- **Generation config:** `temperature: 0.1`, `responseMimeType: application/json`

---

## 3. Flutter App — Theme & Config

### 3.1 Color Palette — `theme/app_colors.dart`

| Token | Hex | Usage |
|---|---|---|
| `corporateRed` | `#ED2321` | Primary, buttons, AppBar |
| `background` | `#FFFFFF` | Scaffold background |
| `textPrimary` | `#1A1A1A` | Headings, body text |
| `textSecondary` | `#757575` | Subtitles, hints |
| `meterGreen` | `#2ECC71` | Risk score 1-30 |
| `meterYellow` | `#F1C40F` | Risk score 31-70 |
| `meterRed` | `#E74C3C` | Risk score 71-100 |
| `surfaceCard` | `#F8F9FA` | Card backgrounds |
| `divider` | `#E0E0E0` | Dividers |

### 3.2 Typography — `theme/app_typography.dart`

- **Font:** `Poppins` from Google Fonts (geometric sans-serif matching BIMB style)
- **Headline Large:** 28sp, Bold — used for "Scam Detector" title
- **Title Medium:** 18sp, SemiBold — section headers
- **Body Large:** 16sp, Regular — analysis message
- **Body Medium:** 14sp, Regular — input text
- **Label:** 12sp, Medium — meter labels

### 3.3 ThemeData — `theme/bank_islam_theme.dart`

```dart
ThemeData bankIslamTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.corporateRed,
    primary: AppColors.corporateRed,
    surface: AppColors.background,
    onSurface: AppColors.textPrimary,
  ),
  scaffoldBackgroundColor: AppColors.background,
  textTheme: appTextTheme(),
  appBarTheme: AppBarTheme(...),  // Corporate Red background, white text
  elevatedButtonTheme: ...,       // Rounded, corporateRed fill
  inputDecorationTheme: ...,      // Rounded border, grey hint
);
```

### 3.4 App Config — `config/app_config.dart`

```dart
class AppConfig {
  /// Toggle to true to use mock responses (no backend needed)
  static const bool useMockApi = true; // ← flip to false when backend is live

  /// Backend base URL
  static const String backendBaseUrl = 'http://10.0.2.2:8080'; // Android emulator → localhost

  /// Analyze endpoint
  static const String analyzeEndpoint = '/analyze';
}
```

> [!IMPORTANT]
> **Demo/Mock mode** is controlled by a single boolean `AppConfig.useMockApi`. When `true`, the app uses `MockApiService` which returns hardcoded responses with a simulated 1.5s delay. When the backend is ready, flip to `false` — zero code changes needed elsewhere.

---

## 4. Service Layer (Flutter)

### 4.1 Analysis Result Model — `models/analysis_result.dart`

```dart
class AnalysisResult {
  final int riskScore;        // 1-100
  final String analysisMessage;

  AnalysisResult({required this.riskScore, required this.analysisMessage});

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
    riskScore: json['risk_score'] as int,
    analysisMessage: json['analysis_message'] as String,
  );
}
```

### 4.2 API Service — `services/api_service.dart`

```dart
abstract class AnalysisApiService {
  Future<AnalysisResult> analyze(String textPayload);
}

class LiveApiService implements AnalysisApiService {
  final Dio _dio;
  LiveApiService() : _dio = Dio(BaseOptions(baseUrl: AppConfig.backendBaseUrl));

  @override
  Future<AnalysisResult> analyze(String textPayload) async {
    final response = await _dio.post(
      AppConfig.analyzeEndpoint,
      data: {'text_payload': textPayload},
    );
    return AnalysisResult.fromJson(response.data);
  }
}
```

### 4.3 Mock API Service — `services/mock_api_service.dart`

```dart
class MockApiService implements AnalysisApiService {
  @override
  Future<AnalysisResult> analyze(String textPayload) async {
    await Future.delayed(const Duration(milliseconds: 1500)); // Simulate latency

    final lowerText = textPayload.toLowerCase();

    // Simple keyword-based mock logic
    if (lowerText.contains('transfer') || lowerText.contains('tac') ||
        lowerText.contains('polis') || lowerText.contains('lhdn')) {
      return AnalysisResult(
        riskScore: 88,
        analysisMessage: 'This message contains hallmarks of a known Malaysian scam involving authority impersonation and financial requests.',
      );
    }

    if (lowerText.contains('http') || lowerText.contains('www') || lowerText.contains('click')) {
      return AnalysisResult(
        riskScore: 65,
        analysisMessage: 'This message contains a suspicious link. Exercise caution before clicking.',
      );
    }

    return AnalysisResult(
      riskScore: 8,
      analysisMessage: 'This message appears to be a normal, safe conversation.',
    );
  }
}
```

---

## 5. State Management — `providers/analysis_provider.dart`

```dart
enum AnalysisState { idle, loading, complete, error }

class AnalysisProvider extends ChangeNotifier {
  final AnalysisApiService _apiService;

  AnalysisState _state = AnalysisState.idle;
  AnalysisResult? _result;
  String? _errorMessage;

  AnalysisState get state => _state;
  AnalysisResult? get result => _result;
  String? get errorMessage => _errorMessage;

  AnalysisProvider(this._apiService);

  Future<void> analyze(String textPayload) async {
    _state = AnalysisState.loading;
    _result = null;
    _errorMessage = null;
    notifyListeners();

    try {
      _result = await _apiService.analyze(textPayload);
      _state = AnalysisState.complete;
    } catch (e) {
      _state = AnalysisState.error;
      _errorMessage = 'Could not analyze. Please try again.';
    }
    notifyListeners();
  }

  void reset() {
    _state = AnalysisState.idle;
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }
}
```

---

## 6. UI Widgets & Screen

### 6.1 Analog Meter — `widgets/analog_meter.dart`

**Implementation: `CustomPainter` on a `CustomPaint` widget**

```
Visual Structure:
         ╭─────────────╮
        ╱   ╱  │  ╲    ╲
       ╱   ╱   │   ╲    ╲
      ╱🟢 ╱ 🟡 │ 🟡 ╲ 🔴 ╲
     ╱   ╱     │     ╲    ╲
    ╱   ╱      │      ╲    ╲
   ╱   ╱       │       ╲    ╲
  ╱───╱────────┼────────╲───╱
        ↗ NEEDLE (animated)

  Below: "Risk Score: 73" label
```

**Key details:**
- **Canvas size:** ~280 x 160 (half-circle)
- **Arc:** 180° sweep from π to 0 (left to right)
- **Segments:** Three colored arcs:
  - Green (0°–54°): score 1-30
  - Yellow (54°–126°): score 31-70
  - Red (126°–180°): score 71-100
- **Needle:** A thin triangle drawn from center, rotated based on `risk_score` mapped to angle
- **Center dot:** Small filled circle at pivot point
- **Animation:** Use `AnimationController` + `Tween<double>(begin: 0, end: targetAngle)` with `CurvedAnimation(curve: Curves.easeOutBack)` for a satisfying overshoot effect
- **Duration:** 1200ms for needle animation
- **Score label:** Centered text below the arc showing the numeric score

### 6.2 Analysis Message Card — `widgets/analysis_message_card.dart`

- `Card` with rounded corners (16px radius)
- Icon row: shield icon colored by risk zone (green/yellow/red)
- `analysis_message` text in `bodyLarge` style
- Subtle fade-in animation using `flutter_animate`

### 6.3 Multi-line Text Input — `widgets/text_input_area.dart`

- `TextField` with `maxLines: 8`, `minLines: 4`
- Hint text: `"Paste a suspicious message or conversation here..."`
- Bank Islam themed border (rounded, grey outline, red focus border)
- Character counter optional

### 6.4 Analyze Button — `widgets/analyze_button.dart`

- `ElevatedButton` with Bank Islam Corporate Red (`#ED2321`)
- White text, bold, rounded corners (12px)
- **States:**
  - Enabled: Red background, "🔍 Analyze" text
  - Loading: Shows `CircularProgressIndicator` (white, small), text changes to "Analyzing..."
  - Disabled: Grey background when input is empty

### 6.5 Home Screen — `screens/home_screen.dart`

**Widget tree:**

```
Scaffold
├── AppBar
│   ├── Bank Islam Logo (leading, small)
│   └── Title: "Scam Detector"
│
└── SingleChildScrollView
    └── Padding (24px horizontal)
        └── Column
            ├── SizedBox(h: 16)
            ├── Text("Check any message for scams", subtitle style)
            ├── SizedBox(h: 24)
            │
            ├── TextInputArea          ← FR 1.1
            ├── SizedBox(h: 16)
            ├── AnalyzeButton          ← FR 1.2
            ├── SizedBox(h: 32)
            │
            ├── // Conditional rendering based on AnalysisState:
            │   ├── idle → SizedBox.shrink() (meter hidden)
            │   ├── loading → SkeletonMeterPlaceholder  ← FR 1.3
            │   ├── complete →
            │   │   ├── AnalogMeter(riskScore: result.riskScore)  ← FR 1.4
            │   │   └── AnalysisMessageCard(message: result.analysisMessage)  ← FR 1.5
            │   └── error → ErrorBanner(message)
            │
            └── SizedBox(h: 40)  // Bottom padding
```

**Async UI States (FR 1.3):**
- **Idle:** Meter section not visible, input area focused
- **Loading:** Skeleton/shimmer placeholder in meter area, button shows spinner, button disabled
- **Complete:** Meter animates in, message card fades in
- **Error:** Red banner with retry option

---

## 7. App Entry Point — `main.dart`

```dart
void main() {
  final apiService = AppConfig.useMockApi
      ? MockApiService()
      : LiveApiService();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AnalysisProvider(apiService),
      child: const KuCubaApp(),
    ),
  );
}
```

---

## 8. File Checklist & Build Order

| # | File | Est. Time | Priority |
|---|---|---|---|
| 1 | Extend existing `eternal_guardian` + `pubspec.yaml` dependencies | 15 min | 🔴 Critical |
| 2 | `theme/app_colors.dart` | 10 min | 🔴 Critical |
| 3 | `theme/app_typography.dart` | 10 min | 🔴 Critical |
| 4 | `theme/bank_islam_theme.dart` | 20 min | 🔴 Critical |
| 5 | `config/app_config.dart` | 5 min | 🔴 Critical |
| 6 | `models/analysis_result.dart` | 5 min | 🔴 Critical |
| 7 | `services/mock_api_service.dart` | 15 min | 🔴 Critical |
| 8 | `services/api_service.dart` | 15 min | 🟡 High |
| 9 | `providers/analysis_provider.dart` | 20 min | 🔴 Critical |
| 10 | `widgets/analog_meter.dart` | 60 min | 🔴 Critical |
| 11 | `widgets/text_input_area.dart` | 15 min | 🔴 Critical |
| 12 | `widgets/analyze_button.dart` | 15 min | 🔴 Critical |
| 13 | `widgets/analysis_message_card.dart` | 15 min | 🟡 High |
| 14 | `screens/home_screen.dart` | 30 min | 🔴 Critical |
| 15 | `main.dart` + `app.dart` | 10 min | 🔴 Critical |
| 16 | `backend/` — all files | 90 min | 🟡 High |
| 17 | Integration test & polish | 30 min | 🟡 High |
| **Total** | | **~6.5 hours** | |

---

## 9. Verification Plan

### Automated
- `flutter analyze` — zero errors
- `flutter build apk --debug` — successful build
- Backend: `dart run backend/bin/server.dart` — starts on port 8080
- `curl -X POST http://localhost:8080/analyze -d '{"text_payload":"test"}'` — valid JSON response

### Manual (On Device / Emulator)
- [ ] App launches with Bank Islam branding (red AppBar, logo, Poppins font)
- [ ] Multi-line text input accepts pasted conversations
- [ ] Analyze button triggers loading state (spinner, disabled)
- [ ] Mock mode returns risk scores and meter animates correctly
- [ ] Meter zones display correct colors (green ≤30, yellow 31-70, red 71-100)
- [ ] Needle animation is smooth with easeOutBack curve
- [ ] Analysis message card appears below meter with fade-in
- [ ] Empty input disables the Analyze button
- [ ] Error state shows retry banner

---

## 10. Open Questions

> [!IMPORTANT]
> **Q1:** For the hackathon demo, should the backend run **locally on your laptop** (the phone calls your laptop's IP on the same WiFi), or do you want to deploy to a free cloud service like **Railway / Render / Cloud Run**?

> [!NOTE]
> **Q2:** Should the app have a **splash screen** with the Bank Islam logo, or is jumping straight to the home screen acceptable for the hackathon?
