# Flutter App Architecture & UI Design

> **Updated:** May 23, 2026  
> **Status:** Superseded for implementation layout  
> **Version:** 1.0

> **Note:** The canonical architecture is `docs/Phase_1_Core_App_Module.md` and `docs/Phase_2_OS_Share_Sheet_Overlay.md`. This file described the dev2 multi-screen MVP; the repo now uses the Phase 1 folder layout (`lib/config/`, `lib/app.dart`, Provider + Dio, single sandbox `HomeScreen`). See `docs/dev_logs/dev2/2026-05-23_architecture_unification.md`.

---

## 1. Overview

The **Eternal Guardian Scam Detector** is a Flutter mobile app that analyzes messages and links for phishing/scam indicators. Users paste suspicious content, and the app returns a risk score (0–100) with analysis and recommendations.

### Key Features (Current MVP)

✅ **Home Screen**
- App branding (Bank Islam visual identity)
- Statistics display (scans protected, threats blocked)
- Quick Scan button
- Pre-built example scams for demo/testing
- WhatsApp Share Sheet integration demo

✅ **Scan Screen**
- Large text input field for message/link
- "Analyze Now" button
- "Paste from Clipboard" quick action

✅ **Result Screen**
- Animated analog meter (0–100 scale)
- Risk badge (SAFE/CAUTION/DANGER)
- Analysis explanation text
- "Report to Authorities" button (when risk > 30)
- "Scan Another Message" button to loop back
- Fallback warning when backend unavailable

---

## 2. Visual Identity

### Colors (Bank Islam Theme)

All colors sourced from `/resources/bank_islam_theme.json` and enforced in `lib/app/theme/app_theme.dart`.

| Role | Hex | RGB | Usage |
|------|-----|-----|-------|
| **Primary Brand** | `#ED2321` | 237, 35, 33 | Buttons, icons, accents, borders |
| **Primary Dark** | `#C91D1B` | 201, 29, 27 | Hover/focus states, gradients |
| **Text Primary** | `#1A1A1A` | 26, 26, 26 | Body text, headers |
| **Text Secondary** | `#757575` | 117, 117, 117 | Labels, metadata, descriptions |
| **Background** | `#FFFFFF` | 255, 255, 255 | Main app background |
| **Surface** | `#FFFFFF` | 255, 255, 255 | Cards, containers |
| **Border** | `#E0E0E0` | 224, 224, 224 | Dividers, input borders |

### Typography

| Element | Font | Size | Weight | Color |
|---------|------|------|--------|-------|
| Display | Poppins | 36px | 700 | Text Primary |
| Headline | Poppins | 30px | 700 | Text Primary |
| Title | Poppins | 20px | 700 | Text Primary |
| Body Large | Poppins | 16px | 500 | Text Primary |
| Body Medium | Poppins | 14px | 400 | Text Secondary |
| Label | Poppins | 16px | 700 | Contextual |

**Font Strategy:** Poppins is a geometric sans-serif with sharp apexes matching Bank Islam's modern aesthetic. Integrated via `google_fonts` package.

### Risk Score Visualization

The analog meter animates from 0 to the calculated risk score using a smooth `easeOut` curve (1.4s duration).

#### Color Mapping

| Risk Range | Color | Icon | Label |
|------------|-------|------|-------|
| 0–30 | Green `#059669` | ✓ check_circle | SAFE |
| 31–70 | Amber `#F59E0B` | ⚠ warning_amber | CAUTION |
| 71–100 | Red `#DC2626` | ✗ cancel | DANGER |

*(Note: These are risk-level colors; primary brand red `#ED2321` is used for actions/buttons.)*

---

## 3. App Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        App Entry                              │
│  lib/main.dart → runApp(EternalGuardianApp())                             │
└────────────────────────┬─────────────────────────────────────┘
                         │
         ┌───────────────▼───────────────┐
         │   EternalGuardianApp (lib/app/app.dart)   │
         │                               │
         │  - MaterialApp config         │
         │  - AppTheme.lightTheme        │
         │  - Home: ScamDetectorPage     │
         │  - Routes (future)            │
         └───────────────┬───────────────┘
                         │
         ┌───────────────▼──────────────────────────────────┐
         │  ScamDetectorPage (Stateful)                      │
         │  lib/features/scam_detector/screens/             │
         │                                                  │
         │  State:                                          │
         │  - _textController (TextField input)             │
         │  - _analysisService (backend/fallback)           │
         │  - _currentScreen (Home|Scan|Result)             │
         │  - _isLoading (analysis in progress)             │
         │  - _result (AnalysisResult?)                     │
         │                                                  │
         │  Methods:                                        │
         │  - _analyzeText() → calls service                │
         │  - _openBottomSheetDemo() → share integration    │
         │  - _pasteFromClipboard()                         │
         │                                                  │
         │  Build Screens:                                  │
         │  - _buildHomeScreen()                            │
         │  - _buildScanScreen()                            │
         │  - _buildResultScreen()                          │
         └───────────────┬──────────────────────────────────┘
                         │
     ┌───────────────────┼───────────────────┐
     │                   │                   │
     ▼                   ▼                   ▼
