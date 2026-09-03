import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF111827);
  static const Color surfaceSecondary = Color(0xFFF3F4F6);
  static const Color surfaceTertiary = Color(0xFFE5E7EB);
  static const Color muted = Color(0xFF6B7280);
  static const Color brand = Color(0xFF0073E6);
  static const Color brandSecondary = Color(0xFF0059B2);
  static const Color brandTertiary = Color(0xFFE6F0FD);
  static const Color onBrand = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderStrong = Color(0xFFD1D5DB);
  static const Color overlay = Color(0x8C0F1115);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double x2l = 32.0;
  static const double x3l = 48.0;
}

class AppRadius {
  static const double sm = 6.0;
  static const double md = 12.0;
  static const double lg = 20.0;
  static const double pill = 999.0;
}

ThemeData getAppTheme() {
  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
  );
  
  return baseTheme.copyWith(
    scaffoldBackgroundColor: AppColors.surface,
    colorScheme: const ColorScheme.light(
      primary: AppColors.brand,
      secondary: AppColors.brandSecondary,
      surface: AppColors.surface,
      error: AppColors.error,
      onSurface: AppColors.onSurface,
    ),
    textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
  );
}
