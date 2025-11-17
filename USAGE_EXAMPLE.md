# Intent App Usage Example

This Flutter app is configured with a cached Flutter engine and can handle intents from other apps, returning results via `setResult()` and `finish()`.

## Features

- **Cached Flutter Engine**: The app uses a pre-warmed Flutter engine for faster startup
- **Intent Handling**: Can receive data from calling apps via Intent extras
- **Result Sending**: Can return results to the calling app using Activity result APIs

## How to Call This App from Another Android App

### Kotlin Example

```kotlin
// In your calling activity
private val launcher = registerForActivityResult(
    ActivityResultContracts.StartActivityForResult()
) { result ->
    if (result.resultCode == Activity.RESULT_OK) {
        val status = result.data?.getStringExtra("status")
        val message = result.data?.getStringExtra("message")
        val timestamp = result.data?.getLongExtra("timestamp", 0)

        Log.d("Result", "Status: $status, Message: $message, Timestamp: $timestamp")
    } else if (result.resultCode == Activity.RESULT_CANCELED) {
        val status = result.data?.getStringExtra("status")
        Log.d("Result", "Cancelled: $status")
    }
}

// Launch the Intent App with data
fun launchIntentApp() {
    val intent = Intent().apply {
        setClassName("com.example.intent_app", "com.example.intent_app.MainActivity")
        putExtra("userId", "12345")
        putExtra("action", "process_payment")
        putExtra("amount", 100.50)
        putExtra("isTest", true)
    }
    launcher.launch(intent)
}
```

### Java Example

```java
// In your calling activity
private ActivityResultLauncher<Intent> launcher;

@Override
protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    launcher = registerForActivityResult(
        new ActivityResultContracts.StartActivityForResult(),
        result -> {
            if (result.getResultCode() == Activity.RESULT_OK) {
                Intent data = result.getData();
                String status = data.getStringExtra("status");
                String message = data.getStringExtra("message");
                long timestamp = data.getLongExtra("timestamp", 0);

                Log.d("Result", "Status: " + status + ", Message: " + message);
            }
        }
    );
}

// Launch the Intent App with data
private void launchIntentApp() {
    Intent intent = new Intent();
    intent.setClassName("com.example.intent_app", "com.example.intent_app.MainActivity");
    intent.putExtra("userId", "12345");
    intent.putExtra("action", "process_payment");
    intent.putExtra("amount", 100.50);
    intent.putExtra("isTest", true);

    launcher.launch(intent);
}
```

## How the App Works

### 1. Cached Engine (MyApplication.kt)

The `MyApplication` class creates and caches a Flutter engine on app startup:

```kotlin
class MyApplication : Application() {
    companion object {
        const val ENGINE_ID = "intent_app_engine"
    }

    lateinit var flutterEngine: FlutterEngine

    override fun onCreate() {
        super.onCreate()

        // Create and cache the Flutter engine
        flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine)
    }
}
```

### 2. Intent Handling (MainActivity.kt)

The `MainActivity` uses the cached engine and provides methods to:
- Get intent data
- Set result and finish

```kotlin
// Uses the cached engine
override fun provideCachedEngine(context: android.content.Context): FlutterEngine? {
    return (context.applicationContext as MyApplication).flutterEngine
}

// Handles method calls from Flutter
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    .setMethodCallHandler { call, result ->
        when (call.method) {
            "getIntentData" -> { /* Return intent extras */ }
            "setResult" -> { /* Set result and finish */ }
        }
    }
```

### 3. Flutter Integration (main.dart)

The Flutter side provides a simple `IntentService` class:

```dart
// Get intent data
final data = await IntentService.getIntentData();

// Send success result
await IntentService.setResultAndFinish(
  resultCode: -1, // Activity.RESULT_OK
  data: {
    'status': 'success',
    'message': 'Operation completed',
  },
);

// Send cancel result
await IntentService.setResultAndFinish(
  resultCode: 0, // Activity.RESULT_CANCELED
  data: {
    'status': 'cancelled',
  },
);
```

## Testing the App

1. Build and install the app on your device
2. Create a test app that calls this app with intent data
3. The Intent App will display the received data
4. Click "Send Success Result" or "Send Cancel Result"
5. The calling app will receive the result

## Supported Data Types

The app currently supports these data types in intents and results:
- String
- Int
- Boolean
- Double
- Long

You can extend the `MainActivity.kt` to support additional types as needed.