[Home]              [Scan]              [Result]
- Header            - Text input        - Meter
- Stats cards       - Analyze btn       - Badge
- Quick Scan        - Paste btn         - Analysis box
- Examples                              - Report btn
- Share demo btn                        - Scan Again btn
- Bottom nav
```

### Service Layer (`lib/features/scam_detector/services/`)

**AnalysisService**

```dart
class AnalysisService {
  // Live API call with fallback
  Future<AnalysisResult> analyzeText(String text) async {
    try {
      // POST to backend /analyze endpoint
      // Timeout: 12 seconds
      // On success: return AnalysisResult(isFallback: false)
    } on SocketException, TimeoutException, FormatException {
      // Network or parse error
      // Return local heuristic analysis (isFallback: true)
    }
  }

  // Local pattern-based analysis (no network)
  AnalysisResult _analyzeLocalHeuristic(String text) {
    // Pattern detection: keywords, URL patterns, urgency markers
    // Returns risk 0–100 based on heuristic score
  }

  // Demo data for bottom sheet preview
  AnalysisResult previewBottomSheetResult() { ... }
}
```

### Model Layer (`lib/features/scam_detector/models/`)

**AnalysisResult**
```dart
class AnalysisResult {
  final int riskScore;          // 0–100
  final String analysisMessage; // Explanation
  final bool isFallback;        // true if from local heuristic
}
```

**QuickScanExample** (demo data only)
```dart
class QuickScanExample {
  final String text;      // Full message to analyze
  final String preview;   // Label for UI button
}
```

---

## 4. Screen Flows

### Home Screen

**Layout:**
1. **Header** (Gradient: red brand → dark red)
   - App icon (shield)
   - Title "Eternal Guardian" + subtitle "Scam Detector"
   - Settings button (placeholder)
   - Glass stats cards (127 scans protected, 23 threats blocked)

2. **Content (Scrollable)**
   - "Quick Scan" button (large, prominent)
   - "Try Quick Examples" section with 3 pre-built scams
   - "Share Sheet Demo" section (WhatsApp integration preview)

3. **Bottom Nav**
   - Home (icon: shield, active state shows brand red)
   - Scan (icon: scanner)
   - *(History tab removed)*

### Scan Screen

**Layout:**
1. **Header** (White background, simple)
   - Back button → returns to Home
   - Title "Scan Message"
   - Subtitle "Paste suspicious text or link to analyze"

2. **Content**
   - Large multiline TextField
   - Placeholder: "Paste message here..." + example text
   - "Analyze Now" button (disabled if empty)
   - "Paste from Clipboard" tonal button

3. **Bottom Nav** (Home + Scan tabs visible)

### Result Screen

**Layout:**
1. **Header** (White background, simple)
   - Home button → returns to Home (clears text)
   - Title "Scan Result"

2. **Content (Scrollable)**
   - **Loading State:**
     - Animated spinner
     - "Analyzing..." + "Checking 10,000+ known scams"

   - **Success State:**
     - AnalogMeter widget (animated needle)
     - RiskBadge (color + label: SAFE/CAUTION/DANGER)
     - *(Optional)* Fallback warning banner (if `isFallback: true`)
     - Analysis box (white background, left border in brand red)
       - Icon + "Analysis" label
       - Message text
     - "Report to Authorities" button (appears if risk > 30)
     - "Scan Another Message" button (clears input, returns to Scan)

3. **Bottom Nav** (Home + Scan tabs visible)

---

## 5. Widget Library

### Reusable Components (`lib/features/scam_detector/widgets/`)

| Widget | File | Props | Purpose |
|--------|------|-------|---------|
| `AnalogMeter` | `analog_meter.dart` | `riskScore`, `size` | Animated risk gauge |
| `RiskBadge` | `risk_badge.dart` | `riskScore` | Status label (SAFE/CAUTION/DANGER) |
| `GlassStatCard` | `scam_widgets.dart` | `value`, `label` | Frosted glass stat display |
| `SpinningLoader` | `scam_widgets.dart` | `size` | Animated circular progress |
| `BottomNavBar` | `scam_widgets.dart` | `selectedIndex`, `onSelect` | Custom bottom navigation |
| `BottomSheetOverlayDemo` | `scam_widgets.dart` | `result` | WhatsApp share sheet preview |

### Helper Functions (`lib/features/scam_detector/widgets/risk_utils.dart`)

```dart
Color riskColor(int risk)           // Maps risk to color
Color riskTint(int risk)            // Light background tint
Color riskShade(int risk)           // Dark variant
IconData riskIcon(int risk)         // Maps risk to icon
String riskLabel(int risk)          // Maps risk to label text
```

---

## 6. State Management

**Current Approach:** Simple StatefulWidget with `setState()`.

**Rationale:**
- MVP scope (single screen with 3 sub-views)
- No global state sharing needed yet
- Easy for hackathon team to understand

**Future Consideration:** If multiple screens or complex state emerges, migrate to:
- Provider package (`lib/providers/analysis_provider.dart`)
- Riverpod
- GetX

---

## 7. Backend Integration

### API Endpoint

**URL:** `POST {API_BASE_URL}/analyze`

**Default:** `http://10.0.2.2:8080` (Android emulator)  
**Override:** `flutter run --dart-define=API_BASE_URL=http://your.host:8080`

