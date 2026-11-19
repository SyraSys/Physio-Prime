# Jitsi Meet SDK ProGuard / R8 keep rules
-keep class org.jitsi.meet.sdk.** { *; }
-keep class com.facebook.react.** { *; }
-keep class com.facebook.jni.** { *; }
-keepattributes *Annotation*
-dontwarn org.jitsi.meet.sdk.**
