// The voucher-price window row and the sheets behind it (web `WindowRow.tsx`, `WindowActions.tsx`, `useWindowSheet.tsx`). A row is a price as the
// headline with the real standard price struck beside it and glyph facts (vouchers bought, event dates, when it starts or ends); the standing prices
// are one "Always on" row. The row opens the actions sheet: figures, how couples see it, Duplicate and End now. Pause and Resume are not here: the
// contract has no pause for a window (requests.md [P-H3]).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/grow_data.dart';
import '../../application/grow_model.dart';
import 'grow_bits.dart';
import 'preview_parts.dart';

typedef Fact = ({IconData icon, String value, String label});

/// The facts of a window as glyph and value. `full` writes every date; the row summarises a long list as a count.
({Fact? events, Fact? run}) windowFacts(BuildContext context, VoucherWindow w, {bool full = false}) {
  final f = context.gzFormat;
  final l = context.l10n;
  final today = ProviderScope.containerOf(context).read(growTodayProvider).toString();
  String day(DateTime d) => dmy(f, f.isoDay(d), today);
  final arrow = f.lang.name == 'ar' ? '←' : '→';
  Fact? events() {
    final label = l.hotelGrowFactDates;
    final dates = w.eventDates;
    if (dates != null && dates.isNotEmpty) {
      if (dates.length > 3 && !full) return (icon: GzIcons.calendarDots, value: f.integer(dates.length), label: label);
      return (icon: GzIcons.calendar, value: dayList(f, [for (final d in dates) d.toString()]), label: label);
    }
    final to = w.eventTo;
    if (to == null) return null;
    final days = w.eventWeekdays == null ? null : weekdayRun(f, w.eventWeekdays!);
    final from = w.eventFrom;
    final span = full || days == null
        ? '${from != null ? '${dmy(f, from.toString(), today)} $arrow ' : ''}${dmy(f, to.toString(), today)}${days != null ? ' · $days' : ''}'
        : '$days $arrow ${dmy(f, to.toString(), today)}';
    return (icon: GzIcons.calendar, value: span, label: label);
  }

  Fact? run() => switch (w.status) {
    VoucherWindowStatus.ended => (icon: GzIcons.calendarCheck, value: day(w.endsAt ?? w.startsAt), label: l.hotelGrowStatEnded),
    VoucherWindowStatus.scheduled => (icon: GzIcons.hourglass, value: day(w.startsAt), label: l.hotelGrowStatStarts),
    _ => w.endsAt != null ? (icon: GzIcons.timer, value: day(w.endsAt!), label: l.hotelGrowStatEnds) : null,
  };
  return (events: events(), run: run());
}

Widget _chip(BuildContext context, Fact fact) => GzFactChip(
  icon: fact.icon,
  valueWidget: GzText(fact.value, role: GzTextRole.figCaption, color: context.gz.colors.textSecondary, figures: true),
  label: fact.label,
  small: true,
  tone: GzFactTone.muted,
);

Widget unitGlyph(BuildContext context, bool flat) {
  final l = context.l10n;
  return Semantics(
    label: flat ? l.hotelGrowUnitPackage : l.hotelGrowUnitGuest,
    excludeSemantics: true,
    child: GzIcon(flat ? GzIcons.package : GzIcons.perGuest, size: GzIconSize.sm, color: context.gz.colors.iconSecondary),
  );
}

class WindowRow extends ConsumerWidget {
  const WindowRow({required this.window, required this.onOpen, this.isNew = false, super.key});

