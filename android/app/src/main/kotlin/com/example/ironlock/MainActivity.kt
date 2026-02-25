package com.example.ironlock

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build

class MainActivity: FlutterActivity() {
    private val CHANNEL = "ironlock_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startSession" -> {
                    val durationMillis = call.argument<Int>("durationMillis")?.toLong() ?: 0L
                    val whitelistedApps = call.argument<List<String>>("whitelistedApps") ?: listOf()
                    
                    val sessionManager = SessionManager(this)
                    sessionManager.startSession(durationMillis, whitelistedApps)
                    
                    val serviceIntent = Intent(this, IronLockForegroundService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    
                    result.success(true)
                }
                "checkAccessibilityPermission" -> {
                    val enabled = checkAccessibilityPermission()
                    result.success(enabled)
                }
                "requestAccessibilityPermission" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                }
                "checkOverlayPermission" -> {
                    val enabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        Settings.canDrawOverlays(this)
                    } else {
                        true
                    }
                    result.success(enabled)
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                        startActivity(intent)
                    }
                    result.success(null)
                }
                "isSessionActive" -> {
                    val sessionManager = SessionManager(this)
                    // If it is active, calculate remaining time, otherwise 0
                    if (sessionManager.isSessionActive()) {
                        val remaining = sessionManager.getEndTime() - System.currentTimeMillis()
                        result.success(remaining)
                    } else {
                        result.success(0L)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun checkAccessibilityPermission(): Boolean {
        var accessibilityEnabled = 0
        val service = packageName + "/" + IronLockAccessibilityService::class.java.canonicalName
        try {
            accessibilityEnabled = Settings.Secure.getInt(
                applicationContext.contentResolver,
                Settings.Secure.ACCESSIBILITY_ENABLED
            )
        } catch (e: Settings.SettingNotFoundException) {
            e.printStackTrace()
        }
        val stringColonSplitter = android.text.TextUtils.SimpleStringSplitter(':')
        if (accessibilityEnabled == 1) {
            val settingValue = Settings.Secure.getString(
                applicationContext.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            if (settingValue != null) {
                stringColonSplitter.setString(settingValue)
                while (stringColonSplitter.hasNext()) {
                    val accessibilityService = stringColonSplitter.next()
                    if (accessibilityService.equals(service, ignoreCase = true)) {
                        return true
                    }
                }
            }
        }
        return false
    }
}
