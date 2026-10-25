// ProposalList (web `ProposalList.tsx`): the dates a venue has picked, in the order the couple will see them (ADR 0034: no words). One row per
// date: a calendar glyph, the short date, then what the same booking costs there as a ticket glyph and an amount. A date that normally costs
// more keeps the quoted voucher price (a lock glyph and the date's own price struck); a cheaper date shows a trend-down glyph and the
// difference; a date taken while the sheet was open is struck and says "Taken". Remove is the close glyph at inline-end.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import 'dc_blocks.dart';

class ProposalEntry {
  const ProposalEntry({required this.date, required this.fils, required this.delta, this.normally, this.taken = false});

  final String date;

  /// What the booking costs on this date as the couple will see it (integer fils).
  final int fils;

  /// Against the original voucher total: negative = lower, 0 = the same or held.
  final int delta;

  /// By how much the date normally costs more than the quoted voucher price (the venue holds the price and absorbs it).
  final int? normally;
  final bool taken;
}

class ProposalList extends StatelessWidget {
  const ProposalList({required this.entries, required this.onRemove, this.readOnly = false, super.key});

  final List<ProposalEntry> entries;
  final ValueChanged<String> onRemove;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cl = context.gzL10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    return Semantics(
      container: true,
      label: l.hotelDecisionsProposeChosen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < entries.length; i++)
            Builder(
              builder: (_) {
                final e = entries[i];
                final day = f.date(e.date, DateStyle.short);
                final held = !e.taken && (e.normally ?? 0) > 0;
                final lower = !e.taken && !held && e.delta < 0;
                return DecoratedBox(
                  decoration: BoxDecoration(border: i == entries.length - 1 ? null : Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: GzSize.controlLg),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: GzSpace.s2),
                      child: Row(
                        children: [
                          DcDiskIcon(e.taken ? GzIcons.calendarX : GzIcons.calendarCheck, danger: e.taken),
                          const SizedBox(width: GzSpace.s3),
                          Expanded(
                            child: Text(
                              day,
                              style: context.gz.text(GzTextRole.body).copyWith(color: e.taken ? c.textSecondary : c.textStrong, decoration: e.taken ? TextDecoration.lineThrough : TextDecoration.none),
                            ),
                          ),
                          if (e.taken)
                            Row(mainAxisSize: MainAxisSize.min, children: [GzIcon(GzIcons.warningCircle, size: GzIconSize.xs, tone: GzIconTone.danger), const SizedBox(width: GzSpace.s1), GzText(l.hotelDecisionsProposeTakenBadge, role: GzTextRole.caption, color: c.textDanger)])
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Semantics(
                                  label: cl.commonVoucherPrice,
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [GzIcon(GzIcons.ticket, size: GzIconSize.xs, tone: GzIconTone.success), const SizedBox(width: GzSpace.s1), GzPrice(fils: e.fils, size: GzPriceSize.strong)]),
                                ),
                                if (held)
                                  Semantics(
                                    label: l.hotelDecisionsProposeHeldLabel,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GzIcon(GzIcons.lock, size: GzIconSize.xs, tone: GzIconTone.accent),
                                        const SizedBox(width: GzSpace.s1),
                                        Directionality(textDirection: TextDirection.ltr, child: Text(f.money(e.fils + (e.normally ?? 0)), style: context.gz.text(GzTextRole.figCaption).copyWith(color: c.textSecondary, decoration: TextDecoration.lineThrough))),
                                      ],
                                    ),
                                  )
                                else if (lower)
                                  Semantics(
                                    label: l.hotelDecisionsProposeLowerLabel,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GzIcon(GzIcons.trendDown, size: GzIconSize.xs, tone: GzIconTone.success, mirror: false),
                                        const SizedBox(width: GzSpace.s1),
                                        GzText(f.money(e.delta.abs()), role: GzTextRole.figCaption, color: c.textSuccess, figures: true),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          if (!readOnly) GzBarButton(icon: GzIcons.close, label: l.hotelDecisionsProposeRemove(f.plain(day)), onPressed: () => onRemove(e.date)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// A glyph in a rose disk like [DcDisk], red-toned when the date was taken.
class DcDiskIcon extends StatelessWidget {
  const DcDiskIcon(this.icon, {this.danger = false, super.key});

  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: GzSize.avatarSm,
      height: GzSize.avatarSm,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: context.gz.colors.surfaceTint, shape: BoxShape.circle),
      child: GzIcon(icon, size: GzIconSize.md, tone: danger ? GzIconTone.danger : GzIconTone.primary),
    ),
  );
}
