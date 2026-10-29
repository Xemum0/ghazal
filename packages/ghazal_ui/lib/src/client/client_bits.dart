// ignore_for_file: prefer_initializing_formals
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat, MoneyMode, MoneyOptions, isolateLtr, kNbsp;
import 'package:ghazal_domain/ghazal_domain.dart'
    show CardPrice, CardPriceExact, CardPriceFlatNight, CardPriceFromGuests, CardPriceFromMinimum, CardPriceRentalFee;

import '../core/core.dart';
import '../foundation.dart';

/// An open-ended budget (`KD 35,000+` / `+35,000 د.ك`): the plus sits inside the number's LTR isolate, never on the far side of the
/// unit. Pure function of the formatter (the web `useOpenBudget`).
String gzOpenBudget(GzFormat f, int fils) {
  final m = f.moneyParts(fils, const MoneyOptions(mode: MoneyMode.browse));
  return f.isArabic ? '${isolateLtr('${m.amount}+')}$kNbsp${m.currency}' : '${m.currency}$kNbsp${m.amount}+';
}

/// `14 Jan` / `14 يناير`: day and short month for CTAs and chips with no room for a weekday (the web `useDayMonth`).
String gzDayMonth(GzFormat f, String iso) {
  final c = f.civil(iso);
  return '${f.integer(c.day)} ${f.monthName(c.month, short: true)}';
}

/// The measured inline size of the space a child gets (the web `useInlineSize`): the builder receives the max width.
class GzInlineSize extends StatelessWidget {
  const GzInlineSize({required this.builder, super.key});

  final Widget Function(BuildContext context, double width) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) => builder(context, c.maxWidth.isFinite ? c.maxWidth : 0));
}

enum GzPriceLineSize { card, strong, display }

/// Deprecated, no effect (ADR 0038: there is no guest mode, every client is signed in). Kept so call sites compile; remove it there.
enum GzPriceAudience { member, guest }

/// The venue price line, one grammar (ADR 0004 D6, ADR 0018 D4, ADR 0033 D4): the VOUCHER price is the headline when the card has one,
/// the standard price sits struck beside it and a saving chip follows. The basis is a glyph and a figure (users 350, a moon for a
/// night, a key for a rental fee); the words are accessible names. "From" stays. [lean] keeps only headline and basis. Takes the
/// generated `CardPrice` model. [audience] is a deprecated no-op (ADR 0038).
class GzCardPriceLine extends StatelessWidget {
  const GzCardPriceLine({
    required this.price,
    this.size = GzPriceLineSize.card,
    this.alignEnd = false,
    this.audience = GzPriceAudience.member,
    this.lean = false,
    super.key,
  });

  final CardPrice price;
  final GzPriceLineSize size;

  /// `align: 'end'` of the web: runs sit on the end side and the line takes the full width.
  final bool alignEnd;

  /// Deprecated, no effect (ADR 0038).
  final GzPriceAudience audience;
  final bool lean;

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    final l = context.gzL10n;
    final c = context.gz.colors;
    final rental = price is CardPriceRentalFee;
    final voucher = rental ? null : price.voucher;
    final headline = voucher?.fils ?? price.amount.fils;
    final priceSize = switch (size) {
      GzPriceLineSize.card => GzPriceSize.card,
      GzPriceLineSize.strong => GzPriceSize.strong,
      GzPriceLineSize.display => GzPriceSize.display,
    };
    Widget amount([String? prefix]) => GzPrice(fils: headline, size: priceSize, prefix: prefix, was: voucher != null && !lean ? price.amount.fils : null);
    Widget basis(IconData icon, String label, [String? value]) => GzFactChip(icon: icon, label: label, value: value, small: true, tone: GzFactTone.muted);

    final List<Widget> body = switch (price) {
      CardPriceExact(:final guests) => [amount(), basis(GzIcons.usersThree, l.uiSharedGuests, f.integer(guests))],
      CardPriceFromGuests(:final guests) => [amount(l.uiSharedFrom), basis(GzIcons.usersThree, l.uiSharedGuests, f.integer(guests))],
      CardPriceFromMinimum(:final guests) => [amount(l.uiSharedFrom), basis(GzIcons.usersThree, l.uiSharedGuests, '${f.integer(guests)}+')],
      CardPriceFlatNight(:final hasSeveralPackages) => [amount(hasSeveralPackages ? l.uiSharedFrom : null), basis(GzIcons.moon, l.uiSharedPerNight)],
      CardPriceRentalFee() => [GzPrice(fils: price.amount.fils, size: priceSize), basis(GzIcons.key, l.uiSharedRentalFee)],
    };
    final saving = price.savings;
    final line = GzBaselineWrap(
      spacing: GzSpace.s2,
      alignEnd: alignEnd,
      children: [
        ...body,
        if (voucher != null && saving != null && !lean)
          Semantics(
            label: l.commonSaveAmount(f.money(saving.fils, const MoneyOptions(mode: MoneyMode.browse))),
            excludeSemantics: true,
            // The pill's first flex item is the trend glyph, so its web baseline is the glyph's bottom edge.
            child: GzGlyphBaseline(
              glyphSize: GzSize.iconXs,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: GzSize.pillMin),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: c.statusSuccessBg, borderRadius: GzRadius.xsAll),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GzIcon(GzIcons.trendDown, size: GzIconSize.xs, color: c.statusSuccessText),
                        const SizedBox(width: GzSpace.s1),
                        GzMoney(fils: saving.fils, inline: true, amountRole: GzTextRole.figLabel, amountColor: c.statusSuccessText),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    return KeyedSubtree(key: const ValueKey('gz-card-price-line'), child: line);
  }
}

/// A wrapping row whose children share one text baseline per run (CSS `display:flex; flex-wrap:wrap; align-items:baseline`).
/// Flutter's `Wrap` only knows start / center / end cross alignment, which drifts a 17 dp price against a 13 dp figure.
/// A child without a baseline sits on the run's bottom edge. [alignEnd] pushes each run to the end side and makes the
/// widget take the full available width (`justify-content: flex-end`).
class GzBaselineWrap extends MultiChildRenderObjectWidget {
  const GzBaselineWrap({required super.children, this.spacing = 0, this.runSpacing = 0, this.alignEnd = false, super.key});

