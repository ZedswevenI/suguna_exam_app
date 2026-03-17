import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:suguna_exam_app/core/widgets/app_text.dart';

class AppRichText extends StatelessWidget {
  final List<AppTextSpan> spans;
  final TextAlign? textAlign;

  const AppRichText({
    super.key,
    required this.spans,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: textAlign ?? TextAlign.start,
      text: TextSpan(
        children: spans.map((span) {
          final style = _getTextStyle(span.style);
          return TextSpan(
            text: span.text,
            style: style.copyWith(
              color: span.color ?? style.color,
              fontWeight: span.fontWeight ?? style.fontWeight,
            ),
            recognizer: span.onTap != null
                ? (TapGestureRecognizer()..onTap = span.onTap)
                : null,
          );
        }).toList(),
      ),
    );
  }

  TextStyle _getTextStyle(AppTextStyle style) {
    // Use same logic as AppText
    return const TextStyle();
  }
}

class AppTextSpan {
  final String text;
  final AppTextStyle style;
  final Color? color;
  final FontWeight? fontWeight;
  final VoidCallback? onTap;

  AppTextSpan({
    required this.text,
    required this.style,
    this.color,
    this.fontWeight,
    this.onTap,
  });
}
