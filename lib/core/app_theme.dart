import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32), // Deep green seed
        primary: const Color(0xFF2E7D32),
        secondary: const Color(0xFF689F38),
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.light().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1B5E20),
        ),
        headlineMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1B5E20),
        ),
        titleLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        bodyLarge: GoogleFonts.outfit(color: Colors.black87),
        bodyMedium: GoogleFonts.outfit(color: Colors.black54),
        labelLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2E7D32),
        ),
      ),

      // Modern, elevated app bar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // Minimal, modern buttons (high-end ERP style)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),

      // Clean, rounded input fields (ERP ready)
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
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
        ),
      ),

      // Professional card styling
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