  final double spacing;
  final double runSpacing;
  final bool alignEnd;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderBaselineWrap(spacing: spacing, runSpacing: runSpacing, alignEnd: alignEnd, textDirection: Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    (renderObject as _RenderBaselineWrap)
      ..spacing = spacing
      ..runSpacing = runSpacing
      ..alignEnd = alignEnd
      ..textDirection = Directionality.of(context);
  }
}

class _WrapData extends ContainerBoxParentData<RenderBox> {}

class _RenderBaselineWrap extends RenderBox with ContainerRenderObjectMixin<RenderBox, _WrapData>, RenderBoxContainerDefaultsMixin<RenderBox, _WrapData> {
  _RenderBaselineWrap({required double spacing, required double runSpacing, required bool alignEnd, required TextDirection textDirection})
    : _spacing = spacing,
      _runSpacing = runSpacing,
      _alignEnd = alignEnd,
      _textDirection = textDirection;

  double _spacing;
  double _runSpacing;
  bool _alignEnd;
  TextDirection _textDirection;
  double? _firstBaseline;

  set spacing(double v) {
    if (v == _spacing) return;
    _spacing = v;
    markNeedsLayout();
  }

  set runSpacing(double v) {
    if (v == _runSpacing) return;
    _runSpacing = v;
    markNeedsLayout();
  }

  set alignEnd(bool v) {
    if (v == _alignEnd) return;
    _alignEnd = v;
    markNeedsLayout();
  }

  set textDirection(TextDirection v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _WrapData) child.parentData = _WrapData();
  }

  /// Chrome snaps each item's baseline to a whole pixel before it aligns a baseline run; Flutter keeps the fractional value of the same
  /// font metrics. Measured against the prototype (see GzChromeBaseline): browser baseline = floor(flutter baseline + 0.22). A glyph-bottom
  /// baseline (a chip or rating whose first item is an icon) is already a whole number and does not move.
  double _baselineOf(RenderBox c) {
    final b = c.getDistanceToBaseline(TextBaseline.alphabetic, onlyReal: true);
    return b == null ? c.size.height : (b + 0.22).floorToDouble();
  }

  Size _layout(BoxConstraints constraints) {
    final maxW = constraints.maxWidth;
    final loose = BoxConstraints(maxWidth: maxW);
    final runs = <List<RenderBox>>[<RenderBox>[]];
    var x = 0.0;
    var widest = 0.0;
    var child = firstChild;
    while (child != null) {
      child.layout(loose, parentUsesSize: true);
      final w = child.size.width;
      final run = runs.last;
      if (run.isNotEmpty && x + _spacing + w > maxW + 0.01) {
        runs.add(<RenderBox>[]);
        x = 0;
      }
      runs.last.add(child);
      x += (runs.last.length > 1 ? _spacing : 0) + w;
      widest = math.max(widest, x);
      child = childAfter(child);
    }
    var y = 0.0;
    _firstBaseline = null;
    final width = constraints.constrainWidth(_alignEnd && maxW.isFinite ? maxW : widest);
    for (var i = 0; i < runs.length; i++) {
      final run = runs[i];
      if (run.isEmpty) continue;
      var ascent = 0.0;
      var descent = 0.0;
      for (final c in run) {
        final b = _baselineOf(c);
        ascent = math.max(ascent, b);
        descent = math.max(descent, c.size.height - b);
      }
      var runW = _spacing * (run.length - 1);
      for (final c in run) {
        runW += c.size.width;
      }
      var cursor = _alignEnd ? width - runW : 0.0;
      for (final c in run) {
        final data = c.parentData! as _WrapData;
        final dx = _textDirection == TextDirection.rtl ? width - cursor - c.size.width : cursor;
        data.offset = Offset(dx, y + ascent - _baselineOf(c));
        cursor += c.size.width + _spacing;
      }
      _firstBaseline ??= y + ascent;
      y += ascent + descent + (i < runs.length - 1 ? _runSpacing : 0);
    }
    return constraints.constrain(Size(width, y));
  }

