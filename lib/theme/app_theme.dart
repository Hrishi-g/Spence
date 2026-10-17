import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0F0F12);
  static const Color surface = Color(0xFF1B1B1F);
  static const Color surfaceLight = Color(0xFF26262B);
  static const Color accentGold = Color(0xFFFFB800);
  static const Color primaryText = Color(0xFFEEEEEE);
  static const Color secondaryText = Color(0xFF9E9E9E);
  static const Color border = Color(0xFF2C2C32);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accentGold,
      colorScheme: const ColorScheme.dark(
        primary: accentGold,
        surface: surface,
        background: background,
        onSurface: primaryText,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: primaryText),
        titleTextStyle: TextStyle(
          color: primaryText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accentGold,
        unselectedItemColor: secondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
    );
  }
}

