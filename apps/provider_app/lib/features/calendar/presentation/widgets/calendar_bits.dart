// Small pieces of the Month and Week views (web `RangeBar.tsx`, `RangeHint.tsx`, `Nudge.tsx`, `Legend.tsx`, `Skeletons.tsx`): the pinned bar of
// range selection, the hint drawing, the weekly "is your calendar up to date" card, the key of the marks and the loading stand-ins.
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show StaffRole;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/calendar_data.dart';

/// The pinned bar of range selection: the chosen dates as a figure and, in one row, Offer, Open and Block, the ONE gold primary at the inline-end.
class RangeBar extends StatelessWidget {
  const RangeBar({required this.summary, required this.count, required this.role, required this.offline, required this.onBlock, required this.onOpen, required this.onOffer, required this.onClear, super.key});

  final String summary;
  final int count;
  final StaffRole role;
  final bool offline;
  final VoidCallback onBlock;
  final VoidCallback onOpen;
  final VoidCallback onOffer;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final none = count == 0;
    final off = none || offline;
    return Container(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s3),
      decoration: BoxDecoration(color: c.surfaceCanvas, border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!none)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: GzSize.touchMin),
              child: Row(
                children: [
                  GzIcon(GzIcons.calendarDots, size: GzIconSize.md, color: c.iconPrimary),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(child: GzText(summary, role: GzTextRole.bodyS, color: c.textStrong, figures: true)),
                        const SizedBox(width: GzSpace.s3),
                        Semantics(label: context.l10n.commonCountDates(count), child: GzText(f.integer(count), role: GzTextRole.figBodyS, color: c.textGoldInk, figures: true)),
                      ],
                    ),
                  ),
                  GzIconButton(icon: GzIcons.close, label: l.commonActionClear, onPressed: onClear),
                ],
              ),
            ),
          const SizedBox(height: GzSpace.s1),
          Row(
            children: [
              if (canOffer(role)) Expanded(child: GzButton(label: l.hotelCalendarRangeOffer, variant: GzButtonVariant.secondary, size: GzButtonSize.cta, fullWidth: true, onPressed: off ? null : onOffer)),
              if (canBlock(role)) ...[
                const SizedBox(width: GzSpace.s2),
                Expanded(child: GzButton(label: l.hotelCalendarRangeOpen, variant: GzButtonVariant.secondary, size: GzButtonSize.cta, fullWidth: true, onPressed: off ? null : onOpen)),
                const SizedBox(width: GzSpace.s2),
                Expanded(child: GzButton(label: l.hotelCalendarRangeBlock, size: GzButtonSize.cta, fullWidth: true, onPressed: off ? null : onBlock)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// How to pick several dates, said as a drawing: two gold cells joined by the thread and an arrow that points the way the week runs.
class RangeHint extends StatelessWidget {
  const RangeHint({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    Widget cell() => Container(width: GzSpace.s6, height: GzSpace.s6, decoration: BoxDecoration(color: c.actionSelectedBg, borderRadius: GzRadius.smAll));
    return Container(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.s4, end: GzSpace.s2),
      decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.smAll),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: l.hotelCalendarHintDrag,
              child: Row(children: [cell(), Container(width: GzSpace.s3, height: GzStroke.thread, color: c.actionSelectedBg), cell(), const SizedBox(width: GzSpace.s2), GzIcon(GzIcons.arrowRight, size: GzIconSize.xs, color: c.iconSecondary)]),
            ),
          ),
          GzInfoButton(title: l.hotelCalendarActionSelect, paragraphs: [l.hotelCalendarHintDrag, l.hotelCalendarHintTap]),
        ],
      ),
    );
  }
}

/// The weekly "is your calendar up to date?" card (OQ-B-22): a quiet rose note, a glyph, a few words and the one action.
class CalNudge extends StatelessWidget {
  const CalNudge({required this.offline, required this.onConfirm, super.key});

