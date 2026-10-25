import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

/// The rating input (web `StarRow`): five stars in 48 (overall, glyph large) or 44 (category, glyph medium) targets, filling from the
/// inline-start edge. On is gold ink, off a hairline outline. [spread] runs the five stars over the full width.
class ReviewStars extends StatelessWidget {
  const ReviewStars({
    required this.id,
    required this.label,
    required this.value,
    required this.onChange,
    this.large = false,
    this.disabled = false,
    super.key,
  });

  final String id;
  final String label;
  final double value;
  final ValueChanged<double> onChange;

  /// The overall score: 48 targets, a large glyph, spread over the full width.
  final bool large;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final target = large ? GzSize.controlMd : GzSize.controlSm;
    return Semantics(
      container: true,
      label: label,
      child: Row(
        mainAxisSize: large ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: large ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
        children: [
          for (var i = 1; i <= 5; i++)
            GzPressable(
              key: ValueKey<String>('review.star.$id.$i'),
              onPressed: disabled ? null : () => onChange(value == i && !large ? 0 : i.toDouble()),
              semanticLabel: '$label: $i',
              scale: 1,
              minHeight: target,
              minWidth: target,
              borderRadius: GzRadius.smAll,
              child: SizedBox(
                width: target,
                height: target,
                child: Center(
                  child: GzIcon(
                    i <= value ? GzIcons.starFill : GzIcons.star,
                    size: large ? GzIconSize.lg : GzIconSize.md,
                    color: disabled ? c.iconDisabled : (i <= value ? c.textGoldInk : c.borderControl),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One category row (web `.rvw-cat`): glyph and word at inline-start, five stars at inline-end, 52 high, a hairline under it.
class ReviewCategoryRow extends StatelessWidget {
  const ReviewCategoryRow({
    required this.id,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChange,
    this.last = false,
    this.disabled = false,
    super.key,
  });

  final String id;
  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChange;
  final bool last;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: GzSize.controlCta),
      decoration: last
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
              ),
            ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                GzIcon(icon, size: GzIconSize.sm, color: c.iconSecondary),
                const SizedBox(width: GzSpace.s3),
                Flexible(
                  child: GzText(label, role: GzTextRole.body, color: c.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(width: GzSpace.s3),
          ReviewStars(id: id, label: label, value: value, onChange: onChange, disabled: disabled),
        ],
      ),
    );
  }
}

/// The media rows (web `.rvw-media`): slots of three per row, square, 8 apart: the photographs, then the add tile, then blanks.
class ReviewMediaGrid extends StatelessWidget {
  const ReviewMediaGrid({required this.photos, required this.canAdd, required this.onAdd, required this.onRemove, this.busy = false, super.key});

  static const int perRow = 3;

  final List<String> photos;
  final bool canAdd;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final used = canAdd ? photos.length + 1 : photos.length;
    final count = ((used + perRow - 1) ~/ perRow) * perRow;
    final rows = count == 0 ? 1 : count ~/ perRow;
    return Column(
      children: [
        for (var r = 0; r < rows; r++) ...[
          if (r > 0) const SizedBox(height: GzSpace.s2),
          Row(
            children: [
              for (var k = 0; k < perRow; k++) ...[if (k > 0) const SizedBox(width: GzSpace.s2), Expanded(child: _slot(context, r * perRow + k))],
            ],
          ),
        ],
      ],
    );
  }

  Widget _slot(BuildContext context, int i) {
    if (i < photos.length) {
      return AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: GzRadius.mdAll,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GzPhoto(src: photos[i], alt: ''),
              PositionedDirectional(
                top: GzSpace.s1,
                end: GzSpace.s1,
                child: GzIconButton(
                  icon: GzIcons.close,
                  label: context.l10n.clientReviewsRewardsWriteMediaRemove,
                  onPressed: busy ? null : () => onRemove(i),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (i == photos.length && canAdd) {
      final c = context.gz.colors;
      return AspectRatio(
        aspectRatio: 1,
        child: GzPressable(
          key: const ValueKey<String>('review.photo.add'),
          onPressed: busy ? null : onAdd,
          semanticLabel: context.l10n.clientReviewsRewardsWriteMediaAdd,
          borderRadius: GzRadius.mdAll,
          child: CustomPaint(
            painter: _Dashed(color: c.borderStrong, radius: GzRadius.md),
            child: Center(
              child: GzIcon(GzIcons.camera, size: GzIconSize.lg, color: busy ? c.iconDisabled : c.textPrimary),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// A dashed hairline rounded box (Flutter has no dashed border; the kit's one is private to the compare tray).
class _Dashed extends CustomPainter {
  const _Dashed({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = GzStroke.hair / 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(inset, inset, size.width - GzStroke.hair, size.height - GzStroke.hair), Radius.circular(radius)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = GzStroke.hair;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 3), paint);
        d += 6;
      }
    }
  }

  @override
  bool shouldRepaint(_Dashed old) => old.color != color || old.radius != radius;
}
