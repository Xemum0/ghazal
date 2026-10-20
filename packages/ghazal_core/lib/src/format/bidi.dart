// Bidi and digit primitives (ADR 0010 D2, D3, D5; ADR 0014 D8). Pure string functions: Dart twin of
// packages/i18n/src/bidi.ts.

/// Unicode isolates: an LTR run inside Arabic text can never reorder its neighbours.
const String kLri = '\u2066';
const String kRli = '\u2067';
const String kFsi = '\u2068';
const String kPdi = '\u2069';

/// Non-breaking space: between a number and its unit or currency (ADR 0010 D5).
const String kNbsp = ' ';

/// Real minus sign for negatives, inside the isolate (ADR 0010 D5).
const String kMinus = '−';
const String kEnDash = '–';

final RegExp _marks = RegExp('[\u200e\u200f\u061c]');
final RegExp _isolates = RegExp('[\u2066\u2067\u2068\u2069]');

String isolateLtr(String s) => '$kLri$s$kPdi';
String isolateRtl(String s) => '$kRli$s$kPdi';
String isolateAuto(String s) => '$kFsi$s$kPdi';
String stripMarks(String s) => s.replaceAll(_marks, '');
String stripIsolates(String s) => s.replaceAll(_isolates, '');

/// Removes isolates and marks: the plain text of a formatter string (semantics labels, logs).
String plainText(String s) => stripMarks(stripIsolates(s));

const int _easternZero = 0x0660;
const int _persianZero = 0x06f0;

/// Western 0-9 to Eastern Arabic-Indic; `,` to `٬` and `.` to `٫` (ADR 0010 D2). Apply to numeric tokens only.
String toEasternDigits(String s) {
  final out = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0x30 && r <= 0x39) {
      out.writeCharCode(_easternZero + (r - 0x30));
    } else if (r == 0x2c) {
      out.write('٬');
    } else if (r == 0x2e) {
      out.write('٫');
    } else {
      out.writeCharCode(r);
    }
  }
  return out.toString();
}

/// Eastern Arabic-Indic and Persian digits to Western; the Arabic decimal and thousands separators to `.` and `,`;
/// the Arabic comma to `,`. Every numeric, phone, OTP and amount input runs through this on entry (ADR 0010 D3).
String normalizeDigits(String s) {
  final out = StringBuffer();
  for (final r in s.runes) {
    if (r >= _easternZero && r <= _easternZero + 9) {
      out.writeCharCode(0x30 + (r - _easternZero));
    } else if (r >= _persianZero && r <= _persianZero + 9) {
      out.writeCharCode(0x30 + (r - _persianZero));
    } else if (r == 0x066b) {
      out.write('.');
    } else if (r == 0x066c || r == 0x060c) {
      out.write(',');
    } else {
      out.writeCharCode(r);
    }
  }
  return out.toString();
}

/// Only the ten digits become Eastern Arabic-Indic; punctuation is left alone (safe for running prose).
String easternDigitsOnly(String s) {
  final out = StringBuffer();
  for (final r in s.runes) {
    out.writeCharCode(r >= 0x30 && r <= 0x39 ? _easternZero + (r - 0x30) : r);
  }
  return out.toString();
}
