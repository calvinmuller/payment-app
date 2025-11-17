package com.example.intent_app

import android.app.Activity
import android.app.Application
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class MyApplication : Application() {
    companion object {
        const val ENGINE_ID = "intent_app_engine"
        const val CHANNEL = "com.example.intent_app/intent"
    }

    lateinit var flutterEngine: FlutterEngine
    lateinit var methodChannel: MethodChannel
    var currentActivity: WeakReference<MainActivity>? = null

    override fun onCreate() {
        super.onCreate()

        // Instantiate a FlutterEngine
        flutterEngine = FlutterEngine(this)

        // Start executing Dart code to pre-warm the FlutterEngine
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )

        // Set up the MethodChannel and handler immediately
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            val activity = currentActivity?.get()
            if (activity != null) {
                activity.handleMethodCall(call, result)
            } else {
                result.error("NO_ACTIVITY", "No activity available", null)
            }
        }

        // Cache the FlutterEngine to be used by FlutterActivity
        FlutterEngineCache
            .getInstance()
            .put(ENGINE_ID, flutterEngine)
    }
}

class MainActivity : FlutterActivity() {
    override fun getCachedEngineId(): String {
        return MyApplication.ENGINE_ID
    }

    override fun shouldDestroyEngineWithHost(): Boolean {
        return false
    }

    override fun onResume() {
        super.onResume()
        // Register this activity so the method channel can access it
        (application as MyApplication).currentActivity = WeakReference(this)
    }

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getIntentData" -> {
                val intentData = getIntentDataMap()
                result.success(intentData)
            }
            "setResult" -> {
                val resultCode = call.argument<Int>("resultCode") ?: Activity.RESULT_CANCELED
                val data = call.argument<Map<String, Any>>("data")

                val resultIntent = Intent()
                data?.forEach { (key, value) ->
                    when (value) {
                        is String -> resultIntent.putExtra(key, value)
                        is Int -> resultIntent.putExtra(key, value)
                        is Boolean -> resultIntent.putExtra(key, value)
                        is Double -> resultIntent.putExtra(key, value)
                        is Long -> resultIntent.putExtra(key, value)
                    }
                }

                setResult(resultCode, resultIntent)
                finish()
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun getIntentDataMap(): Map<String, Any?> {
        val intentData = mutableMapOf<String, Any?>()

        intent?.extras?.let { bundle ->
            bundle.keySet().forEach { key ->
                intentData[key] = bundle.get(key)
            }
        }

        intentData["action"] = intent?.action
        intentData["dataUri"] = intent?.data?.toString()

        return intentData
    }
}
