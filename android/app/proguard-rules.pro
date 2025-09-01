# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Play Core rules (completely exclude to avoid conflicts)
-dontwarn com.google.android.play.core.**
-keep class !com.google.android.play.core.** { *; }

# 16 KBページサイズのネイティブライブラリアライメントをサポート
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Native

# General Android rules
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# gRPC and OkHttp rules to fix R8 issues
-keep class io.grpc.** { *; }
-keep class com.squareup.okhttp.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Keep reflection-related classes
-keep class java.lang.reflect.** { *; }
-keep class com.google.common.reflect.** { *; }

# Additional rules for missing classes
-dontwarn com.squareup.okhttp.**
-dontwarn io.grpc.okhttp.**
-dontwarn java.lang.reflect.**
-dontwarn com.google.common.reflect.**

# Keep your app's main package (corrected package name)
-keep class com.ikcoding.maikago.** { *; }