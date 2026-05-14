-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

-keepattributes JavascriptInterface
-keepattributes *Annotation*

-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}

-optimizestep -1
-keep class com.razorpay.** {*;}
-keepclasseswithmembers class com.razorpay.** {*;}
-keepattributes *Annotation*
-keepattributes JavascriptInterface
