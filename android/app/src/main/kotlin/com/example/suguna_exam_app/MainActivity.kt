package com.example.suguna_exam_app

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "exam_lock"
    private var channel: MethodChannel? = null
    private var isLockEnabled = false

    // Lock task mode — only works (fully blocks Home) if MDM has removed
    // LOCK_TASK_FEATURE_HOME from setLockTaskFeatures(). Keep true so the
    // exam task is at least pinned in the stack even if Home still navigates.
    private val ENABLE_LOCK_TASK = true

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
                        // Hide navigation bar — home button disappears visually
                        hideSystemUI()
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
                        // Restore navigation bar
                        showSystemUI()
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
                    "exitApp" -> {
                        // Force-close even while pinned: finish() is ignored
                        // for a lock-task root activity, so leave lock-task
                        // first (verified, with retries), remove the task,
                        // then kill the process.
                        isLockEnabled = false
                        handler.removeCallbacks(lockMonitor)
                        showSystemUI()
                        result.success(true)
                        forceExit(0)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // onUserLeaveHint fires before onPause — good for early detection of
    // Home/Recents press. onWindowFocusChanged handles the bring-back after
    // a short delay, so we only notify Flutter here.
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (isLockEnabled) {
            try { channel?.invokeMethod("homePressed", null) } catch (_: Exception) {}
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

    // Re-hide nav bar whenever a system overlay (nav bar swipe, notification)
    // temporarily reveals it, so the home button disappears again immediately.
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (isLockEnabled) {
            if (hasFocus) {
                hideSystemUI()
            } else {
                // Focus loss on its own is NOT a Home press: the screen-pinning
                // confirmation shown by startLockTask() at exam start, the
                // notification shade, permission/system dialogs all take focus
                // while the activity stays resumed. Only treat it as "left the
                // app" if the activity has actually been paused by the time
                // the delay elapses (Home / Recents / task switch).
                handler.postDelayed({
                    if (isLockEnabled && !isForeground) {
                        try {
                            channel?.invokeMethod("homePressed", null)
                        } catch (_: Exception) {}
                        if (BRING_BACK_ON_HOME) {
                            try {
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
                }, 300)
            }
        }
    }

    /// Unpins (retrying until the system reports LOCK_TASK_MODE_NONE or we
    /// give up), then finishes the task and kills the process.
    private fun forceExit(attempt: Int) {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val locked = am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
        if (locked && attempt < 10) {
            try {
                stopLockTask()
            } catch (e: Exception) {
                android.util.Log.e("exam_lock", "stopLockTask failed (attempt $attempt)", e)
            }
            handler.postDelayed({ forceExit(attempt + 1) }, 150)
            return
        }
        if (locked) {
            android.util.Log.e("exam_lock", "Still in lock task after retries — exiting anyway")
        }
        try { finishAndRemoveTask() } catch (_: Exception) {}
        handler.postDelayed({
            android.os.Process.killProcess(android.os.Process.myPid())
        }, 200)
    }

    override fun onDestroy() {
        isLockEnabled = false
        handler.removeCallbacks(lockMonitor)
        super.onDestroy()
    }

    private fun hideSystemUI() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.let {
                it.hide(WindowInsets.Type.systemBars())
                it.systemBarsBehavior =
                    WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_FULLSCREEN
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            )
        }
    }

    private fun showSystemUI() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.show(WindowInsets.Type.systemBars())
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
        }
    }
}
