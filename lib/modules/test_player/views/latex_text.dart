import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart' show Math, MathStyle;
import 'package:flutter_tex/flutter_tex.dart';

class LatexText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;

  const LatexText({
    super.key,
    required this.text,
    this.fontSize = 16,
    this.color = Colors.black,
    this.fontWeight = FontWeight.w500,
  });

  @override
  Widget build(BuildContext context) {
    return Math.tex(
      text,
      mathStyle: MathStyle.text,
      textStyle: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: 1.4,
      ),
      onErrorFallback: (_) {
        return Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: fontWeight,
          ),
        );
      },
    );
    // return TeXView( style: const TeXViewStyle( backgroundColor: Colors.transparent, padding: TeXViewPadding.all(0), ), child: TeXViewColumn( children: [ // Question TeXViewDocument('\\(3 \\log 5 + 2 \\log 4 - \\log 2\\) (P) 4', style: TeXViewStyle.fromCSS( 'font-size:16px; margin-bottom:16px;', ), ), // Option A TeXViewDocument('14 \\(m^{2}\\)', style: TeXViewStyle.fromCSS( 'padding:12px; border:1px solid #e5e7eb; border-radius:8px; margin-bottom:8px;', ), ), // Option B TeXViewDocument('7 \\(m^{2}\\)', style: TeXViewStyle.fromCSS( 'padding:12px; border:1px solid #e5e7eb; border-radius:8px; margin-bottom:8px;', ), ), // Option C TeXViewDocument('10 \\(m^{2}\\)', style: TeXViewStyle.fromCSS( 'padding:12px; border:1px solid #e5e7eb; border-radius:8px; margin-bottom:8px;', ), ), // Option D TeXViewDocument( r'<p>D. $96\,\text{m}$</p>', style: TeXViewStyle.fromCSS( 'padding:12px; border:1px solid #e5e7eb; border-radius:8px;', ), ), ], ), );
  }

  String _htmlWrapper(String latex) {
    return '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body {
              margin: 0;
              padding: 0;
              font-size: ${fontSize}px;
              color: ${_toHex(color)};
              font-weight: ${_fontWeightToCss(fontWeight)};
              line-height: 1.4;
            }
          </style>
        </head>
        <body>
          $latex
        </body>
      </html>
      ''';
  }

  String _toHex(Color c) => '#${c.value.toRadixString(16).substring(2)}';

  String _fontWeightToCss(FontWeight w) {
    switch (w) {
      case FontWeight.w100:
        return '100';
      case FontWeight.w200:
        return '200';
      case FontWeight.w300:
        return '300';
      case FontWeight.w400:
        return '400';
      case FontWeight.w500:
        return '500';
      case FontWeight.w600:
        return '600';
      case FontWeight.w700:
        return '700';
      case FontWeight.w800:
        return '800';
      case FontWeight.w900:
        return '900';
      default:
        return '400';
    }
  }
}


