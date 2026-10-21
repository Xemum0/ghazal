import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Venue;

import '../core/core.dart';
import '../foundation.dart';

/// The reference point of a drive time ("Salmiya", id `ref-salmiya`).
@immutable
class GzMapOrigin {
  const GzMapOrigin({required this.id, required this.name});

  final String id;
  final String name;
}

/// A small deterministic offset from the coordinates so each venue's illustration differs, with no randomness (the web `jitter`).
int _jitter(double n, int span) => (((math.sin(n * 12.9898) * 43758.5453).abs() % 1) * span).round();

/// MapPreview (web `MapPreview`, CL-VENU): a static illustration drawn from tokens only (no tiles, no blur): land, water down the left
/// edge, blocks, roads and one pin, with the area chip over it; the address, the drive time from [origin] and an "Open in Maps" action
/// under it. [areaName] is the venue's area, already localised.
class GzMapPreview extends StatelessWidget {
  const GzMapPreview({required this.venue, this.areaName, this.origin, this.onOpen, super.key});

  final Venue venue;
  final String? areaName;
  final GzMapOrigin? origin;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final lang = gz.locale.languageCode;
    final name = venue.name.of(lang);
    final drive = origin == null ? null : venue.distances[origin!.id];
    final sx = _jitter(venue.geo.lat, 60);
    final sy = _jitter(venue.geo.lng, 40);
    final block = venue.address.block;
    final street = venue.address.street;
    final address = [
      ?areaName,
      if (block != null && block.isNotEmpty) l.uiClientVenueInfoBlock(block),
      if (!street.isEmpty) street.of(lang),
    ].join(' · ');

    final plate = AspectRatio(
      aspectRatio: GzLayout.aspect16x10,
      child: ClipRRect(
        borderRadius: GzRadius.mdAll,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _MapPainter(colors: c, sx: sx, sy: sy),
            ),
            if (areaName != null)
              PositionedDirectional(
                bottom: GzSpace.s3,
                start: GzSpace.s3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.surfaceCanvas,
                    borderRadius: GzRadius.xsAll,
                    boxShadow: [BoxShadow(color: c.scrimRingFab, spreadRadius: GzStroke.hair)],
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2, vertical: GzSpace.s1),
                    child: GzText(areaName!, role: GzTextRole.caption, color: c.textStrong),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(image: true, label: l.uiClientVenueInfoMapPin(name), excludeSemantics: true, child: plate),
        const SizedBox(height: GzSpace.s3),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: GzSpace.s4,
          runSpacing: GzSpace.s2,
          children: [
            SizedBox(
              width: double.infinity,
              child: GzText(address, role: GzTextRole.bodyS, color: c.textPrimary, figures: true),
            ),
            if (drive != null && origin != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzIcon(GzIcons.car, size: GzIconSize.xs, color: c.iconSecondary),
                  const SizedBox(width: GzSpace.s1),
                  GzText(
                    l.uiClientVenueInfoMapDrive(l.commonCountMinutes(drive.minutes), origin!.name),
                    role: GzTextRole.caption,
                    color: c.textSecondary,
                    figures: true,
                  ),
                ],
              ),
            GzButton(label: l.uiClientVenueInfoMapOpen, variant: GzButtonVariant.tertiary, iconEnd: GzIcons.externalLink, onPressed: onOpen),
          ],
        ),
      ],
    );
  }
}

/// The 320 x 200 illustration of the web SVG, drawn scaled to the plate (the plate is 16:10, so `slice` crops nothing).
class _MapPainter extends CustomPainter {
  const _MapPainter({required this.colors, required this.sx, required this.sy});

  final GzColors colors;
  final int sx;
  final int sy;

  @override
  void paint(Canvas canvas, Size size) {
    final k = math.max(size.width / 320, size.height / 200);
    canvas
      ..save()
      ..translate((size.width - 320 * k) / 2, (size.height - 200 * k) / 2)
      ..scale(k);
    final x = sx.toDouble(), y = sy.toDouble();
    Paint fill(Color c) => Paint()..color = c;
    Paint stroke(Color c, double w, {bool round = false}) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = round ? StrokeCap.round : StrokeCap.butt;

    canvas.drawRect(const Rect.fromLTWH(0, 0, 320, 200), fill(colors.surfaceQuiet));
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(70 + x, 0)
        ..cubicTo(50 + x, 40, 90 + x, 70, 60 + x, 110)
        ..cubicTo(40 + x, 140, 80 + x, 170, 50 + x, 200)
        ..lineTo(0, 200)
        ..close(),
      fill(colors.surfacePlaceholder),
    );
    void block(double bx, double by, double w, double h) =>
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, w, h), const Radius.circular(4)), fill(colors.surfaceTint));
    block(120 + x, 20 + y, 44, 28);
    block(176 + x, 20 + y, 36, 28);
    block(120 + x, 60 + y, 28, 36);
    block(60 + y, 130 - y, 52, 30);
    block(230 - y, 110 + y, 44, 36);
    block(196 + x, 150, 52, 28);

    final minor = stroke(colors.borderHairline, 3);
    canvas
      ..drawPath(
        Path()
          ..moveTo(100 + x, 0)
          ..lineTo(100 + x, 200),
        minor,
      )
      ..drawPath(
        Path()
          ..moveTo(0, 100 + y)
          ..lineTo(320, 100 + y),
        minor,
      )
      ..drawPath(
        Path()
          ..moveTo(200 + x, 0)
          ..lineTo(150 + x, 200),
        minor,
      );

    final road = stroke(colors.surfaceRaised, 8, round: true);
    canvas
      ..drawPath(
        Path()
          ..moveTo(40 + x, 200)
          ..cubicTo(120 + x, 140, 160 + x, 90, 320, 60 + y),
        road,
      )
      ..drawPath(
        Path()
          ..moveTo(90 + x, 0)
          ..cubicTo(130 + x, 70, 150 + x, 120, 260 + x, 200),
        road,
      );

    canvas.save();
    canvas.translate(160, 92);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..cubicTo(-14, -16, -20, -26, -20, -36)
        ..arcToPoint(const Offset(20, -36), radius: const Radius.circular(20))
        ..cubicTo(20, -26, 14, -16, 0, 0)
        ..close(),
      fill(colors.surfaceDark),
    );
    canvas.drawCircle(const Offset(0, -36), 7, fill(colors.markKhayt));
    canvas
      ..restore()
      ..restore();
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.colors != colors || old.sx != sx || old.sy != sy;
}
