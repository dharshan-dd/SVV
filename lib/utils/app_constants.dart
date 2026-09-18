import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color primaryGreenLight = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF81C784);
  static const Color creditGreen = Color(0xFF2E7D32);
  static const Color debitOrange = Color(0xFFEF6C00);
  static const Color debitOrangeLight = Color(0xFFFF9800);
  static const Color darkText = Color(0xFF212121);
  static const Color lightText = Color(0xFF757575);
  static const Color bgLight = Color(0xFFF5F5F5);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color infoBlue = Color(0xFF1976D2);
}

class AppConstants {
  static const String appName = 'SVV Finance';
  static const String appTagline = 'Microfinance Collection Management';
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double inputBorderRadius = 8.0;
}

class AppTextStyles {
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
  );
}
