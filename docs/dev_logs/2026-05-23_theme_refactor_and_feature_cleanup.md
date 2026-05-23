# 2026-05-23: Theme Refactor to Bank Islam Brand + Feature Cleanup

**Authors:** GitHub Copilot  
**Goal:** Align Flutter app visual identity with Bank Islam Malaysia resource theme; remove history/recent scans feature; establish modular app architecture.

---

## Problem Statement

1. **Theme Mismatch:** Original emerald green theme did not align with the Bank Islam corporate red brand (`#ED2321`) from `/resources/bank_islam_theme.json`.
2. **Typography Inconsistency:** App used Plus Jakarta Sans, but resource specified Geometric Sans-Serif (Poppins for Flutter).
3. **Feature Creep:** Home screen listed Recent Scans with a History view—neither feature had backend persistence or meaningful value for MVP.
4. **Monolithic Code:** All UI, state, and styling was in a single `lib/main.dart`; needed modular structure for testability and team collaboration.

---

## Changes Made

### 1. App Architecture Refactoring

**Files Created/Refactored:**

| File | Purpose |
|------|---------|
| `lib/main.dart` | **Clean entrypoint** — imports `EternalGuardianApp` from `lib/app/app.dart` |
| `lib/app/app.dart` | **App shell** — MaterialApp config, theme application, home route |
| `lib/app/theme/app_theme.dart` | **Centralized theme tokens** — colors, typography, component styles |
| `lib/features/scam_detector/screens/scam_detector_page.dart` | **Main screen** — Home, Scan, Result flows (History removed) |
| `lib/features/scam_detector/services/analysis_service.dart` | **Backend integration** — HTTP POST to `/analyze`, fallback heuristics |
| `lib/features/scam_detector/models/analysis_result.dart` | **Data class** — risk_score, analysis_message, isFallback flag |
| `lib/features/scam_detector/models/scam_demo_models.dart` | **UI demo data** — QuickScanExample list (RecentScan removed) |
| `lib/features/scam_detector/widgets/analog_meter.dart` | **Risk visualization** — animated gauge widget |
| `lib/features/scam_detector/widgets/risk_badge.dart` | **Status label** — SAFE/CAUTION/DANGER badge |
| `lib/features/scam_detector/widgets/risk_utils.dart` | **Helper functions** — riskColor(), riskIcon(), riskLabel() |
| `lib/features/scam_detector/widgets/scam_widgets.dart` | **Reusable components** — GlassStatCard, SpinningLoader, BottomNavBar |

**Before:** 1,200+ lines in `lib/main.dart`  
**After:** 11 focused files, ~1,300 total lines (+ clearer intent per file)

---

### 2. Theme Migration: Emerald → Corporate Red

#### Color Palette

| Token | Old Value | New Value | Source |
|-------|-----------|-----------|--------|
| `primaryBrand` | `#059669` (emerald) | `#ED2321` (red) | `bank_islam_theme.json` |
| `primaryBrandDeep` | `#047857` | `#C91D1B` | Derived darkening |
| `textPrimary` | `#111827` | `#1A1A1A` | Resource spec |
| `textSecondary` | `#6B7280` | `#757575` | Resource spec |
| `appBackground` | `#F9FAFB` | `#FFFFFF` | Resource: "Clean white" |
| `border` | `#E5E7EB` | `#E0E0E0` | Neutral grey |

**Backward Compatibility:** Added aliases in `AppTheme`:
```dart
static const Color emerald = primaryBrand;  // Keeps old references functional
static const Color emeraldDeep = primaryBrandDeep;
```

#### Typography

| Aspect | Before | After | Rationale |
|--------|--------|-------|-----------|
| Font Family | Plus Jakarta Sans | Poppins | Resource: "Geometric Sans-Serif" |
| Strategy | `GoogleFonts.plusJakartaSansTextTheme()` | `GoogleFonts.poppinsTextTheme()` | Cleaner, geometric forms |
| Font weights | Consistent w/ Plus | Same hierarchy (700, 500) | Poppins supports same weights |

**Implementation:** Updated in `lib/app/theme/app_theme.dart`:
```dart
final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
  headlineLarge: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.w700, color: textPrimary),
  titleLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
  // ... etc.
);
```

**UI Updates:** All hardcoded color references swapped:
- Action buttons: `Color(0xFF10B981)` → `AppTheme.primaryBrand`
- Accent icons: `Color(0xFF059669)` → `AppTheme.primaryBrand`
- Focus states: Focus border now uses `primaryBrand` instead of green
- Fallback message bg: yellow → uses primary for consistency

---

### 3. Feature Removal: History & Recent Scans

#### Removed Elements

1. **Enum variant:** `AppScreen.history` removed from screen navigation
2. **UI Screens:** `_buildHistoryScreen()` method deleted (~150 lines)
3. **Models:** `RecentScan` class and `recentScans` constant removed from demo data
4. **Bottom Nav:** History tab icon removed (now only Home + Scan)
5. **Home Screen:** "Recent Scans" section and "View All" button removed

#### Why?