  final VoucherWindow window;
  final VoidCallback onOpen;
  final bool isNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final cat = ref.watch(growCatalogProvider).value;
    final weekend = ref.watch(growConfigProvider).value?.weekendTierDays ?? const [4, 5, 6];
    final today = ref.watch(growTodayProvider);
    final std = cat == null ? null : standardOf(window, cat, today, weekend);
    final rate = windowRate(window);
    final facts = windowFacts(context, window);
    final title = window.title.of(lang);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: GzPressable(
        onPressed: onOpen,
        semanticLabel: title,
        minHeight: GzSize.touchMin,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    growRowTitle(context, title, maxLines: 2),
                    const SizedBox(height: GzSpace.s2),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: GzSpace.s2,
                      runSpacing: GzSpace.s1,
                      children: [
                        if (std != null) unitGlyph(context, std.flat),
                        GzPrice(fils: rate, size: GzPriceSize.strong, was: std != null && std.standard > rate ? std.standard : null),
                        if (isNew) GzTag(label: l.commonLabelNew, icon: GzIcons.sparkle),
                      ],
                    ),
                    const SizedBox(height: GzSpace.s2),
                    GzFactRow(
                      label: l.hotelGrowFactsLabel,
                      children: [
                        GzFactChip(
                          icon: GzIcons.ticket,
                          value: f.integer(window.vouchersBought ?? 0),
                          label: l.hotelGrowStatVouchers,
                          small: true,
                          tone: GzFactTone.muted,
                        ),
                        if (facts.events != null) _chip(context, facts.events!),
                        if (facts.run != null) _chip(context, facts.run!),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: GzSpace.s3),
              GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary, mirror: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// The standing voucher prices of every package: one "Always on" row, never a single misleading price.
class StandingRow extends ConsumerWidget {
  const StandingRow({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final cat = ref.watch(growCatalogProvider).value;
    final count = cat == null ? 0 : voucherPackages(cat).length;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: GzPressable(
        onPressed: onOpen,
        semanticLabel: l.hotelGrowStandingTitle,
        minHeight: GzSize.touchMin,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4),
          child: Row(
            children: [
              Container(
                width: GzSize.thumbMd,
                height: GzSize.thumbMd,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.surfaceTintSoft, borderRadius: GzRadius.mdAll),
                child: GzIcon(GzIcons.ticket, size: GzIconSize.md, color: c.iconPrimary),
              ),
              const SizedBox(width: GzSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    growRowTitle(context, l.hotelGrowStandingTitle),
                    const SizedBox(height: GzSpace.s2),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: GzSpace.s2,
                      children: [
                        GzTag(label: l.hotelGrowAlwaysOn, icon: GzIcons.check),
                        GzFactChip(
                          icon: GzIcons.package,
                          value: f.integer(count),
                          label: l.hotelGrowStandingCount,
                          small: true,
                          tone: GzFactTone.muted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary, mirror: true),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- the sheets

/// The sheet of one window: its price and facts, three figures, how couples see it behind a toggle, Duplicate and End now.
class WindowActions extends ConsumerStatefulWidget {
  const WindowActions({required this.id, required this.onDuplicate, required this.onEnd, super.key});

  final String id;
  final VoidCallback onDuplicate;
  final VoidCallback onEnd;

  @override
  ConsumerState<WindowActions> createState() => _WindowActionsState();
}

class _WindowActionsState extends ConsumerState<WindowActions> {
  bool _preview = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final w = ref.watch(growWindowsProvider).value?.where((x) => x.id == widget.id).firstOrNull;
    final cat = ref.watch(growCatalogProvider).value;
    if (w == null || cat == null) return const SizedBox(height: GzSpace.s8);
    final weekend = ref.watch(growConfigProvider).value?.weekendTierDays ?? const [4, 5, 6];
    final today = ref.watch(growTodayProvider);
    final std = standardOf(w, cat, today, weekend);
    final rate = windowRate(w);
    final ended = w.status == VoucherWindowStatus.ended;
    final perf = windowPerformance(w);
    final facts = windowFacts(context, w, full: true);
    final names = [for (final id in w.packageIds) editorOf(cat, id)?.package.name.of(lang) ?? id];
    final busy = ref.watch(growActionsProvider).isBusy;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: GzSpace.s2),
        Row(
          children: [
            unitGlyph(context, std.flat),
            const SizedBox(width: GzSpace.s2),
            GzPrice(fils: rate, size: GzPriceSize.strong, was: std.standard > rate ? std.standard : null),
            const Spacer(),
            GzInfoButton(title: l.hotelGrowEffectTitle, paragraphs: [l.hotelGrowEffectNote]),
          ],
        ),
        const SizedBox(height: GzSpace.s3),
        GzFactRow(
          children: [
            GzFactChip(
              icon: GzIcons.package,
              valueWidget: GzText(
                names.isEmpty ? f.integer(voucherPackages(cat).length) : (names.length > 1 ? f.integer(names.length) : names.first),
                role: GzTextRole.figCaption,
                color: c.textSecondary,
                figures: true,
              ),
              label: l.hotelGrowFactPackages,
              small: true,
              tone: GzFactTone.muted,
            ),
            if (facts.events != null) _chip(context, facts.events!),
            if (facts.run != null) _chip(context, facts.run!),
          ],
        ),
        const SizedBox(height: GzSpace.s4),
        Row(
          children: [
            Expanded(
              child: GzIconStat(icon: GzIcons.ticket, value: f.integer(perf.vouchers), label: l.hotelGrowStatVouchers),
            ),
            Expanded(
              child: GzIconStat(icon: GzIcons.clipboard, value: f.integer(perf.requests), label: l.hotelGrowStatRequests),
            ),
            Expanded(
              child: GzIconStat(icon: GzIcons.calendarCheck, value: f.integer(perf.confirmed), label: l.hotelGrowStatConfirmed),
            ),
          ],
        ),
        const SizedBox(height: GzSpace.s4),
        GzPressable(
          onPressed: () => setState(() => _preview = !_preview),
          semanticLabel: l.hotelGrowPreviewLabel,
          expanded: _preview,
          child: Row(
            children: [
              GzIcon(GzIcons.eye, size: GzIconSize.sm, color: c.iconSecondary),
              const SizedBox(width: GzSpace.s2),
              Expanded(
                child: GzText(l.hotelGrowPreviewLabel, role: GzTextRole.label, color: c.textStrong),
              ),
              GzIcon(_preview ? GzIcons.chevronUp : GzIcons.chevronDown, size: GzIconSize.sm, color: c.iconSecondary),
            ],
          ),
        ),
        if (_preview) ...[
          const SizedBox(height: GzSpace.s3),
          PreviewStrip(flat: true, rate: rate, packageIds: w.packageIds, dates: [for (final d in w.eventDates ?? const <LocalDate>[]) d.toString()]),
        ],
        const SizedBox(height: GzSpace.s4),
        GzButton(
          label: l.hotelGrowDuplicate,
          variant: GzButtonVariant.secondary,
          iconStart: GzIcons.copy,
          fullWidth: true,
          onPressed: widget.onDuplicate,
        ),
        if (!ended) ...[
          const SizedBox(height: GzSpace.s3),
          GzButton(
            label: l.hotelGrowEndNow,
            variant: GzButtonVariant.destructive,
            iconStart: GzIcons.close,
            fullWidth: true,
            loading: busy,
            onPressed: widget.onEnd,
          ),
        ],
      ],
    );
  }
}

/// The sheet of the standing voucher prices: how many packages carry one, and the way to change them (package prices, HL-VENU-02).
class StandingActions extends ConsumerWidget {
  const StandingActions({required this.onEdit, super.key});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.gzFormat;
    final cat = ref.watch(growCatalogProvider).value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: GzSpace.s2),
        Row(
          children: [
            GzTag(label: l.hotelGrowAlwaysOn, icon: GzIcons.check),
            const SizedBox(width: GzSpace.s3),
            GzFactChip(
              icon: GzIcons.package,
              value: f.integer(cat == null ? 0 : voucherPackages(cat).length),
              label: l.hotelGrowStandingCount,
              small: true,
              tone: GzFactTone.muted,
            ),
            const Spacer(),
            GzInfoButton(title: l.hotelGrowStandingInfoTitle, paragraphs: [l.hotelGrowStandingExplain, l.hotelGrowStandingNote]),
          ],
        ),
        const SizedBox(height: GzSpace.s4),
        GzButton(label: l.hotelGrowStandingEditCta, iconEnd: GzIcons.chevronRight, fullWidth: true, onPressed: onEdit),
      ],
    );
  }
}
