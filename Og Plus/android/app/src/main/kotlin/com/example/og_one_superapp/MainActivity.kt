package com.ogonegroup.ogplusapp

import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val securityChannel = "og.one.security"
    private val badgeChannel = "com.ogonegroup.ogplusapp/badge"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // ── Security channel ──
        MethodChannel(messenger, securityChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableSecureFlag" -> {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(null)
                }

                "isDeveloperMode" -> {
                    val adbEnabled = Settings.Global.getInt(
                        contentResolver, Settings.Global.ADB_ENABLED, 0
                    ) == 1
                    val developerOptions = Settings.Global.getInt(
                        contentResolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0
                    ) == 1
                    result.success(adbEnabled || developerOptions)
                }

                "isEmulator" -> result.success(isEmulator())

                "openDeveloperSettings" -> {
                    try {
                        startActivity(
                            Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                    } catch (e: Exception) {
                        // Some OEMs hide this screen; fall back to main settings
                        startActivity(
                            Intent(Settings.ACTION_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                    }
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        // ── Badge channel ──
        // Android launcher badges come from posted notifications, so this
        // only persists the count locally.
        MethodChannel(messenger, badgeChannel).setMethodCallHandler { call, result ->
            val prefs = getSharedPreferences("badge", Context.MODE_PRIVATE)
            when (call.method) {
                "setBadgeCount" -> {
                    val count = call.argument<Int>("count") ?: 0
                    prefs.edit().putInt("count", count).apply()
                    result.success(null)
                }

                "removeBadge" -> {
                    prefs.edit().putInt("count", 0).apply()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun isEmulator(): Boolean {
        return Build.FINGERPRINT.startsWith("generic")
                || Build.FINGERPRINT.contains("emulator")
                || Build.MODEL.contains("Emulator")
                || Build.MODEL.contains("Android SDK built for")
                || Build.MANUFACTURER.contains("Genymotion")
                || Build.HARDWARE.contains("goldfish")
                || Build.HARDWARE.contains("ranchu")
                || Build.PRODUCT.contains("sdk")
                || Build.PRODUCT.contains("emulator")
    }
}