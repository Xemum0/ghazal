// The sections of the Today screen (web `TodayBlocks.tsx`), one widget each so the role variants are a different order of the same blocks. Content
// comes from the repositories through `today_data`; every number goes through the shared formatter. There is no money here: Ghazal holds no event
// payment, so the tiles count requests, vouchers and dates (ADR 0033 D7). Text diet: a glyph and a figure say what a sentence used to.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show clockProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/today_data.dart';
import 'need_queue.dart';
import 'today_bits.dart';
import 'today_header.dart';

/// What Today lists itself: the rows that need a decision from a person. Messages, reviews and the calendar check wait behind the count.
const List<NeedKind> kOnToday = [NeedKind.request, NeedKind.visit];

/// Today shows the nearest few; the rest sit behind the count (the full queue).
const int kTodayRows = 3;

/// One section: the gutter, a head and its content.
class TodaySection extends StatelessWidget {
  const TodaySection({required this.label, required this.children, super.key});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    child: Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s2), children[i]],
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------- the status of the Ink band

/// What needs the partner, as a figure: how many, and when the first deadline falls (ADR 0008 D4 step 1). The sentence is read, not shown.
class TodayStatus extends StatelessWidget {
  const TodayStatus({required this.items, super.key});

  final List<NeedItem> items;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final requests = items.where((e) => e.kind == NeedKind.request).toList();
    final visits = items.where((e) => e.kind == NeedKind.visit).toList();
    if (requests.isNotEmpty) {
      final first = requests.first.sla;
      return StatusBand(
        icon: GzIcons.calendarDots,
        figure: f.integer(requests.length),
        say: l.hotelTodayStatusNeeds(requests.length),
        extra: first == null
            ? null
            : TimeLeft(minutes: first.minutesLeft, tone: leftToneOf(first.state), onDark: true, large: true, say: l.hotelTodayStatusFirst),
      );
    }
    if (visits.isNotEmpty) {
      return StatusBand(icon: GzIcons.calendarPlus, figure: f.integer(visits.length), say: l.hotelTodayStatusVisits(visits.length));
    }
    return StatusBand(icon: GzIcons.checkCircle, say: l.hotelTodayAllClear);
  }
}

// ---------------------------------------------------------------- needs you

class NeedsYouBlock extends ConsumerWidget {
  const NeedsYouBlock({required this.entries, this.initiallyOpen, super.key});

  final List<NeedItem> entries;
  final String? initiallyOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.gzFormat;
    final nav = GzNavigatorScope.of(context);
    final confirmed = ref.watch(calendarConfirmedProvider);
    final all = entries.where((e) => !(confirmed && e.kind == NeedKind.calendar)).toList();
    final eligible = all.where((e) => kOnToday.contains(e.kind)).toList();
    final shown = eligible.take(kTodayRows).toList();
    final total = all.length;
    final heading = l.hotelTodayNeedsYouTitle;
    return TodaySection(
      label: heading,
      children: [
        SectionLink(
          title: heading,
          count: total > 0 ? f.integer(total) : null,
          hint: l.hotelTodaySeeAllCount(f.integer(total)),
          onPressed: total > 0 ? () => nav.push('HL-TODY-02') : null,
        ),
        if (shown.isEmpty) const AllClearLine() else NeedQueue(entries: shown, initiallyOpen: initiallyOpen),
      ],
    );
  }
}

/// The queue is empty: a drawing, the two-word state and the next thing on the day as facts (a calm check, not a celebration).
class AllClearLine extends ConsumerWidget {
  const AllClearLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final today = ref.watch(partnerTodayProvider).value;
    final now = ref.watch(clockProvider)();
    final next = nextEventOf(today, now, lang);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s2),
      child: Row(
        children: [
          const GzIllustration(GzIllustrationName.seal, size: GzIllustrationSize.md),
          const SizedBox(width: GzSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GzText(l.hotelTodayAllClear, role: GzTextRole.uiTitle, color: c.textStrong),
                if (next != null) ...[
                  const SizedBox(height: GzSpace.s2),
                  GzFactRow(
                    label: l.hotelTodayNextLabel,
                    children: [
                      TextFact(icon: GzIcons.clock, label: l.hotelTodayFactTime, text: f.time(f.instant('${f.isoDay(now)}T${next.start}'))),
                      TextFact(icon: GzIcons.hall, label: l.hotelTodayFactHall, text: next.hall, muted: true),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- quick actions

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.name, required this.onPressed, this.wide = false});

  final IconData icon;
  final String label;
  final String name;
  final VoidCallback onPressed;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final glyph = GzIcon(icon, size: GzIconSize.md, color: c.iconPrimary);
    final text = ExcludeSemantics(
      child: GzText(label, role: GzTextRole.button, color: c.textStrong, textAlign: TextAlign.center, maxLines: 1),
    );
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: name,
      borderRadius: GzRadius.mdAll,
      minHeight: 0,
      minWidth: 0,
      scale: 1,
      builder: (context, st) => Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: wide ? GzSize.controlLg : GzSize.rowMin),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2, vertical: GzSpace.s3),
        decoration: BoxDecoration(
          color: st.pressed ? c.surfaceQuiet : c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderStrong, width: GzStroke.hair),
        ),
        child: wide
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  glyph,
                  const SizedBox(width: GzSpace.s2),
                  Flexible(child: text),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  glyph,
                  const SizedBox(height: GzSpace.s2),
                  text,
                ],
              ),
      ),
    );
  }
}

class QuickActions extends StatelessWidget {
  const QuickActions({this.prices = true, this.block = true, super.key});

  final bool prices;
  final bool block;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final actions = <(IconData, String, String, VoidCallback)>[
      (GzIcons.qrCode, l.hotelTodayRedeem, l.hotelTodayRedeemName, () => nav.push('HL-BOOK-06')),
      if (block)
        (
          GzIcons.lock,
          l.hotelTodayBlockDate,
          l.hotelTodayBlockName,
          () => nav.openSheet('HL-CALN-04', options: const GzSheetOptions(params: {'mode': 'block'})),
        ),
      if (prices) (GzIcons.offer, l.hotelTodayNewPrice, l.hotelTodayNewPriceName, () => nav.push('HL-GROW-02')),
    ];
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
      child: Semantics(
        container: true,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: _ActionTile(
                    icon: actions[i].$1,
                    label: actions[i].$2,
                    name: actions[i].$3,
                    onPressed: actions[i].$4,
                    wide: actions.length == 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
