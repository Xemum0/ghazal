import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart' show Area, Audience, MoneyAmount, MoneyRange;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../app/state/state.dart' show SearchBrief;
import '../../../../l10n/l10n.dart';
import '../../application/brief_draft.dart';
import '../../application/discover_filters.dart';
import '../../application/discover_search.dart';
import 'brief_panels_a.dart' show DraftSetter;
import 'brief_rows.dart';
import 'discover_labels.dart';

const List<int> kGuestPresets = <int>[100, 150, 200, 250, 300, 350, 400, 500];
const int kGuestsMin = 20;
const int kGuestsMax = 1500;

/// One three-way section control (ladies, men, mixed), a stepper and preset chips. Ladies and men are the two separate receptions and each
/// keeps its own count; mixed is one celebration with one count.
class BriefGuestsPanel extends StatelessWidget {
  const BriefGuestsPanel({required this.draft, required this.set, super.key});

  final BriefDraft draft;
  final DraftSetter set;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final labels = DiscoverLabels(context);
    final b = draft.brief;
    final section = draft.split ? (b.audience == Audience.men ? Audience.men : Audience.women) : Audience.mixed;
    final value = b.guests ?? (section == Audience.men ? draft.men : draft.women);

    void setGuests(int n) => set(
      (d) => d.copyWith(
        brief: d.brief.copyWith(guests: n),
        women: section == Audience.men ? d.women : n,
        men: section == Audience.women ? d.men : n,
      ),
    );
    void pick(Audience v) => set(
      (d) => v == Audience.mixed
          ? d.copyWith(split: false, brief: d.brief.copyWith(audience: Audience.mixed, guests: d.brief.guests ?? d.women))
          : d.copyWith(split: true, brief: d.brief.copyWith(audience: v, guests: v == Audience.men ? d.men : d.women)),
    );
    return Column(
      key: const ValueKey<String>('discover.brief.guests'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzIconSegmented<Audience>(
          label: l.clientDiscoverBriefGuestsSection,
          labels: GzIconSegmentedLabels.all,
          value: section,
          onChanged: pick,
          options: [for (final a in kArrangements) GzIconSegmentedOption<Audience>(value: a, icon: arrangementIcon(a), label: labels.arrangement(a))],
        ),
        const SizedBox(height: GzSpace.s4),
        Row(
          children: [
            GzIcon(GzIcons.usersThree, size: GzIconSize.md, color: c.iconSecondary),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: GzStepper(
                key: const ValueKey<String>('discover.brief.stepper'),
                min: kGuestsMin,
                max: kGuestsMax,
                step: 10,
                value: value,
                onChanged: setGuests,
                valueText: (n) => f.guests(n),
              ),
            ),
          ],
        ),
        const SizedBox(height: GzSpace.s4),
        GzChipGroup<int>(
          label: l.clientDiscoverBriefGuestsPresets,
          value: kGuestPresets.contains(value) ? value : null,
          onChanged: (n) {
            if (n != null) setGuests(n);
          },
          options: [for (final n in kGuestPresets) GzChipOption<int>(value: n, label: f.integer(n))],
        ),
      ],
    );
  }
}

const int _budgetMax = 60000;
const int _budgetStep = 500;

/// The five bands of the Brief budget in dinars; the last is open-ended.
const List<(int, int?)> kBudgetBands = <(int, int?)>[(0, 5000), (5000, 10000), (10000, 20000), (20000, 35000), (35000, null)];

/// The venue and catering budget as five bands (chips) and a dual-thumb slider over a histogram of what the roster's halls cost for the
/// couple's guest count. One four-word caption says it is the hall and its catering only.
class BriefBudgetPanel extends ConsumerWidget {
  const BriefBudgetPanel({required this.draft, required this.set, super.key});

