import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart' show GzApp, GzEmptyState, GzErrorState, GzOfflineState, GzSkeleton, GzStubScreen;
import 'package:path/path.dart' as p;

/// What one shot proves about a screen besides its pixels: the final sweep (tools/flutter-sweep.mjs) reads these files to find a screen
/// that raised a framework error or an overflow, still shows `Not built yet`, is stuck on its skeleton, shows an error or empty state
/// where data was expected, or says less than the prototype says (the visible texts are compared with the web DOM by
/// tools/parity/content.mjs).
class ShotHealth {
  ShotHealth({
    required this.id,
    required this.lang,
    required this.width,
    required this.state,
    required this.errors,
    required this.stub,
    required this.skeletons,
    required this.errorState,
    required this.offlineState,
    required this.emptyState,
    required this.texts,
  });

  final String id;
  final String lang;
  final double width;
  final String state;

  /// First line of every framework error raised while the shot ran (overflow, build errors, assertion failures).
  final List<String> errors;
  final bool stub;

  /// Skeleton widgets still on screen after the settle: a screen stuck loading.
  final int skeletons;
  final bool errorState;
  final bool offlineState;
  final bool emptyState;

  /// The visible text of the app (device chrome excluded), cleaned: isolates and no-break spaces removed, icon glyphs dropped.
  final List<String> texts;

  bool get overflow => errors.any((e) => e.contains('overflowed') || e.contains('OVERFLOWING'));

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'lang': lang,
    'w': width.round(),
    'state': state,
    'errors': errors,
    'overflow': overflow,
    'stub': stub,
    'skeletons': skeletons,
    'errorState': errorState,
    'offlineState': offlineState,
    'emptyState': emptyState,
    'textCount': texts.length,
  };

  /// Writes `<label>.health.json` and `<label>.texts.json` into [dir].
  void write(String dir, String label) {
    Directory(dir).createSync(recursive: true);
    File(p.join(dir, '$label.health.json')).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(toJson()));
    File(p.join(dir, '$label.texts.json')).writeAsStringSync(jsonEncode(<String, Object?>{'id': id, 'lang': lang, 'w': width.round(), 'texts': texts}));
  }

  /// Reads the state of the widget tree (call after the settle, before the screenshot).
  static ShotHealth capture(WidgetTester tester, {required String id, required String lang, required double width, required String state, required List<String> errors}) {
    return ShotHealth(
      id: id,
      lang: lang,
      width: width,
      state: state,
      errors: List<String>.of(errors),
      stub: find.byType(GzStubScreen).evaluate().isNotEmpty,
      skeletons: find.byType(GzSkeleton).evaluate().length,
      errorState: find.byType(GzErrorState).evaluate().isNotEmpty,
      offlineState: find.byType(GzOfflineState).evaluate().isNotEmpty,
      emptyState: find.byType(GzEmptyState).evaluate().isNotEmpty,
      texts: collectTexts(tester),
    );
  }

  /// Every non-empty string drawn by the app (not the harness chrome around it), in tree order.
  static List<String> collectTexts(WidgetTester tester) {
    final root = find.byType(GzApp);
    final finder = root.evaluate().isEmpty ? find.byType(RichText) : find.descendant(of: root, matching: find.byType(RichText));
    final out = <String>[];
    for (final w in tester.widgetList<RichText>(finder)) {
      final cleaned = clean(w.text.toPlainText(includePlaceholders: false, includeSemanticsLabels: false));
      if (cleaned.isNotEmpty && !_glyphOnly(cleaned)) out.add(cleaned);
    }
    return out;
  }

  /// Bidi isolates and no-break spaces out, runs of white space to one space.
  static String clean(String s) => s.replaceAll(RegExp(r'[\u2066-\u2069\u200e\u200f\u061c\u202a-\u202e]'), '').replaceAll(RegExp(r'\u00a0'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  // Icon glyphs are drawn as text from a private-use font: no word of the prototype corresponds to them.
  static bool _glyphOnly(String s) => s.runes.every((r) => (r >= 0xe000 && r <= 0xf8ff) || r >= 0xf0000);
}

/// Runs [body] with every framework error recorded into [errors]. With [swallow] the errors do not fail the test (the sweep reads them
/// from the health file); without it each error is also passed on, so an ordinary `pnpm fshot` still fails on an overflow.
Future<void> recordingErrors(List<String> errors, Future<void> Function() body, {required bool swallow}) async {
  final previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final text = details.exceptionAsString().split('\n').first.trim();
    errors.add(text.length > 220 ? '${text.substring(0, 220)}...' : text);
    if (!swallow) previous?.call(details);
  };
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
}
