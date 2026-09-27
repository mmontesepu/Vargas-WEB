import 'package:flutter/services.dart';

class ClpInputFormatter extends TextInputFormatter {
  const ClpInputFormatter();

  static String format(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) return '';

    return digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
  }

  static double parse(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    return double.tryParse(digits) ?? 0;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsBeforeCursor = newValue.text
        .substring(
          0,
          newValue.selection.baseOffset.clamp(0, newValue.text.length),
        )
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;

    final formatted = format(newValue.text);

    var cursor = 0;
    var digitsFound = 0;

    while (cursor < formatted.length && digitsFound < digitsBeforeCursor) {
      if (RegExp(r'[0-9]').hasMatch(formatted[cursor])) {
        digitsFound++;
      }
      cursor++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}
