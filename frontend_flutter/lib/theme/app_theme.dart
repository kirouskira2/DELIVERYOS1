import 'package:flutter/material.dart';

/// Tema global do Delivery OS (Dark Mode / Blue Midnight)
/// Segue a estética de SaaS do Vale do Silício, conforme os requisitos do PRD.
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF020617), // slate-950
      primaryColor: const Color(0xFF2563EB), // blue-600
      
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF2563EB), // Brand
        secondary: Color(0xFF34D399), // Success (Emerald)
        error: Color(0xFFEF4444), // Danger (Red)
        surface: Color(0xFF0F172A), // Cards background (slate-900)
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF0F172A).withOpacity(0.8), // Glassmorphism base
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF1E293B), width: 1), // border-slate-800
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Inter', color: Color(0xFFF8FAFC), fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: Color(0xFFF8FAFC)),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: Color(0xFF94A3B8)), // text-slate-400
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF020617),
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
