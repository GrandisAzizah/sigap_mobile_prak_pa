
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF5B4DE3);
  static const Color secondary = Color(0xFF886CF6);
  static const Color accent = Color(0xFFFFD166);
  static const Color light = Color(0xFFEDE6FF);
  static const Color background = Color(0xFFF8F9FB);

  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF292343);
  static const Color textSecondary = Color(0xFF77718B);

  static const Color success = Color(0xFF65B98A);
  static const Color warning = Color(0xFFFFB547);
  static const Color error = Color(0xFFE76F79);
  static const Color info = Color(0xFF64A6E8);
}

class AppTextStyle {
  // Font Poppins untuk heading dan button
  static TextStyle get heading => GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  // Font Inter untuk isi dan label
  static TextStyle get body => GoogleFonts.inter(
        color: AppColors.textPrimary,
      );

  static TextStyle get button => GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.white,
        error: AppColors.error,
      ),

      textTheme: TextTheme(
        displayLarge: AppTextStyle.heading.copyWith(fontSize: 32),
        displayMedium: AppTextStyle.heading.copyWith(fontSize: 28),
        headlineLarge: AppTextStyle.heading.copyWith(fontSize: 24),
        headlineMedium: AppTextStyle.heading.copyWith(fontSize: 20),
        titleLarge: AppTextStyle.heading.copyWith(fontSize: 18),
        bodyLarge: AppTextStyle.body.copyWith(fontSize: 16),
        bodyMedium: AppTextStyle.body.copyWith(fontSize: 14),
        bodySmall: AppTextStyle.body.copyWith(fontSize: 12),
        labelLarge: AppTextStyle.button.copyWith(fontSize: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyle.button,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.light,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.light,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
