package com.example.ironlock

import android.accessibilityservice.AccessibilityService
import android.content.Intent
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

        // Ignore our own app's events to prevent overlay flickering/loops
        if (packageName == "com.example.ironlock") {
            return
        }

        if (sessionManager.isFullLockMode()) {
            // Exceptions for emergency calls
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
            
            Log.d(TAG, "Full Lock Mode: locking screen")
            // Show overlay briefly just in case, but main goal is to turn off screen
            overlayController.show()
            
            if (android.os.Build.VERSION.SDK_INT >= 28) { // Build.VERSION_CODES.P
                performGlobalAction(8) // GLOBAL_ACTION_LOCK_SCREEN
            } else {
                performGlobalAction(GLOBAL_ACTION_HOME)
            }
            return
        }

        // Specific Apps Mode
        if (sessionManager.shouldBlockApp(packageName)) {
            Log.d(TAG, "Blocking app: $packageName")
            overlayController.show()
            
            if (packageName != lastBlockedPackage && packageName != "com.android.systemui") {
                lastBlockedPackage = packageName
                performGlobalAction(GLOBAL_ACTION_HOME)
            }
        } else {
            // Only hide if not SystemUI (notification shade or lock screen)
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
