package com.example.flutter_chat

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.view.*
import android.widget.ImageView
import android.widget.Toast
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleObserver
import androidx.lifecycle.OnLifecycleEvent
import androidx.lifecycle.ProcessLifecycleOwner

class BubbleService : Service(), LifecycleObserver {
    private var windowManager: WindowManager? = null
    private var bubbleView: View? = null
    private var menuView: View? = null
    private val CHANNEL_ID = "bubble_channel"
    private val NOTIFICATION_ID = 1
    private var bubbleEnabled = false
    private var bubbleCurrentlyVisible = false
    private var menuCurrentlyVisible = false

    companion object {
        var isRunning = false
        
        fun startService(context: Context) {
            if (!isRunning) {
                val intent = Intent(context, BubbleService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            }
        }
        
        fun stopService(context: Context) {
            val intent = Intent(context, BubbleService::class.java)
            context.stopService(intent)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        isRunning = true
        ProcessLifecycleOwner.get().lifecycle.addObserver(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, createNotification())
        
        if (Settings.canDrawOverlays(this)) {
            bubbleEnabled = true
            // Only show bubble if app is in background
            if (ProcessLifecycleOwner.get().lifecycle.currentState != Lifecycle.State.RESUMED) {
                showBubbleInternal()
            }
        } else {
            Toast.makeText(this, "Overlay permission required for bubble", Toast.LENGTH_LONG).show()
            stopSelf()
        }
        
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Bubble Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Chat bubble overlay service"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Chat Bubble Active")
            .setContentText("Tap to open chat")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_RESUME)
    fun onAppForegrounded() {
        // Only hide bubble if it's currently visible and app comes to foreground
        // Use a slight delay to prevent flicker during app transitions
        if (bubbleEnabled && bubbleCurrentlyVisible) {
            Handler(Looper.getMainLooper()).postDelayed({
                if (ProcessLifecycleOwner.get().lifecycle.currentState == Lifecycle.State.RESUMED) {
                    hideBubbleInternal()
                }
            }, 200)
        }
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_PAUSE)
    fun onAppBackgrounded() {
        // Show bubble with delay to ensure app is truly backgrounded
        if (bubbleEnabled && !bubbleCurrentlyVisible) {
            Handler(Looper.getMainLooper()).postDelayed({
                if (ProcessLifecycleOwner.get().lifecycle.currentState != Lifecycle.State.RESUMED) {
                    showBubbleInternal()
                }
            }, 500)
        }
    }

    private fun showBubbleInternal() {
        if (bubbleCurrentlyVisible) return
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        
        bubbleView = LayoutInflater.from(this).inflate(R.layout.bubble_layout, null)
        
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        )
        
        params.gravity = Gravity.TOP or Gravity.START
        params.x = 100
        params.y = 100

        bubbleView?.let { bubble ->
            windowManager?.addView(bubble, params)
            bubbleCurrentlyVisible = true
            
            bubble.setOnTouchListener(object : View.OnTouchListener {
                private var initialX = 0
                private var initialY = 0
                private var initialTouchX = 0f
                private var initialTouchY = 0f
                
                override fun onTouch(v: View?, event: MotionEvent?): Boolean {
                    when (event?.action) {
                        MotionEvent.ACTION_DOWN -> {
                            initialX = params.x
                            initialY = params.y
                            initialTouchX = event.rawX
                            initialTouchY = event.rawY
                            return true
                        }
                        MotionEvent.ACTION_MOVE -> {
                            params.x = initialX + (event.rawX - initialTouchX).toInt()
                            params.y = initialY + (event.rawY - initialTouchY).toInt()
                            windowManager?.updateViewLayout(bubble, params)
                            return true
                        }
                        MotionEvent.ACTION_UP -> {
                            val deltaX = event.rawX - initialTouchX
                            val deltaY = event.rawY - initialTouchY
                            
                            if (Math.abs(deltaX) < 10 && Math.abs(deltaY) < 10) {
                                // It's a click, show menu
                                showMenu()
                            }
                            return true
                        }
                    }
                    return false
                }
            })
        }
    }

    private fun hideBubbleInternal() {
        hideMenu()
        bubbleView?.let { 
            windowManager?.removeView(it)
            bubbleView = null
            bubbleCurrentlyVisible = false
        }
    }

    private fun showMenu() {
        if (menuCurrentlyVisible) {
            hideMenu()
            return
        }

        menuView = LayoutInflater.from(this).inflate(R.layout.bubble_menu_layout, null)
        
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        )
        
        // Position menu overlapping with the bubble for a connected look
        bubbleView?.let { bubble ->
            val bubbleParams = bubble.layoutParams as WindowManager.LayoutParams
            params.gravity = Gravity.TOP or Gravity.START
            params.x = bubbleParams.x // Same x position as bubble
            params.y = bubbleParams.y // Same y position as bubble
        }

        menuView?.let { menu ->
            windowManager?.addView(menu, params)
            menuCurrentlyVisible = true
            
            // Setup click listeners
            val chatButton = menu.findViewById<View>(R.id.chat_button)
            val mainBubble = menu.findViewById<View>(R.id.main_bubble)
            
            chatButton.setOnClickListener {
                hideMenu()
                openMainActivity()
            }
            
            // Main bubble can also be clicked to close menu or open app
            mainBubble.setOnClickListener {
                hideMenu()
            }
            
            // Auto-hide menu after 5 seconds if no interaction
            Handler(Looper.getMainLooper()).postDelayed({
                if (menuCurrentlyVisible) {
                    hideMenu()
                }
            }, 5000)
        }
    }

    private fun hideMenu() {
        menuView?.let { 
            windowManager?.removeView(it)
            menuView = null
            menuCurrentlyVisible = false
        }
    }

    private fun openMainActivity() {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        startActivity(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        ProcessLifecycleOwner.get().lifecycle.removeObserver(this)
        hideBubbleInternal()
        isRunning = false
        bubbleEnabled = false
    }
}