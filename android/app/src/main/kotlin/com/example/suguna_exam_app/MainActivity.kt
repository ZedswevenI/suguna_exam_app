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
    private val lockCheckInterval = 1500L // Check every 1.5 seconds

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
                        try {
                            window.setFlags(
                                WindowManager.LayoutParams.FLAG_SECURE,
                                WindowManager.LayoutParams.FLAG_SECURE
                            )
                        } catch (_: Exception) {}
                        // Keep screen awake during exam (prevent auto-lock)
                        try {
                            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        } catch (_: Exception) {}
                        try {
                            startLockTask()
                        } catch (_: Exception) {}
                        handler.removeCallbacks(lockMonitor)
                        handler.postDelayed(lockMonitor, lockCheckInterval)
                        result.success(true)
                    }
                    "stopLock" -> {
                        isLockEnabled = false
                        handler.removeCallbacks(lockMonitor)
                        // Remove screenshot block
                        try {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } catch (_: Exception) {}
                        // Release wake lock
                        try {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        } catch (_: Exception) {}
                        // stopLockTask() throws IllegalStateException if the
                        // app is not currently in lock-task mode (e.g. an MDM
                        // policy already exited it). Swallow it so the Flutter
                        // side can continue to navigate.
                        try {
                            stopLockTask()
                        } catch (_: Exception) {}
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
