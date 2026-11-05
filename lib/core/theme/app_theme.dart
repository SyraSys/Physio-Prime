import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Brand Palette from Developer Handoff & Apple Color Balance
  static const Color primary = Color(0xFF0891B2);      // Primary cyan / teal
  static const Color deepTeal = Color(0xFF0E7490);     // Pressed states & emphasis
  static const Color darkTeal = Color(0xFF155E75);     // Deep accents
  static const Color accentTeal = Color(0xFF14B8A6);   // Gradient middle
  static const Color brightCyan = Color(0xFF22D3EE);   // Gradient highlight
  static const Color background = Color(0xFFF6FBF9);   // Calming soft mint page background
  static const Color surfaceSoft = Color(0xFFECFEFF);  // Soft cyan surfaces
  static const Color bodyText = Color(0xFF475569);     // Slate body copy
  static const Color headingText = Color(0xFF0F172A);  // Deep slate headings
  static const Color borderSoft = Color(0xFFE2EFEA);   // Card/navigation hairline border
  static const Color white = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFEF4444);

  // Apple-grade Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0891B2), Color(0xFF0E7490), Color(0xFF0F766E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF0891B2), Color(0xFF14B8A6), Color(0xFF22D3EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accentTeal,
        surface: AppColors.white,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // Optical sizing: negative tracking on large text, tight leading on headings, looser on body
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          height: 1.18,
          color: AppColors.headingText,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          height: 1.24,
          color: AppColors.headingText,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          height: 1.28,
          color: AppColors.headingText,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: AppColors.headingText,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.0,
          height: 1.5,
          color: AppColors.bodyText,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.0,
          height: 1.45,
          color: AppColors.bodyText,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          color: AppColors.white,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.25, // Positive tracking for small tags
          color: AppColors.bodyText,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.headingText,
        ),
        iconTheme: const IconThemeData(color: AppColors.headingText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.borderSoft, width: 0.8),
        ),
      ),
    );
  }
}
