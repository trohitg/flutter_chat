package com.example.flutter_chat

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.*
import android.widget.Toast
import androidx.core.app.NotificationCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ProcessLifecycleOwner

class BubbleService : Service(), LifecycleEventObserver {
    private var windowManager: WindowManager? = null
    private var bubbleView: View? = null
    private var menuView: View? = null
    private val CHANNEL_ID = "bubble_channel"
    private val NOTIFICATION_ID = 1
    private val TAG = "BubbleService"
    private var bubbleEnabled = false
    private var bubbleCurrentlyVisible = false
    private var menuCurrentlyVisible = false
    private var isServiceRunning = false
    private var hideHandler: Handler? = null
    private var showHandler: Handler? = null

    companion object {
        @Volatile
        var isRunning = false
            private set
        
        fun startService(context: Context) {
            synchronized(this) {
                if (!isRunning) {
                    Log.d("BubbleService", "Starting bubble service")
                    val intent = Intent(context, BubbleService::class.java)
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            context.startForegroundService(intent)
                        } else {
                            context.startService(intent)
                        }
                    } catch (e: Exception) {
                        Log.e("BubbleService", "Failed to start service", e)
                    }
                }
            }
        }
        
        fun stopService(context: Context) {
            synchronized(this) {
                Log.d("BubbleService", "Stopping bubble service")
                val intent = Intent(context, BubbleService::class.java)
                context.stopService(intent)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "BubbleService onCreate")
        
        try {
            createNotificationChannel()
            isServiceRunning = true
            isRunning = true
            
            // Initialize handlers
            hideHandler = Handler(Looper.getMainLooper())
            showHandler = Handler(Looper.getMainLooper())
            
            // Register lifecycle observer
            ProcessLifecycleOwner.get().lifecycle.addObserver(this)
            
            Log.d(TAG, "BubbleService created successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error in onCreate", e)
            stopSelf()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand called")
        
        try {
            // Start foreground service with proper type specification
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID, 
                    createNotification(),
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } else {
                startForeground(NOTIFICATION_ID, createNotification())
            }
            
            if (Settings.canDrawOverlays(this)) {
                bubbleEnabled = true
                Log.d(TAG, "Overlay permission granted")
                
                // Only show bubble if app is in background
                val currentState = ProcessLifecycleOwner.get().lifecycle.currentState
                Log.d(TAG, "Current lifecycle state: $currentState")
                
                if (currentState != Lifecycle.State.RESUMED) {
                    showBubbleInternal()
                } else {
                    Log.d(TAG, "App is in foreground, not showing bubble")
                }
            } else {
                Log.w(TAG, "Overlay permission not granted")
                Toast.makeText(this, "Overlay permission required for bubble", Toast.LENGTH_LONG).show()
                stopSelf()
                return START_NOT_STICKY
            }
            
            return START_STICKY
        } catch (e: Exception) {
            Log.e(TAG, "Error in onStartCommand", e)
            stopSelf()
            return START_NOT_STICKY
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        Log.d(TAG, "onBind called")
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Chat Bubble Service",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Manages the floating chat bubble overlay"
                    setShowBadge(false)
                    enableVibration(false)
                    enableLights(false)
                    setSound(null, null)
                }
                
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.createNotificationChannel(channel)
                Log.d(TAG, "Notification channel created")
            } catch (e: Exception) {
                Log.e(TAG, "Error creating notification channel", e)
            }
        }
    }

    private fun createNotification(): Notification {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
            }
            
            val pendingIntent = PendingIntent.getActivity(
                this, 
                0, 
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            return NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Chat Bubble Active")
                .setContentText("Floating chat bubble is running")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .setSilent(true)
                .setAutoCancel(false)
                .setShowWhen(false)
                .setLocalOnly(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .build()
        } catch (e: Exception) {
            Log.e(TAG, "Error creating notification", e)
            // Return minimal notification as fallback
            return NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Chat Bubble")
                .setSmallIcon(R.mipmap.ic_launcher)
                .build()
        }
    }

    override fun onStateChanged(source: LifecycleOwner, event: Lifecycle.Event) {
        Log.d(TAG, "Lifecycle event: $event")
        
        when (event) {
            Lifecycle.Event.ON_RESUME -> onAppForegrounded()
            Lifecycle.Event.ON_PAUSE -> onAppBackgrounded()
            Lifecycle.Event.ON_STOP -> onAppStopped()
            Lifecycle.Event.ON_DESTROY -> onAppDestroyed()
            else -> { /* No action needed for other events */ }
        }
    }
    
    private fun onAppForegrounded() {
        Log.d(TAG, "App foregrounded")
        
        // Cancel any pending show operations
        showHandler?.removeCallbacksAndMessages(null)
        
        // Only hide bubble if it's currently visible and app comes to foreground
        if (bubbleEnabled && bubbleCurrentlyVisible && isServiceRunning) {
            hideHandler?.postDelayed({
                if (ProcessLifecycleOwner.get().lifecycle.currentState == Lifecycle.State.RESUMED) {
                    Log.d(TAG, "Hiding bubble - app is in foreground")
                    hideBubbleInternal()
                }
            }, 300) // Slightly longer delay for smooth transitions
        }
    }

    private fun onAppBackgrounded() {
        Log.d(TAG, "App backgrounded")
        
        // Cancel any pending hide operations
        hideHandler?.removeCallbacksAndMessages(null)
        
        // Show bubble with delay to ensure app is truly backgrounded
        if (bubbleEnabled && !bubbleCurrentlyVisible && isServiceRunning) {
            showHandler?.postDelayed({
                val currentState = ProcessLifecycleOwner.get().lifecycle.currentState
                if (currentState != Lifecycle.State.RESUMED && currentState != Lifecycle.State.STARTED) {
                    Log.d(TAG, "Showing bubble - app is in background")
                    showBubbleInternal()
                }
            }, 600) // Longer delay to avoid false triggers
        }
    }
    
    private fun onAppStopped() {
        Log.d(TAG, "App stopped")
        // App is definitely in background, show bubble if needed
        if (bubbleEnabled && !bubbleCurrentlyVisible && isServiceRunning) {
            showBubbleInternal()
        }
    }
    
    private fun onAppDestroyed() {
        Log.d(TAG, "App destroyed")
        // Keep bubble visible as app is completely destroyed
    }

    private fun showBubbleInternal() {
        if (bubbleCurrentlyVisible || !isServiceRunning) {
            Log.d(TAG, "Bubble already visible or service not running")
            return
        }
        
        try {
            Log.d(TAG, "Showing bubble")
            windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            
            bubbleView = LayoutInflater.from(this).inflate(R.layout.bubble_layout, null)
            
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                },
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
                PixelFormat.TRANSLUCENT
            )
            
            params.gravity = Gravity.TOP or Gravity.START
            params.x = 100
            params.y = 200 // Lower position to avoid status bar

            bubbleView?.let { bubble ->
                windowManager?.addView(bubble, params)
                bubbleCurrentlyVisible = true
                Log.d(TAG, "Bubble view added to window manager")
                
                bubble.setOnTouchListener(object : View.OnTouchListener {
                    private var initialX = 0
                    private var initialY = 0
                    private var initialTouchX = 0f
                    private var initialTouchY = 0f
                    private var isDragging = false
                    
                    override fun onTouch(v: View?, event: MotionEvent?): Boolean {
                        try {
                            when (event?.action) {
                                MotionEvent.ACTION_DOWN -> {
                                    initialX = params.x
                                    initialY = params.y
                                    initialTouchX = event.rawX
                                    initialTouchY = event.rawY
                                    isDragging = false
                                    return true
                                }
                                MotionEvent.ACTION_MOVE -> {
                                    val deltaX = event.rawX - initialTouchX
                                    val deltaY = event.rawY - initialTouchY
                                    
                                    if (Math.abs(deltaX) > 10 || Math.abs(deltaY) > 10) {
                                        isDragging = true
                                        params.x = initialX + deltaX.toInt()
                                        params.y = initialY + deltaY.toInt()
                                        
                                        // Keep bubble within screen bounds
                                        val display = windowManager?.defaultDisplay
                                        val size = android.graphics.Point()
                                        display?.getSize(size)
                                        
                                        params.x = params.x.coerceIn(0, size.x - bubble.width)
                                        params.y = params.y.coerceIn(0, size.y - bubble.height)
                                        
                                        windowManager?.updateViewLayout(bubble, params)
                                    }
                                    return true
                                }
                                MotionEvent.ACTION_UP -> {
                                    if (!isDragging) {
                                        // It's a click, show menu
                                        Log.d(TAG, "Bubble clicked")
                                        showMenu()
                                    }
                                    return true
                                }
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error in touch listener", e)
                        }
                        return false
                    }
                })
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error showing bubble", e)
            bubbleCurrentlyVisible = false
        }
    }

    private fun hideBubbleInternal() {
        try {
            Log.d(TAG, "Hiding bubble")
            hideMenu()
            
            bubbleView?.let { bubble ->
                try {
                    windowManager?.removeView(bubble)
                    Log.d(TAG, "Bubble view removed from window manager")
                } catch (e: Exception) {
                    Log.e(TAG, "Error removing bubble view", e)
                }
                bubbleView = null
                bubbleCurrentlyVisible = false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error hiding bubble", e)
        }
    }

    private fun showMenu() {
        try {
            if (menuCurrentlyVisible) {
                hideMenu()
                return
            }
            
            Log.d(TAG, "Showing menu")
            menuView = LayoutInflater.from(this).inflate(R.layout.bubble_menu_layout, null)
            
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                },
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
                PixelFormat.TRANSLUCENT
            )
            
            // Position menu overlapping with the bubble for a connected look
            bubbleView?.let { bubble ->
                val bubbleParams = bubble.layoutParams as WindowManager.LayoutParams
                params.gravity = Gravity.TOP or Gravity.START
                params.x = bubbleParams.x
                params.y = bubbleParams.y
            }

            menuView?.let { menu ->
                windowManager?.addView(menu, params)
                menuCurrentlyVisible = true
                Log.d(TAG, "Menu view added")
                
                // Setup click listeners with error handling
                try {
                    val chatButton = menu.findViewById<View>(R.id.chat_button)
                    val mainBubble = menu.findViewById<View>(R.id.main_bubble)
                    
                    chatButton?.setOnClickListener {
                        Log.d(TAG, "Chat button clicked")
                        hideMenu()
                        openMainActivity()
                    }
                    
                    mainBubble?.setOnClickListener {
                        Log.d(TAG, "Main bubble clicked")
                        hideMenu()
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error setting up menu click listeners", e)
                }
                
                // Auto-hide menu after 8 seconds if no interaction
                hideHandler?.postDelayed({
                    if (menuCurrentlyVisible) {
                        Log.d(TAG, "Auto-hiding menu after timeout")
                        hideMenu()
                    }
                }, 8000)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error showing menu", e)
        }
    }

    private fun hideMenu() {
        try {
            menuView?.let { menu ->
                try {
                    windowManager?.removeView(menu)
                    Log.d(TAG, "Menu view removed")
                } catch (e: Exception) {
                    Log.e(TAG, "Error removing menu view", e)
                }
                menuView = null
                menuCurrentlyVisible = false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error hiding menu", e)
        }
    }

    private fun openMainActivity() {
        try {
            Log.d(TAG, "Opening main activity")
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                       Intent.FLAG_ACTIVITY_CLEAR_TOP or
                       Intent.FLAG_ACTIVITY_SINGLE_TOP
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening main activity", e)
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "BubbleService onDestroy")
        
        try {
            // Remove lifecycle observer
            ProcessLifecycleOwner.get().lifecycle.removeObserver(this)
            
            // Clean up handlers
            hideHandler?.removeCallbacksAndMessages(null)
            showHandler?.removeCallbacksAndMessages(null)
            hideHandler = null
            showHandler = null
            
            // Hide all views
            hideBubbleInternal()
            
            // Update flags
            isServiceRunning = false
            isRunning = false
            bubbleEnabled = false
            
            Log.d(TAG, "BubbleService cleanup completed")
        } catch (e: Exception) {
            Log.e(TAG, "Error in onDestroy", e)
        } finally {
            super.onDestroy()
        }
    }
    
    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.d(TAG, "Task removed")
        // Keep service running even when task is removed
        // This ensures bubble remains visible when app is swiped away
    }
    
    override fun onLowMemory() {
        super.onLowMemory()
        Log.w(TAG, "Low memory warning received")
        // Could hide menu to free up memory if needed
        if (menuCurrentlyVisible) {
            hideMenu()
        }
    }
    
    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        Log.d(TAG, "Trim memory level: $level")
        
        when (level) {
            TRIM_MEMORY_UI_HIDDEN -> {
                // App UI is hidden, this is normal
                Log.d(TAG, "App UI hidden")
            }
            TRIM_MEMORY_BACKGROUND,
            TRIM_MEMORY_MODERATE -> {
                // System is running low on memory, consider reducing resources
                if (menuCurrentlyVisible) {
                    hideMenu()
                }
            }
            TRIM_MEMORY_COMPLETE -> {
                // Critical memory situation
                Log.w(TAG, "Critical memory situation")
                if (menuCurrentlyVisible) {
                    hideMenu()
                }
            }
        }
    }
}