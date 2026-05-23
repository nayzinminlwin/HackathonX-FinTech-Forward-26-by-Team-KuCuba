# Phase 3: Pinned Notification Banner — Implementation Plan

> **Scope:** Android Foreground Service, persistent notification with "Analyze Copied Text" button, clipboard reading, background analysis, and in-notification result display with horizontal risk bar.
> **Estimated Time:** ~10 hours (most complex phase — heavy native Android work)
> **Prerequisite:** Phase 1 **backend** must be complete and verified (`POST /analyze` working). Phase 2 (Share Sheet) is **not** required — Phase 3 may be implemented **in parallel** with Phase 2; both call the same analysis API (see `docs/AI/rule.md` §0.1).
> **Priority:** Stretch goal — implement when backend is stable and hackathon time allows (parallel with Phase 2 is OK).

---

## 0. Feature Overview

```
┌──────────────────────────────────────────────────────┐
│              Android Notification Drawer              │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │ 🛡️ Scam Detector              RUNNING          │  │
│  │                                                │  │
│  │  [ 🔍 Analyze Copied Text ]                    │  │
│  │                                                │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
│              ↓ After analysis ↓                      │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │ 🛡️ Scam Detector              RESULT           │  │
│  │                                                │  │
│  │  ████████████░░░░░░░░░  Risk: 65/100           │  │
│  │  ▓▓GREEN▓▓▓▓▓▓YELLOW▓▓▓▓▓RED                  │  │
│  │                                                │  │
│  │  "This message contains a suspicious link.     │  │
│  │   Exercise caution before clicking."           │  │
│  │                                                │  │
│  │  [ 🔍 Analyze Again ]                          │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

## 1. Architecture — Native ↔ Flutter Bridge

Phase 3 requires **significant native Android (Kotlin) code** because:
- Foreground Services must be registered in `AndroidManifest.xml`
- Custom notification layouts use `RemoteViews` (Android-only API)
- Clipboard access from a service requires `ClipboardManager`
- Notification action buttons use `PendingIntent` + `BroadcastReceiver`

### 1.1 Communication Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Flutter (Dart)                      │
│                                                     │
│  ┌─────────────────────┐                            │
│  │ NotificationService  │ (Dart controller class)   │
│  │  Controller          │                           │
│  │  - startService()    │──────────┐                │
│  │  - stopService()     │          │                │
│  └─────────────────────┘          │                │
│                                    │ MethodChannel  │
│                    'com.kucuba/notification_service' │
│                                    │                │
└────────────────────────────────────┼────────────────┘
                                     │
┌────────────────────────────────────▼────────────────┐
│              Native Android (Kotlin)                │
│                                                     │
│  ┌──────────────────────────────┐                   │
│  │ ScamDetectorForegroundService│                   │
│  │  - Creates notification      │                   │
│  │  - Manages lifecycle         │                   │
│  └──────────────────────────────┘                   │
│                                                     │
│  ┌──────────────────────────────┐                   │
│  │ AnalyzeReceiver              │                   │
│  │  (BroadcastReceiver)         │                   │
│  │  - Reads clipboard           │                   │
│  │  - Calls backend via HTTP    │                   │
│  │  - Updates notification      │                   │
│  └──────────────────────────────┘                   │
│                                                     │
│  ┌──────────────────────────────┐                   │
│  │ NotificationHelper           │                   │
│  │  - Builds custom RemoteViews │                   │
│  │  - Updates notification UI   │                   │
│  └──────────────────────────────┘                   │
└─────────────────────────────────────────────────────┘
```

> [!IMPORTANT]
> **Key decision:** The notification action button ("Analyze Copied Text") triggers a `BroadcastReceiver` on the native side that reads the clipboard and makes the HTTP call **directly from Kotlin** using **`java.net.HttpURLConnection`** by default. Use `okhttp3` only if `HttpURLConnection` is conclusively insufficient on the test device. This avoids waking the Flutter engine from a notification tap. The backend URL is passed as an extra to the service.

---

## 2. Native Android Implementation

### 2.1 New Kotlin Files

All files in `android/app/src/main/kotlin/com/kucuba/eternal_guardian/`:

#### 2.1.1 `ScamDetectorForegroundService.kt`

```kotlin
class ScamDetectorForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "scam_detector_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_ANALYZE = "com.kucuba.ACTION_ANALYZE_CLIPBOARD"
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createNotificationChannel()
        val notification = NotificationHelper.buildIdleNotification(this)
        startForeground(NOTIFICATION_ID, notification)
        return START_STICKY
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Scam Detector Guardian",
            NotificationManager.IMPORTANCE_LOW  // Low = no sound, persistent
        ).apply {
            description = "Always-on scam detection from clipboard"
            setShowBadge(false)
        }
        getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
```

#### 2.1.2 `AnalyzeReceiver.kt`

```kotlin
class AnalyzeReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        // 1. Read clipboard (FR 3.3)
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clipText = clipboard.primaryClip?.getItemAt(0)?.text?.toString()

        if (clipText.isNullOrBlank()) {
            NotificationHelper.updateNotificationError(context, "No text found on clipboard.")
            return
        }

        // 2. Show "Scanning..." state (FR 3.4)
        NotificationHelper.updateNotificationScanning(context)

        // 3. Call backend in background thread
        Thread {
            try {
                val backendUrl = intent.getStringExtra("backend_url")
                    ?: AppConfig.BACKEND_URL  // fallback
                val result = HttpAnalysisClient.analyze(backendUrl, clipText)

                // 4. Update notification with result (FR 3.5)
                NotificationHelper.updateNotificationResult(
                    context,
                    result.riskScore,
                    result.analysisMessage
                )
            } catch (e: Exception) {
                NotificationHelper.updateNotificationError(
                    context,
                    "Analysis failed. Try again."
                )
            }
        }.start()
    }
}
```

#### 2.1.3 `NotificationHelper.kt`

Manages building and updating the notification with `RemoteViews`:

```kotlin
object NotificationHelper {

    // IDLE STATE — Shows "Analyze Copied Text" button
    fun buildIdleNotification(context: Context): Notification {
        val analyzeIntent = Intent(context, AnalyzeReceiver::class.java).apply {
            action = ScamDetectorForegroundService.ACTION_ANALYZE
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context, 0, analyzeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val remoteViews = RemoteViews(context.packageName, R.layout.notification_idle)
        remoteViews.setOnClickPendingIntent(R.id.btn_analyze, pendingIntent)

        return NotificationCompat.Builder(context, ScamDetectorForegroundService.CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_shield)
            .setCustomContentView(remoteViews)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }

    // SCANNING STATE — Shows spinner/progress
    fun updateNotificationScanning(context: Context) {
        val remoteViews = RemoteViews(context.packageName, R.layout.notification_scanning)
        // ... build and notify
    }

    // RESULT STATE — Shows horizontal bar + message (FR 3.5)
    fun updateNotificationResult(context: Context, riskScore: Int, message: String) {
        val remoteViews = RemoteViews(context.packageName, R.layout.notification_result)

        // Set progress bar (FR 3.5)
        remoteViews.setProgressBar(R.id.risk_bar, 100, riskScore, false)

        // Color the bar based on zone
        val barColor = when {
            riskScore <= 30 -> Color.parseColor("#2ECC71")  // Green
            riskScore <= 70 -> Color.parseColor("#F1C40F")  // Yellow
            else -> Color.parseColor("#E74C3C")             // Red
        }
        remoteViews.setInt(R.id.risk_bar, "setProgressTintList",
            ColorStateList.valueOf(barColor))

        // Set text
        remoteViews.setTextViewText(R.id.risk_label, "Risk: $riskScore/100")
        remoteViews.setTextViewText(R.id.analysis_message, message)

        // Add "Analyze Again" button
        // ... same PendingIntent as idle

        // ... build and notify
    }
}
```

#### 2.1.4 `HttpAnalysisClient.kt`

Simple HTTP client for making the `POST /analyze` call from native Kotlin:

