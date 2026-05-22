# Phase 2: OS Share-Sheet Overlay — Implementation Plan

> **Scope:** Android share-sheet integration, bottom-sheet-style overlay via transparent `Scaffold` (not `showModalBottomSheet`), auto-analysis on shared text, reuse of Phase 1 widgets.
> **Estimated Time:** ~8 hours (builds on Phase 1 foundation)
> **Prerequisite:** Phase 1 must be complete and functional.

---

## 0. Feature Overview

```
┌──────────────────────────────────────────────────────┐
│                 WhatsApp / SMS / etc.                 │
│                                                      │
│   User selects scam text → taps "Share" → picks     │
│   "Scam Detector" from Android share menu            │
│                                                      │
└────────────────────┬─────────────────────────────────┘
                     │ ACTION_SEND (text/plain)
                     ▼
┌──────────────────────────────────────────────────────┐
│          Transparent Overlay Activity                │
│   ┌──────────────────────────────────────────────┐   │
│   │    Bottom sheet panel (manual layout)        │   │
│   │                                              │   │
│   │   ┌──────────────────────────────────┐       │   │
│   │   │      Analog Meter (animated)     │       │   │
│   │   │        from Phase 1              │       │   │
│   │   └──────────────────────────────────┘       │   │
│   │                                              │   │
│   │   ┌──────────────────────────────────┐       │   │
│   │   │   Analysis Message Card          │       │   │
│   │   │        from Phase 1              │       │   │
│   │   └──────────────────────────────────┘       │   │
│   │                                              │   │
│   │            [ ✕ Close / Done ]                │   │
│   │     (tap-outside-dismiss DISABLED)           │   │
│   └──────────────────────────────────────────────┘   │
│   ░░░░░░░░░░ Semi-transparent BG ░░░░░░░░░░░░░░░░   │
│   ░░░░░░░░ (WhatsApp visible behind) ░░░░░░░░░░░░   │
└──────────────────────────────────────────────────────┘
```

---

## 1. Android Intent Registration

### 1.1 AndroidManifest.xml Changes

**File:** `android/app/src/main/AndroidManifest.xml`

Add the `ACTION_SEND` intent filter to the **existing** `MainActivity` entry in `android/app/src/main/AndroidManifest.xml` (do not create a second activity):

```xml
<!-- Inside <application> tag, AFTER the existing MainActivity -->

<!-- Share-Sheet Overlay Activity -->
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTask"
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">
    
    <!-- Existing main launcher intent -->
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>

    <!-- NEW: Share sheet intent filter (FR 2.1) -->
    <intent-filter>
        <action android:name="android.intent.action.SEND" />
        <category android:name="android.intent.category.DEFAULT" />
        <data android:mimeType="text/plain" />
    </intent-filter>
</activity>
```

> [!NOTE]
> Since Flutter uses a single `MainActivity`, both the launcher and share intents will route to the same activity. The app will differentiate the launch mode by checking the incoming intent in Dart code.

### 1.2 Share Intent Package

**Package:** `receive_sharing_intent: ^1.8.1` (or latest)

Add to `pubspec.yaml`:
```yaml
dependencies:
  receive_sharing_intent: ^1.8.1
```

This package handles:
- Listening for `ACTION_SEND` text intents
- Providing the shared text to Flutter via a stream
- Works with `singleTask` launch mode

---

## 2. App Routing & Intent Detection

### 2.1 Updated App Architecture

```
main.dart
  └── KuCubaApp (MaterialApp)
        └── IntentRouter (new widget)
              ├── If launched via SHARE intent → OverlayScreen
              └── If launched normally → HomeScreen
```

### 2.2 Intent Router — `lib/screens/intent_router.dart`

