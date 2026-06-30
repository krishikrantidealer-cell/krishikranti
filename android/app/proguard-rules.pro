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

