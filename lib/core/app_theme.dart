import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// Brand color constants for reuse across both themes
class _AppColors {
  static const primary = Color(0xFF298E4D);
  static const secondary = Color(0xFFFA9527);

  // Dark mode surfaces
  static const darkBackground = Color(0xFF0F1412);
  static const darkSurface = Color(0xFF1A2420);
  static const darkCard = Color(0xFF1E2B26);
  static const darkNavBar = Color(0xFF151D1A);
  static const darkBorder = Color(0xFF2A3D35);

  // Dark mode primary tinted
  static const primaryDark = Color(0xFF38B058); // slightly brighter in dark
}

class AppTheme {
  // ── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _AppColors.primary,
        primary: _AppColors.primary,
        secondary: _AppColors.secondary,
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.light().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: _AppColors.primary,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: _AppColors.primary,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(color: Colors.black87),
        bodyMedium: GoogleFonts.plusJakartaSans(color: Colors.black54),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: _AppColors.primary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _AppColors.primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        indicatorColor: _AppColors.primary.withValues(alpha: 0.1),
        height: 65,
        labelTextStyle: WidgetStateProperty.resolveWith((_) {
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _AppColors.primary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _AppColors.primary, size: 24);
          }
          return const IconThemeData(color: Colors.black45, size: 24);
        }),
      ),
    );
  }

  // ── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: _AppColors.primaryDark,
        primary: _AppColors.primaryDark,
        secondary: _AppColors.secondary,
        surface: _AppColors.darkSurface,
        onSurface: Colors.white,
      ).copyWith(
        surface: _AppColors.darkSurface,
        onSurface: const Color(0xFFE8F0EC),
      ),
      scaffoldBackgroundColor: _AppColors.darkBackground,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: _AppColors.primaryDark,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: _AppColors.primaryDark,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: const Color(0xFFECF0EE),
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: const Color(0xFFCDD5D1),
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF8FA89E),
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: _AppColors.primaryDark,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: _AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFFECF0EE),
        shadowColor: Colors.black.withValues(alpha: 0.3),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _AppColors.primaryDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _AppColors.darkCard,
        hintStyle: const TextStyle(color: Color(0xFF5A7268)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: _AppColors.primaryDark,
            width: 1.5,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: _AppColors.darkCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: _AppColors.darkBorder, width: 1),
        ),
      ),
      dividerColor: _AppColors.darkBorder,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _AppColors.darkNavBar,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        indicatorColor: _AppColors.primaryDark.withValues(alpha: 0.15),
        height: 65,
        labelTextStyle: WidgetStateProperty.resolveWith((_) {
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _AppColors.primaryDark,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _AppColors.primaryDark, size: 24);
          }
          return const IconThemeData(color: Color(0xFF5A7268), size: 24);
        }),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF1E2B26),
        contentTextStyle: TextStyle(color: Color(0xFFCDD5D1)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

