# ML Kit Text Recognition: Ignorar módulos de idiomas no utilizados para evitar errores de R8
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Reglas generales para Google Play Services y ML Kit
-dontwarn com.google.android.gms.internal.**
-dontwarn com.google.mlkit.common.internal.model.ModelUtils

# Evita que el build falle por advertencias de clases faltantes en librerías externas
-ignorewarnings