```kotlin
object HttpAnalysisClient {
    data class AnalysisResult(val riskScore: Int, val analysisMessage: String)

    fun analyze(backendUrl: String, textPayload: String): AnalysisResult {
        val url = URL("$backendUrl/analyze")
        val connection = url.openConnection() as HttpURLConnection
        connection.requestMethod = "POST"
        connection.setRequestProperty("Content-Type", "application/json")
        connection.doOutput = true

        val body = """{"text_payload": "${textPayload.replace("\"", "\\\"")}"}"""
        connection.outputStream.write(body.toByteArray())

        val response = connection.inputStream.bufferedReader().readText()
        val json = JSONObject(response)

        return AnalysisResult(
            riskScore = json.getInt("risk_score"),
            analysisMessage = json.getString("analysis_message")
        )
    }
}
```

---

## 3. Custom Notification Layouts (RemoteViews XML)

### 3.1 Layout Files

Create in `android/app/src/main/res/layout/`:

#### `notification_idle.xml` (FR 3.2)

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    android:padding="12dp">

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="🛡️ Scam Detector Guardian"
        android:textSize="14sp"
        android:textStyle="bold"
        android:textColor="#1A1A1A" />

    <Button
        android:id="@+id/btn_analyze"
        android:layout_width="match_parent"
        android:layout_height="40dp"
        android:layout_marginTop="8dp"
        android:text="🔍 Analyze Copied Text"
        android:textSize="13sp"
        android:backgroundTint="#ED2321"
        android:textColor="#FFFFFF" />
</LinearLayout>
```

#### `notification_scanning.xml` (FR 3.4)

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    android:padding="12dp">

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="🛡️ Scanning..."
        android:textSize="14sp"
        android:textStyle="bold" />

    <ProgressBar
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="8dp"
        style="?android:attr/progressBarStyleHorizontal"
        android:indeterminate="true"
        android:indeterminateTint="#ED2321" />
</LinearLayout>
```

#### `notification_result.xml` (FR 3.5)

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    android:padding="12dp">

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="🛡️ Scam Detector"
        android:textSize="14sp"
        android:textStyle="bold"
        android:textColor="#1A1A1A" />

    <!-- Horizontal segmented risk bar (FR 3.5) -->
    <ProgressBar
        android:id="@+id/risk_bar"
        android:layout_width="match_parent"
        android:layout_height="8dp"
        android:layout_marginTop="8dp"
        style="?android:attr/progressBarStyleHorizontal"
        android:max="100"
        android:progress="0" />

    <TextView
        android:id="@+id/risk_label"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="4dp"
        android:text="Risk: 0/100"
        android:textSize="12sp"
        android:textColor="#757575" />

    <TextView
        android:id="@+id/analysis_message"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="4dp"
        android:text=""
        android:textSize="13sp"
        android:textColor="#1A1A1A"
        android:maxLines="3"
        android:ellipsize="end" />

    <Button
        android:id="@+id/btn_analyze_again"
        android:layout_width="match_parent"
        android:layout_height="36dp"
        android:layout_marginTop="8dp"
        android:text="🔍 Analyze Again"
        android:textSize="12sp"
        android:backgroundTint="#ED2321"
        android:textColor="#FFFFFF" />
</LinearLayout>
```

---

## 4. Android Manifest Additions

```xml
<!-- Service declaration -->
<service
    android:name=".ScamDetectorForegroundService"
    android:exported="false"
    android:foregroundServiceType="specialUse" />

<!-- Broadcast receiver for notification button -->
<receiver
    android:name=".AnalyzeReceiver"
    android:exported="false">
    <intent-filter>
        <action android:name="com.kucuba.ACTION_ANALYZE_CLIPBOARD" />
    </intent-filter>
</receiver>

<!-- Permissions -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

---

## 5. Flutter-Side Controller

### 5.1 `lib/services/notification_service_controller.dart`

```dart
class NotificationServiceController {
  static const _channel = MethodChannel('com.kucuba/notification_service');

  /// Start the foreground service (called from Guardian Mode toggle in the app — not on device boot)
  static Future<void> startService() async {
    await _channel.invokeMethod('startService', {
      'backend_url': AppConfig.backendBaseUrl,
    });
  }

  /// Stop the foreground service
  static Future<void> stopService() async {
    await _channel.invokeMethod('stopService');
  }

  /// Check if the service is currently running
  static Future<bool> isRunning() async {
    return await _channel.invokeMethod('isRunning') ?? false;
  }
}
```

