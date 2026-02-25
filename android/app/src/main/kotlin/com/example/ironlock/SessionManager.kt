package com.example.ironlock

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONException

class SessionManager(context: Context) {
    private val PREF_NAME = "IronLockSession"
    private val KEY_END_TIME = "endTime"
    private val KEY_WHITELIST = "whitelist"

    private val prefs: SharedPreferences = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)

    fun startSession(durationMillis: Long, whitelistedApps: List<String>) {
        val endTime = System.currentTimeMillis() + durationMillis
        
        val jsonArray = JSONArray()
        for (app in whitelistedApps) {
            jsonArray.put(app)
        }

        prefs.edit()
            .putLong(KEY_END_TIME, endTime)
            .putString(KEY_WHITELIST, jsonArray.toString())
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

    fun isAppWhitelisted(packageName: String): Boolean {
        // App itself is always whitelisted
        if (packageName == "com.example.ironlock") return true
        
        // Settings and Play Store are intentionally NOT whitelisted unless explicitly added 
        // to prevent uninstallation, but we usually want to explicitly block them anyway.

        val whitelistJson = prefs.getString(KEY_WHITELIST, "[]")
        try {
            val jsonArray = JSONArray(whitelistJson)
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