  @override
  void performLayout() => size = _layout(constraints);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) => _firstBaseline;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    // Dry layout is only needed by intrinsic-size callers; a real layout of a clone is not possible, so measure children dry.
    final maxW = constraints.maxWidth;
    final loose = BoxConstraints(maxWidth: maxW);
    var x = 0.0, widest = 0.0, y = 0.0, runH = 0.0;
    var count = 0;
    var child = firstChild;
    while (child != null) {
      final s = child.getDryLayout(loose);
      if (count > 0 && x + _spacing + s.width > maxW + 0.01) {
        y += runH + _runSpacing;
        x = 0;
        runH = 0;
        count = 0;
      }
      x += (count > 0 ? _spacing : 0) + s.width;
      widest = math.max(widest, x);
      runH = math.max(runH, s.height);
      count++;
      child = childAfter(child);
    }
    return constraints.constrain(Size(_alignEnd && maxW.isFinite ? maxW : widest, y + runH));
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => defaultHitTestChildren(result, position: position);
}

/// A wrapping row of centred items whose LAST item can be pushed to the physical right end of the run it lands on: the web
/// `display: flex; flex-wrap: wrap; align-items: center` with `margin-left: auto` on the last item (a figure-role, LTR item). Items
/// flow in the reading direction (mirrored in RTL); with [pushLastRight] false the last item simply follows the others.
class GzWrapPushEnd extends MultiChildRenderObjectWidget {
  const GzWrapPushEnd({required super.children, this.spacing = 0, this.runSpacing = 0, this.pushLastRight = true, super.key});

  final double spacing;
  final double runSpacing;
  final bool pushLastRight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderWrapPushEnd(spacing: spacing, runSpacing: runSpacing, pushLast: pushLastRight, textDirection: Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    (renderObject as _RenderWrapPushEnd)
      ..spacing = spacing
      ..runSpacing = runSpacing
      ..pushLast = pushLastRight
      ..textDirection = Directionality.of(context);
  }
}

class _RenderWrapPushEnd extends RenderBox with ContainerRenderObjectMixin<RenderBox, _WrapData>, RenderBoxContainerDefaultsMixin<RenderBox, _WrapData> {
  _RenderWrapPushEnd({required double spacing, required double runSpacing, required bool pushLast, required TextDirection textDirection})
      : _spacing = spacing,
        _runSpacing = runSpacing,
        _pushLast = pushLast,
        _textDirection = textDirection;

  double _spacing;
  double _runSpacing;
  bool _pushLast;
  TextDirection _textDirection;

  set spacing(double v) {
    if (v == _spacing) return;
    _spacing = v;
    markNeedsLayout();
  }

  set runSpacing(double v) {
    if (v == _runSpacing) return;
    _runSpacing = v;
    markNeedsLayout();
  }

  set pushLast(bool v) {
    if (v == _pushLast) return;
    _pushLast = v;
    markNeedsLayout();
  }

  set textDirection(TextDirection v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _WrapData) child.parentData = _WrapData();
  }

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final maxW = constraints.maxWidth;
    final loose = BoxConstraints(maxWidth: maxW);
    final runs = <List<RenderBox>>[<RenderBox>[]];
    final sizes = <RenderBox, Size>{};
    var x = 0.0;
    var widest = 0.0;
    var child = firstChild;
    while (child != null) {
      final Size s;
      if (dry) {
        s = child.getDryLayout(loose);
      } else {
        child.layout(loose, parentUsesSize: true);
        s = child.size;
      }
      sizes[child] = s;
      if (runs.last.isNotEmpty && x + _spacing + s.width > maxW + 0.01) {
        runs.add(<RenderBox>[]);
        x = 0;
      }
      runs.last.add(child);
      x += (runs.last.length > 1 ? _spacing : 0) + s.width;
      widest = math.max(widest, x);
      child = childAfter(child);
    }
    final width = constraints.constrainWidth(_pushLast && maxW.isFinite ? maxW : widest);
    var y = 0.0;
    for (var i = 0; i < runs.length; i++) {
      final run = runs[i];
      if (run.isEmpty) continue;
      final h = run.map((c) => sizes[c]!.height).reduce(math.max);
      var cursor = 0.0;
      for (var j = 0; j < run.length; j++) {
        final c = run[j];
        final w = sizes[c]!.width;
        var start = cursor;
        if (_pushLast && j == run.length - 1 && i == runs.length - 1 && c == lastChild && _textDirection == TextDirection.ltr) start = width - w;
        if (!dry) {
          final dx = _textDirection == TextDirection.rtl ? width - start - w : start;
          (c.parentData! as _WrapData).offset = Offset(dx, y + (h - sizes[c]!.height) / 2);
        }
        cursor = start + w + _spacing;
      }
      y += h + (i < runs.length - 1 ? _runSpacing : 0);
    }
    return constraints.constrain(Size(width, y));
  }

  @override
  void performLayout() => size = _layout(constraints, dry: false);

  @override
  Size computeDryLayout(BoxConstraints constraints) => _layout(constraints, dry: true);

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => defaultHitTestChildren(result, position: position);
}
