import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Core Colors (Lighter, friendlier palette) ───
  // ─── Core Colors (Lighter, friendlier palette) ───
  static const Color primaryBg = Color(0xFF112118); // Slightly lighter than 0F1A13
  static const Color surfaceColor = Color(0xFF1A3324);
  static const Color cardColor = Color(0xFF20402E);
  static const Color cardLight = Color(0xFF2A523B);
  static const Color inputBg = Color(0xFF223F30);

  // ─── Accent Colors (Warm & vibrant) ───
  static const Color accentGreen = Color(0xFF4ADE80);
  static const Color emerald = Color(0xFF34D399);
  static const Color deepGreen = Color(0xFF16A34A);
  static const Color glowGreen = Color(0xFF86EFAC);
  static const Color tealAccent = Color(0xFF2DD4BF);
  static const Color gold = Color(0xFFFBBF24);
  static const Color warmOrange = Color(0xFFFB923C);

  // ─── Text Colors (Higher contrast for readability) ───
  static const Color textPrimary = Color(0xFFF0FDF4);
  static const Color textSecondary = Color(0xFFA7F3D0);
  static const Color textMuted = Color(0xFF6EE7B7);

  // ─── Bubble Colors (Distinct, easy to differentiate) ───
  static const Color userBubble = Color(0xFF1E3A5F);
  static const Color userBubbleGrad = Color(0xFF153050);
  static const Color aiBubble = Color(0xFF1A3D28);
  static const Color aiBubbleGrad = Color(0xFF122D1C);

  // ─── Orb Colors ───
  static const Color orbCenter = Color(0xFF4ADE80);
  static const Color orbMiddle = Color(0xFF2DD4BF);
  static const Color orbOuter = Color(0xFF065F46);
  static const Color orbGlow = Color(0xFF4ADE80);
  static const Color orbRecording = Color(0xFFF87171);
  static const Color orbProcessing = Color(0xFFFBBF24);

  // ─── Gradients ───
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF112118), Color(0xFF162E21), Color(0xFF112118)],
  );

  static const LinearGradient userBubbleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E4876), Color(0xFF163B60)],
  );

  static const LinearGradient aiBubbleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E4D30), Color(0xFF143A22)],
  );

  // ─── Glassmorphism ───
  static BoxDecoration glassCard({double opacity = 0.10}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.08),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration glassInput() {
    return BoxDecoration(
      color: inputBg.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: accentGreen.withValues(alpha: 0.2),
        width: 1,
      ),
    );
  }

  // ─── Theme Data ───
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryBg,
      primaryColor: accentGreen,
      colorScheme: const ColorScheme.dark(
        primary: accentGreen,
        secondary: emerald,
        surface: surfaceColor,
        error: Color(0xFFF87171),
        onPrimary: primaryBg,
        onSecondary: primaryBg,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: accentGreen,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: accentGreen,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: GoogleFonts.inter(
          color: textMuted,
          fontSize: 14,
        ),
      ),
      iconTheme: const IconThemeData(color: textSecondary),
      dividerColor: Colors.white.withValues(alpha: 0.08),
      splashColor: accentGreen.withValues(alpha: 0.12),
      highlightColor: accentGreen.withValues(alpha: 0.06),
    );
  }
}
