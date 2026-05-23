# Bank Islam Theme Migration — Quick Reference

**Date:** May 23, 2026  
**Status:** ✓ Complete

---

## Color Palette Swap

### Before (Emerald Green)
```
Primary:        #059669 (emerald)
Primary Dark:   #047857 (emerald dark)
Accent:         #10B981 (green)
```

### After (Corporate Red)
```
Primary:        #ED2321 (Bank Islam red)
Primary Dark:   #C91D1B (derived dark)
Accent:         #ED2321 (same as primary)
```

**All occurrences updated:**
- FilledButton background colors
- AnalogMeter gauge colors
- Icon colors in headers
- Focus/active states in form inputs
- Border left accent in analysis boxes
- Bottom nav active state

---

## Typography Changes

| Component | Before | After |
|-----------|--------|-------|
| Font | Plus Jakarta Sans | Poppins |
| Source | google_fonts | google_fonts |
| Rationale | Rounded sans | Geometric sans (per Bank Islam brand) |

**Implementation File:** `lib/app/theme/app_theme.dart` (see `lightTheme` getter)

---

## Removed Features

| Feature | Where | Why |
|---------|-------|-----|
| History Screen | `_buildHistoryScreen()` | No persistence; mock data only |
| Recent Scans Section | Home screen, ListTile widget | Removed with history |
| History Tab | BottomNavBar | No destination to navigate to |
| RecentScan Model | `scam_demo_models.dart` | No longer used |

**Lines of Code Removed:** ~250

---

## New File Structure

```
lib/
├── main.dart                  # Simple entrypoint
├── app/
│   ├── app.dart              # EternalGuardianApp (MaterialApp + theme)
│   └── theme/
│       └── app_theme.dart    # Color tokens, typography, component styles
└── features/
    └── scam_detector/
        ├── screens/
        │   └── scam_detector_page.dart       # Home, Scan, Result screens
        ├── services/
        │   └── analysis_service.dart         # Backend API + fallback
        ├── models/
        │   ├── analysis_result.dart          # Data class
        │   └── scam_demo_models.dart         # Demo data (QuickScanExample)
        └── widgets/
            ├── analog_meter.dart             # Risk gauge widget
            ├── risk_badge.dart               # SAFE/CAUTION/DANGER label
            ├── risk_utils.dart               # Helper functions
            └── scam_widgets.dart             # Reusable components
```

**Total Files Created:** 11  
**Total Lines of Code:** ~1,300 (up from 1,200 monolithic main.dart)

---

## Backend Integration Summary

**Endpoint:** `POST /analyze`

**Fallback:** If network unavailable or response malformed, uses local keyword/pattern analysis and marks result as `isFallback: true` (shows warning banner in UI).

**Config:** API base URL set to `http://10.0.2.2:8080` by default (Android emulator). Override with:
```bash
flutter run --dart-define=API_BASE_URL=http://your.host:8080
```

---

## Verification Checklist

- [x] Theme colors migrated to Bank Islam red
- [x] Typography switched to Poppins
- [x] History/Recent Scans removed
- [x] All files formatted with `dart format`
- [x] `flutter analyze` shows no errors in lib/
- [x] App compiles without warnings
- [x] Bottom nav shows only Home + Scan (no History)
- [x] Home screen no longer displays recent scans list
- [x] All buttons and accents use brand red

---

## Files to Review

1. **Theme:** `lib/app/theme/app_theme.dart`
2. **Main Screen:** `lib/features/scam_detector/screens/scam_detector_page.dart`
3. **Widgets:** `lib/features/scam_detector/widgets/scam_widgets.dart`
4. **Colors:** `lib/features/scam_detector/widgets/risk_utils.dart` (risk level colors unchanged — they are distinct from brand red)

---

## Notes for Team

- The `emerald` and `emeraldDeep` color aliases still exist in `AppTheme` and now point to `primaryBrand` / `primaryBrandDeep` for backward compatibility.
- **Risk level colors** (green/amber/red for safety indicators) are distinct from the **brand primary color** (red). This is intentional—the gauge and badge use semantic colors for risk communication.
- All hardcoded color literals (`Color(0xFF...)`) in screens/widgets have been replaced with theme tokens for consistency.

---

**Next Phase:** Phase 2 — Share Sheet Overlay refinements
