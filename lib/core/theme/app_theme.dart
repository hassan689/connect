import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary color used throughout the app
  static const Color primaryColor = Color(0xFF00C7BE);
  
  // Professional font combinations
  // Headings: Inter (clean, modern, professional)
  // Body: Roboto (highly readable)
  // Buttons: Poppins (friendly, approachable)
  // Special elements: Montserrat (elegant)
  
  // Heading styles - Inter for clean, professional look
  static TextStyle get heading1 => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    letterSpacing: -0.5,
  );
  
  static TextStyle get heading2 => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    letterSpacing: -0.3,
  );
  
  static TextStyle get heading3 => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    letterSpacing: -0.2,
  );
  
  static TextStyle get heading4 => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    letterSpacing: -0.1,
  );
  
  // Body text styles - Roboto for excellent readability
  static TextStyle get bodyLarge => GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.black,
    height: 1.5,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.black,
    height: 1.4,
  );
  
  static TextStyle get bodySmall => GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.black54,
    height: 1.3,
  );
  
  // Caption and small text - Roboto for consistency
  static TextStyle get caption => GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.black54,
    height: 1.2,
  );
  
  // Button text - Poppins for friendly, approachable feel
  static TextStyle get button => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.2,
  );
  
  // Input styles - Roboto for readability
  static TextStyle get input => GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.black,
    height: 1.4,
  );
  
  static TextStyle get inputHint => GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.black54,
    height: 1.4,
  );
  
  // Special text styles for different purposes
  static TextStyle get appBarTitle => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    letterSpacing: -0.1,
  );
  
  static TextStyle get cardTitle => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    letterSpacing: -0.1,
  );
  
  static TextStyle get priceText => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    letterSpacing: 0.2,
  );
  
  static TextStyle get statusText => GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    letterSpacing: 0.5,
  );
  
  static TextStyle get navigationText => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.black,
    letterSpacing: 0.1,
  );
  
  // App theme data
  static ThemeData get lightTheme => ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    textTheme: TextTheme(
      displayLarge: heading1,
      displayMedium: heading2,
      displaySmall: heading3,
      headlineMedium: heading4,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: button,
      labelMedium: caption,
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: inputHint,
      labelStyle: bodyMedium,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        textStyle: button,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      titleTextStyle: appBarTitle,
      iconTheme: const IconThemeData(color: Colors.black),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
} 