### 5.2 `MainActivity.kt` — MethodChannel Handler

```kotlin
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.kucuba/notification_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        val backendUrl = call.argument<String>("backend_url")
                        val intent = Intent(this, ScamDetectorForegroundService::class.java)
                        intent.putExtra("backend_url", backendUrl)
                        startForegroundService(intent)
                        result.success(true)
                    }
                    "stopService" -> {
                        stopService(Intent(this, ScamDetectorForegroundService::class.java))
                        result.success(true)
                    }
                    "isRunning" -> {
                        result.success(isServiceRunning())
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
```

---

## 6. UI Integration in Flutter App

### 6.1 Settings Toggle on Home Screen

Add a toggle switch to the home screen (or a settings page) to control the notification service:

```
HomeScreen AppBar → Settings Icon → 
  ┌─────────────────────────────────────────┐
  │  Guardian Mode                          │
  │  ──────────────────────────             │
  │  🛡️ Clipboard Scanner    [Toggle ON/OFF]│
  │  Keeps a notification pinned for        │
  │  quick clipboard analysis.              │
  └─────────────────────────────────────────┘
```

### 6.2 Notification Permission Request

On Android 13+ (API 33), `POST_NOTIFICATIONS` requires runtime permission:

```dart
Future<void> _requestNotificationPermission() async {
  if (Platform.isAndroid) {
    // Use permission_handler package
    final status = await Permission.notification.request();
    if (status.isGranted) {
      await NotificationServiceController.startService();
    }
  }
}
```

Add to `pubspec.yaml`:
```yaml
dependencies:
  permission_handler: ^11.3.1
```

---

## 7. Drawable Resources

Create notification icon in `android/app/src/main/res/drawable/`:

#### `ic_shield.xml` (Vector drawable)

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#ED2321"
        android:pathData="M12,2L4,5v6.09c0,5.05 3.41,9.76 8,10.91c4.59,-1.15 8,-5.86 8,-10.91V5L12,2z" />
