package com.fundapp

import android.content.Context
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val SECURITY_CHANNEL = "com.fundapp.security"
        private const val BADGE_CHANNEL = "com.fundapp/badge"
        private const val BADGE_PREFS = "badge_prefs"
        private const val BADGE_KEY = "badge_count"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableSecureScreen()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ─────────────────────────────────────────────
        // SECURITY CHANNEL (FLAG_SECURE)
        // ─────────────────────────────────────────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SECURITY_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableSecureScreen" -> {
                    enableSecureScreen()
                    result.success(true)
                }
                "disableSecureScreen" -> {
                    disableSecureScreen()
                    result.success(true)
                }
                "isSecureScreenEnabled" -> {
                    result.success(isSecureScreenEnabled())
                }
                else -> result.notImplemented()
            }
        }

        // ─────────────────────────────────────────────
        // BADGE CHANNEL
        //
        // Android 8+ shows launcher badges automatically when a
        // notification is posted through flutter_local_notifications.
        // We no longer use ShortcutBadger — it was creating a
        // persistent "Fundi App / N" tray notification on Samsung
        // and other OEM launchers.
        //
        // These handlers keep the Dart-side API contract intact and
        // persist the count locally (so getBadgeCount() still returns
        // a meaningful value if anything reads it). They do NOT
        // create or remove tray notifications.
        // ─────────────────────────────────────────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BADGE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setBadgeCount" -> {
                    val count = (call.argument<Int>("count")) ?: 0
                    saveBadgeCount(count)
                    result.success(true)
                }
                "removeBadge", "clearBadge" -> {
                    saveBadgeCount(0)
                    result.success(true)
                }
                "getBadgeCount" -> {
                    result.success(getBadgeCount())
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        enableSecureScreen()
    }

    private fun enableSecureScreen() {
        runOnUiThread {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
        }
    }

    private fun disableSecureScreen() {
        runOnUiThread {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    private fun isSecureScreenEnabled(): Boolean {
        return (window.attributes.flags and WindowManager.LayoutParams.FLAG_SECURE) != 0
    }

    private fun saveBadgeCount(count: Int) {
        val prefs = getSharedPreferences(BADGE_PREFS, Context.MODE_PRIVATE)
        prefs.edit().putInt(BADGE_KEY, count).apply()
    }

    private fun getBadgeCount(): Int {
        val prefs = getSharedPreferences(BADGE_PREFS, Context.MODE_PRIVATE)
        return prefs.getInt(BADGE_KEY, 0)
    }
}