```dart
class IntentRouter extends StatefulWidget { ... }

class _IntentRouterState extends State<IntentRouter> {
  StreamSubscription? _intentSub;
  String? _sharedText;
  bool _isFromShare = false;

  @override
  void initState() {
    super.initState();
    
    // Check for initial share intent (app was closed)
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        setState(() {
          _sharedText = value.first.path; // For text/plain, this is the text content
          _isFromShare = true;
        });
      }
    });

    // Listen for share intents while app is running
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          setState(() {
            _sharedText = value.first.path;
            _isFromShare = true;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFromShare && _sharedText != null) {
      // Show overlay with auto-analysis
      return OverlayScreen(
        sharedText: _sharedText!,
        onDismiss: () {
          ReceiveSharingIntent.instance.reset();
          // Close the app and return to the sharing app
          SystemNavigator.pop();
        },
      );
    }
    return const HomeScreen();
  }
}
```

> [!IMPORTANT]
> **Intent handling approach:** We use `receive_sharing_intent` for cross-platform compatibility. If this package has issues, the fallback is to use a custom `MethodChannel` to read the intent from `MainActivity.kt`.

---

## 3. Overlay Screen — `lib/screens/overlay_screen.dart`

### 3.1 Visual Design

The overlay screen renders a **bottom-sheet-style panel** (manual bottom-aligned container inside a transparent `Scaffold`) that:
- Covers approximately 60-70% of the screen height
- Has a semi-transparent dark scrim behind it
- Shows the shared text, meter, and analysis — all within the sheet
- Cannot be dismissed by tapping outside (FR 2.5)

### 3.2 Widget Tree

```
Scaffold (transparent background)
└── Stack
    ├── Container (scrim: Colors.black54)  ← semi-transparent overlay
    └── Align (bottom)
        └── Container (white, rounded top corners 24px)
            └── Column
                ├── DragHandle bar (cosmetic, centered grey pill)
                ├── Row
                │   ├── Bank Islam Logo (small)
                │   ├── Text("Scam Analysis")
                │   └── IconButton("✕") → onDismiss()    ← FR 2.5
                │
                ├── Divider
                │
                ├── // Shared text preview (collapsed, max 3 lines)
                │   └── Container(grey bg, rounded)
                │       └── Text(_sharedText, maxLines: 3, overflow: ellipsis)
                │
                ├── SizedBox(h: 16)
                │
                ├── // Analysis result area (same states as Phase 1):
                │   ├── loading → Shimmer + "Scanning..." text
                │   ├── complete →
                │   │   ├── AnalogMeter(riskScore)    ← REUSED from Phase 1 (FR 2.4)
                │   │   └── AnalysisMessageCard(msg)  ← REUSED from Phase 1 (FR 2.4)
                │   └── error → Error message + retry
                │
                └── Padding (bottom: MediaQuery.viewPadding.bottom + 16)
                    └── ElevatedButton.icon("Done", Icons.check) → onDismiss()
```

### 3.3 Auto-Execution Logic (FR 2.3)

```dart
class _OverlayScreenState extends State<OverlayScreen> {
  @override
  void initState() {
    super.initState();
    // AUTO-TRIGGER analysis immediately — no button press needed (FR 2.3)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalysisProvider>().analyze(widget.sharedText);
    });
  }
  // ...
}
```

### 3.4 Anti-Accident Dismissal (FR 2.5)

- The overlay is **NOT** a Flutter `showModalBottomSheet` (which has built-in tap-to-dismiss)
- Instead, it's a **full-screen Scaffold** with a manual bottom-aligned container
- The scrim `GestureDetector` does **nothing** on tap — only the "✕" and "Done" buttons dismiss
- **Back Button Handling:** Wrap the `Scaffold` in a `PopScope` to intercept physical Android back button presses. Ensure both the physical back button and the UI "✕"/"Done" buttons trigger the exact same shared dismissal logic.
- On dismiss: call `ReceiveSharingIntent.instance.reset()` then `SystemNavigator.pop()` to return to the sharing app cleanly, preventing unexpected back stack behavior.

---

## 4. New & Modified Files

### 4.1 New Files

| File | Purpose |
|---|---|
| `lib/screens/overlay_screen.dart` | Share overlay UI (transparent `Scaffold` + bottom panel) with auto-analysis |
| `lib/screens/intent_router.dart` | Routes between HomeScreen and OverlayScreen based on intent |

### 4.2 Modified Files

