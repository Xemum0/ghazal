import 'package:flutter/services.dart';

import '../format/bidi.dart';

/// Normalises Arabic-Indic and Persian digits (and the Arabic decimal and thousands separators) to ASCII as the person
/// types or pastes (ADR 0010 D3). Put it first in `inputFormatters` of every numeric, phone, OTP and amount field; the
/// cursor is kept at the end of the newly typed text.
class DigitNormalizingFormatter extends TextInputFormatter {
  const DigitNormalizingFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = normalizeDigits(newValue.text);
    if (text == newValue.text) return newValue;
    // The replacement is one code unit for one code unit, so selection and composing offsets stay valid.
    return newValue.copyWith(text: text);
  }
}
