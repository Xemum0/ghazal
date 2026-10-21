import 'dart:convert';
import 'dart:io';

import 'package:flutter/rendering.dart';
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
    this.words = const <ShotWord>[],
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

  /// Every visible word with its box in the shot's coordinates (dp, origin = top-left of the app area): the geometry diff of
  /// tools/parity/geo.mjs matches them with the same words of the web frame and shows where the layout drifts.
  final List<ShotWord> words;

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
    File(p.join(dir, '$label.texts.json')).writeAsStringSync(jsonEncode(<String, Object?>{'id': id, 'lang': lang, 'w': width.round(), 'texts': texts, 'words': [for (final w in words) w.toJson()]}));
  }

  /// Reads the state of the widget tree (call after the settle, before the screenshot).
  static ShotHealth capture(WidgetTester tester, {required String id, required String lang, required double width, required String state, required List<String> errors}) {
    final collected = _collect(tester);
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
      texts: collected.texts,
      words: collected.words,
    );
  }

  /// Every non-empty string drawn by the app (not the harness chrome around it), in tree order.
  static List<String> collectTexts(WidgetTester tester) => _collect(tester).texts;

  /// Walks the element tree of the app: the strings and the words with their boxes. A subtree that is not drawn (`Visibility` with
  /// visible false, `Offstage`: the hidden width copy of a chip label) is skipped, like the hidden elements of the web dump.
  static ({List<String> texts, List<ShotWord> words}) _collect(WidgetTester tester) {
    final texts = <String>[];
    final words = <ShotWord>[];
    final roots = find.byType(GzApp).evaluate();
    final start = roots.isEmpty ? tester.binding.rootElement : roots.first;
    if (start == null) return (texts: texts, words: words);
    void visit(Element e) {
      final w = e.widget;
      if (w is Visibility && !w.visible) return;
      if (w is Offstage && w.offstage) return;
      if (w is RichText) {
        final box = e.renderObject;
        final raw = w.text.toPlainText(includePlaceholders: false, includeSemanticsLabels: false);
        final cleaned = clean(raw);
        if (cleaned.isNotEmpty && !_glyphOnly(cleaned)) {
          texts.add(cleaned);
          if (box is RenderParagraph && box.hasSize) {
            try {
              final origin = box.localToGlobal(Offset.zero);
              for (final m in RegExp(r'\S+').allMatches(raw)) {
                final token = clean(m.group(0)!);
                if (token.isEmpty || _glyphOnly(token) || token.contains('\ufffc')) continue;
                final boxes = box.getBoxesForSelection(TextSelection(baseOffset: m.start, extentOffset: m.end));
                if (boxes.isEmpty) continue;
                var l = boxes.first.left, t = boxes.first.top, r = boxes.first.right, b = boxes.first.bottom;
                for (final x in boxes.skip(1)) {
                  if (x.left < l) l = x.left;
                  if (x.top < t) t = x.top;
                  if (x.right > r) r = x.right;
                  if (x.bottom > b) b = x.bottom;
                }
                words.add(ShotWord(token, origin.dx + l, origin.dy + t, r - l, b - t));
              }
            } on Object {
              // a paragraph without geometry (never laid out) has no words to compare
            }
          }
        }
      }
      e.visitChildren(visit);
    }

    start.visitChildren(visit);
    return (texts: texts, words: words);
  }

  /// Bidi isolates and no-break spaces out, runs of white space to one space.
  static String clean(String s) => s.replaceAll(RegExp(r'[\u2066-\u2069\u200e\u200f\u061c\u202a-\u202e]'), '').replaceAll(RegExp(r'\u00a0'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  // Icon glyphs are drawn as text from a private-use font: no word of the prototype corresponds to them.
  static bool _glyphOnly(String s) => s.runes.every((r) => (r >= 0xe000 && r <= 0xf8ff) || r >= 0xf0000);
}

/// One visible word and its box in dp (origin: the top-left of the app area, the same origin as the web frame).
class ShotWord {
  const ShotWord(this.t, this.x, this.y, this.w, this.h);

  final String t;
  final double x;
  final double y;
  final double w;
  final double h;

  Map<String, Object?> toJson() => <String, Object?>{'t': t, 'x': double.parse(x.toStringAsFixed(2)), 'y': double.parse(y.toStringAsFixed(2)), 'w': double.parse(w.toStringAsFixed(2)), 'h': double.parse(h.toStringAsFixed(2))};
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
