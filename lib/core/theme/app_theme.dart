import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    // Use the new ThemeData.light(useMaterial3: true) constructor
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: const Color(0xFF146C43), // emerald green
        secondary: const Color(0xFFD4A017), // golden accent
      ),
      textTheme: GoogleFonts.playfairDisplayTextTheme(
          base.textTheme), // Replaces serifTextTheme
      chipTheme: base.chipTheme.copyWith(
        selectedColor: const Color(0xFF146C43)
            .withValues(alpha: 0.12), // replaces withOpacity()
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF146C43),
        elevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF146C43),
          ),
        ),
      ),
      scaffoldBackgroundColor: Colors.grey[50],
      cardTheme: const CardTheme(
        elevation: 0.3,
        margin: EdgeInsets.all(4),
      ),
    );
  }
}
