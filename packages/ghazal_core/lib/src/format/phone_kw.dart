// Phone numbers (ADR 0012 D1-D3, ADR 0010 D2). Dart twin of packages/i18n/src/phone.ts. Stored as E.164, shown
// `+965 5123 4567` inside an LTR isolate in both languages, always Western digits. Validation is a loose shape check,
// never libphonenumber `isValid`: WhatsApp delivery is the real validation.
import 'bidi.dart';
import 'config.dart';

/// Kuwaiti (default country) phone helpers. Pass another [CountryConfig] for GCC expansion.
class PhoneKw {
  const PhoneKw._();

  /// National digits from whatever a person typed or pasted: Eastern and Persian digits become Western, spaces, dashes
  /// and brackets go, and a leading `+965`, `00965` or `965` (only when 11 digits follow the pattern) is removed.
  static String normalizeInput(String raw, [CountryConfig? country]) {
    final c = country ?? kKuwait;
    final cc = c.phone.callingCode;
    final typed = normalizeDigits(raw).trim();
    final international = typed.startsWith('+') || typed.startsWith('00');
    var digits = typed.replaceAll(RegExp(r'\D'), '');
    if (typed.startsWith('00')) digits = digits.substring(2);
    final pasted = digits.length == cc.length + 8; // an 8-digit national number is never 11 digits long
    if ((international || pasted) && digits.startsWith(cc)) digits = digits.substring(cc.length);
    return digits;
  }

  /// Loose shape: 8 digits, mobiles 5, 6, 9 and 41xx, landlines 2 (`^(?:[2569]\d{7}|41\d{6})$`).
  static bool isValidShape(String national, [CountryConfig? country]) => (country ?? kKuwait).phone.nationalPattern.hasMatch(national);

  /// Validates raw input (any digits, any prefix).
  static bool isValid(String raw, [CountryConfig? country]) => isValidShape(normalizeInput(raw, country), country);

  /// `+96551234567`, or null when the national number does not have the expected shape.
  static String? toE164(String raw, [CountryConfig? country]) {
    final c = country ?? kKuwait;
    final national = normalizeInput(raw, c);
    return isValidShape(national, c) ? '+${c.phone.callingCode}$national' : null;
  }

  static String _group(String national, List<int> groups) {
    final parts = <String>[];
    var i = 0;
    for (final size in groups) {
      if (i >= national.length) break;
      parts.add(national.substring(i, i + size > national.length ? national.length : i + size));
      i += size;
    }
    if (i < national.length) parts.add(national.substring(i));
    return parts.join(' ');
  }

  /// `5123 4567`: the 4 + 4 grouping, no isolate (for the field value).
  static String formatNational(String raw, [CountryConfig? country]) {
    final c = country ?? kKuwait;
    return _group(normalizeInput(raw, c), c.phone.groups);
  }

  /// `+965 5123 4567` inside an LTR isolate, both languages (ADR 0012 D2).
  static String format(String raw, [CountryConfig? country]) {
    final c = country ?? kKuwait;
    return isolateLtr('+${c.phone.callingCode} ${formatNational(raw, c)}');
  }

  /// `tel:+96551234567` (ADR 0012 D3). Null for a malformed number.
  static String? telHref(String raw, [CountryConfig? country]) {
    final e = toE164(raw, country);
    return e == null ? null : 'tel:$e';
  }

  /// `https://wa.me/96551234567`: digits only, no plus (ADR 0012 D3).
  static String? whatsappHref(String raw, [CountryConfig? country]) {
    final e = toE164(raw, country);
    return e == null ? null : 'https://wa.me/${e.substring(1)}';
  }
}
