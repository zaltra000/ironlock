package com.example.ironlock

import android.accessibilityservice.AccessibilityService
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class IronLockAccessibilityService : AccessibilityService() {
    private lateinit var sessionManager: SessionManager
    private lateinit var overlayController: BlockOverlayController
    private val TAG = "IronLockService"

    override fun onServiceConnected() {
        super.onServiceConnected()
        sessionManager = SessionManager(this)
        overlayController = BlockOverlayController(this)
        Log.d(TAG, "Accessibility Service Connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            
            Log.d(TAG, "Window state changed: $packageName")
            checkAndBlock(packageName)
        }
    }
    
    private var lastBlockedPackage: String = ""

    private fun checkAndBlock(packageName: String) {
        if (!sessionManager.isSessionActive()) {
            lastBlockedPackage = ""
            overlayController.hide()
            return
        }

        // Ignore our own app's events
        if (packageName == "com.example.ironlock") {
            return
        }

        if (sessionManager.isFullLockMode()) {
            // Emergency call exceptions
            val emergencyPackages = setOf(
                "com.android.phone",
                "com.android.server.telecom",
                "com.android.dialer",
                "com.google.android.dialer",
                "com.samsung.android.dialer"
            )
            if (emergencyPackages.contains(packageName)) {
                overlayController.hide()
                return
            }
            
            // Ignore SystemUI events (lock screen, notification shade) to prevent loops
            if (packageName == "com.android.systemui") {
                return
            }

            Log.d(TAG, "Full Lock Mode: locking screen via Device Admin")
            
            // Use Device Admin to lock the screen (real power-button-like lock)
            val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val componentName = ComponentName(applicationContext, IronLockDeviceAdminReceiver::class.java)
            if (dpm.isAdminActive(componentName)) {
                dpm.lockNow()
            } else {
                // Fallback: show overlay + go home if Device Admin is not enabled
                overlayController.show()
                performGlobalAction(GLOBAL_ACTION_HOME)
            }
            return
        }

        // ===== Specific Apps Mode =====
        if (sessionManager.shouldBlockApp(packageName)) {
            Log.d(TAG, "Blocking app: $packageName")
            overlayController.show()
            
            if (packageName != lastBlockedPackage && packageName != "com.android.systemui") {
                lastBlockedPackage = packageName
                performGlobalAction(GLOBAL_ACTION_HOME)
            }
        } else {
            if (packageName != "com.android.systemui") {
                Log.d(TAG, "App allowed: $packageName")
                lastBlockedPackage = ""
                overlayController.hide()
            }
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service Interrupted")
        overlayController.hide()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        overlayController.hide()
    }
}
