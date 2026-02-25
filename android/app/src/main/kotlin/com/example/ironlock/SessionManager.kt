package com.example.ironlock

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONException

class SessionManager(context: Context) {
    private val PREF_NAME = "IronLockSession"
    private val KEY_END_TIME = "endTime"
    private val KEY_SELECTED_APPS = "selectedApps"
    private val KEY_IS_FULL_LOCK_MODE = "isFullLockMode"

    private val prefs: SharedPreferences = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)

    fun startSession(durationMillis: Long, isFullLockMode: Boolean, selectedApps: List<String>) {
        val endTime = System.currentTimeMillis() + durationMillis
        
        val jsonArray = JSONArray()
        for (app in selectedApps) {
            jsonArray.put(app)
        }

        prefs.edit()
            .putLong(KEY_END_TIME, endTime)
            .putBoolean(KEY_IS_FULL_LOCK_MODE, isFullLockMode)
            .putString(KEY_SELECTED_APPS, jsonArray.toString())
            .apply()
    }

    fun clearSession() {
        prefs.edit().clear().apply()
    }

    fun isSessionActive(): Boolean {
        val endTime = prefs.getLong(KEY_END_TIME, 0)
        return System.currentTimeMillis() < endTime
    }

    fun getEndTime(): Long {
        return prefs.getLong(KEY_END_TIME, 0)
    }

    fun isFullLockMode(): Boolean {
        return prefs.getBoolean(KEY_IS_FULL_LOCK_MODE, true)
    }

    fun shouldBlockApp(packageName: String): Boolean {
        // App itself is never blocked
        if (packageName == "com.example.ironlock") return false

        if (isFullLockMode()) {
            // In Full Lock Mode, block everything except basics (calculator, dialer, etc.)
            // We can add a predefined whitelist here if needed.
            // For now, block all by returning true.
            return true
        } else {
            // In Specific Apps Mode, ONLY block the apps present in the list
            val selectedAppsJson = prefs.getString(KEY_SELECTED_APPS, "[]")
            try {
                val jsonArray = JSONArray(selectedAppsJson)
                for (i in 0 until jsonArray.length()) {
                    if (jsonArray.getString(i) == packageName) {
                        return true
                    }
                }
            } catch (e: JSONException) {
                e.printStackTrace()
            }
            return false
        }
    }
}
