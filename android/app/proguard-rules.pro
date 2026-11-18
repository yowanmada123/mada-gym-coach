# ML Kit Text Recognition: aplikasi hanya memakai pengenal huruf Latin.
# Plugin google_mlkit_text_recognition merujuk modul bahasa lain (Cina, Devanagari,
# Jepang, Korea) yang tidak disertakan — abaikan referensi tersebut saat R8.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