| File | Changes |
|---|---|
| `pubspec.yaml` | Add `receive_sharing_intent` dependency |
| `android/app/src/main/AndroidManifest.xml` | Add `ACTION_SEND` intent filter |
| `lib/main.dart` | Wrap app with `IntentRouter` instead of directly showing `HomeScreen` |
| `lib/app.dart` | Update home route to use `IntentRouter` |
| `lib/widgets/analog_meter.dart` | Minor: add `compact` parameter for smaller overlay rendering |
| `lib/widgets/analysis_message_card.dart` | Minor: add `compact` parameter |

---

## 5. Edge Cases & Error Handling

| Scenario | Handling |
|---|---|
| User shares an image (not text) | `IntentRouter` checks media type; if not text, show a "Please share text only" toast and close |
| Share intent with empty text | Show "No text received" error state in overlay |
| Backend unreachable | Show error in overlay with manual "Retry" button |
| User shares while app is already open | Stream listener catches it, re-routes to overlay |
| User rotates device during overlay | `configChanges` handles orientation; bottom panel adjusts height |

---

## 6. Build Order & Time Estimates

| # | Task | Est. Time | Priority |
|---|---|---|---|
| 1 | Add `receive_sharing_intent` to pubspec.yaml | 5 min | 🔴 Critical |
| 2 | Modify `AndroidManifest.xml` with intent filter | 15 min | 🔴 Critical |
| 3 | Create `intent_router.dart` | 30 min | 🔴 Critical |
| 4 | Create `overlay_screen.dart` | 90 min | 🔴 Critical |
| 5 | Update `main.dart` / `app.dart` routing | 10 min | 🔴 Critical |
| 6 | Add `compact` mode to `AnalogMeter` & `AnalysisMessageCard` | 20 min | 🟡 High |
| 7 | Test share from WhatsApp → overlay flow | 30 min | 🔴 Critical |
| 8 | Test share from SMS, Chrome, Notes | 20 min | 🟡 High |
| 9 | Polish animations & transitions | 30 min | 🟡 High |
| 10 | Edge case testing (empty text, non-text, rotation) | 30 min | 🟡 High |
| **Total** | | **~4.5 hours** | |

---

## 7. Testing Checklist

### Device/Emulator Testing
- [ ] App appears in Android share menu when sharing from WhatsApp
- [ ] App appears in share menu when sharing from SMS/Messages
- [ ] App appears in share menu when sharing from Chrome (selected text)
- [ ] Overlay renders OVER the sharing app (not full-screen takeover)
- [ ] Analysis auto-triggers on share (no Analyze button needed) — FR 2.3
- [ ] Analog meter animates correctly in overlay — FR 2.4
- [ ] Analysis message displays correctly in overlay — FR 2.4
- [ ] Tapping outside the bottom sheet panel does NOT dismiss it — FR 2.5
- [ ] "✕" close button returns to the sharing app — FR 2.5
- [ ] "Done" button returns to the sharing app — FR 2.5
- [ ] Sharing while app is already open works correctly
- [ ] Sharing empty text shows appropriate error

### Performance
- [ ] Overlay appears within 500ms of tapping share
- [ ] Full analysis completes within 2.5s target (NFR 1)

---

## 8. Potential Risks & Mitigations

> [!WARNING]
> **Risk: `receive_sharing_intent` compatibility.** Some Flutter share-intent packages have known issues with newer Android versions or specific OEM skins. 
> **Mitigation:** If the package fails, implement a minimal native Kotlin `MethodChannel` in `MainActivity.kt` to forward the intent text to Flutter. This is ~30 lines of Kotlin code.

> [!NOTE]
> **Risk: Overlay vs Full-Screen.** True Android overlay behavior (drawing over other apps) requires `SYSTEM_ALERT_WINDOW` permission and is complex. Our approach uses a **transparent-themed Activity** that *looks* like an overlay but is technically a separate activity. This is the standard Flutter approach and works well for share-sheet use cases. The underlying app (WhatsApp) will be visible behind the scrim only visually — it's actually in the back stack.

> [!NOTE]
> **Risk: App state on re-share.** If the user shares text while the app is already in the foreground, the `singleTask` launch mode ensures the existing instance handles the new intent via `onNewIntent`. The `receive_sharing_intent` stream handles this case.
