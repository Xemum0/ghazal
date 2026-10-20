import 'package:flutter/widgets.dart';

/// Unicode isolates: a number, phone, code or money value is an LTR island inside Arabic text (ADR 0010 D5, ADR 0012).
abstract final class GzBidi {
  /// LEFT-TO-RIGHT ISOLATE and POP DIRECTIONAL ISOLATE.
  static const String lri = '\u2066';
  static const String pdi = '\u2069';

  /// Wraps [text] in an LTR isolate (U+2066 ... U+2069), first removing isolates it already carries so there is only one pair.
  static String isolateLtr(String text) => '$lri${strip(text)}$pdi';

  /// Removes the invisible isolate and embedding controls (the formatter adds them; the wrapper must be the only isolate).
  static String strip(String text) => text.replaceAll(RegExp('[\u2066-\u2069\u202a-\u202e\u200e\u200f]'), '');
}

/// A left-to-right island for a widget subtree (phone numbers, codes, a money row): the web `.gz-ltr`.
class GzLtr extends StatelessWidget {
  const GzLtr({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.ltr, child: child);
}
