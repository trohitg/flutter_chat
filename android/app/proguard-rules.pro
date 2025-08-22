# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Play Core classes (for deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Kotlin metadata
-keep class kotlin.Metadata { *; }

# Keep HTTP client classes
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }

# Keep AndroidX classes
-keep class androidx.** { *; }
-dontwarn androidx.**

# Keep Google classes
-keep class com.google.** { *; }
-dontwarn com.google.**

# Performance optimizations
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 3
-allowaccessmodification
-dontpreverify

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}