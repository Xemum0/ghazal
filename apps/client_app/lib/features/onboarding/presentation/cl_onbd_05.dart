// CL-ONBD-05 Guests and budget (CA-ONB-04, CA-ONB-05, CA-ONB-08, CA-ONB-09). Port of CL-ONBD-05.tsx.
// Guest count and the venue-and-catering budget are one decision in Kuwait (hall prices are per guest), so they share a screen, but the
// screen is figures and glyphs. Guests: a large stepper (hard cap 1,500) with the common counts as chips; the ladies' and men's split is a
// switch. Budget: five bands as bare figures, a histogram of what the halls cost at that guest count, a range slider whose two values are
// money, and the per-guest figure as a fact. Each half can be put off on its own (Later) and then shows a drawing row with the way back.
// Continue writes both answers; Skip writes nothing.
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat, gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show BudgetBand, MoneyAmount, MoneyRange;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/onboarding_data.dart';
import '../application/onboarding_profile.dart';
import 'widgets/form_section.dart';
import 'widgets/price_histogram.dart';
import 'widgets/step_bar.dart';

const int _guestMin = 10;
const int _guestMax = 1500;
const int _guestStep = 10;
const List<int> _presets = <int>[100, 150, 200, 300, 400, 500, 650, 800, 1000];

/// The slider's dinars: the last band ("35,000 and above") ends at the rail's end.
const int _budgetMax = 40000;
const int _budgetStep = 1000;

int _dinars(int fils) => (fils / 1000).round();

class ClOnbd05Screen extends ConsumerStatefulWidget {
  const ClOnbd05Screen({super.key});

  @override
  ConsumerState<ClOnbd05Screen> createState() => _ClOnbd05State();
}

class _ClOnbd05State extends ConsumerState<ClOnbd05Screen> {
  late bool _split;
  late int _guests;
  late int _men;
  late (double, double) _range;
  bool _skipGuests = false;
  bool _skipBudget = false;

  @override
  void initState() {
    super.initState();
    // The demo persona's answers start the form (docs/product/fixtures.md): 350 guests, KD 20,000 to 35,000.
    final saved = ref.read(obdDraftProvider);
    final women = saved.guests?.women ?? 0;
    _split = (saved.guests?.men ?? 0) > 0;
    _guests = women > 0 ? women : ObdStory.guestsWomen;
    _men = (saved.guests?.men ?? 0) > 0 ? saved.guests!.men : ObdStory.guestsMen;
    final b = saved.venueBudget;
    _range = b != null
        ? (_dinars(b.min.fils).toDouble(), _dinars(b.max.fils).clamp(0, _budgetMax).toDouble())
        : (_dinars(ObdStory.budgetMinFils).toDouble(), _dinars(ObdStory.budgetMaxFils).toDouble());
  }

  /// The last optional step (Done or Skip): the answers become the profile and the Brief, and Home opens.
  void _next() => ref.finishOnboarding();

  void _confirm() {
    ref.commitGuestsBudget(
      women: _skipGuests ? 0 : _guests,
      men: _skipGuests || !_split ? 0 : _men,
      budget: _skipBudget ? null : MoneyRange(min: MoneyAmount(_range.$1.round() * 1000), max: MoneyAmount(_range.$2.round() * 1000)),
    );
    _next();
  }

  Widget _later(AppL10n l10n, VoidCallback onPressed) =>
      GzButton(label: l10n.clientOnboardingSkipHalf, variant: GzButtonVariant.tertiary, flushInline: true, onPressed: onPressed);

  /// What a put-off question leaves: a drawing, its one word, and the way back in. Nothing is lost by putting it off.
  Widget _putOff(AppL10n l10n, VoidCallback onAdd) => GzIconListRow(
    flush: true,
    last: true,
    illustration: GzIllustrationName.hourglass,
    title: l10n.clientOnboardingSkipHalf,
    trailing: GzButton(label: l10n.commonActionAdd, variant: GzButtonVariant.secondary, size: GzButtonSize.sm, onPressed: onAdd),
  );

