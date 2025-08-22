package com.example.flutter_chat

import android.content.Intent
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.flutter_chat/bubble"
    private val OVERLAY_PERMISSION_REQUEST = 1000
    private val TAG = "MainActivity"
    
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "MainActivity onCreate")
    }
    
    override fun onStart() {
        super.onStart()
        Log.d(TAG, "MainActivity onStart")
    }
    
    override fun onResume() {
        super.onResume()
        Log.d(TAG, "MainActivity onResume")
    }
    
    override fun onPause() {
        super.onPause()
        Log.d(TAG, "MainActivity onPause")
    }
    
    override fun onStop() {
        super.onStop()
        Log.d(TAG, "MainActivity onStop")
    }
    
    override fun onDestroy() {
        Log.d(TAG, "MainActivity onDestroy")
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        super.onDestroy()
    }
    
    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        Log.d(TAG, "Configuration changed: ${newConfig.orientation}")
    }
    
    override fun onLowMemory() {
        super.onLowMemory()
        Log.w(TAG, "Low memory warning received")
        // Notify Flutter about low memory
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).invokeMethod("onLowMemory", null)
        }
    }
    
    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        Log.d(TAG, "Trim memory level: $level")
        when (level) {
            TRIM_MEMORY_UI_HIDDEN -> {
                // App is hidden, reduce memory usage
                Log.d(TAG, "App UI hidden - reducing memory usage")
            }
            TRIM_MEMORY_BACKGROUND -> {
                // App is in background, release non-critical resources
                Log.d(TAG, "App in background - releasing resources")
            }
            TRIM_MEMORY_MODERATE,
            TRIM_MEMORY_COMPLETE -> {
                // Critical memory situation
                Log.w(TAG, "Critical memory situation - level $level")
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "Configuring Flutter engine")
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "showBubble" -> {
                        Log.d(TAG, "showBubble called")
                        if (canDrawOverlays()) {
                            BubbleService.startService(this)
                            result.success(true)
                        } else {
                            Log.w(TAG, "Overlay permission not granted")
                            requestOverlayPermission()
                            result.success(false)
                        }
                    }
                    "hideBubble" -> {
                        Log.d(TAG, "hideBubble called")
                        BubbleService.stopService(this)
                        result.success(true)
                    }
                    "canDrawOverlays" -> {
                        val canDraw = canDrawOverlays()
                        Log.d(TAG, "canDrawOverlays: $canDraw")
                        result.success(canDraw)
                    }
                    "requestOverlayPermission" -> {
                        Log.d(TAG, "requestOverlayPermission called")
                        if (!canDrawOverlays()) {
                            requestOverlayPermission()
                            result.success(false)
                        } else {
                            result.success(true)
                        }
                    }
                    else -> {
                        Log.w(TAG, "Method not implemented: ${call.method}")
                        result.notImplemented()
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error handling method call: ${call.method}", e)
                result.error("NATIVE_ERROR", "Failed to execute ${call.method}: ${e.message}", null)
            }
        }
    }

    private fun canDrawOverlays(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Settings.canDrawOverlays(this)
            } else {
                true
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking overlay permission", e)
            false
        }
    }

    private fun requestOverlayPermission() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Log.d(TAG, "Requesting overlay permission")
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error requesting overlay permission", e)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        Log.d(TAG, "onActivityResult: requestCode=$requestCode, resultCode=$resultCode")
        
        when (requestCode) {
            OVERLAY_PERMISSION_REQUEST -> {
                val hasPermission = canDrawOverlays()
                Log.d(TAG, "Overlay permission result: $hasPermission")
                if (hasPermission) {
                    Log.d(TAG, "Starting bubble service after permission granted")
                    BubbleService.startService(this)
                }
                // Notify Flutter about permission result
                methodChannel?.invokeMethod("onOverlayPermissionResult", hasPermission)
            }
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "onNewIntent: ${intent.action}")
        setIntent(intent)
    }
    
    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        Log.d(TAG, "Saving instance state")
        // Save any important state here
    }
    
    override fun onRestoreInstanceState(savedInstanceState: Bundle) {
        super.onRestoreInstanceState(savedInstanceState)
        Log.d(TAG, "Restoring instance state")
        // Restore any important state here
    }
}
