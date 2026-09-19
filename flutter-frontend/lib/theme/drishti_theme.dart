import 'package:flutter/material.dart';

/// Centralized color palette for DRISHTI AI disaster response & relief platform.
///
/// Strictly enforces the exact hex values defined in the official DRISHTI design system.
class DrishtiColors {
  DrishtiColors._();

  // PRIMARY BRAND COLORS
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color deepNavy = Color(0xFF1E3A8A);
  static const Color darkNavyText = Color(0xFF0F172A);

  // EMERGENCY / ALERT COLORS
  static const Color emergencyRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF97316);
  static const Color alertYellow = Color(0xFFFBBF24);

  // SUCCESS / SAFETY COLORS
  static const Color successGreen = Color(0xFF22C55E);
  static const Color softGreen = Color(0xFFDCFCE7);

  // SUPPORTING COLORS
  static const Color lightBlue = Color(0xFFDBEAFE);
  static const Color purple = Color(0xFF8B5CF6);

  // NEUTRAL COLORS
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color secondaryText = Color(0xFF64748B);

  // SEMANTIC LIGHT BACKGROUNDS
  static const Color medicalLightRed = Color(0xFFFEE2E2);
  static const Color fireLightOrange = Color(0xFFFED7AA);
  static const Color accidentLightPurple = Color(0xFFEDE9FE);
  static const Color warningLightYellow = Color(0xFFFEF3C7);
  static const Color neutralLight = Color(0xFFF1F5F9);
  static const Color neutralDark = Color(0xFF334155);

  // CONVENIENT ALIASES
  static const Color purpleAccent = purple;
  static const Color medicalLight = medicalLightRed;
  static const Color fireLight = fireLightOrange;
  static const Color accidentLight = accidentLightPurple;
  static const Color warningLight = warningLightYellow;
  static const Color deepNavyBlue = deepNavy;
  static const Color neutralGrey = secondaryText;
  static const Color surfaceAlt = neutralLight;
  static const Color emergencyLight = medicalLightRed;
}

/// Centralized ThemeData and UI component styles for DRISHTI AI.
class DrishtiTheme {
  DrishtiTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: DrishtiColors.background,
      primaryColor: DrishtiColors.primaryBlue,
      colorScheme: const ColorScheme.light(
        primary: DrishtiColors.primaryBlue,
        secondary: DrishtiColors.deepNavy,
        surface: DrishtiColors.surface,
        error: DrishtiColors.emergencyRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: DrishtiColors.darkNavyText,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: DrishtiColors.surface,
        foregroundColor: DrishtiColors.darkNavyText,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: DrishtiColors.darkNavyText,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: DrishtiColors.primaryBlue),
      ),
      cardTheme: CardThemeData(
        color: DrishtiColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: DrishtiColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DrishtiColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DrishtiColors.darkNavyText,
          side: const BorderSide(color: DrishtiColors.border, width: 1.2),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DrishtiColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DrishtiColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DrishtiColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DrishtiColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DrishtiColors.emergencyRed),
        ),
        labelStyle: const TextStyle(color: DrishtiColors.secondaryText, fontSize: 13),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      ),
      dividerTheme: const DividerThemeData(
        color: DrishtiColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Common Card BoxDecorations
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: DrishtiColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: DrishtiColors.border, width: 1),
  );

  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
    color: DrishtiColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: DrishtiColors.border, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Common SOS Button Style
  static ButtonStyle get sosButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: DrishtiColors.emergencyRed,
    foregroundColor: Colors.white,
    elevation: 2,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    textStyle: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
    ),
  );
}
