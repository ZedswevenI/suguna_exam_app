import 'package:flutter/material.dart';
import 'package:suguna_exam_app/core/theme/app_colors.dart';

class AppText extends StatelessWidget {
  final String text;
  final AppTextStyle style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? color;
  final FontWeight? fontWeight;
  final double? fontSize;
  final TextDecoration? decoration;

  const AppText(
    this.text, {
    super.key,
    this.style = AppTextStyle.bodyMedium,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.color,
    this.fontWeight,
    this.fontSize,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = _getTextStyle();
    return Text(
      text,
      style: textStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
    );
  }

  TextStyle _getTextStyle() {
    TextStyle baseStyle = _getBaseStyle();
    return baseStyle.copyWith(
      color: color ?? baseStyle.color,
      fontWeight: fontWeight ?? baseStyle.fontWeight,
      fontSize: fontSize ?? baseStyle.fontSize,
      decoration: decoration ?? baseStyle.decoration,
    );
  }

  TextStyle _getBaseStyle() {
    switch (style) {
      case AppTextStyle.headlineLarge:
        return const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.2);
      case AppTextStyle.headlineMedium:
        return const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.2);
      case AppTextStyle.headlineSmall:
        return const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.3);
      case AppTextStyle.titleLarge:
        return const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3);
      case AppTextStyle.titleMedium:
        return const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4);
      case AppTextStyle.titleSmall:
        return const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4);
      case AppTextStyle.bodyLarge:
        return const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.textPrimary, height: 1.5);
      case AppTextStyle.bodyMedium:
        return const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textPrimary, height: 1.5);
      case AppTextStyle.bodySmall:
        return const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textSecondary, height: 1.5);
      case AppTextStyle.labelLarge:
        return const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.4);
      case AppTextStyle.labelMedium:
        return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary, height: 1.4);
      case AppTextStyle.labelSmall:
        return const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textSecondary, height: 1.4);
      case AppTextStyle.caption:
        return const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textSecondary, height: 1.4);
      case AppTextStyle.overline:
        return const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textSecondary, height: 1.4, letterSpacing: 0.5);
    }
  }

  factory AppText.headlineLarge(String text, {Key? key, TextAlign? textAlign, Color? color, int? maxLines}) {
    return AppText(text, key: key, style: AppTextStyle.headlineLarge, textAlign: textAlign, color: color, maxLines: maxLines);
  }

  factory AppText.headlineMedium(String text, {Key? key, TextAlign? textAlign, Color? color, int? maxLines}) {
    return AppText(text, key: key, style: AppTextStyle.headlineMedium, textAlign: textAlign, color: color, maxLines: maxLines);
  }

  factory AppText.titleLarge(String text, {Key? key, TextAlign? textAlign, Color? color, int? maxLines}) {
    return AppText(text, key: key, style: AppTextStyle.titleLarge, textAlign: textAlign, color: color, maxLines: maxLines);
  }

  factory AppText.titleMedium(String text, {Key? key, TextAlign? textAlign, Color? color, int? maxLines}) {
    return AppText(text, key: key, style: AppTextStyle.titleMedium, textAlign: textAlign, color: color, maxLines: maxLines);
  }

  factory AppText.bodyLarge(String text, {Key? key, TextAlign? textAlign, Color? color, int? maxLines}) {
    return AppText(text, key: key, style: AppTextStyle.bodyLarge, textAlign: textAlign, color: color, maxLines: maxLines);
  }

  factory AppText.bodyMedium(String text, {Key? key, TextAlign? textAlign, Color? color, int? maxLines}) {
    return AppText(text, key: key, style: AppTextStyle.bodyMedium, textAlign: textAlign, color: color, maxLines: maxLines);
  }

  factory AppText.bodySmall(String text, {Key? key, TextAlign? textAlign, Color? color, int? maxLines}) {
    return AppText(text, key: key, style: AppTextStyle.bodySmall, textAlign: textAlign, color: color, maxLines: maxLines);
  }
}

enum AppTextStyle {
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
  caption,
  overline,
}
