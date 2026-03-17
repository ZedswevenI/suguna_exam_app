import 'package:flutter/material.dart';

class ResponsiveHelper {
  static const double tabletBreakpoint = 600;

  static bool isTablet(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= tabletBreakpoint;
  }

  static bool isMobile(BuildContext context) {
    return !isTablet(context);
  }

  static EdgeInsets getPadding(BuildContext context) {
    if (isTablet(context)) {
      return const EdgeInsets.all(32);
    }
    return const EdgeInsets.all(16);
  }

  static EdgeInsets getHorizontalPadding(BuildContext context) {
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 48);
    }
    return const EdgeInsets.symmetric(horizontal: 24);
  }

  static EdgeInsets getVerticalPadding(BuildContext context) {
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(vertical: 32);
    }
    return const EdgeInsets.symmetric(vertical: 16);
  }

  static double getFontSizeMultiplier(BuildContext context) {
    if (isTablet(context)) {
      return 1.3;
    }
    return 1.0;
  }

  static double getIconSize(BuildContext context, {double baseSize = 48}) {
    if (isTablet(context)) {
      return baseSize * 1.5;
    }
    return baseSize;
  }

  static double getSpacing(BuildContext context, {double baseSpacing = 16}) {
    if (isTablet(context)) {
      return baseSpacing * 1.5;
    }
    return baseSpacing;
  }

  static double getMaxContentWidth(BuildContext context) {
    if (isTablet(context)) {
      return 1000;
    }
    return double.infinity;
  }

  static int getGridCrossAxisCount(BuildContext context) {
    if (isTablet(context)) {
      return 3;
    }
    return 2;
  }
}
