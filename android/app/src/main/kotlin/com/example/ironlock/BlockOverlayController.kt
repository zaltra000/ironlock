package com.example.ironlock

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView

class BlockOverlayController(private val context: Context) {
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var isAdded = false

    init {
        windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        createOverlayView()
    }

    private fun createOverlayView() {
        val layout = android.widget.LinearLayout(context).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            setBackgroundColor(Color.BLACK)
            gravity = Gravity.CENTER
            setPadding(32, 32, 32, 32)
        }

        val textTitle = TextView(context).apply {
            text = "لا مفر"
            textSize = 36f
            setTextColor(Color.RED)
            textAlignment = View.TEXT_ALIGNMENT_CENTER
            setTypeface(null, android.graphics.Typeface.BOLD)
        }

        val textMessage = TextView(context).apply {
            text = "عد إلى عملك! القفل لا يزال مفعلاً ولن تستطيع الهروب."
            textSize = 20f
            setTextColor(Color.WHITE)
            textAlignment = View.TEXT_ALIGNMENT_CENTER
            setPadding(0, 24, 0, 0)
        }

        layout.addView(textTitle)
        layout.addView(textMessage)

        overlayView = layout
    }

    fun show() {
        if (!isAdded && overlayView != null) {
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                else
                    WindowManager.LayoutParams.TYPE_PHONE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            )
            params.gravity = Gravity.CENTER
            
            try {
                windowManager?.addView(overlayView, params)
                isAdded = true
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    fun hide() {
        if (isAdded && overlayView != null) {
            try {
                windowManager?.removeView(overlayView)
                isAdded = false
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
