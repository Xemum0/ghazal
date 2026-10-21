import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show VenueResult, VenueType;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

const double _clusterRadius = GzSpace.s12;
const double _panThreshold = GzSpace.s6;
const double _zoomStep = 2.6;
const double _minSpan = 0.14;

/// A venue the voucher can be asked for shows its voucher price on the pin; anything else the standard price (a governmental facility its
/// rental fee, no notch).
bool pinIsVoucher(VenueResult r) => r.venue.voucherEnabled && r.venue.type != VenueType.governmental && r.price?.voucher != null;

String pinLabel(BuildContext context, VenueResult r) {
  final m = pinIsVoucher(r) ? r.price?.voucher : r.price?.amount;
  return m == null ? '' : context.gzFormat.integer((m.fils / 1000).round());
}

class _Pt {
  _Pt(this.row, this.x, this.y);

  final VenueResult row;
  final double x;
  final double y;
  String get id => row.venue.id;
}

class _View {
  const _View({this.zoom = 1, this.fx = 0.5, this.fy = 0.5, this.panX = 0, this.panY = 0});

  final double zoom;
  final double fx;
  final double fy;
  final double panX;
  final double panY;

  _View copyWith({double? zoom, double? fx, double? fy, double? panX, double? panY}) =>
      _View(zoom: zoom ?? this.zoom, fx: fx ?? this.fx, fy: fy ?? this.fy, panX: panX ?? this.panX, panY: panY ?? this.panY);
}

/// The brand-toned map of Results, drawn from tokens only (land, water, blocks, roads) and the venues' real coordinates. It is a schematic,
/// not tiles: east stays on the right in both languages (geography never mirrors, so pins are placed with physical offsets). Price-label pins
/// show the voucher price with a ticket notch (a perforation and a ticket glyph, so colour is never the only cue) or the standard price in a
/// plain pill; the selected pin fills ink. Pins closer than 48 draw as a cluster with a count; tapping one zooms in. Dragging pans; a drag of
/// more than 24 offers "Search this area".
class MapCanvas extends StatefulWidget {
  const MapCanvas({
    required this.rows,
    required this.selectedId,
    required this.onSelect,
    required this.zoomed,
    required this.onZoomedChange,
    this.here = false,
    this.onMoved,
    this.empty = false,
    super.key,
  });

  final List<VenueResult> rows;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  /// Where the person is (after the location is granted): a quiet dot, never a pin.
  final bool here;
  final VoidCallback? onMoved;
  final bool zoomed;
  final ValueChanged<bool> onZoomedChange;

  /// Draws no pins at all (the loading, empty or blocked map).
  final bool empty;

  @override
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas> {
  _View _view = const _View();
  Offset? _down;
  Offset _panStart = Offset.zero;
  bool _moved = false;

  @override
  void didUpdateWidget(MapCanvas old) {
    super.didUpdateWidget(old);
    if (!widget.zoomed && _view.zoom != 1) _view = const _View();
  }

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.l10n;
    final f = context.gzFormat;
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final height = box.maxHeight;
        final geo = widget.rows;
        final lats = [for (final r in geo) r.venue.geo.lat];
        final lngs = [for (final r in geo) r.venue.geo.lng];
        double mid(List<double> a) => (a.reduce(math.min) + a.reduce(math.max)) / 2;
        final hasGeo = geo.isNotEmpty;
        final spanLat = hasGeo ? math.max(lats.reduce(math.max) - lats.reduce(math.min), _minSpan) : _minSpan;
        final spanLng = hasGeo ? math.max(lngs.reduce(math.max) - lngs.reduce(math.min), _minSpan) : _minSpan;
        final maxLat = hasGeo ? mid(lats) + spanLat / 2 : 0.0;
        final minLng = hasGeo ? mid(lngs) - spanLng / 2 : 0.0;
        // The usable window of the map: under the top controls and above the carousel.
        const left = GzSpace.s16;
        final top = height * 0.36;
        final bw = width - 2 * left;
        final bh = height - top - height * 0.34;
        Offset place(double lat, double lng) {
          final fx = (lng - minLng) / spanLng;
          final fy = (maxLat - lat) / spanLat;
          return Offset(left + bw / 2 + (fx - _view.fx) * bw * _view.zoom + _view.panX, top + bh / 2 + (fy - _view.fy) * bh * _view.zoom + _view.panY);
        }

        final points = <_Pt>[for (final r in geo) () {
          final p = place(r.venue.geo.lat, r.venue.geo.lng);
          return _Pt(r, p.dx, p.dy);
        }()];
        // Greedy clustering in view coordinates: the first pin of a cluster is the anchor; the selected venue never hides inside a cluster.
        final clusters = <({_Pt anchor, List<_Pt> members})>[];
        final order = [...points]..sort((a, b) => (b.id == widget.selectedId ? 1 : 0) - (a.id == widget.selectedId ? 1 : 0));
        for (final p in order) {
          final hit = clusters.where((k) => math.sqrt(math.pow(k.anchor.x - p.x, 2) + math.pow(k.anchor.y - p.y, 2)) < _clusterRadius && p.id != widget.selectedId && k.anchor.id != widget.selectedId).firstOrNull;
          if (hit != null) {
            hit.members.add(p);
          } else {
            clusters.add((anchor: p, members: [p]));
          }
        }

        void zoomInto(List<_Pt> members) {
          final cx = members.fold<double>(0, (a, m) => a + m.x) / members.length;
          final cy = members.fold<double>(0, (a, m) => a + m.y) / members.length;
          final fx = (cx - left - bw / 2 - _view.panX) / (bw * _view.zoom) + _view.fx;
          final fy = (cy - top - bh / 2 - _view.panY) / (bh * _view.zoom) + _view.fy;
          setState(() => _view = _View(zoom: _view.zoom * _zoomStep, fx: fx, fy: fy));
          widget.onZoomedChange(true);
        }

        final ground = Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            // ignore: deprecated_member_use
            ..translate(_view.panX, _view.panY)
            // ignore: deprecated_member_use
            ..scale(_view.zoom),
          child: CustomPaint(size: Size(width, height), painter: _GroundPainter(c)),
        );

