package com.example.suguna_exam_app

import android.app.ActivityManager
import android.content.Context
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "exam_lock"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startLock" -> {
                        startLockTask()
                        result.success(true)
                    }
                    "stopLock" -> {
                        stopLockTask()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}