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
        if (sessionManager.isSessionActive()) {
            if (sessionManager.shouldBlockApp(packageName)) {
                Log.d(TAG, "Blocking app: $packageName")
                overlayController.show()
                
                // Emulate Home button press for a smooth, lag-free exit from the app
                // Only do this if we aren't already on the home screen/launcher.
                // To prevent infinite loop, we avoid calling it repeatedly for the same package.
                if (packageName != lastBlockedPackage && packageName != "com.android.systemui") {
                    lastBlockedPackage = packageName
                    performGlobalAction(GLOBAL_ACTION_HOME)
                }
            } else {
                Log.d(TAG, "App allowed: $packageName")
                lastBlockedPackage = ""
                overlayController.hide()
            }
        } else {
            lastBlockedPackage = ""
            overlayController.hide()
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
