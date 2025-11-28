import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Crestadel Premium Theme - Crypto + Estate + Delicacy
  static const Color primaryColor = Color(0xFFD4AF37); // Royal Gold
  static const Color secondaryColor = Color(0xFF1A1A2E); // Deep Navy
  static const Color accentColor = Color(0xFFE8D5B7); // Champagne
  static const Color backgroundColor = Color(0xFF0A0A0F); // Obsidian Black
  static const Color surfaceColor = Color(0xFF141420); // Dark Charcoal
  static const Color glassColor = Color(0x1AFFFFFF); // White with low opacity
  
  // Additional Crestadel colors
  static const Color crownGold = Color(0xFFFFD700);
  static const Color royalPurple = Color(0xFF6B3FA0);
  static const Color emeraldGreen = Color(0xFF50C878);
  static const Color rubyRed = Color(0xFFE0115F);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: surfaceColor,
      ),
      textTheme: GoogleFonts.playfairDisplayTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white).copyWith(
        bodyLarge: GoogleFonts.outfit(color: Colors.white),
        bodyMedium: GoogleFonts.outfit(color: Colors.white),
        bodySmall: GoogleFonts.outfit(color: Colors.white),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static BoxDecoration get glassDecoration => BoxDecoration(
    color: glassColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 1),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withValues(alpha: 0.1),
        blurRadius: 16,
        spreadRadius: 4,
      ),
    ],
  );

  // Premium gradient for Crestadel
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD4AF37), // Royal Gold
      Color(0xFFE8D5B7), // Champagne
      Color(0xFFD4AF37), // Royal Gold
    ],
  );

  // Castle gradient background
  static const LinearGradient castleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0A0A0F),
      Color(0xFF1A1A2E),
      Color(0xFF0A0A0F),
    ],
  );
}
