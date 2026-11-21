# Flutter ProGuard / R8 keep rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# WebRTC & Dav1dDecoder (Jitsi Meet SDK / Telehealth)
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# Jitsi Meet SDK & React Native
-keep class org.jitsi.meet.sdk.** { *; }
-dontwarn org.jitsi.meet.sdk.**
-keep class com.facebook.react.** { *; }
-dontwarn com.facebook.react.**
-keep class com.facebook.jni.** { *; }
-dontwarn com.facebook.jni.**
-keepattributes *Annotation*
-dontwarn okio.**
-dontwarn javax.annotation.**

# Razorpay Payment SDK
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