  final BriefDraft draft;
  final DraftSetter set;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final b = draft.brief;
    final lo = b.budget == null ? 0 : (b.budget!.min.fils / 1000).round();
    final hi = b.budget == null ? _budgetMax : (isOpenBudget(b.budget!) ? _budgetMax : (b.budget!.max.fils / 1000).round());
    String money(int kd) => f.money(kd * 1000, const MoneyOptions(mode: MoneyMode.browse));
    String open(int kd) => briefBudgetText(f, MoneyRange(min: MoneyAmount(kd * 1000), max: const MoneyAmount(0)));
    final pricing = SearchBrief(date: b.date, guests: b.guests ?? 350, audience: b.audience ?? Audience.women);
    final rows = ref.watch(discoverSearchProvider(DiscoverQuery(brief: pricing, filters: const DiscoverFilters(areaIds: <String>[])))).value ?? const [];
    final totals = <double>[
      for (final r in rows)
        if (r.price != null && r.price!.amount.fils / 1000 <= _budgetMax) r.price!.amount.fils / 1000,
    ];
    final bandIndex = kBudgetBands.indexWhere((x) => x.$1 == lo && (x.$2 ?? _budgetMax) == hi);
    String label((int, int?) x) => x.$1 == 0 && x.$2 != null
        ? l.clientDiscoverBriefBudgetUnder(money(x.$2!))
        : x.$2 == null
        ? open(x.$1)
        : f.moneyRange(x.$1 * 1000, x.$2! * 1000, const MoneyOptions(mode: MoneyMode.browse));
    void setRange(int a, int z) =>
        set((d) => d.copyWith(brief: d.brief.copyWith(budget: MoneyRange(min: MoneyAmount(a * 1000), max: MoneyAmount(z >= _budgetMax ? 0 : z * 1000)))));
    return Column(
      key: const ValueKey<String>('discover.brief.budget'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzText(l.clientDiscoverBriefBudgetHelper, role: GzTextRole.caption, color: c.textSecondary),
        const SizedBox(height: GzSpace.s4),
        GzChipGroup<int>(
          label: l.clientDiscoverBriefBudgetBands,
          value: bandIndex < 0 ? null : bandIndex,
          onChanged: (i) {
            if (i != null) setRange(kBudgetBands[i].$1, kBudgetBands[i].$2 ?? _budgetMax);
          },
          options: [for (var i = 0; i < kBudgetBands.length; i++) GzChipOption<int>(value: i, label: label(kBudgetBands[i]))],
        ),
        const SizedBox(height: GzSpace.s4),
        Histogram(values: totals, min: 0, max: _budgetMax.toDouble(), range: (lo.toDouble(), hi.toDouble()), bins: 15),
        const SizedBox(height: GzSpace.s2),
        GzRangeSlider(
          min: 0,
          max: _budgetMax.toDouble(),
          step: _budgetStep.toDouble(),
          minGap: _budgetStep.toDouble(),
          label: l.clientDiscoverBriefBudgetTitle,
          value: (lo.toDouble(), hi.toDouble()),
          showCaptions: false,
          valuesAt: GzRangeValues.below,
          valueText: (n, edge) => edge == GzRangeEdge.max && n >= _budgetMax ? open(_budgetMax) : money(n.round()),
          formatValue: (context, n, edge) => Text.rich(
            TextSpan(children: GzFigures.spans(context, edge == GzRangeEdge.max && n >= _budgetMax ? open(_budgetMax) : money(n.round()), role: GzTextRole.figBodyS)),
            style: context.gz.text(GzTextRole.figBodyS).copyWith(color: c.textStrong, decoration: TextDecoration.none),
          ),
          onChanged: (r) => setRange(r.$1.round(), r.$2.round()),
        ),
      ],
    );
  }
}

/// Where the roster's prices fall, drawn above a range slider: flex columns, bars inside the chosen range are darker. Decorative for
/// assistive technology (the slider carries the value).
class Histogram extends StatelessWidget {
  const Histogram({required this.values, required this.min, required this.max, required this.range, this.bins = 12, super.key});

