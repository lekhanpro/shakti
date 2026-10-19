# Flutter embedding and plugin registrant
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
# Play Core (deferred components) is referenced by the embedding but not shipped.
-dontwarn com.google.android.play.core.**

# Shakti native layer (services/receivers are referenced from the manifest; keep names stable)
-keep class in.shakti.shakti.** { *; }

# another_telephony (SMS) - uses reflection-free code but keep to be safe, incl. background handler
-keep class com.shounakmulay.telephony.** { *; }

# flutter_local_notifications: Gson-serialised models
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# local_auth / biometric
-keep class androidx.biometric.** { *; }

# record, geolocator, torch, vibration (JNI/reflection-safe, but keep plugin entry points)
-keep class com.llfbandit.record.** { *; }
-keep class com.baseflow.** { *; }

# Kotlin metadata
-dontwarn kotlin.**
-dontwarn org.jetbrains.annotations.**
