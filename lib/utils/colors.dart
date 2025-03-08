import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryAppBar = Color(0xFF03045E);
  static const Color primaryButton = Color(0xFF023E8A);

  // Secondary Colors
  static const Color secondaryButton = Color(0xFF0077B6);

  // Background Colors
  static const Color cardBackground = Color(0xFF0096C7);
  static const Color softBackground = Color(0xFF90E0EF);
  static const Color inputModelBackground = Color(0xFFADE8F4);
  static const Color scaffoldBackground = Color(0xFFCAF0F8);

  // Text and Elements
  static const Color jetBlack = Color(0xFF000000);
  static const Color subText = Color(0xFF333333);
  static const Color lightGray = Color(0xFFD3D3D3); // Light Gray

  static const Color mutedElements = Color(0xFF48CAE4);

  // Utility Colors
  static const Color whiteBar = Color(0xFFFFFFFF);
  static const Color dangerRed = Color(0xFFFF4D4D);
  static const Color successGreen = Color(0xFF2ECC71);
  static const Color grey = Color.fromARGB(255, 124, 124, 124);

  // Borders and Dividers
  static const Color borderDivider = Color(0xFFF0F0F0);
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [primaryAppBar, mutedElements], // Gradient colors
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const LinearGradient scafoldBackGroundGrandient = LinearGradient(
    colors: [scaffoldBackground, cardBackground], // Gradient colors
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