  final bool offline;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    return Semantics(
      container: true,
      label: l.hotelCalendarNudgeTitle,
      child: Container(
        padding: const EdgeInsets.all(GzSpace.s3),
        decoration: BoxDecoration(color: c.surfaceTint, borderRadius: GzRadius.mdAll),
        child: Row(
          children: [
            Container(width: GzSize.avatarSm, height: GzSize.avatarSm, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceRaised), child: GzIcon(GzIcons.calendarCheck, size: GzIconSize.md, color: c.iconPrimary)),
            const SizedBox(width: GzSpace.s3),
            Expanded(child: GzText(l.hotelCalendarNudgeTitle, role: GzTextRole.title, color: c.textStrong)),
            const SizedBox(width: GzSpace.s3),
            GzButton(label: l.commonActionConfirm, variant: GzButtonVariant.secondary, size: GzButtonSize.sm, onPressed: offline ? null : onConfirm),
          ],
        ),
      ),
    );
  }
}

/// The key of the marks of the month grid, behind an (i): a shape and one word each.
class MonthKey extends StatelessWidget {
  const MonthKey({required this.soft, super.key});

  final bool soft;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    Widget row(Widget mark, String word) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSize.touchMin),
      child: Row(children: [SizedBox(width: GzSpace.s6, child: Center(child: mark)), const SizedBox(width: GzSpace.s3), GzText(word, role: GzTextRole.body, color: c.textPrimary)]),
    );
    Widget dot(Color fill, {bool ring = false}) => Container(width: GzSpace.s3, height: GzSpace.s3, decoration: BoxDecoration(shape: BoxShape.circle, color: ring ? null : fill, border: ring ? Border.all(color: fill, width: GzStroke.thread) : null));
    return GzInfoButton(
      title: l.hotelCalendarKeyTitle,
      children: [
        row(dot(c.textStrong), l.commonAvailabilityBooked),
        row(dot(c.textStrong, ring: true), l.commonAvailabilityHeld),
        row(Container(width: GzSpace.s3, height: GzStroke.thread, color: c.textStrong), l.commonAvailabilityBlocked),
        row(dot(c.textGoldInk), l.hotelCalendarRequestedLabel),
        if (soft) row(dot(c.textGoldInk, ring: true), l.hotelCalendarLegendSoft),
        const SizedBox(height: GzSpace.s2),
        GzText(l.hotelCalendarRequestNote, role: GzTextRole.bodyS, color: c.textSecondary),
      ],
    );
  }
}

class MonthSkeleton extends StatelessWidget {
  const MonthSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GzSkeleton(inlineSize: 152, blockSize: 28),
        const SizedBox(height: GzSpace.s4),
        for (var w = 0; w < 5; w++) ...[const GzSkeleton(blockSize: GzSize.calCellHeight), const SizedBox(height: GzSpace.s1)],
        const SizedBox(height: GzSpace.s5),
        const GzSkeleton(inlineSize: 216, blockSize: 28),
        const SizedBox(height: GzSpace.s3),
        const GzSkeleton(blockSize: 64),
        const SizedBox(height: GzSpace.s3),
        const GzSkeleton(blockSize: 64),
      ],
    ),
  );
}

class WeekSkeleton extends StatelessWidget {
  const WeekSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
    child: Column(children: [for (var i = 0; i < 7; i++) ...[const GzSkeleton(blockSize: 96), const SizedBox(height: GzSpace.s2)]]),
  );
}

class DaySkeleton extends StatelessWidget {
  const DaySkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [GzSkeleton(inlineSize: 168, blockSize: 28), SizedBox(height: GzSpace.s2), GzSkeleton(inlineSize: 216, blockSize: 20), SizedBox(height: GzSpace.s3), GzSkeleton(blockSize: 32), SizedBox(height: GzSpace.s3), GzSkeleton(blockSize: 96), SizedBox(height: GzSpace.s6), GzSkeleton(inlineSize: 168, blockSize: 28), SizedBox(height: GzSpace.s3), GzSkeleton(blockSize: 96)],
    ),
  );
}
