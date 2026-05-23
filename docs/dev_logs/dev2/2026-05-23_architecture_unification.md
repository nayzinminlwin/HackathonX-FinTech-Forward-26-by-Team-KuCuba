# Architecture unification (post dev2 merge)

**Date:** 2026-05-23  
**Branch:** main / integration

## Summary

Aligned Flutter client with `docs/Phase_1_Core_App_Module.md`, SRD, and `docs/AI/rule.md` after dev2 UI merge.

## Changes

- Restored planned folder layout: `lib/config/`, `lib/app.dart`, `lib/services/api_service.dart`, `lib/services/mock_api_service.dart`, `lib/theme/bank_islam_theme.dart`, Phase 1 widgets.
- Single `AnalysisProvider` + `AnalysisApiService` (Dio live / mock) wired in `main.dart` via `AppConfig.useMockApi`.
- Phase 1 sandbox `HomeScreen`: multi-line input, analyze button, skeleton loading, meter hidden until first result, error banner with retry.
- Phase 2 `OverlayScreen` reuses same provider and widgets; no `showModalBottomSheet` demo.
- Removed dev2-only files: `analysis_service.dart`, `scam_demo_models.dart`, `scam_widgets.dart`, `risk_badge.dart`, `app_theme.dart`.
- `risk_utils` colors aligned to `AppColors.meter*`.
- Added `flutter_animate` on `AnalysisMessageCard`.

## Config

Set `AppConfig.useMockApi = false` when testing against `backend/` on port 8080.
