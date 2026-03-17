import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Purple header (#6A1B9A)
  // static const Color primary = Color(0xFF6A1B9A);
  // static const Color primaryDark = Color(0xFF4A148C);
  // static const Color primaryLight = Color(0xFF9C27B0);
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryLight = Color(0xFF6F66E6);
  static const Color primaryLightMew = Color(0xFFF9E7FF);


  // Background Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color sidebarBackground = Color(0xFFF5F5F5);
  static const Color sidebarSelected = Color(0xFFE0E0E0);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textWhite = Color(0xFFFFFFFF);
  
  // Score Circle Colors (STRICT RULES)
  static const Color scoreRed = Color(0xFFE53935);        // 0.0 - 2.0
  static const Color scoreOrange = Color(0xFFFF6F00);      // 2.1 - 4.0
  static const Color scoreYellow = Color(0xFFFFD600);     // 4.1 - 7.0
  static const Color scoreLightGreen = Color(0xFF8BC34A); // 7.1 - 8.0
  static const Color scoreDarkGreen = Color(0xFF388E3C); // 8.1 - 10.0
  
  // Question Palette Colors
  static const Color notVisited = Color(0xFFE0E0E0);
  static const Color answered = Color(0xFF4CAF50);
  static const Color marked = Color(0xFFFF9800);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFB00020);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  
  // Get score color based on value
  static Color getScoreColor(double score) {
    if (score >= 0.0 && score <= 2.0) return scoreRed;
    if (score >= 2.1 && score <= 4.0) return scoreOrange;
    if (score >= 4.1 && score <= 7.0) return scoreYellow;
    if (score >= 7.1 && score <= 8.0) return scoreLightGreen;
    if (score >= 8.1 && score <= 10.0) return scoreDarkGreen;
    return scoreRed;
  }
}
