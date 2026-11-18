# ============================================================
#  Fundi App — ProGuard / R8 rules
#  Required because isMinifyEnabled = true for release.
# ============================================================

# ────────────────────────────────────────────────────────────
# FLUTTER CORE
# ────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ────────────────────────────────────────────────────────────
# APP MODELS  (applicationId = com.fundapp)
# ────────────────────────────────────────────────────────────
-keep class com.fundapp.** { *; }
-keepclassmembers class com.fundapp.** {
    <fields>;
    <methods>;
}

# ────────────────────────────────────────────────────────────
# FIREBASE / FCM
# ────────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ────────────────────────────────────────────────────────────
# FLUTTER LOCAL NOTIFICATIONS
# ────────────────────────────────────────────────────────────
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }

# ────────────────────────────────────────────────────────────
# ML KIT — FACE DETECTION  (Step 4 face capture)
# ────────────────────────────────────────────────────────────
-keep class com.google.mlkit.** { *; }
-keep class com.google.mlkit.vision.face.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_face.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_face_bundled.** { *; }
-dontwarn com.google.mlkit.**

# ML Kit model files — the obfuscator must not rename or strip them
-keep class com.google.mlkit.common.model.** { *; }
-keep class com.google.mlkit.common.sdkinternal.** { *; }
-keep class com.google.mlkit.vision.face.internal.** { *; }

# ────────────────────────────────────────────────────────────
# CAMERA  (camera plugin uses CameraX + Camera2 under the hood)
# ────────────────────────────────────────────────────────────
-keep class androidx.camera.** { *; }
-keep class androidx.camera.core.** { *; }
-keep class androidx.camera.camera2.** { *; }
-keep class androidx.camera.lifecycle.** { *; }
-dontwarn androidx.camera.**

# ────────────────────────────────────────────────────────────
# BIOMETRIC  (local_auth — Step 3 fingerprint)
# ────────────────────────────────────────────────────────────
-keep class androidx.biometric.** { *; }
-keep class androidx.biometric.BiometricPrompt { *; }
-keep class androidx.biometric.BiometricManager { *; }
-dontwarn androidx.biometric.**

# ────────────────────────────────────────────────────────────
# SHORTCUT BADGER  (app_badge_plus)
# ────────────────────────────────────────────────────────────
-keep class me.leolin.shortcutbadger.** { *; }
-dontwarn me.leolin.shortcutbadger.**

# ────────────────────────────────────────────────────────────
# GEO LOCATION  (geolocator)
# ────────────────────────────────────────────────────────────
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# ────────────────────────────────────────────────────────────
# SHARED PREFERENCES / SECURE STORAGE
# ────────────────────────────────────────────────────────────
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**

# ────────────────────────────────────────────────────────────
# DIO / DART — no OkHttp in the APK
#   (dio is pure Dart over dart:io, no native network classes)
#   Nothing to keep here.
# ────────────────────────────────────────────────────────────

# ────────────────────────────────────────────────────────────
# ANNOTATIONS + GENERIC SIGNATURES
# ────────────────────────────────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes Exceptions

# ────────────────────────────────────────────────────────────
# SUPPRESS WARNINGS FOR THIRD-PARTY LIBS
# ────────────────────────────────────────────────────────────
-dontwarn javax.annotation.**
-dontwarn kotlinx.**
-dontwarn org.jetbrains.annotations.**

# Keep Kotlin metadata (needed for reflection used by plugins)
-keep class kotlin.Metadata { *; }
-keep class kotlin.reflect.** { *; }
-dontwarn kotlin.reflect.**