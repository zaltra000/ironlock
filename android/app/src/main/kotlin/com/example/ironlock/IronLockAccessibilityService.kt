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
    
    private fun checkAndBlock(packageName: String) {
        if (sessionManager.isSessionActive()) {
            if (!sessionManager.isAppWhitelisted(packageName)) {
                Log.d(TAG, "Blocking app: $packageName")
                overlayController.show()
                
                // Force go home to close the app below the overlay
                val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_HOME)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(homeIntent)
            } else {
                Log.d(TAG, "App whitelisted: $packageName")
                overlayController.hide()
            }
        } else {
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
