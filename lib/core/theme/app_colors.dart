import 'package:flutter/material.dart';

class AppColors {
  // Primary — App Blue
  static const primary = Color(0xFF1E56A6);
  static const primaryDark = Color(0xFF153D7A);
  static const primaryLight = Color(0xFFE8F0FB);

  // Accent
  static const red = Color(0xFFC92325);
  static const redLight = Color(0xFFFEEBEB);

  // Neutrals
  static const black = Color(0xFF090909);
  static const grey = Color(0xFF7C7C7C);
  static const greyLight = Color(0xFFF6F6F6);
  static const greyBorder = Color(0xFFE0E0E0);
  static const white = Color(0xFFFFFFFF);

  // Backgrounds
  static const background = Color(0xFFFFFFFF);
  static const surfaceGrey = Color(0xFFF8F8F8);
  static const scaffoldBg = Color(0xFFF8FAFC);

  // Status
  static const success = Color(0xFF027329);
  static const warning = Color(0xFFFFA000);
  static const error = Color(0xFFC92325);

  // Splash gradient
  static const gradientTop = Color(0xFFCEEFFF);
  static const gradientMid = Color(0xFF84D2FF);

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment(0.19, -1.0),
    end: Alignment(-0.19, 1.0),
    colors: [
      Color(0xFFCEEFFF),
      Color(0xFF84D2FF),
      Color(0xFF84D2FF),
      Color(0xFFCEEFFF),
      Color(0xFF84D2FF),
      Color(0xFFCEEFFF),
    ],
    stops: [0.0, 0.3029, 0.3029, 0.5577, 0.8077, 1.0],
  );

  // Bottom nav
  static const navActive = Color(0xFF2258A8);
  static const sellLeft = Color(0xFF3B77FE);
  static const sellRight = Color(0xFF1D57A7);
}
