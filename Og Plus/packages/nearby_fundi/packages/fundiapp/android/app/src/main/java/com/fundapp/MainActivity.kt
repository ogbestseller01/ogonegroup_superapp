package com.fundapp

import android.content.Context
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val SECURITY_CHANNEL        = "com.fundapp/security"
        private const val BADGE_CHANNEL           = "com.fundapp/badge"
        // Legacy names kept so old Dart builds don't crash during rollout
        private const val LEGACY_SECURITY_CHANNEL = "com.nearbyfundi/security"
        private const val LEGACY_BADGE_CHANNEL    = "com.nearbyfundi/badge"

        private const val BADGE_PREFS = "badge_prefs"
        private const val BADGE_KEY   = "badge_count"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableSecureScreen()
    }

    override fun onResume() {
        super.onResume()
        enableSecureScreen()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        val securityHandler = MethodChannel.MethodCallHandler { call, result ->
            when (call.method) {
                "enableSecureScreen"    -> { enableSecureScreen();    result.success(true) }
                "disableSecureScreen"   -> { disableSecureScreen();   result.success(true) }
                "isSecureScreenEnabled" -> result.success(isSecureScreenEnabled())
                else                    -> result.notImplemented()
            }
        }

        val badgeHandler = MethodChannel.MethodCallHandler { call, result ->
            when (call.method) {
                "setBadgeCount" -> {
                    val count = call.argument<Number>("count")?.toInt() ?: 0
                    saveBadgeCount(count)
                    result.success(true)
                }
                "removeBadge", "clearBadge" -> {
                    saveBadgeCount(0)
                    result.success(true)
                }
                "getBadgeCount" -> result.success(getBadgeCount())
                else            -> result.notImplemented()
            }
        }

        MethodChannel(messenger, SECURITY_CHANNEL).setMethodCallHandler(securityHandler)
        MethodChannel(messenger, BADGE_CHANNEL).setMethodCallHandler(badgeHandler)
        MethodChannel(messenger, LEGACY_SECURITY_CHANNEL).setMethodCallHandler(securityHandler)
        MethodChannel(messenger, LEGACY_BADGE_CHANNEL).setMethodCallHandler(badgeHandler)
    }

    private fun enableSecureScreen() {
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    private fun disableSecureScreen() {
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    private fun isSecureScreenEnabled(): Boolean =
        (window.attributes.flags and WindowManager.LayoutParams.FLAG_SECURE) != 0

    private fun saveBadgeCount(count: Int) {
        getSharedPreferences(BADGE_PREFS, Context.MODE_PRIVATE)
            .edit()
            .putInt(BADGE_KEY, count.coerceAtLeast(0))
            .apply()
    }

    private fun getBadgeCount(): Int =
        getSharedPreferences(BADGE_PREFS, Context.MODE_PRIVATE)
            .getInt(BADGE_KEY, 0)
}