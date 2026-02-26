/// Lumina Lanka - App Theme
/// iOS 26-inspired theme with glassmorphism support
/// 
/// Color palette:
/// - Background: #000000 to #1C1C1E
/// - Accent Green: #30D158 (working lights)
/// - Accent Red: #FF453A (faulty lights)
/// - Accent Amber: #FFD60A (maintenance)
/// - Accent Blue: #0A84FF (info/draft)
library;

import 'package:flutter/material.dart';

/// Core color constants for the application
class AppColors {
  // Prevent instantiation
  AppColors._();
  
  // Background colors
  static const Color bgPrimary = Color(0xFF000000);
  static const Color bgSecondary = Color(0xFF1C1C1E);
  static const Color bgTertiary = Color(0xFF2C2C2E);
  static const Color bgElevated = Color(0xFF3A3A3C);
  
  // Glassmorphism
  static Color bgGlass = const Color(0xFF1C1C1E).withOpacity(0.7);
  static Color bgGlassLight = const Color(0xFF2C2C2E).withOpacity(0.5);
  
  // Accent colors (status orbs)
  static const Color accentGreen = Color(0xFF30D158);   // Working
  static const Color accentRed = Color(0xFFFF453A);     // Faulty
  static const Color accentAmber = Color(0xFFFFD60A);   // Maintenance
  static const Color accentBlue = Color(0xFF0A84FF);    // Info/Draft
  
  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF636366);
  
  // Border colors
  static const Color borderPrimary = Color(0xFF3A3A3C);
  static Color borderGlass = Colors.white.withOpacity(0.1);
  
  // Semantic colors
  static const Color success = accentGreen;
  static const Color error = accentRed;
  static const Color warning = accentAmber;
  static const Color info = accentBlue;
}

/// Glow effects for map markers
class GlowStyles {
  GlowStyles._();
  
  static List<BoxShadow> greenGlow = [
    BoxShadow(
      color: AppColors.accentGreen.withOpacity(0.6),
      blurRadius: 12,
      spreadRadius: 4,
    ),
  ];
  
  static List<BoxShadow> redGlow = [
    BoxShadow(
      color: AppColors.accentRed.withOpacity(0.7),
      blurRadius: 16,
      spreadRadius: 6,
    ),
  ];
  
  static List<BoxShadow> amberGlow = [
    BoxShadow(
      color: AppColors.accentAmber.withOpacity(0.6),
      blurRadius: 12,
      spreadRadius: 4,
    ),
  ];
  
  static List<BoxShadow> blueGlow = [
    BoxShadow(
      color: AppColors.accentBlue.withOpacity(0.5),
      blurRadius: 10,
      spreadRadius: 3,
    ),
  ];
}

/// Application theme configuration
class AppTheme {
  AppTheme._();
  
  /// Dark theme matching iOS 26 aesthetic
  static ThemeData get darkTheme {
    return ThemeData(
      platform: TargetPlatform.iOS,
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'GoogleSansFlex',
      
      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentGreen,
        secondary: AppColors.accentBlue,
        surface: AppColors.bgSecondary,
        error: AppColors.accentRed,
        onPrimary: AppColors.textPrimary,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textPrimary,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.bgPrimary,
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'GoogleSansFlex', 
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(
          color: AppColors.accentBlue,
        ),
      ),
      
      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgSecondary,
        selectedItemColor: AppColors.accentGreen,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      
      // Cards
      cardTheme: CardThemeData(
        color: AppColors.bgSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.borderGlass),
        ),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGreen,
          foregroundColor: AppColors.bgPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'GoogleSansFlex', 
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderPrimary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'GoogleSansFlex', 
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentBlue,
          textStyle: const TextStyle(
            fontFamily: 'GoogleSansFlex', 
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(
          fontFamily: 'GoogleSansFlex', 
          color: AppColors.textTertiary,
          fontSize: 16,
        ),
      ),
      
      // Bottom sheets
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      
      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Dividers
      dividerTheme: const DividerThemeData(
        color: AppColors.borderPrimary,
        thickness: 0.5,
      ),
      
      // Icons
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),
      
      // Text theme
      textTheme: _textTheme,
    );
  }

  /// Light theme matching iOS aesthetic
  static ThemeData get lightTheme {
    return ThemeData(
      platform: TargetPlatform.iOS,
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'GoogleSansFlex',
      
      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentGreen,
        secondary: AppColors.accentBlue,
        surface: Colors.white,
        error: AppColors.accentRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black,
        onError: Colors.white,
      ),
      
      // Scaffold (iOS light grey background)
      scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF2F2F7),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'GoogleSansFlex', 
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        iconTheme: IconThemeData(
          color: AppColors.accentBlue,
        ),
      ),
      
      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.accentGreen,
        unselectedItemColor: Color(0xFF8E8E93),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      
      // Cards
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'GoogleSansFlex', 
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Color(0xFFE5E5EA)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'GoogleSansFlex', 
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentBlue,
          textStyle: const TextStyle(
            fontFamily: 'GoogleSansFlex', 
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(
          fontFamily: 'GoogleSansFlex', 
          color: Color(0xFF8E8E93),
          fontSize: 16,
        ),
      ),
      
      // Bottom sheets
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      
      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Dividers
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E5EA),
        thickness: 0.5,
      ),
      
      // Icons
      iconTheme: const IconThemeData(
        color: Color(0xFF8E8E93),
        size: 24,
      ),
      
      // Text theme (apply dark text colors for light mode)
      textTheme: _textTheme.apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
    );
  }
  
  /// Custom text theme using GoogleSansFlex
  static TextTheme get _textTheme {
    return const TextTheme(
      // Display
      displayLarge: TextStyle(
        fontFamily: 'GoogleSansFlex', 
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      displayMedium: TextStyle(
        fontFamily: 'GoogleSansFlex', 
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      displaySmall: TextStyle(
        fontFamily: 'GoogleSansFlex', 
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      
      // Headline
      headlineLarge: TextStyle(
        fontFamily: 'GoogleSansFlex', 
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'GoogleSansFlex', 
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'GoogleSansFlex', 
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      
      // Title
      titleLarge: TextStyle(
        fontFamily: 'GoogleSansFlex', 
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'GoogleSansFlex', 
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontFamily: 'GoogleSansFlex', 
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
      ),
      
      // Body
      bodyLarge: TextStyle(
        fontFamily: 'GoogleSansFlex', 
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'GoogleSansFlex', 
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodySmall: TextStyle(
        fontFamily: 'GoogleSansFlex', 
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      
      // Label
      labelLarge: TextStyle(
        fontFamily: 'GoogleSansFlex', 
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontFamily: 'GoogleSansFlex', 
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontFamily: 'GoogleSansFlex', 
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