</vector>
```

---

## 8. Complete File List

### 8.1 New Files

| File | Language | Purpose |
|---|---|---|
| `android/.../ScamDetectorForegroundService.kt` | Kotlin | Foreground service |
| `android/.../AnalyzeReceiver.kt` | Kotlin | Clipboard read + API call |
| `android/.../NotificationHelper.kt` | Kotlin | Build/update notifications |
| `android/.../HttpAnalysisClient.kt` | Kotlin | Native HTTP client |
| `android/.../AppConfig.kt` | Kotlin | Backend URL config |
| `android/.../res/layout/notification_idle.xml` | XML | Idle notification layout |
| `android/.../res/layout/notification_scanning.xml` | XML | Scanning state layout |
| `android/.../res/layout/notification_result.xml` | XML | Result with bar layout |
| `android/.../res/drawable/ic_shield.xml` | XML | Shield notification icon |
| `lib/services/notification_service_controller.dart` | Dart | Flutter ↔ native bridge |

### 8.2 Modified Files

| File | Changes |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | Add service, receiver, permissions |
| `android/.../MainActivity.kt` | Add MethodChannel handler |
| `pubspec.yaml` | Add `permission_handler` |
| `lib/screens/home_screen.dart` | Add Guardian Mode toggle |

---

## 9. Build Order & Time Estimates

| # | Task | Est. Time | Priority |
|---|---|---|---|
| 1 | Create notification layout XMLs (idle, scanning, result) | 30 min | 🔴 Critical |
| 2 | Create `ic_shield.xml` drawable | 10 min | 🔴 Critical |
| 3 | Implement `ScamDetectorForegroundService.kt` | 45 min | 🔴 Critical |
| 4 | Implement `NotificationHelper.kt` | 60 min | 🔴 Critical |
| 5 | Implement `AnalyzeReceiver.kt` | 45 min | 🔴 Critical |
| 6 | Implement `HttpAnalysisClient.kt` | 30 min | 🔴 Critical |
| 7 | Update `AndroidManifest.xml` | 15 min | 🔴 Critical |
| 8 | Update `MainActivity.kt` with MethodChannel | 30 min | 🔴 Critical |
| 9 | Create `notification_service_controller.dart` (Dart) | 15 min | 🔴 Critical |
| 10 | Add toggle UI to HomeScreen | 20 min | 🟡 High |
| 11 | Add notification permission handling | 15 min | 🟡 High |
| 12 | End-to-end testing (copy text → tap notification → see result) | 45 min | 🔴 Critical |
| 13 | Edge case testing (empty clipboard, no backend, etc.) | 30 min | 🟡 High |
| 14 | Polish notification colors and layout | 20 min | 🟢 Nice-to-have |
| **Total** | | **~6.5 hours** | |

---

## 10. Testing Checklist

### Functional Tests
- [ ] Foreground service starts when toggle is enabled
- [ ] Persistent notification appears in notification drawer
- [ ] Notification survives app being swiped away from recents
- [ ] "Analyze Copied Text" button reads clipboard correctly — FR 3.3
- [ ] Notification transitions to "Scanning..." state — FR 3.4
- [ ] After analysis, risk bar shows correct color zone — FR 3.5
- [ ] Analysis message text displays in notification — FR 3.5
- [ ] "Analyze Again" button works for subsequent scans
- [ ] Service stops when toggle is disabled
- [ ] Notification permission dialog appears on Android 13+

### Edge Cases
- [ ] Empty clipboard → "No text found" message
- [ ] Very long clipboard text (2000+ chars) → truncated for API, no crash
- [ ] Backend offline → "Analysis failed. Try again." message
- [ ] Battery optimization: service persists after 30 min idle
- [ ] Device restart: service does NOT auto-start (would need BOOT_COMPLETED, out of scope)

### Performance
- [ ] Clipboard read + analysis completes within 3 seconds
- [ ] Notification update is immediate (no visible delay between states)
- [ ] Service memory footprint stays under 30MB

---

## 11. Risks & Mitigations

> [!WARNING]
> **Risk: Android 14+ Foreground Service Restrictions.** Android 14 tightened rules around foreground services. `FOREGROUND_SERVICE_SPECIAL_USE` may require a Play Store policy declaration.
> **Mitigation:** For hackathon demo, this won't matter since we're sideloading. Document this for future production release.

> [!WARNING]
> **Risk: Clipboard access restrictions on Android 12+.** Starting Android 12, apps can only read the clipboard if they are the current foreground app OR are the default input method. A notification tap triggers a `BroadcastReceiver` which may not count as "foreground."
> **Mitigation:** Use `ClipboardManager.addPrimaryClipChangedListener()` to cache the last clipboard content when the app IS in the foreground. Alternatively, use `RemoteInput` on the notification to ask the user to paste text directly.

> [!CAUTION]
> **Fallback plan:** If clipboard access from the notification receiver fails on the test device, convert the notification button to **open the app's HomeScreen with a "paste from clipboard" action** instead of reading it natively. This is a 15-minute change.

> [!NOTE]
> **Risk: OEM battery optimization.** Samsung, Xiaomi, and other OEMs aggressively kill background services. The notification may disappear on some devices.
> **Mitigation:** For the hackathon demo, disable battery optimization for the app manually on the demo device. Add an in-app prompt guiding users to whitelist the app.

---

## 12. Hackathon Priority Assessment

> [!IMPORTANT]
> **This phase is the highest-risk, lowest-reward phase** for the hackathon:
> - It requires ~6.5 hours of native Android/Kotlin work
> - It has multiple platform-specific pitfalls (clipboard restrictions, service lifecycle)
> - The core value proposition (scam detection) is already demonstrated by Phase 1 + 2
>
> **Recommendation:** If Phase 1 + 2 are done and stable with **>8 hours remaining**, proceed with Phase 3. Otherwise, prepare a **slide/mockup** showing the notification concept and focus on polishing Phase 1 + 2.
>
> **Quick-win alternative (2 hours):** Instead of the full foreground service, implement a simpler "Paste from Clipboard" button on the HomeScreen that reads `Clipboard.getData()` in Flutter and feeds it to the existing analysis flow. This gives 80% of the value with 20% of the effort.
