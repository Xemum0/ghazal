// HL-VENU-05 Policies (web `HL-VENU-05.tsx`): the venue's own terms in plain words, shown to couples as written (payment and cancellation are agreed
// with the venue directly: Ghazal holds no event money, so there are no tiers, cooling-off or refund settings), the voucher terms Ghazal sets (read
// only), the boys' age rule per section, the dress code and the opening hours. Everything is bilingual where couples read it.
// Requirements: HA-VMGT-08, HA-VMGT-09, HA-AUTH-02 (voucher model, ADR 0033).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/venue_data.dart';
import 'widgets/policy_parts.dart';
import 'widgets/venue_bits.dart';
import 'widgets/venue_fields.dart';

class _Policy {
  _Policy({required this.terms, required this.dress, required this.women, required this.men, required this.hours});

  LocalizedText terms;
  LocalizedText dress;
  int? women;
  int? men;
  List<HoursRule> hours;

  _Policy copy() => _Policy(terms: terms, dress: dress, women: women, men: men, hours: [...hours]);

  @override
  bool operator ==(Object other) =>
      other is _Policy && other.terms == terms && other.dress == dress && other.women == women && other.men == men && sameHours(other.hours, hours);

  @override
  int get hashCode => Object.hash(terms, dress, women, men, hours.length);
}

bool sameHours(List<HoursRule> a, List<HoursRule> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].open != b[i].open || a[i].close != b[i].close || a[i].days.join() != b[i].days.join()) return false;
  }
  return true;
}

int? _boysAge(HallList halls, Audience a) {
  for (final h in halls.halls) {
    for (final s in h.sections) {
      if (s.audience == a) return s.policy.boysMaxAge;
    }
  }
  return null;
}

class HlVenu05Screen extends ConsumerStatefulWidget {
  const HlVenu05Screen({super.key});

  @override
  ConsumerState<HlVenu05Screen> createState() => _HlVenu05ScreenState();
}

class _HlVenu05ScreenState extends ConsumerState<HlVenu05Screen> {
  _Policy? _base;
  _Policy? _draft;

  bool get _dirty => _draft != null && _draft != _base;

  void _seed(VenuePolicies p, HallList halls, BusinessHours hours) {
    if (_draft != null) return;
    _base = _Policy(
      terms: p.terms,
      dress: p.dressCode,
      women: _boysAge(halls, Audience.women),
      men: _boysAge(halls, Audience.men),
      hours: hours.rules,
    );
    _draft = _base!.copy();
  }

  bool _blank(LocalizedText t) => (t.ar ?? '').trim().isEmpty || (t.en ?? '').trim().isEmpty;

  Future<void> _save(VenuePolicies policies, HallList halls, BusinessHours hours) async {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final d = _draft!;
    final actions = ref.read(venueActionsProvider.notifier);
    final res = await actions.savePolicies(
      VenuePolicies(
        children: policies.children,
        dressCode: LocalizedText(ar: d.dress.ar?.trim(), en: d.dress.en?.trim()),
        terms: LocalizedText(ar: d.terms.ar?.trim(), en: d.terms.en?.trim()),
        responseSlaHours: policies.responseSlaHours,
        serviceChargeBps: policies.serviceChargeBps,
      ),
    );
    if (!mounted) return;
    if (!res.isSuccess) return toastResult(context, res);
    if (!sameHours(d.hours, _base!.hours)) {
      final r = await actions.saveHours(BusinessHours(rules: d.hours, closures: hours.closures));
      if (!mounted) return;
      if (!r.isSuccess) return toastResult(context, r);
    }
    if (d.women != _base!.women || d.men != _base!.men) {
      for (final h in halls.halls) {
        final sections = [
          for (final s in h.sections)
            if (s.audience == Audience.women && d.women != _base!.women)
              s.copyWith(policy: s.policy.copyWith(boysMaxAge: d.women))
            else if (s.audience == Audience.men && d.men != _base!.men)
              s.copyWith(policy: s.policy.copyWith(boysMaxAge: d.men))
            else
              s,
        ];
        final r = await actions.saveHall(h.id, hallInputOf(h, sections: sections));
        if (!mounted) return;
        if (!r.isSuccess) return toastResult(context, r);
      }
    }
    _base = d.copy();
    if (!mounted) return;
    nav.toast(GzToastSpec(message: l.hotelVenueToastPolicySaved, icon: GzIcons.checkCircle));
    nav.pop();
  }

