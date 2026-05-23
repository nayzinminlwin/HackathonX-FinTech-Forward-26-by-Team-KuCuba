# Phase 1 Backend — Sector 4: HTTP → Dio Migration

**Date:** 2026-05-23 14:10  
**Branch:** `dev0`  
**Scope:** Replace `package:http` with `package:dio` across all backend HTTP calls  
**Prerequisite:** Sectors 1–3 verified (full pipeline operational)  
**Status:** ✅ Complete

---

## Goal

Standardize the backend's outgoing HTTP client from `package:http` to `package:dio` (`^5.7.0`), aligning with `rule.md` §2.1 which mandates Dio for all HTTP calls. This eliminates the `http` dependency entirely from the project.

---

## Files Changed

### [MODIFIED] `backend/pubspec.yaml`
- Replaced `http: ^1.3.0` with `dio: ^5.7.0`

### [MODIFIED] `backend/lib/services/safe_browsing.dart`
- Replaced `import 'package:http/http.dart' as http;` with `import 'package:dio/dio.dart';`
- Removed now-unused `import 'dart:convert';` (Dio handles JSON serialization internally)
- Created a `Dio` instance in the constructor with `connectTimeout` and `receiveTimeout` (10s each)
- Replaced `http.post(uri, headers, body: jsonEncode(...))` with `_dio.post<Map<String, dynamic>>(url, data: ..., options: Options(...))`
- Response body access changed from `jsonDecode(response.body)` to `response.data` (Dio auto-parses JSON)
- Added specific `DioException` catch block for network/timeout errors alongside generic catch
- All behavior preserved: fail-open, empty-key guard, threat detection, logging

### [MODIFIED] `backend/bin/run_tests.dart`
- Replaced `import 'package:http/http.dart' as http;` with `import 'package:dio/dio.dart';`
- Replaced `http.Client()` with `Dio(BaseOptions(baseUrl: ..., validateStatus: (_) => true))`
- Using `validateStatus: (_) => true` so Dio doesn't throw on non-2xx (test runner handles status codes itself)
- Response parsing updated for Dio's auto-decoded `response.data`
- `client.close()` → `dio.close()`
- All 20 test cases and markdown report generation preserved identically

---

## Verification

### `dart analyze` — zero issues ✅

```
Analyzing backend...
No issues found!
```

### `dart pub get` — resolved cleanly ✅

No dependency conflicts. Dio `^5.7.0` resolved alongside existing packages.

---

## Notes

- The `http` package is no longer a dependency of the backend at all
- Dio provides built-in JSON serialization, timeouts, and interceptors — cleaner than raw `http` + manual `jsonEncode`/`jsonDecode`
- No changes to `analyze_handler.dart`, `gemini_service.dart`, `link_extractor.dart`, or `server.dart` — those files did not use `package:http`
- The `google_generative_ai` package uses its own internal HTTP client and is unaffected