- **No persistence layer:** Without local DB or backend storage, history was mock data.
- **MVP scope:** Scan + Result flows are sufficient for hackathon demo.
- **UI clarity:** Fewer tabs = faster navigation, lower cognitive load.

#### Affected Files

- `lib/features/scam_detector/screens/scam_detector_page.dart` (-200 lines)
- `lib/features/scam_detector/widgets/scam_widgets.dart` (-80 lines)
- `lib/features/scam_detector/models/scam_demo_models.dart` (-20 lines)

---

### 4. Backend Integration

#### API Contract

**Endpoint:** `POST /analyze`

**Request Body:**
```json
{
  "text_payload": "string to analyze"
}
```

**Response Body:**
```json
{
  "risk_score": 0-100,
  "analysis_message": "explanation string"
}
```

#### Implementation (`lib/features/scam_detector/services/analysis_service.dart`)

- **Live Mode:** POST to backend (configurable base URL via `--dart-define=API_BASE_URL=...`)
- **Fallback Logic:**
  - Network timeout (12s) → local heuristic analysis
  - Non-200 status code → local heuristic
  - Malformed JSON → local heuristic
  - Sentinel risk score `-1` → local heuristic
  - Any exception → local heuristic
- **Local Heuristic:** Pattern matching on keywords (bank, urgent, prize, URL indicators)
- **Fallback Flag:** Result marked with `isFallback: true` to show warning banner in UI

#### Android Emulator Setup

Default API base URL is `http://10.0.2.2:8080` (Android emulator bridge to host).

Override for physical device:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.X:8080
```

---

## Files Modified

### Core App Files

| File | Lines ± | Changes |
|------|---------|---------|
| `lib/main.dart` | 2 | Clean entrypoint (was 1200+) |
| `lib/app/app.dart` | new | App shell with EternalGuardianApp class |
| `lib/app/theme/app_theme.dart` | new | Bank Islam theme tokens, Poppins typography |
| `pubspec.yaml` | +2 | Added `http: ^1.2.2`, `google_fonts: ^6.3.0` |

### Feature Screens & Services

| File | Lines ± | Changes |
|------|---------|---------|
| `lib/features/scam_detector/screens/scam_detector_page.dart` | new (~700) | Home/Scan/Result flows; removed History |
| `lib/features/scam_detector/services/analysis_service.dart` | new (~150) | Backend POST + fallback heuristics |
| `lib/features/scam_detector/models/analysis_result.dart` | new (~30) | AnalysisResult data class |
| `lib/features/scam_detector/models/scam_demo_models.dart` | new (~25) | QuickScanExample (RecentScan removed) |

### Widgets & Styling

| File | Lines ± | Changes |
|------|---------|---------|
| `lib/features/scam_detector/widgets/analog_meter.dart` | new (~200) | Risk gauge animation |
| `lib/features/scam_detector/widgets/risk_badge.dart` | new (~50) | SAFE/CAUTION/DANGER label |
| `lib/features/scam_detector/widgets/risk_utils.dart` | new (~50) | Color/icon helper functions |
| `lib/features/scam_detector/widgets/scam_widgets.dart` | new (~350) | GlassStatCard, BottomNav, Loader, BottomSheet |

### Tests

| File | Changes |
|------|---------|
| `test/widget_test.dart` | Updated to test EternalGuardianApp; removed MyApp counter test |

---

## Build & Verification

### Dependencies Installed

```bash
flutter pub get
# google_fonts 6.3.3
# http ^1.2.2
# (others from existing pubspec)
```

### Analyzer Validation

```bash
flutter analyze
# Result: ✓ No errors in lib/
# Info: 40 lint warnings in backend/ (pre-existing, acceptable)
```

### Formatting

```bash
dart format lib/
# All 11 Dart files formatted to style guide
```

### No Build Errors

All compile-time errors fixed:
- `main.dart` parser errors (corruption from earlier draft) ✓ resolved
- `analog_meter.dart` num→double type mismatch ✓ resolved
- `widget_test.dart` MyApp reference ✓ updated to EternalGuardianApp

---

## Backward-Compatibility Notes

1. **Color aliases:** Code using `AppTheme.emerald` still works (now points to red).
2. **Typography:** Poppins renders similarly to Plus Jakarta Sans; no layout breakage.
3. **Navigation:** Removed history tab does not break existing imports (navigation enum cleaned).
4. **Demo data:** QuickScanExample unchanged; RecentScan only used in removed screens.

---

## Next Steps (Future Phases)

- [ ] **Persistence:** Add Hive/sqflite for local scan history if scope expands.
- [ ] **Real API Testing:** Test against live backend server once deployed.
- [ ] **Internationalization:** Extract hardcoded strings to `lib/l10n/` for multi-language support.
- [ ] **Accessibility:** Add semantic labels and test with screen readers.
- [ ] **Error Analytics:** Log fallback instances for monitoring API health.

---

## How to Run

```bash
# Standard debug build
flutter run

# With custom API endpoint
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8080

# With release optimizations
flutter run --release
```

---

**Status:** ✓ Complete — Ready for Phase 2 (Share Sheet Overlay)