        Widget pin(_Pt p) {
          final on = p.id == widget.selectedId;
          final voucher = pinIsVoucher(p.row);
          final text = pinLabel(context, p.row);
          final m = voucher ? p.row.price?.voucher : p.row.price?.amount;
          final spoken = '${p.row.venue.name.of(gz.locale.languageCode)} ${voucher ? '${l.clientDiscoverMapVoucherPin} ' : ''}${m == null ? '' : f.money(m.fils)}';
          final fg = on ? c.textOnDark : c.textStrong;
          return GzPressable(
            key: ValueKey<String>('discover.pin.${p.id}'),
            onPressed: () => widget.onSelect(p.id),
            semanticLabel: spoken,
            selected: on,
            borderRadius: GzRadius.pillAll,
            builder: (context, st) => ConstrainedBox(
              constraints: const BoxConstraints(minWidth: GzSize.touchMin, minHeight: GzSize.touchMin),
              child: Center(
                child: Container(
                  height: GzSpace.s8,
                  padding: EdgeInsetsDirectional.only(start: voucher ? GzSpace.s2 : GzSpace.s3, end: GzSpace.s3),
                  decoration: BoxDecoration(
                    color: on ? c.surfaceDark : c.surfaceRaised,
                    borderRadius: voucher ? GzRadius.smAll : GzRadius.pillAll,
                    boxShadow: GzElevation.e2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (voucher) ...[
                        GzIcon(GzIcons.ticket, size: GzIconSize.xs, color: fg),
                        const SizedBox(width: GzSpace.s1),
                        _Perforation(color: fg),
                        const SizedBox(width: GzSpace.s1),
                      ],
                      Text(GzBidi.isolateLtr(text), style: gz.text(GzTextRole.figTitle).copyWith(color: fg, decoration: TextDecoration.none)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        Widget cluster(List<_Pt> members) => GzPressable(
          onPressed: () => zoomInto(members),
          semanticLabel: l.clientDiscoverMapCluster(members.length),
          borderRadius: GzRadius.pillAll,
          builder: (context, st) => ConstrainedBox(
            constraints: const BoxConstraints(minWidth: GzSize.touchMin, minHeight: GzSize.touchMin),
            child: Center(
              child: Container(
                width: GzSize.thumbSm,
                height: GzSize.thumbSm,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.surfaceRaised,
                  border: Border.all(color: c.textStrong, width: GzStroke.hair),
                  boxShadow: GzElevation.e2,
                ),
                child: Center(child: Text(GzBidi.isolateLtr(f.integer(members.length)), style: gz.text(GzTextRole.figTitle).copyWith(color: c.textStrong, decoration: TextDecoration.none))),
              ),
            ),
          ),
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) {
            _down = d.localPosition;
            _panStart = Offset(_view.panX, _view.panY);
            _moved = false;
          },
          onPanUpdate: (d) {
            final s = _down;
            if (s == null) return;
            final delta = d.localPosition - s;
            if (!_moved && delta.distance > _panThreshold) {
              _moved = true;
              widget.onMoved?.call();
            }
            setState(() => _view = _view.copyWith(panX: _panStart.dx + delta.dx, panY: _panStart.dy + delta.dy));
          },
          onPanEnd: (_) => _down = null,
          child: ClipRect(
            child: Stack(
              key: const ValueKey<String>('discover.map'),
              children: [
                Positioned.fill(child: ExcludeSemantics(child: ground)),
                if (!widget.empty)
                  for (final k in clusters)
                    // geography never mirrors: east stays on the right in both languages, so the offsets are physical
                    Positioned(
                      left: k.anchor.x, // gz-rules-ok
                      top: k.anchor.y,
                      child: FractionalTranslation(translation: const Offset(-0.5, -0.5), child: k.members.length > 1 ? cluster(k.members) : pin(k.anchor)),
                    ),
                if (widget.here)
                  Positioned(
                    left: width * 0.42 - GzSpace.s4, // gz-rules-ok
                    top: height * 0.5 - GzSpace.s4,
                    child: ExcludeSemantics(
                      child: Container(
                        width: GzSpace.s8,
                        height: GzSpace.s8,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceRaised, boxShadow: GzElevation.e2),
                        child: Center(child: GzIcon(GzIcons.navigate, size: GzIconSize.sm, color: c.textStrong)),
                      ),
                    ),
                  ),
                if (widget.zoomed)
                  PositionedDirectional(
                    start: GzSpace.gutter,
                    top: MediaQuery.paddingOf(context).top + GzSpace.s24 + GzSpace.s1,
                    child: GzPressable(
                      key: const ValueKey<String>('discover.map.zoomout'),
                      onPressed: () {
                        setState(() => _view = const _View());
                        widget.onZoomedChange(false);
                      },
                      semanticLabel: l.clientDiscoverMapZoomOut,
                      borderRadius: GzRadius.pillAll,
                      builder: (context, st) => Container(
                        constraints: const BoxConstraints(minHeight: GzSize.touchMin),
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4),
                        decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.pillAll, boxShadow: GzElevation.e2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GzIcon(GzIcons.minus, size: GzIconSize.sm, color: c.textStrong),
                            const SizedBox(width: GzSpace.s2),
                            Text(l.clientDiscoverMapZoomOut, style: gz.text(GzTextRole.button).copyWith(color: c.textStrong, decoration: TextDecoration.none)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The dashed perforation of a ticket pin (a 16 high vertical dash line).
class _Perforation extends StatelessWidget {
  const _Perforation({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(GzStroke.hair, GzSpace.s4), painter: _DashPainter(color));
}

class _DashPainter extends CustomPainter {
  const _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = GzStroke.hair;
    for (var y = 0.0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0.5, y), Offset(0.5, math.min(y + 2, size.height)), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// The decorative ground: land, water, blocks and roads of a 390 x 844 sketch, scaled to fill the frame (slice).
class _GroundPainter extends CustomPainter {
  const _GroundPainter(this.c);

  final GzColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.max(size.width / 390, size.height / 844);
    canvas
      ..save()
      ..translate((size.width - 390 * s) / 2, (size.height - 844 * s) / 2)
      ..scale(s);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 390, 844), Paint()..color = c.surfaceQuiet);
    final water = Path()
      ..moveTo(390, 0)
      ..lineTo(210, 0)
      ..cubicTo(250, 70, 230, 120, 290, 170)
      ..cubicTo(340, 210, 330, 270, 390, 300)
      ..close();
    canvas.drawPath(water, Paint()..color = c.surfacePlaceholder);
    final block = Paint()..color = c.surfaceTint;
    for (final r in const <Rect>[
      Rect.fromLTWH(40, 260, 64, 40),
      Rect.fromLTWH(120, 300, 48, 56),
      Rect.fromLTWH(230, 360, 72, 44),
      Rect.fromLTWH(60, 420, 56, 48),
      Rect.fromLTWH(190, 470, 60, 40),
      Rect.fromLTWH(290, 450, 64, 52),
      Rect.fromLTWH(100, 540, 72, 44),
      Rect.fromLTWH(250, 560, 56, 48),
    ]) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), block);
    }
    final minor = Paint()
      ..color = c.borderHairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas
      ..drawLine(const Offset(0, 330), const Offset(390, 330), minor)
      ..drawLine(const Offset(0, 520), const Offset(390, 520), minor)
      ..drawLine(const Offset(110, 180), const Offset(110, 844), minor)
      ..drawLine(const Offset(280, 300), const Offset(280, 844), minor);
    final road = Paint()
      ..color = c.surfaceRaised
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawPath(Path()..moveTo(0, 640)..cubicTo(120, 560, 220, 470, 390, 400), road)
      ..drawPath(Path()..moveTo(150, 180)..cubicTo(170, 300, 200, 420, 330, 844), road)
      ..drawPath(Path()..moveTo(20, 360)..cubicTo(120, 330, 240, 330, 390, 350), road)
      ..restore();
  }

  @override
  bool shouldRepaint(_GroundPainter old) => old.c != c;
}
