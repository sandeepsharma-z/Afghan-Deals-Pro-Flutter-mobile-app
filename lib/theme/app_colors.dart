import 'package:flutter/material.dart';

class AppColors {
  // Gradient colors (splash background)
  static const Color gradientTop = Color(0xFFCEEFFF);
  static const Color gradientMid = Color(0xFF84D2FF);
  static const Color gradientBottom = Color(0xFFCEEFFF);

  // Primary button color
  static const Color primary = Color(0xFF1E56A6);

  // Text colors
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color textLight = Color(0xFFFFFFFF);

  // Background
  static const Color white = Color(0xFFFFFFFF);
  static const Color scaffoldBg = Color(0xFFF8FAFC);

  // Border
  static const Color borderColor = Color(0xFFE5E7EB);

  // Splash gradient
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      gradientTop,
      gradientMid,
      gradientMid,
      gradientTop,
    ],
    stops: [0.0, 0.35, 0.65, 1.0],
  );
}
