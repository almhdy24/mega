# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Plugins
-keep class com.tekartik.sqflite.** { *; }
-keepclassmembers class com.tekartik.sqflite.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keepclassmembers class io.flutter.plugins.sharedpreferences.** { *; }

# WorkManager and App Startup
-keep class androidx.work.** { *; }
-keepclassmembers class androidx.work.** { *; }
-keep class androidx.startup.** { *; }
-keepclassmembers class androidx.startup.** { *; }
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
-keep class * extends androidx.work.Worker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
-keep class * extends androidx.startup.Initializer {
    public <init>();
}

# Kotlin Coroutines
-keep class kotlinx.coroutines.** { *; }

# Keep native app classes and workers
-keep class com.elmahdi.mega.** { *; }
-keepclassmembers class com.elmahdi.mega.** { *; }

# Preserve annotations and attributes
-keepattributes *Annotation*,EnclosingMethod,InnerClasses,Signature
-dontwarn androidx.work.**