  Widget _who(IconData glyph, String label) => Semantics(
    label: label,
    child: ExcludeSemantics(
      child: GzIcon(glyph, size: GzIconSize.md, color: context.gz.colors.iconPrimary),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final f = ref.watch(gzFormatProvider);
    final bands = ref.watch(onboardingBudgetBandsProvider).value ?? const <BudgetBand>[];
    final briefGuests = _skipGuests ? null : _guests;
    final prices = ref.watch(onboardingPricesProvider(briefGuests)).value ?? const <int>[];
    final currency = f.moneyParts(0).currency;
    final perGuest = briefGuests != null && !_skipBudget
        ? f.moneyRange((_range.$1 * 1000 / briefGuests / 1000).round() * 1000, (_range.$2 * 1000 / briefGuests / 1000).round() * 1000)
        : null;

    return GzScreen(
      top: ObdStepBar(step: 3, total: 3, onSkip: _next),
      bottom: GzActionBar(
        action: GzActionBarAction(label: l10n.commonActionDone, onPressed: _confirm),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, label: l10n.clientOnboardingGuestsTitle, child: const SizedBox.shrink()),
            ObdFormSection(
              title: l10n.clientOnboardingGuestsSection,
              icon: GzIcons.usersThree,
              action: _skipGuests ? null : _later(l10n, () => setState(() => _skipGuests = true)),
              child: _skipGuests ? _putOff(l10n, () => setState(() => _skipGuests = false)) : _guestsBody(l10n, f),
            ),
            const SizedBox(height: GzSpace.s8),
            ObdFormSection(
              title: l10n.clientOnboardingBudgetSection,
              icon: GzIcons.coins,
              unit: currency,
              action: _skipBudget ? null : _later(l10n, () => setState(() => _skipBudget = true)),
              child: _skipBudget ? _putOff(l10n, () => setState(() => _skipBudget = false)) : _budgetBody(l10n, f, bands, prices, perGuest),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guestsBody(AppL10n l10n, GzFormat f) {
    final spoken = f.guests;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_split) ...[
          Row(
            children: [
              _who(GzIcons.sectionWomen, l10n.clientOnboardingGuestsLadies),
              Expanded(
                child: GzStepper(
                  value: _guests,
                  onChanged: (v) => setState(() => _guests = v),
                  min: _guestMin,
                  max: _guestMax,
                  step: _guestStep,
                  valueText: spoken,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _who(GzIcons.sectionMen, l10n.clientOnboardingGuestsMen),
              Expanded(
                child: GzStepper(
                  value: _men,
                  onChanged: (v) => setState(() => _men = v),
                  min: _guestMin,
                  max: _guestMax,
                  step: _guestStep,
                  valueText: spoken,
                ),
              ),
            ],
          ),
        ] else ...[
          GzStepper(
            variant: GzStepperVariant.hero,
            semanticLabel: l10n.clientOnboardingGuestsExpected,
            value: _guests,
            onChanged: (v) => setState(() => _guests = v),
            min: _guestMin,
            max: _guestMax,
            step: _guestStep,
            valueText: spoken,
          ),
          const SizedBox(height: GzSpace.s4),
          Semantics(
            container: true,
            label: l10n.clientOnboardingGuestsPresets,
            child: Column(
              children: [
                for (var r = 0; r < 3; r++) ...[
                  if (r > 0) const SizedBox(height: GzSpace.s2),
                  Row(
                    children: [
                      for (var i = r * 3; i < r * 3 + 3; i++) ...[
                        if (i > r * 3) const SizedBox(width: GzSpace.s2),
                        Expanded(
                          child: GzChip(
                            expand: true,
                            figures: true,
                            label: _presets[i] == 1000
                                ? GzBidi.isolateLtr(l10n.clientOnboardingGuestsPresetMax(f.integer(_presets[i])))
                                : f.integer(_presets[i]),
                            selected: _guests == _presets[i],
                            onPressed: () => setState(() => _guests = _presets[i]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: GzSpace.s4),
        // The split: the two section glyphs (the glyph is the value) and a switch; the sentence is the switch's accessible name.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _split = !_split),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.rowMin),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Row(
                    children: [
                      GzIcon(GzIcons.sectionWomen, size: GzIconSize.md, color: context.gz.colors.iconPrimary),
                      const SizedBox(width: GzSpace.s1),
                      GzIcon(GzIcons.sectionMen, size: GzIconSize.md, color: context.gz.colors.iconPrimary),
                    ],
                  ),
                ),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: GzText(
                    l10n.clientOnboardingGuestsSplitTitle,
                    role: GzTextRole.body,
                    color: context.gz.colors.textStrong,
                    excludeSemantics: true,
                  ),
                ),
                const SizedBox(width: GzSpace.s3),
                GzSwitch(label: l10n.clientOnboardingGuestsSplitLabel, checked: _split, onChanged: (v) => setState(() => _split = v)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _budgetBody(AppL10n l10n, GzFormat f, List<BudgetBand> bands, List<int> prices, String? perGuest) {
    final c = context.gz.colors;
    final spec = <({String id, (double, double) range, String label})>[
      for (final b in bands)
        (
          id: b.id,
          range: (_dinars(b.min.fils).toDouble(), (b.max == null ? _budgetMax : _dinars(b.max!.fils)).toDouble()),
          label: b.max == null
              ? GzBidi.isolateLtr(l10n.clientOnboardingGuestsPresetMax(f.integer(_dinars(b.min.fils))))
              : '${f.integer(_dinars(b.min.fils))} – ${f.integer(_dinars(b.max!.fils))}',
        ),
    ];
    final active = spec.where((b) => b.range.$1 == _range.$1 && b.range.$2 == _range.$2).map((b) => b.id).firstOrNull;
    // `35,000+` with the currency on the side the language puts it: built from the formatter's parts, never typed.
    String money(double dinars, {bool openEnd = false}) {
      if (!openEnd) return f.money(dinars.round() * 1000);
      final p = f.moneyParts(dinars.round() * 1000);
      return f.isArabic ? '${p.integer}+ ${p.currency}' : '${p.currency} ${p.integer}+';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label: l10n.clientOnboardingBudgetBands,
          child: _BandRail(
            activeIndex: spec.indexWhere((b) => b.id == active),
            chips: [for (final b in spec) GzChip(label: b.label, selected: active == b.id, onPressed: () => setState(() => _range = b.range))],
          ),
        ),
        const SizedBox(height: GzSpace.s4 + GzSpace.s2),
        ObdPriceHistogram(prices: prices, min: 0, max: _budgetMax.toDouble(), range: _range),
        const SizedBox(height: GzSpace.s2),
        GzRangeSlider(
          label: l10n.clientOnboardingBudgetRange,
          min: 0,
          max: _budgetMax.toDouble(),
          step: _budgetStep.toDouble(),
          minGap: _budgetStep.toDouble(),
          value: _range,
          onChanged: (r) => setState(() => _range = r),
          showCaptions: false,
          formatValue: (context, n, edge) => GzText(
            money(n, openEnd: edge == GzRangeEdge.max && n == _budgetMax),
            role: GzTextRole.figBody,
            color: c.textStrong,
            figures: true,
          ),
          valueText: (n, edge) => edge == GzRangeEdge.max && n == _budgetMax ? l10n.clientOnboardingBudgetAbove(money(n)) : money(n),
        ),
        if (perGuest != null) ...[
          const SizedBox(height: GzSpace.s4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: GzFactChip(icon: GzIcons.perGuest, label: l10n.commonUnitPerGuest, value: perGuest),
          ),
        ],
      ],
    );
  }
}

/// The bands: one rail that scrolls sideways; the chosen band is brought to the middle of it (on arrival and when the slider lands on one).
class _BandRail extends StatefulWidget {
  const _BandRail({required this.chips, required this.activeIndex});

  final List<Widget> chips;
  final int activeIndex;

  @override
  State<_BandRail> createState() => _BandRailState();
}

class _BandRailState extends State<_BandRail> {
  final List<GlobalKey> _keys = <GlobalKey>[];
  final ScrollController _scroll = ScrollController();
  bool _settled = false;

  @override
  void didUpdateWidget(_BandRail old) {
    super.didUpdateWidget(old);
    if (old.activeIndex != widget.activeIndex) _center();
  }

  @override
  void initState() {
    super.initState();
    _center();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Scrolls only this rail (never the page): the chip's centre to the rail's centre.
  void _center() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.activeIndex < 0 || widget.activeIndex >= _keys.length || !_scroll.hasClients) return;
      final chip = _keys[widget.activeIndex].currentContext?.findRenderObject();
      final rail = context.findRenderObject();
      if (chip is! RenderBox || rail is! RenderBox) return;
      final chipCentre = chip.localToGlobal(chip.size.center(Offset.zero)).dx;
      final railCentre = rail.localToGlobal(rail.size.center(Offset.zero)).dx;
      final rtl = Directionality.of(context) == TextDirection.rtl;
      final delta = (chipCentre - railCentre) * (rtl ? -1 : 1);
      final target = (_scroll.offset + delta).clamp(0.0, _scroll.position.maxScrollExtent);
      final smooth = _settled && !GzReducedMotion.of(context);
      if (smooth) {
        _scroll.animateTo(target, duration: GzMotion.durationBase, curve: GzMotion.easeStandard);
      } else {
        _scroll.jumpTo(target);
      }
      _settled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    while (_keys.length < widget.chips.length) {
      _keys.add(GlobalKey());
    }
    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < widget.chips.length; i++) ...[
            if (i > 0) const SizedBox(width: GzSpace.s2),
            KeyedSubtree(key: _keys[i], child: widget.chips[i]),
          ],
        ],
      ),
    );
  }
}