### Request/Response

```dart
// Request
{
  "text_payload": "suspicious message or link"
}

// Response (200 OK)
{
  "risk_score": 45,
  "analysis_message": "Detected potential phishing attempt: message uses urgency tactics and requests personal action."
}

// Error responses: timeout, non-200, or malformed JSON
// → Fallback to local heuristic analysis
```

### Fallback Logic

If backend is unreachable, returns local-only analysis:

```dart
AnalysisResult _analyzeLocalHeuristic(String text) {
  int riskScore = 0;
  
  // Pattern detection
  if (text.contains(RegExp(r'bank|verify|account|urgent', caseSensitive: false))) {
    riskScore += 20;
  }
  if (text.contains(RegExp(r'http|\.xyz|fake-link', caseSensitive: false))) {
    riskScore += 30;
  }
  if (text.contains(RegExp(r'congratulations|won|prize|claim', caseSensitive: false))) {
    riskScore += 25;
  }
  
  return AnalysisResult(
    riskScore: riskScore.clamp(0, 100),
    analysisMessage: 'Local analysis only (backend unavailable)',
    isFallback: true,
  );
}
```

The UI shows a warning banner when `isFallback: true`.

---

## 8. Theming System

### Theme Configuration (`lib/app/theme/app_theme.dart`)

```dart
class AppTheme {
  static const Color primaryBrand = Color(0xFFED2321);
  static const Color primaryBrandDeep = Color(0xFFC91D1B);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color appBackground = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE0E0E0);

  // Poppins typography
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: appBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBrand,
        brightness: Brightness.light,
      ).copyWith(
        primary: primaryBrand,
        onPrimary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
    );

    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme)
        .copyWith(
          displaySmall: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w700, color: textPrimary),
          headlineLarge: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.w700, color: textPrimary),
          titleLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
          bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
          bodyMedium: GoogleFonts.poppins(fontSize: 14, color: textSecondary),
          labelLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
        );

    return base.copyWith(
      textTheme: textTheme,
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primaryBrand, width: 2),
        ),
      ),
    );
  }
}
```

### Usage

```dart
MaterialApp(
  theme: AppTheme.lightTheme,
  home: const ScamDetectorPage(),
)
```

---

## 9. Responsive Design

**Breakpoints:**
- Mobile: < 600dp (primary target)
- Tablet: ≥ 600dp (not currently optimized; safe mode applies)

**Strategy:**
- Single-column layouts (Mobile First)
- Full-width buttons and inputs
- Scrollable content areas
- `SafeArea` for notch/status bar safety

---

## 10. Accessibility

**Current Coverage:**
- High contrast text (text primary `#1A1A1A` on white bg)
- Icon labels in bottom nav
- Semantic button labels

**Future Work:**
- Semantic widgets for screen readers
- Adjustable text size
- Color-blind mode testing

---

## 11. Testing

### Unit Tests (`test/widget_test.dart`)

```dart
testWidgets('Scam detector home renders', (WidgetTester tester) async {
  await tester.pumpWidget(const EternalGuardianApp());
  await tester.pumpAndSettle();

  expect(find.text('Eternal Guardian'), findsOneWidget);
  expect(find.text('Quick Scan'), findsOneWidget);
});
```

### Manual Testing Checklist

- [ ] Home screen loads with branding, stats, examples
- [ ] Tap Quick Scan → navigates to Scan screen
- [ ] Paste from Clipboard button works (copy text first)
- [ ] Analyze Now button disabled when input empty
- [ ] Analysis loads with spinner → risk meter animates
- [ ] Risk badge color changes (green/amber/red)
- [ ] Report button appears for risk > 30
- [ ] Scan Another Message → clears input, returns to Scan
- [ ] Bottom nav tabs selectable
- [ ] Share Sheet demo loads correctly

---

## 12. Performance Notes

- **Meter Animation:** 1.4s easeOut curve (smooth, not laggy)
- **Network Timeout:** 12 seconds (generous for 3G networks)
- **Demo Data:** 3 QuickScanExample items (instant tap response)
- **Image Assets:** None in MVP (uses system icons + vectors)

---

## 13. Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.3.0          # Poppins typography
  http: ^1.2.2                  # Backend API calls
  
dev_dependencies:
  flutter_test:
    sdk: flutter
```

---

**Last Updated:** May 23, 2026  
**Next Review:** Phase 2 (Share Sheet Overlay)
