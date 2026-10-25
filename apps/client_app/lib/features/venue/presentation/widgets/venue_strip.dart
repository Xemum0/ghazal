import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/venue_model.dart';
import '../venue_glyphs.dart';
import 'venue_money.dart';

/// DateStrip (CL-VENU-01, direction rule 8): the ruled YOUR DATE strip. A hairline above and below, not a panel. It answers the two
/// questions of the visit: is the hall free on our date, and what will it cost. The date in the display face, the availability as a pill,
/// the guests as a glyph and a figure, the two prices of the quote as glyphs and figures (ADR 0033, 0034). A held date is its pill; an
/// unavailable date offers the nearest free dates as chips instead of a dead end; no date is a small calendar drawing and two words.
class VenueDateStrip extends StatelessWidget {
  const VenueDateStrip({
    required this.date,
    required this.guests,
    required this.status,
    required this.prices,
    required this.row,
    required this.onOpenCalendar,
    required this.onEditGuests,
    required this.onPickDate,
    this.guest = false,
    this.owned = false,
    this.windowTitle,
    this.nearest = const <LocalDate>[],
    this.onHow,
    super.key,
  });

  final LocalDate? date;
  final int? guests;
  final DayStatusKind status;
  final QuotePrices? prices;
  final PackageRow? row;
  final bool guest;
  final bool owned;
  final String? windowTitle;
  final List<LocalDate> nearest;
  final VoidCallback onOpenCalendar;
  final VoidCallback onEditGuests;
  final VoidCallback? onHow;
  final ValueChanged<LocalDate> onPickDate;

  /// The loading skeleton of the strip.
  static Widget loading(BuildContext context) => _frame(
    context,
    const [
      GzSkeleton(inlineSize: 200, blockSize: 32),
      SizedBox(height: GzSpace.s3),
      GzSkeleton(inlineSize: 96, blockSize: 20),
      SizedBox(height: GzSpace.s3),
      GzSkeleton(blockSize: 72),
    ],
  );

  static Widget _frame(BuildContext context, List<Widget> children) {
    final c = context.gz.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
      child: Container(
        decoration: BoxDecoration(
          border: Border.symmetric(horizontal: BorderSide(color: c.borderHairline, width: GzStroke.hair)),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    final f = context.gzFormat;
    final unavailable = status == DayStatusKind.unavailable;
    final priced = prices != null && row != null && (status == DayStatusKind.available || status == DayStatusKind.held);
    return _frame(context, [
      GzPressable(
        onPressed: onOpenCalendar,
        semanticLabel: '${l.clientVenueDateLabel}. ${l.clientVenueDateChangeLabel}',
        minHeight: GzSize.controlLg,
        scale: 1,
        child: Row(
          children: [
            if (date != null)
              const GzIcon(GzIcons.calendar, size: GzIconSize.md, tone: GzIconTone.secondary)
            else
              const GzIllustration(GzIllustrationName.calendar, size: GzIllustrationSize.md),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: GzText(date == null ? l.clientVenueDateChoose : shortDay(f, date!), role: GzTextRole.d1, color: c.textStrong, figures: date != null),
            ),
            const SizedBox(width: GzSpace.s3),
            GzIcon(date != null ? GzIcons.chevronDown : GzIcons.chevronRight, size: GzIconSize.sm, tone: GzIconTone.secondary),
          ],
        ),
      ),
      if (date != null) ...[
        const SizedBox(height: GzSpace.s2),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: GzSpace.s5,
          children: [
            if (status == DayStatusKind.available) const GzStatusPill(status: GzStatus.available),
            if (status == DayStatusKind.held) Semantics(label: l.clientVenueHeldSr, child: const GzStatusPill(status: GzStatus.held)),
            if (unavailable) const GzStatusPill(status: GzStatus.unavailable),
            GzPressable(
              onPressed: onEditGuests,
              semanticLabel: l.clientVenueGuestsChangeLabel,
              scale: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (guests != null) ...[
                    GzFactChip(icon: GzIcons.usersThree, label: l.clientVenueGuestsLabel, value: f.integer(guests!)),
                    const SizedBox(width: GzSpace.s2),
                    const GzIcon(GzIcons.edit, size: GzIconSize.xs, tone: GzIconTone.secondary),
                  ] else ...[
                    const GzIcon(GzIcons.usersThree, size: GzIconSize.sm, tone: GzIconTone.secondary),
                    const SizedBox(width: GzSpace.s2),
                    GzText(l.clientVenueGuestsAdd, role: GzTextRole.bodyS, color: c.textPrimary),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
      if (unavailable) ...[
        const SizedBox(height: GzSpace.s2),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (nearest.isNotEmpty)
                Wrap(
                  spacing: GzSpace.s2,
                  runSpacing: GzSpace.s2,
                  children: [
                    for (final d in nearest) GzChip(label: shortDay(f, d), iconStart: GzIcons.calendar, figures: true, onPressed: () => onPickDate(d)),
                  ],
                ),
              if (nearest.isNotEmpty) const SizedBox(height: GzSpace.s2),
              GzButton(label: l.clientVenueSeeAllDates, variant: GzButtonVariant.tertiary, iconEnd: GzIcons.calendar, onPressed: onOpenCalendar),
            ],
          ),
        ),
      ],
      if (priced) ...[
        const SizedBox(height: GzSpace.s2),
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair)),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: GzSpace.s4, bottom: GzSpace.s1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PriceBlock(prices: prices!, guest: guest, owned: owned, onHow: prices!.eligible ? onHow : null),
                if (row!.belowMinimum || (prices!.eligible && windowTitle != null)) ...[
                  const SizedBox(height: GzSpace.s3),
                  GzFactRow(
                    children: [
                      if (row!.belowMinimum)
                        GzFactChip(
                          icon: GzIcons.usersThree,
                          value: '${f.integer(row!.minGuests)}+',
                          label: l.clientVenueEstimateMinimum(guestsText(f, row!.minGuests)),
                          tone: GzFactTone.accent,
                        ),
                      if (prices!.eligible && windowTitle != null)
                        GzFactChip(icon: GzIcons.percent, value: windowTitle, label: l.clientVenueWindowApplied(windowTitle!), tone: GzFactTone.accent),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ]);
  }
}

/// The slim bar that appears under the top bar once the strip has scrolled away: date, availability, change.
class VenueDateStripCompact extends StatelessWidget {
  const VenueDateStripCompact({required this.date, required this.status, required this.onPressed, super.key});

  final LocalDate? date;
  final DayStatusKind status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    final f = context.gzFormat;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceCanvas,
        border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair)),
      ),
      child: GzPressable(
        onPressed: onPressed,
        semanticLabel: l.clientVenueDateChangeLabel,
        minHeight: GzSize.controlMd,
        scale: 1,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
          child: Row(
            children: [
              const GzIcon(GzIcons.calendar, size: GzIconSize.sm, tone: GzIconTone.secondary),
              const SizedBox(width: GzSpace.s3),
              Expanded(child: GzText(date == null ? l.clientVenueDateChoose : shortDay(f, date!), role: GzTextRole.title, color: c.textStrong, figures: date != null)),
              if (status == DayStatusKind.available) const GzStatusPill(status: GzStatus.available),
              if (status == DayStatusKind.held) const GzStatusPill(status: GzStatus.held),
              if (status == DayStatusKind.unavailable) const GzStatusPill(status: GzStatus.unavailable),
              const SizedBox(width: GzSpace.s3),
              const GzIcon(GzIcons.chevronDown, size: GzIconSize.sm, tone: GzIconTone.secondary),
            ],
          ),
        ),
      ),
    );
  }
}
