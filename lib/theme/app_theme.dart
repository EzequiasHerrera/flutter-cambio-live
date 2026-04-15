import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFFF9900);
  static const Color infoBlue = Color(0xFFE8F2FC);
  static const Color infoBlueDark = Color(0xFF2F79B8);
  static const double radius = 16;

  // 🌨️ LA SOMBRA AHORA RECIBE EL COLORSCHEME
  // Esto permite que la sombra cambie si estamos en modo oscuro
  static BoxShadow getHardShadow(ColorScheme colorScheme, {bool isPrimary = false}) {
    return BoxShadow(
      color: isPrimary ? colorScheme.shadow : colorScheme.outlineVariant,
      offset: const Offset(0, 6),
      blurRadius: 0,
    );
  }

  // --- MODO CLARO ---
  static ThemeData get lightTheme {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      tertiary: infoBlueDark,
      tertiaryContainer: infoBlue,
      brightness: Brightness.light,
      shadow: const Color(0xFFEB7914), // Sombra naranja para modo claro
      outlineVariant: const Color(0xFFE4E4E4), // Sombra gris para modo claro
    );

    return _buildTheme(scheme);
  }

  // --- MODO OSCURO ---
  static ThemeData get darkTheme {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      tertiary: infoBlueDark,
      tertiaryContainer: infoBlue,
      brightness: Brightness.dark,
      shadow: const Color(0xFF8A4500), // Sombra naranja oscura para modo dark
      outlineVariant: const Color(0xFF2A2A2A), // Sombra casi negra para modo dark
    );

    return _buildTheme(scheme);
  }

  // --- CONSTRUCTOR DE TEMA (Para no repetir código) ---
  static ThemeData _buildTheme(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(color: scheme.outline.withOpacity(0.1), width: 1),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}