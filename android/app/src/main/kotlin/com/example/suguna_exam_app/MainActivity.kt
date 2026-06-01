package com.example.suguna_exam_app

import android.app.ActivityManager
import android.content.Context
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "exam_lock"
    private var isLockEnabled = false
    private val handler = Handler(Looper.getMainLooper())
    private val lockCheckInterval = 2000L // Check every 2 seconds

    private val lockMonitor = object : Runnable {
        override fun run() {
            if (isLockEnabled) {
                val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                if (activityManager.lockTaskModeState == ActivityManager.LOCK_TASK_MODE_NONE) {
                    // App was unpinned — re-pin (will show system confirmation once)
                    try {
                        startLockTask()
                    } catch (_: Exception) {}
                }
                handler.postDelayed(this, lockCheckInterval)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startLock" -> {
                        isLockEnabled = true
                        // Block screenshots
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE
                        )
                        // Keep screen awake during exam (prevent auto-lock)
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        startLockTask()
                        handler.removeCallbacks(lockMonitor)
                        handler.postDelayed(lockMonitor, lockCheckInterval)
                        result.success(true)
                    }
                    "stopLock" -> {
                        isLockEnabled = false
                        handler.removeCallbacks(lockMonitor)
                        // Remove screenshot block
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        // Release wake lock
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        stopLockTask()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        isLockEnabled = false
        handler.removeCallbacks(lockMonitor)
        super.onDestroy()
    }
}
