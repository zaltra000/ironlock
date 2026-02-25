package com.example.ironlock

import android.app.admin.DevicePolicyManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Listens for ACTION_USER_PRESENT (user unlocked the phone).
 * If Full Lock session is active, immediately re-locks the screen.
 */
class ScreenUnlockReceiver : BroadcastReceiver() {
    private val TAG = "IronLockUnlock"

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_USER_PRESENT || intent.action == Intent.ACTION_SCREEN_ON) {
            val sessionManager = SessionManager(context)
            
            if (sessionManager.isSessionActive() && sessionManager.isFullLockMode()) {
                Log.d(TAG, "User unlocked phone during Full Lock session. Re-locking NOW.")
                
                val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                val componentName = ComponentName(context, IronLockDeviceAdminReceiver::class.java)
                
                if (dpm.isAdminActive(componentName)) {
                    // Small delay to let the system finish the unlock animation,
                    // then lock immediately. Without the delay, some OEMs ignore the lock.
                    android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                        dpm.lockNow()
                        Log.d(TAG, "Screen re-locked successfully.")
                    }, 300)
                } else {
                    Log.w(TAG, "Device Admin not active, cannot re-lock.")
                }
            }
        }
    }
}
