/// Shared helpers of the client discovery cards (part A): image descriptors, the venue summary of a full venue, a baseline box
/// for a glyph-first row, and the pressed-preview scale. Nothing here is a widget other code builds screens from.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Audience, ImageRef, LocalDate, LocalizedText, Venue, VenueSummary;

import '../foundation.dart';

/// The `GzPhoto` descriptor of an image: the CDN / mock base (`baseUrl`) when the API sent one, else the file name.
String gzImageSrc(ImageRef image) => image.baseUrl ?? image.file;

/// The same for a gallery item (`GalleryItem` carries the same two fields as `ImageRef`).
String gzGalleryItemSrc(String? baseUrl, String file) => baseUrl ?? file;

/// The summary a card needs, from a full `Venue` (a screen that holds the detail passes it to the card as-is).
VenueSummary gzVenueSummaryOf(Venue v) => VenueSummary(
  id: v.id,
  slug: v.slug,
  name: v.name,
  type: v.type,
  style: v.style,
  tier: v.tier,
  stars: v.stars,
  channel: v.channel,
  status: v.status,
  governorateId: v.governorateId,
  areaId: v.areaId,
  address: v.address,
  geo: v.geo,
  tagline: v.tagline,
  cover: v.cover,
  hasVideo: v.hasVideo,
  rating: v.rating,
  voucherEnabled: v.voucherEnabled,
  flags: v.flags,
);

/// The whole-card pressed look of the gallery (`previewState: 'pressed'`): the real press scale from the tokens.
Widget gzPressedPreview(bool pressed, Widget child) => pressed ? Transform.scale(scale: GzMotion.scalePress, child: child) : child;

/// A row whose first item is a glyph has no text baseline: CSS takes the glyph's bottom edge (a 16 px star in a baseline-aligned
/// head row sits with its bottom on the name's baseline). Reports the same baseline for a vertically centred glyph of [glyphSize].
class GzGlyphBaseline extends SingleChildRenderObjectWidget {
  const GzGlyphBaseline({required this.glyphSize, required super.child, super.key});

  final double glyphSize;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderGlyphBaseline(glyphSize);

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    (renderObject as _RenderGlyphBaseline).glyphSize = glyphSize;
  }
}

class _RenderGlyphBaseline extends RenderProxyBox {
  _RenderGlyphBaseline(this._glyphSize);

  double _glyphSize;

  set glyphSize(double v) {
    if (v == _glyphSize) return;
    _glyphSize = v;
    markNeedsLayout();
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) => (size.height + _glyphSize) / 2;
}

/// The four decisions of a brief (web `BriefField`).
enum GzBriefField { guests, date, area, budget }

/// The couple's brief as the cards read it: audience, guests, date, areas, budget. Every field may be empty (a skipped answer).
/// Areas arrive already resolved to names (a widget never looks anything up); the budget is an integer-fils range whose top is
/// null for an open budget (`KD 35,000+`).
@immutable
class GzBrief {
  const GzBrief({this.audience, this.guests, this.date, this.areas = const [], this.budgetMinFils, this.budgetMaxFils});

  final Audience? audience;
  final int? guests;

  /// A civil date.
  final LocalDate? date;
  final List<LocalizedText> areas;
  final int? budgetMinFils;
  final int? budgetMaxFils;

  GzBrief copyWith({
    Audience? audience,
    int? guests,
    LocalDate? date,
    List<LocalizedText>? areas,
    int? budgetMinFils,
    int? budgetMaxFils,
    bool openBudget = false,
  }) => GzBrief(
    audience: audience ?? this.audience,
    guests: guests ?? this.guests,
    date: date ?? this.date,
    areas: areas ?? this.areas,
    budgetMinFils: budgetMinFils ?? this.budgetMinFils,
    budgetMaxFils: openBudget ? null : (budgetMaxFils ?? this.budgetMaxFils),
  );
}

/// Chrome places a text baseline on a whole pixel; Flutter keeps the fractional value of the same font metrics
/// (docs/engineering/flutter-dev.md, "Reading parity scores": Flutter's baseline is 0.1 to 0.9 dp lower). Measured against the
/// prototype (probe boxes of baseline-aligned rows) the browser baseline equals `floor(flutter baseline + 0.22)`: EN d1 18.75 -> 18,
/// AR d1 22.22 -> 22, EN body-s 17.745 -> 17, AR body-s 18.552 -> 18, EN caption 14.979 -> 15, EN countdown numeral 70.80 -> 71.
/// In a baseline-aligned row that changes the row height by up to 1 dp, and a card of several such rows drifts 1 to 2 dp against the
/// prototype.
///
/// This wraps ONE text (its resolved [style], the one the child draws) and reproduces the browser's baseline: the child is painted
/// `chrome - flutter` higher inside its own box and the box reports the browser's baseline, so the box extends below the baseline
/// exactly as the web line box does. Glyph pixels stay where a baseline-aligned neighbour puts them.
class GzChromeBaseline extends StatelessWidget {
  const GzChromeBaseline({required this.style, required this.child, super.key});

  final TextStyle style;
  final Widget child;

  static final Map<String, double> _offsets = {};

  /// `chrome - flutter` baseline offset of [style] (negative: the browser's baseline is higher).
  static double offsetOf(TextStyle style, TextDirection direction) {
    final key = '${style.fontFamily}|${style.fontSize}|${style.height}|${style.fontWeight}|${style.letterSpacing}|$direction';
    return _offsets[key] ??= _measure(style, direction);
  }

  static double _measure(TextStyle style, TextDirection direction) {
    final real = TextPainter(text: TextSpan(text: 'x', style: style.copyWith(color: null)), textDirection: direction)..layout();
    final flutter = real.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    real.dispose();
    return (flutter + 0.22).floorToDouble() - flutter;
  }

  @override
  Widget build(BuildContext context) => _ChromeBaseline(offset: offsetOf(style, Directionality.of(context)), child: child);
}

class _ChromeBaseline extends SingleChildRenderObjectWidget {
  const _ChromeBaseline({required this.offset, required super.child});

  final double offset;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderChromeBaseline(offset);

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    (renderObject as _RenderChromeBaseline).offset = offset;
  }
}

class _RenderChromeBaseline extends RenderShiftedBox {
  _RenderChromeBaseline(this._offset) : super(null);

  double _offset;

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
    (c.parentData! as BoxParentData).offset = Offset(0, _offset);
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final b = child?.getDistanceToActualBaseline(baseline);
    return b == null ? null : b + _offset;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => child?.getDryLayout(constraints) ?? constraints.smallest;
}
