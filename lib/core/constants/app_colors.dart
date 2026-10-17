import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors
  static const Color primaryLight = Color(0xFF6C5CE7);
  static const Color secondaryLight = Color(0xFFA29BFE);
  static const Color backgroundLight = Color(0xFFF8F9FE);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF2D3436);
  static const Color textSecondaryLight = Color(0xFF636E72);

  // Dark Mode Colors
  static const Color primaryDark = Color(0xFF8C7AE6);
  static const Color secondaryDark = Color(0xFF9C88FF);
  static const Color backgroundDark = Color(0xFF121222);
  static const Color surfaceDark = Color(0xFF1E1E30);
  static const Color textPrimaryDark = Color(0xFFF5F6FA);
  static const Color textSecondaryDark = Color(0xFFB2BEC3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF81ECEC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFF7675), Color(0xFF6C5CE7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient avatarCardGradient = LinearGradient(
    colors: [Color(0xFFA29BFE), Color(0xFF74B9FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
