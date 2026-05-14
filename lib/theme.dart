// lib/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🎨 Brand Colors
const Color primaryGreen = Color(0xFF2E7D32);
const Color darkGreen = Color(0xFF1B5E20);
const Color lightGreen = Color(0xFF66BB6A);

/// ☀️ LIGHT ECO THEME
ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.grey.shade100,
  primaryColor: primaryGreen,
  textTheme: GoogleFonts.poppinsTextTheme(), // 📝 Modern Font
  appBarTheme: AppBarTheme(
    titleTextStyle: GoogleFonts.poppins(
        fontSize: 19, fontWeight: FontWeight.w600, color: Colors.white),
    backgroundColor: primaryGreen,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    primary: primaryGreen,
    secondary: lightGreen,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      textStyle: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
    ),
  ),
);

/// 🌙 DARK ECO THEME
ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF121212),
  primaryColor: primaryGreen,
  textTheme: GoogleFonts.poppinsTextTheme(
    ThemeData(brightness: Brightness.dark).textTheme,
  ),
  appBarTheme: AppBarTheme(
    titleTextStyle: GoogleFonts.poppins(
        fontSize: 19, fontWeight: FontWeight.w600, color: Colors.white),
    backgroundColor: darkGreen,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  colorScheme: const ColorScheme.dark(
    primary: primaryGreen,
    secondary: lightGreen,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      textStyle: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
    ),
  ),
);