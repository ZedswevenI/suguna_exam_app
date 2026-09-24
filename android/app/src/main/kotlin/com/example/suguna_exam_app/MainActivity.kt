package com.example.suguna_exam_app

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "exam_lock"
    private var channel: MethodChannel? = null
    private var isLockEnabled = false

    // Screen pinning / lock-task is disabled: with it on, Android swallows the
    // Home press entirely (just shows the "pinned" toast) so the app never
    // gets a chance to show the submit confirmation. With it off, Home
    // reaches onUserLeaveHint() and Flutter treats it like Back.
    // Flip to true to restore pinning.
    private val ENABLE_LOCK_TASK = false

    // When Home is pressed mid-exam, immediately bring this task back to the
    // front so the student stays on the exam (with the submit confirmation
    // on top) instead of landing on the launcher. Best-effort: the request
    // is issued while we're still the foreground app, which is the only
    // moment Android allows it.
    private val BRING_BACK_ON_HOME = true
    // startLockTask() must only be called from a foreground activity; calling
    // it while paused (e.g. right after Home was pressed) is a no-op at best.
    private var isForeground = false
    private val handler = Handler(Looper.getMainLooper())
    private val lockCheckInterval = 1500L // Check every 1.5 seconds

    private val lockMonitor = object : Runnable {
        override fun run() {
            if (isLockEnabled && ENABLE_LOCK_TASK) {
                val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                if (isForeground &&
                    activityManager.lockTaskModeState == ActivityManager.LOCK_TASK_MODE_NONE) {
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

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler { call, result ->
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
                        if (ENABLE_LOCK_TASK) {
                            try {
                                startLockTask()
                            } catch (_: Exception) {}
                            handler.removeCallbacks(lockMonitor)
                            handler.postDelayed(lockMonitor, lockCheckInterval)
                        }
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

    // Fired by Android when the user presses Home / Recents (not for incoming
    // calls, screen off, etc.). While the exam lock is on, tell Flutter so it
    // can treat it exactly like a Back press (submit confirmation).
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (isLockEnabled) {
            try { channel?.invokeMethod("homePressed", null) } catch (_: Exception) {}
            if (BRING_BACK_ON_HOME) {
                try {
                    // singleTop launchMode → this lands in onNewIntent on the
                    // existing instance; the Flutter engine is untouched.
                    val intent = Intent(this, MainActivity::class.java).apply {
                        addFlags(
                            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP
                        )
                    }
                    startActivity(intent)
                } catch (_: Exception) {}
            }
        }
    }

    override fun onResume() {
        super.onResume()
        isForeground = true
        // Came back to the foreground mid-exam (e.g. MDM launcher relaunched
        // us after Home) — re-enter lock task immediately rather than waiting
        // for the next monitor tick.
        if (isLockEnabled && ENABLE_LOCK_TASK) {
            try {
                val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                if (activityManager.lockTaskModeState == ActivityManager.LOCK_TASK_MODE_NONE) {
                    startLockTask()
                }
            } catch (_: Exception) {}
        }
    }

    override fun onPause() {
        isForeground = false
        super.onPause()
    }

    override fun onDestroy() {
        isLockEnabled = false
        handler.removeCallbacks(lockMonitor)
        super.onDestroy()
    }
}
