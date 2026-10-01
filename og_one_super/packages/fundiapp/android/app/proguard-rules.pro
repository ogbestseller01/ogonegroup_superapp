# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Firebase Messaging / Cloud Messaging
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# flutter_local_notifications
-keep class com.dexterous.** { *; }
-keep class * extends com.dexterous.flutterlocalnotifications.** { *; }

# Dio / OkHttp (used internally)
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Gson-style / JSON model classes — keep your data models from being stripped
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.example.fundiapp.** { *; }

# ShortcutBadger
-keep class me.leolin.shortcutbadger.** { *; }
-dontwarn me.leolin.shortcutbadger.**