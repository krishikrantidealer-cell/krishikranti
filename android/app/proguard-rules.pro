-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

-keepattributes JavascriptInterface
-keepattributes *Annotation*

-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}

-keep class com.razorpay.** {*;}
-keepclasseswithmembers class com.razorpay.** {*;}
-keepattributes *Annotation*
-keepattributes JavascriptInterface

# Keep Facebook SDK classes to prevent stripping during minification/obfuscation
-keep class com.facebook.** { *; }
-dontwarn com.facebook.**

# Flutter Downloader
-keep class vn.hunghd.flutterdownloader.** { *; }

# Firebase Messaging & Cloud Messaging
-keep class com.google.firebase.messaging.** { *; }
-keep class io.flutter.plugins.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

