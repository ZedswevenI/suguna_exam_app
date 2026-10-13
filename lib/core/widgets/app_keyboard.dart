import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

/// Which keys an [AppKeyboard] shows.
enum AppKeyboardLayout {
  /// Digits row + QWERTY letters + a few symbols. For test IDs / passcodes.
  alphanumeric,

  /// QWERTY letters only (e.g. typing SUBMIT).
  letters,

  /// Phone-style numeric keypad (e.g. enrolment number).
  digits,
}

/// In-app keyboard used wherever the OS keyboard must not appear (it covers
/// the whole screen on the tablets in landscape). Emits one key per tap:
/// a character, `'⌫'` for backspace or `'CLEAR'`.
class AppKeyboard extends StatefulWidget {
  final AppKeyboardLayout layout;
  final ValueChanged<String> onKey;
  final double keyWidth;
  final double keyHeight;

  const AppKeyboard({
    super.key,
    required this.onKey,
    this.layout = AppKeyboardLayout.alphanumeric,
    this.keyWidth = 44,
    this.keyHeight = 42,
  });

  @override
  State<AppKeyboard> createState() => _AppKeyboardState();
}

class _AppKeyboardState extends State<AppKeyboard> {
  bool _caps = true;

  static const _digits = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
  static const _rows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];
  static const _symbols = ['-', '_', '.', '@'];

  bool get _alnum => widget.layout == AppKeyboardLayout.alphanumeric;

  void _tap(String label) {
    switch (label) {
      case '⇧':
        setState(() => _caps = !_caps);
        return;
      case '⌫':
      case 'CLEAR':
        widget.onKey(label);
        return;
      case 'CLR':
        widget.onKey('CLEAR');
        return;
      default:
        final isLetter = label.length == 1 && RegExp(r'[A-Z]').hasMatch(label);
        widget.onKey(isLetter && !_caps ? label.toLowerCase() : label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = <List<String>>[
      if (widget.layout == AppKeyboardLayout.digits) ...[
        ['1', '2', '3'],
        ['4', '5', '6'],
        ['7', '8', '9'],
        ['⌫', '0', 'CLR'],
      ] else ...[
      if (_alnum) _digits,
      _rows[0],
      _rows[1],
      [if (_alnum) '⇧', ..._rows[2], '⌫'],
      if (_alnum) _symbols,
      ],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < row.length; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  _key(row[i]),
                ],
              ],
            ),
          ),
        if (widget.layout != AppKeyboardLayout.digits)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _tap('CLEAR'),
            icon: const Icon(Icons.clear_rounded, size: 16),
            label: const Text('Clear'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
          ),
        ),
      ],
    );
  }

  Widget _key(String label) {
    final isAction = label == '⌫' || label == '⇧' || label == 'CLR';
    final isLetter = label.length == 1 && RegExp(r'[A-Z]').hasMatch(label);
    final display = isLetter && !_caps ? label.toLowerCase() : label;
    final highlighted = label == '⇧' && _caps;
    return Material(
      color: highlighted
          ? AppColors.primary
          : (isAction ? const Color(0xFFE0E7FF) : Colors.white),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => _tap(label),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: isAction ? widget.keyWidth + 14 : widget.keyWidth,
          height: widget.keyHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: label == '⌫'
              ? const Icon(Icons.backspace_outlined,
                  size: 18, color: Color(0xFF4F46E5))
              : label == 'CLR'
                  ? const Icon(Icons.clear_rounded,
                      size: 20, color: Color(0xFFDC2626))
              : label == '⇧'
                  ? Icon(Icons.keyboard_capslock_rounded,
                      size: 20,
                      color: highlighted ? Colors.white : AppColors.primary)
                  : Text(
                      display,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
        ),
      ),
    );
  }
}

/// Applies a key from [AppKeyboard] to a [TextEditingController].
/// Returns false if the key was rejected (e.g. [maxLength] reached).
bool applyKeyboardKey(
  TextEditingController controller,
  String key, {
  int? maxLength,
}) {
  final current = controller.text;
  String next;
  switch (key) {
    case '⌫':
      next = current.isEmpty ? current : current.substring(0, current.length - 1);
      break;
    case 'CLEAR':
      next = '';
      break;
    default:
      if (maxLength != null && current.length >= maxLength) return false;
      next = current + key;
  }
  controller.value = TextEditingValue(
    text: next,
    selection: TextSelection.collapsed(offset: next.length),
  );
  return true;
}

/// Read-only value box for keyboard-driven input. Not a TextField, so it can
/// never summon the OS keyboard. Tap → [onTap] (e.g. open a keyboard dialog).
class KeyboardInputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool obscure;
  final VoidCallback? onTap;
  final double fontSize;

  const KeyboardInputBox({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.obscure = false,
    this.onTap,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final text = value.text;
        final shown = obscure ? '•' * text.length : text;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: text.isEmpty ? const Color(0xFFE8ECF4) : AppColors.primary,
                width: text.isEmpty ? 1 : 1.5,
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: const Color(0xFFADB5C7), size: 18),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    text.isEmpty ? hint : shown,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      letterSpacing: text.isEmpty ? 0 : (obscure ? 3 : 1),
                      fontWeight: text.isEmpty ? FontWeight.w400 : FontWeight.w600,
                      color: text.isEmpty
                          ? const Color(0xFFADB5C7)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.keyboard_alt_outlined,
                      size: 18, color: Color(0xFFADB5C7)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Opens a dialog with a value box and an [AppKeyboard] that edits
/// [controller]. Changes are applied live; Cancel restores the old value.
Future<void> showKeyboardInputDialog({
  required String title,
  required TextEditingController controller,
  String hint = '',
  bool obscure = false,
  int? maxLength,
  IconData? icon,
}) {
  final original = controller.text;
  final RxBool reveal = false.obs;
  return Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Obx(() {
                    // Read the observable unconditionally — `obscure && …`
                    // would short-circuit for plain fields and leave the
                    // Obx with nothing to observe (GetX throws).
                    final revealed = reveal.value;
                    return KeyboardInputBox(
                      controller: controller,
                      hint: hint,
                      icon: icon,
                      obscure: obscure && !revealed,
                      fontSize: 18,
                    );
                  }),
                ),
                if (obscure)
                  Obx(() => IconButton(
                        tooltip: reveal.value ? 'Hide' : 'Show',
                        onPressed: () => reveal.value = !reveal.value,
                        icon: Icon(reveal.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                      )),
              ],
            ),
            const SizedBox(height: 12),
            AppKeyboard(
              onKey: (k) => applyKeyboardKey(controller, k, maxLength: maxLength),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            controller.text = original;
            Get.back();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Get.back(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Done'),
        ),
      ],
    ),
    barrierDismissible: false,
  );
}