  void _openHours(int index) {
    final l = context.l10n;
    GzNavigatorScope.of(context).openSheetBuilder(
      (_) => HoursSheet(rule: _draft!.hours[index], onSave: (next) => setState(() => _draft!.hours[index] = next)),
      options: GzSheetOptions(title: l.hotelVenueHoursTitle),
    );
  }

  Widget _children(BuildContext context, String label, int? age, ValueChanged<int?> set) {
    final l = context.l10n;
    final c = context.gz.colors;
    return Container(
      padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: c.borderStrong, width: GzStroke.hair),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzText(label, role: GzTextRole.title, color: c.textStrong),
          const SizedBox(height: GzSpace.s4),
          GzChipGroup<bool>(
            label: label,
            value: age != null,
            onChanged: (v) => v == null ? null : setState(() => set(v ? (age ?? 8) : null)),
            options: [
              GzChipOption<bool>(value: false, label: l.hotelVenueChildrenNoLimit),
              GzChipOption<bool>(value: true, label: l.hotelVenueChildrenLimit),
            ],
          ),
          if (age != null) ...[
            const SizedBox(height: GzSpace.s4),
            GzStepper(
              label: l.hotelVenueChildrenAge,
              value: age,
              min: 1,
              max: 18,
              onChanged: (v) => setState(() => set(v)),
              valueText: (n) => context.l10n.hotelVenueYears(n),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final lang = context.gz.locale.languageCode;
    final policies = ref.watch(venuePoliciesProvider);
    final halls = ref.watch(venueHallsProvider);
    final hours = ref.watch(venueHoursProvider);
    final config = ref.watch(venueConfigProvider).value;
    final venueName = ref.watch(partnerVenueProvider).value?.venue.name.of(lang);
    final value = combineAsync([policies, halls, hours]);
    if (policies.value != null && halls.value != null && hours.value != null) _seed(policies.value!, halls.value!, hours.value!);
    final d = _draft;
    final problem = d == null ? null : (_blank(d.terms) ? l.hotelVenueTermsNeeded : (_blank(d.dress) ? l.hotelVenueDressNeeded : null));
    final saving = ref.watch(venueActionsProvider).busy.any((k) => k.startsWith('save:'));
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await confirmDiscard(context, dirty: true) && context.mounted) nav.pop();
      },
      child: GzScreen(
        top: GzTopBar(title: l.hotelVenuePolTitle, subtitle: venueName),
        bottom: d == null
            ? null
            : venueSaveBar(
                context,
                dirty: _dirty,
                problem: problem,
                saving: saving,
                onSave: () => _save(policies.value!, halls.value!, hours.value!),
              ),
        child: GzAsyncView<bool>(
          value: value,
          loading: const FormSkeleton(),
          onRetry: () {
            ref.invalidate(venuePoliciesProvider);
            ref.invalidate(venueHallsProvider);
            ref.invalidate(venueHoursProvider);
          },
          data: (_) {
            final dd = _draft!;
            return VenuePage(
              children: [
                VenueSection(
                  title: l.hotelVenueSecTerms,
                  children: [
                    BilingualField(
                      label: l.hotelVenueTermsLabel,
                      ar: dd.terms.ar ?? '',
                      en: dd.terms.en ?? '',
                      multiline: true,
                      maxLength: 600,
                      onAr: (v) => setState(() => dd.terms = LocalizedText(ar: v, en: dd.terms.en)),
                      onEn: (v) => setState(() => dd.terms = LocalizedText(ar: dd.terms.ar, en: v)),
                    ),
                    VoucherTerms(config: config),
                  ],
                ),
                VenueSection(
                  title: l.hotelVenueSecChildren,
                  children: [
                    _children(context, l.hotelVenueSectionWomen, dd.women, (v) => dd.women = v),
                    _children(context, l.hotelVenueSectionMen, dd.men, (v) => dd.men = v),
                  ],
                ),
                VenueSection(
                  title: l.hotelVenueSecDress,
                  children: [
                    BilingualField(
                      label: l.hotelVenueDressLabel,
                      ar: dd.dress.ar ?? '',
                      en: dd.dress.en ?? '',
                      maxLength: 80,
                      onAr: (v) => setState(() => dd.dress = LocalizedText(ar: v, en: dd.dress.en)),
                      onEn: (v) => setState(() => dd.dress = LocalizedText(ar: dd.dress.ar, en: v)),
                    ),
                  ],
                ),
                VenueSection(
                  title: l.hotelVenueSecHours,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [for (var i = 0; i < dd.hours.length; i++) HoursRow(rule: dd.hours[i], onOpen: () => _openHours(i))],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
