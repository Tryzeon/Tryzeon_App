import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _primary = Color(0xFF9D84FF); // Lavender/Purple
  static const Color _onPrimary = Colors.white;
  static const Color _secondary = Color(0xFF76E4C6); // Mint
  static const Color _onSecondary = Color(0xFF1A3B32);
  static const Color _tertiary = Color(0xFFFF8FB1); // Neon Pink
  static const Color _surface = Colors.white;
  static const Color _error = Color(0xFFFF6B6B);

  static ThemeData get lightTheme {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      primary: _primary,
      onPrimary: _onPrimary,
      secondary: _secondary,
      onSecondary: _onSecondary,
      tertiary: _tertiary,
      surface: _surface,
      error: _error,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseColorScheme,

      // Typography
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        displaySmall: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Colors.black87,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.black54,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
