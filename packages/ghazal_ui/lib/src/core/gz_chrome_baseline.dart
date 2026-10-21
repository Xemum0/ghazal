import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Chrome rounds a font's ascent and descent to whole pixels and puts the baseline of a line box at
/// `floor((line - (round(ascent) + round(descent))) / 2) + round(ascent)`; Flutter keeps the fractional value of the same font metrics
/// (docs/engineering/flutter-dev.md, "Reading parity scores": Flutter's baseline is 0.1 to 0.9 dp lower). In a baseline-aligned row the
/// difference changes the row height by up to 1 dp, and a card of several such rows drifts 1 to 2 dp against the prototype.
///
/// This wraps ONE text (its resolved [style], the one the child draws) and reproduces the browser's baseline: the child is painted
/// `chrome - flutter` higher inside its own box and the box reports the browser's baseline, so the box extends below the baseline
/// exactly as the web line box does. Glyph pixels stay where a baseline-aligned neighbour puts them. The formula reproduces every
/// measured pair (EN d1 18.75 -> 18, AR d1 22.22 -> 22, EN body-s 17.74 -> 17, AR body-s 18.55 -> 18, EN caption 14.98 -> 15, AR title
/// 19.90 -> 19, EN countdown numeral 70.80 -> 71); the earlier `floor(flutter + 0.22)` fit all but the Arabic title.
class GzChromeBaseline extends StatelessWidget {
  const GzChromeBaseline({required this.style, required this.child, this.paint = true, super.key});

  final TextStyle style;
  final Widget child;

  /// `true`: the glyphs move with the baseline (they sit on the row's baseline exactly). `false`: only the reported baseline and the
  /// box height change; the glyphs stay where Flutter draws them inside the box.
  final bool paint;

  static final Map<String, double> _offsets = {};

  /// The browser's baseline of one line of [style] (its line height box), whole pixels.
  static double baselineOf(TextStyle style, TextDirection direction) => _flutterBaseline(style, direction) + offsetOf(style, direction);

  static double _flutterBaseline(TextStyle style, TextDirection direction) {
    final p = TextPainter(text: TextSpan(text: 'x', style: style.copyWith(color: null)), textDirection: direction)..layout();
    final b = p.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    p.dispose();
    return b;
  }

  /// `chrome - flutter` baseline offset of [style] (negative: the browser's baseline is higher).
  static double offsetOf(TextStyle style, TextDirection direction) {
    final key = '${style.fontFamily}|${style.fontSize}|${style.height}|${style.fontWeight}|${style.letterSpacing}|$direction';
    return _offsets[key] ??= _measure(style, direction);
  }

  static double _measure(TextStyle style, TextDirection direction) {
    final real = TextPainter(text: TextSpan(text: 'x', style: style.copyWith(color: null)), textDirection: direction)..layout();
    final flutter = real.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    real.dispose();
    // The font's own ascent and descent: the same family and size without the line height.
    final natural = TextPainter(
      text: TextSpan(
        text: 'x',
        style: TextStyle(fontFamily: style.fontFamily, fontFamilyFallback: style.fontFamilyFallback, fontSize: style.fontSize, fontWeight: style.fontWeight, fontStyle: style.fontStyle),
      ),
      textDirection: direction,
    )..layout();
    final m = natural.computeLineMetrics().first;
    natural.dispose();
    final ascent = m.ascent.roundToDouble();
    final descent = m.descent.roundToDouble();
    final line = (style.height ?? 0) * (style.fontSize ?? 16);
    if (line <= 0) return 0; // an inline run with a zero line height takes its line from the parent
    final chrome = ((line - (ascent + descent)) / 2).floorToDouble() + ascent;
    return chrome - flutter;
  }

  @override
  Widget build(BuildContext context) => _ChromeBaseline(offset: offsetOf(style, Directionality.of(context)), paint: paint, child: child);
}

class _ChromeBaseline extends SingleChildRenderObjectWidget {
  const _ChromeBaseline({required this.offset, required this.paint, required super.child});

  final double offset;
  final bool paint;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderChromeBaseline(offset, paint);

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    (renderObject as _RenderChromeBaseline)
      ..offset = offset
      ..moveGlyphs = paint;
  }
}

class _RenderChromeBaseline extends RenderShiftedBox {
  _RenderChromeBaseline(this._offset, this._paint) : super(null);

  double _offset;
  bool _paint;

  set moveGlyphs(bool v) {
    if (v == _paint) return;
    _paint = v;
    markNeedsLayout();
  }

  set offset(double v) {
    if (v == _offset) return;
    _offset = v;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.smallest;
      return;
    }
    c.layout(constraints, parentUsesSize: true);
    size = c.size;
    (c.parentData! as BoxParentData).offset = Offset(0, _paint ? _offset : 0);
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final b = child?.getDistanceToActualBaseline(baseline);
    return b == null ? null : b + _offset;
  }

  @override
  double? computeDryBaseline(BoxConstraints constraints, TextBaseline baseline) {
    final b = child?.getDryBaseline(constraints, baseline);
    return b == null ? null : b + _offset;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => child?.getDryLayout(constraints) ?? constraints.smallest;
}

/// A plain [Text] of a resolved role [style] that reports the browser's baseline (the glyphs stay where Flutter draws them): what
/// every text inside a baseline-aligned row must be, so that rows made of [GzText], [GzNum] and this one agree on their height.
/// Use [GzText] when a role is enough; this is for the few texts that need an own weight, a decoration or a fixed string.
Widget gzSnappedText(String data, {required TextStyle style, bool softWrap = true, TextAlign? textAlign, int? maxLines, TextOverflow? overflow}) {
  return GzChromeBaseline(
    style: style,
    paint: false,
    child: Text(data, style: style, softWrap: softWrap, textAlign: textAlign, maxLines: maxLines, overflow: overflow),
  );
}
