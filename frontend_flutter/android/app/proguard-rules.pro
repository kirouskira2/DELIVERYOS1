# Flutter ProGuard Rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Core (deferred components) — Required by Flutter engine
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.splitcompat.SplitCompatApplication { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Supabase / GoTrue / PostgREST / Realtime
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# HTTP / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Kotlin
-dontwarn kotlinx.coroutines.**
-dontwarn kotlin.**

# Keep annotations
-keepattributes *Annotation*