  final List<double> values;
  final double min;
  final double max;
  final (double, double) range;
  final int bins;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final width = (max - min) / bins;
    final counts = List<int>.generate(
      bins,
      (i) => values.where((v) => ((v - min) / width).floor().clamp(0, bins - 1) == i).length,
    );
    final tallest = counts.fold<int>(1, (a, b) => a > b ? a : b);
    return ExcludeSemantics(
      child: SizedBox(
        key: const ValueKey<String>('discover.histogram'),
        height: GzSpace.s10,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < bins; i++) ...[
              if (i > 0) const SizedBox(width: GzSpace.s1),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final n = counts[i];
                    final lo = min + i * width;
                    final inside = lo + width > range.$1 && lo < range.$2 && n > 0;
                    final h = n == 0 ? GzSpace.s1 / 2 : ((n / tallest) * GzSpace.s10 / GzSpace.s1).roundToDouble().clamp(1, GzSpace.s10 / GzSpace.s1) * GzSpace.s1;
                    return Align(
                      alignment: AlignmentDirectional.bottomCenter,
                      child: Container(
                        height: h,
                        decoration: BoxDecoration(
                          color: inside ? c.borderStrong : c.borderHairline,
                          borderRadius: const BorderRadiusDirectional.only(topStart: Radius.circular(GzRadius.xs), topEnd: Radius.circular(GzRadius.xs)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The merge variant (shown once after sign-in when the account already holds a different Brief): the two Briefs side by side, each as
/// glyph-and-value facts with its own "Keep" under it. Nothing is preselected.
class BriefMergePanel extends StatelessWidget {
  const BriefMergePanel({required this.phone, required this.account, required this.areas, required this.onKeep, super.key});

  final SearchBrief phone;
  final SearchBrief account;
  final List<Area> areas;
  final ValueChanged<bool> onKeep;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    return Container(
      key: const ValueKey<String>('discover.brief.merge'),
      decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _MergeColumn(brief: phone, title: l.clientDiscoverMergePhone, areas: areas, keyId: 'phone', onKeep: () => onKeep(true))),
            ColoredBox(color: c.borderHairline, child: const SizedBox(width: GzStroke.hair)),
            Expanded(child: _MergeColumn(brief: account, title: l.clientDiscoverMergeAccount, areas: areas, keyId: 'account', onKeep: () => onKeep(false))),
          ],
        ),
      ),
    );
  }
}

class _MergeColumn extends StatelessWidget {
  const _MergeColumn({required this.brief, required this.title, required this.areas, required this.keyId, required this.onKeep});

  final SearchBrief brief;
  final String title;
  final List<Area> areas;
  final String keyId;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    Widget fact(IconData icon, String text) => Row(
      children: [
        GzIcon(icon, size: GzIconSize.sm, color: c.iconSecondary),
        const SizedBox(width: GzSpace.s2),
        Expanded(
          child: Text.rich(
            TextSpan(children: GzFigures.spans(context, text, role: GzTextRole.bodyS)),
            style: context.gz.text(GzTextRole.bodyS).copyWith(color: c.textStrong, decoration: TextDecoration.none),
          ),
        ),
      ],
    );
    final areaText = f.list(briefAreaNames(areas, brief.areaIds, lang));
    return Padding(
      key: ValueKey<String>('discover.merge.$keyId'),
      padding: const EdgeInsetsDirectional.all(GzSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzText(title, role: GzTextRole.label, color: c.textSecondary, header: true),
          const SizedBox(height: GzSpace.s4),
          fact(GzIcons.calendar, brief.date == null ? l.clientDiscoverBriefChooseDate : f.date(brief.date.toString(), DateStyle.compact)),
          if (brief.guests != null) ...[const SizedBox(height: GzSpace.s3), fact(brief.audience == null ? GzIcons.usersThree : arrangementIcon(brief.audience!), f.integer(brief.guests!))],
          if (areaText.isNotEmpty) ...[const SizedBox(height: GzSpace.s3), fact(GzIcons.pin, areaText)],
          const Spacer(),
          const SizedBox(height: GzSpace.s4),
          GzButton(key: ValueKey<String>('discover.merge.keep.$keyId'), label: l.clientDiscoverMergeKeep, variant: GzButtonVariant.secondary, fullWidth: true, onPressed: onKeep),
        ],
      ),
    );
  }
}
