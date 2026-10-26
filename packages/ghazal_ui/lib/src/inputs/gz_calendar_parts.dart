import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';
import 'gz_calendar_model.dart';

/// first | mid | last | only: where a peak column sits in its contiguous band (drives the band's rounded outer corners).
enum GzPeakPos { first, mid, last, only }

GzPeakPos gzPeakPos(List<bool> row, int i) {
  final before = i > 0 && row[i - 1];
  final after = i < row.length - 1 && row[i + 1];
  if (before && after) return GzPeakPos.mid;
  if (before) return GzPeakPos.last;
  if (after) return GzPeakPos.first;
  return GzPeakPos.only;
}

/// One day cell of [GzCalendar]: a 52 dp high button with the figure, an optional price line and a held bead. [role] is the position
/// in the chosen date or range (`only`, `start`, `end`, `mid`); a range draws the gold thread along the foot of every cell from
/// endpoint to endpoint (it draws on from the inline-start, 200 ms, instant under reduced motion).
class GzCalendarDay extends StatelessWidget {
  const GzCalendarDay({
    required this.iso,
    required this.dayLabel,
    required this.status,
    required this.selectable,
    required this.semanticLabel,
    this.priceLabel,
    this.role,
    this.range = false,
    this.today = false,
    this.focusNode,
    this.onPressed,
    this.onFocusChange,
    super.key,
  });

  final String iso;
  final String dayLabel;
  final String? priceLabel;
  final GzDayStatus status;
  final bool selectable;
  final String? role;
  final bool range;
  final bool today;
  final String semanticLabel;
  final FocusNode? focusNode;
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onFocusChange;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final selected = role == 'start' || role == 'end' || role == 'only';
    final inRange = role == 'mid';
    final struck = status == GzDayStatus.booked || status == GzDayStatus.blocked;
    final figColor = selected ? c.textOnGold : (status == GzDayStatus.closed ? c.iconDisabled : (struck ? c.borderControl : c.textStrong));
    final border = selected
        ? c.markKhayt
        : (today ? c.borderFocus : (status == GzDayStatus.blocked ? c.borderStrong : c.surfaceCanvas.withValues(alpha: 0)));
    final rings = selected
        ? [
            // a 2 dp canvas ring and a 1 dp gold-600 ring outside it
            BoxShadow(color: c.markDecor, spreadRadius: GzStroke.thread + GzStroke.hair),
            BoxShadow(color: c.surfaceCanvas, spreadRadius: GzStroke.thread),
          ]
        : const <BoxShadow>[];
    return Focus(
      canRequestFocus: false,
      onFocusChange: onFocusChange,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (role == 'start' || role == 'end' || role == 'mid')
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: GzStroke.thread,
              height: GzStroke.thread,
              child: _ThreadSegment(color: c.markKhayt),
            ),
          Positioned.fill(
            child: GzPressable(
              focusNode: focusNode,
              onPressed: onPressed,
              semanticLabel: semanticLabel,
              selected: selected ? true : null,
              borderRadius: GzRadius.smAll,
              scale: selectable ? GzMotion.scalePress : 1,
              builder: (context, st) => Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: selected ? (st.pressed ? c.markPressed : c.markKhayt) : (st.pressed && selectable ? c.surfaceQuiet : null),
                  borderRadius: GzRadius.smAll,
                  border: Border.all(color: border, width: GzStroke.hair),
                  boxShadow: rings,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          gzFigText(
                            context,
                            dayLabel,
                            role: GzTextRole.calDay,
                            color: figColor,
                            weight: inRange ? gz.text(GzTextRole.priceStrong).fontWeight : null,
                            decoration: struck ? TextDecoration.lineThrough : null,
                          ),
                          if (priceLabel != null)
                            gzFigText(context, priceLabel!, role: GzTextRole.calPrice, color: selected ? c.textOnGold : c.textSecondary),
                        ],
                      ),
                    ),
                    if (status == GzDayStatus.held)
                      PositionedDirectional(
                        top: GzSpace.s2,
                        end: GzSpace.s2,
                        child: _HeldBead(color: selected ? c.textOnGold : c.iconAccent),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeldBead extends StatelessWidget {
  const _HeldBead({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: 0.7853981633974483,
    child: SizedBox.square(
      dimension: GzSize.knotBead,
      child: ColoredBox(color: color),
    ),
  );
}

class _ThreadSegment extends StatelessWidget {
  const _ThreadSegment({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final reduced = GzReducedMotion.of(context);
    // decoration, out of the semantics tree for the reason given at `GzDrawOnce`
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduced ? 1 : 0, end: 1),
        duration: GzReducedMotion.movement(context, GzMotion.durationBase),
        curve: GzMotion.easeStandard,
        builder: (context, v, child) => Transform.scale(scaleX: v, alignment: AlignmentDirectional.centerStart, child: child),
        child: ColoredBox(color: color),
      ),
    );
  }
}

/// One legend entry under the grid: a 24 dp swatch drawn like the day it explains, and its word.
class GzCalendarLegendItem extends StatelessWidget {
  const GzCalendarLegendItem({required this.status, super.key});

  /// `held`, `booked`, `blocked` or `peak`.
  final GzDayStatus status;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l10n = context.gzL10n;
    final word = switch (status) {
      GzDayStatus.held => l10n.commonAvailabilityHeld,
      GzDayStatus.booked => l10n.commonAvailabilityBooked,
      GzDayStatus.blocked => l10n.commonAvailabilityBlocked,
      _ => l10n.commonCalendarPeak,
    };
    Widget? fig;
    switch (status) {
      case GzDayStatus.held:
        fig = Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            gzFigText(context, f.plain(f.integer(14)), role: GzTextRole.calDay, color: c.textStrong),
            PositionedDirectional(
              top: GzSpace.s2,
              end: GzSpace.s2,
              child: _HeldBead(color: c.iconAccent),
            ),
          ],
        );
      case GzDayStatus.booked:
        fig = gzFigText(
          context,
          f.plain(f.integer(12)),
          role: GzTextRole.calDay,
          color: c.borderControl,
          decoration: TextDecoration.lineThrough,
        );
      case GzDayStatus.blocked:
        fig = gzFigText(
          context,
          f.plain(f.integer(13)),
          role: GzTextRole.calDay,
          color: c.borderControl,
          decoration: TextDecoration.lineThrough,
        );
      default:
        fig = null;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Container(
            width: GzSize.iconMd,
            height: GzSize.iconMd,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: status == GzDayStatus.peak ? c.surfaceTintSoft : null,
              borderRadius: GzRadius.xsAll,
              border: status == GzDayStatus.blocked
                  ? Border.all(color: c.borderStrong, width: GzStroke.hair)
                  : (status == GzDayStatus.peak ? Border.all(color: c.borderHairline, width: GzStroke.hair) : null),
            ),
            child: fig,
          ),
        ),
        const SizedBox(width: GzSpace.s2),
        GzText(word, role: GzTextRole.caption, color: c.textSecondary),
      ],
    );
  }
}
