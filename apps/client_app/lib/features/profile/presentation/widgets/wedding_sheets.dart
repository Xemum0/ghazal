// The pickers of Wedding info (CL-PROF-02): role, guests (ladies and men apart), date, budget and areas. Each sheet keeps a draft and
// writes the wedding file (and the Brief it feeds) on Done, or on the tap for a single choice; dismissing discards. Port of the web
// `WeddingSheets.tsx`.
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, MoneyMode, MoneyOptions, clockProvider, gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show DateMode, GuestSplit, LocalDate, MoneyAmount, MoneyRange, WeddingProfile, WeddingProfileInput, WeddingRole;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/wedding_edit.dart';
import 'profile_parts.dart';

typedef SavedCallback = void Function();

Widget _done(BuildContext context, VoidCallback onPressed, {bool loading = false}) =>
    GzSheetFooter(child: GzButton(label: context.l10n.commonActionDone, fullWidth: true, loading: loading, onPressed: onPressed));

/// Writes [input], closes the sheet and tells the screen; a refusal is a danger toast and the sheet stays.
Future<void> _commit(BuildContext context, WidgetRef ref, WeddingProfileInput input, SavedCallback onSaved) async {
  final nav = context.gzNav;
  final failed = context.l10n.clientProfileSharedSaveFailed;
  final problem = await saveWedding(ref, input);
  if (problem != null) {
    nav.toast(GzToastSpec(message: failed, tone: GzToastTone.danger));
    return;
  }
  nav.closeSheet();
  onSaved();
}

String roleLabel(BuildContext context, WeddingRole r) {
  final l = context.l10n;
  return switch (r) {
    WeddingRole.bride => l.clientProfileWedRoleBride,
    WeddingRole.groom => l.clientProfileWedRoleGroom,
    WeddingRole.planner => l.clientProfileWedRolePlanner,
    _ => l.clientProfileWedRoleFamily,
  };
}

class RoleSheet extends ConsumerWidget {
  const RoleSheet({required this.profile, required this.onSaved, super.key});

  final WeddingProfile profile;
  final SavedCallback onSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const roles = <WeddingRole>[WeddingRole.bride, WeddingRole.groom, WeddingRole.family, WeddingRole.planner];
    return ProfChoiceList<WeddingRole>(
      label: context.l10n.clientProfileWedRole,
      value: roles.contains(profile.role) ? profile.role : WeddingRole.family,
      onChanged: (r) => _commit(context, ref, WeddingProfileInput(role: r), onSaved),
      options: [for (final r in roles) ProfChoice<WeddingRole>(value: r, semantic: roleLabel(context, r), title: Text(roleLabel(context, r)))],
    );
  }
}

class GuestsSheet extends ConsumerStatefulWidget {
  const GuestsSheet({required this.profile, required this.onSaved, super.key});

  final WeddingProfile profile;
  final SavedCallback onSaved;

  @override
  ConsumerState<GuestsSheet> createState() => _GuestsSheetState();
}

class _GuestsSheetState extends ConsumerState<GuestsSheet> {
  late int _women = widget.profile.guests.women;
  late int _men = widget.profile.guests.men;

  Widget _stepper(BuildContext context, IconData icon, String name, int value, ValueChanged<int> on) {
    final f = ref.watch(gzFormatProvider);
    return GzStepper(
      labelWidget: GzIcon(icon, size: GzIconSize.lg, color: context.gz.colors.iconPrimary),
      semanticLabel: name,
      min: 0,
      max: kGuestsMax,
      step: 10,
      value: value,
      onChanged: on,
      valueText: f.guests,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepper(context, GzIcons.sectionWomen, l.clientProfileWedLadies, _women, (v) => setState(() => _women = v)),
        const SizedBox(height: GzSpace.s4),
        _stepper(context, GzIcons.sectionMen, l.clientProfileWedMen, _men, (v) => setState(() => _men = v)),
        _done(context, () => _commit(context, ref, WeddingProfileInput(guests: GuestSplit(women: _women, men: _men)), widget.onSaved)),
      ],
    );
  }
}

class DateSheet extends ConsumerStatefulWidget {
  const DateSheet({required this.profile, required this.onSaved, super.key});

  final WeddingProfile profile;
  final SavedCallback onSaved;

  @override
  ConsumerState<DateSheet> createState() => _DateSheetState();
}

enum _DateView { calendar, undecided, months }

class _DateSheetState extends ConsumerState<DateSheet> {
  LocalDate? _date;
  DateMode _mode = DateMode.exact;
  late _DateView _view;
  late GzYm _month;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _mode = p.dateMode;
    _date = p.dateMode == DateMode.undecided ? null : p.weddingDate;
    _view = p.dateMode == DateMode.undecided ? _DateView.undecided : (p.dateMode == DateMode.exact ? _DateView.calendar : _DateView.months);
    final base = _date ?? LocalDate.parse(ref.read(gzFormatProvider).isoDay(ref.read(clockProvider)()));
    _month = GzYm(base.year, base.month);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = ref.watch(gzFormatProvider);
    final today = f.isoDay(f.now());
    final start = GzYm(int.parse(today.substring(0, 4)), int.parse(today.substring(5, 7)));
    final months = <GzYm>[for (var i = 0; i < 12; i++) GzYm(start.year + (start.month - 1 + i) ~/ 12, (start.month - 1 + i) % 12 + 1)];
    String monthText(GzYm m) => f.date(f.kuwaitDate(m.year, m.month, 1), DateStyle.monthYear);
    final chosenMonth = _mode == DateMode.flexibleMonth && _date != null ? GzYm(_date!.year, _date!.month) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: GzSpace.s2,
          runSpacing: GzSpace.s2,
          children: [
            GzChip(
              label: context.gzL10n.commonLabelNotDecided,
              selected: _view == _DateView.undecided,
              onPressed: () => setState(() {
                _view = _DateView.undecided;
                _date = null;
                _mode = DateMode.undecided;
              }),
            ),
            GzChip(
              label: chosenMonth != null ? monthText(chosenMonth) : l.clientDiscoverBriefDateFlexible,
              iconStart: GzIcons.calendarDots,
              menu: true,
              selected: _view == _DateView.months || chosenMonth != null,
              onPressed: () => setState(() => _view = _view == _DateView.months ? _DateView.calendar : _DateView.months),
            ),
          ],
        ),
        const SizedBox(height: GzSpace.s4),
        if (_view != _DateView.months)
          GzCalendar(
            value: _view == _DateView.undecided || _mode != DateMode.exact ? null : _date?.toString(),
            onChanged: (iso) => setState(() {
              _view = _DateView.calendar;
              _date = iso == null ? null : LocalDate.parse(iso);
              _mode = iso == null ? DateMode.undecided : DateMode.exact;
            }),
            month: _month,
            onMonthChange: (m) => setState(() => _month = m),
            summary: false,
            legend: false,
            label: l.clientProfileWedDate,
          )
        else
          Wrap(
            spacing: GzSpace.s2,
            runSpacing: GzSpace.s2,
            children: [
              for (final m in months)
                GzChip(
                  label: monthText(m),
                  selected: chosenMonth == m,
                  onPressed: () => setState(() {
                    _date = LocalDate(m.year, m.month, 1);
                    _mode = DateMode.flexibleMonth;
                  }),
                ),
            ],
          ),
        _done(context, () => _commit(context, ref, WeddingProfileInput(weddingDate: _date, dateMode: _mode), widget.onSaved)),
      ],
    );
  }
}

class BudgetSheet extends ConsumerStatefulWidget {
  const BudgetSheet({required this.profile, required this.onSaved, super.key});

  final WeddingProfile profile;
  final SavedCallback onSaved;

  @override
  ConsumerState<BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends ConsumerState<BudgetSheet> {
  late int _lo = (widget.profile.venueBudget.min.fils / 1000).round();
  late int _hi = isOpenProfileBudget(widget.profile.venueBudget.max.fils) ? kBudgetMaxKd : (widget.profile.venueBudget.max.fils / 1000).round();

  @override
  Widget build(BuildContext context) {
    final f = ref.watch(gzFormatProvider);
    final c = context.gz.colors;
    final l = context.l10n;
    String money(int kd) => f.money(kd * 1000, const MoneyOptions(mode: MoneyMode.browse));
    String open(int kd) => l.clientDiscoverBriefBudgetOver(money(kd));
    String label((int, int?) b) => b.$1 == 0 && b.$2 != null
        ? l.clientDiscoverBriefBudgetUnder(money(b.$2!))
        : b.$2 == null
            ? open(b.$1)
            : f.moneyRange(b.$1 * 1000, b.$2! * 1000, const MoneyOptions(mode: MoneyMode.browse));
    final band = kBudgetBandsKd.indexWhere((x) => x.$1 == _lo && (x.$2 ?? kBudgetMaxKd) == _hi);
    void set(int a, int z) => setState(() {
      _lo = a;
      _hi = z;
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzText(l.clientDiscoverBriefBudgetHelper, role: GzTextRole.caption, color: c.textSecondary),
        const SizedBox(height: GzSpace.s4),
        GzChipGroup<int>(
          label: l.clientDiscoverBriefBudgetBands,
          value: band < 0 ? null : band,
          onChanged: (i) {
            if (i != null) set(kBudgetBandsKd[i].$1, kBudgetBandsKd[i].$2 ?? kBudgetMaxKd);
          },
          options: [for (var i = 0; i < kBudgetBandsKd.length; i++) GzChipOption<int>(value: i, label: label(kBudgetBandsKd[i]))],
        ),
        const SizedBox(height: GzSpace.s4),
        GzRangeSlider(
          min: 0,
          max: kBudgetMaxKd.toDouble(),
          step: kBudgetStepKd.toDouble(),
          minGap: kBudgetStepKd.toDouble(),
          label: l.clientProfileWedBudget,
          value: (_lo.toDouble(), _hi.toDouble()),
          showCaptions: false,
          valuesAt: GzRangeValues.below,
          valueText: (n, edge) => edge == GzRangeEdge.max && n >= kBudgetMaxKd ? open(kBudgetMaxKd) : money(n.round()),
          onChanged: (r) => set(r.$1.round(), r.$2.round()),
        ),
        _done(
          context,
          () => _commit(context, ref, WeddingProfileInput(venueBudget: MoneyRange(min: MoneyAmount(_lo * 1000), max: MoneyAmount(_hi >= kBudgetMaxKd ? kBudgetMaxKd * 1000 : _hi * 1000))), widget.onSaved),
        ),
      ],
    );
  }
}

class AreasSheet extends ConsumerStatefulWidget {
  const AreasSheet({required this.profile, required this.onSaved, super.key});

  final WeddingProfile profile;
  final SavedCallback onSaved;

  @override
  ConsumerState<AreasSheet> createState() => _AreasSheetState();
}

class _AreasSheetState extends ConsumerState<AreasSheet> {
  late List<String> _ids = <String>[...widget.profile.areaIds];

  @override
  Widget build(BuildContext context) {
    final lang = context.gz.locale.languageCode;
    final c = context.gz.colors;
    final areas = ref.watch(profileAreasProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        areas.when(
          loading: () => const GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 120),
          error: (e, _) => GzErrorState(kind: GzErrorKind.load, onRetry: () => ref.invalidate(profileAreasProvider), fill: false),
          data: (r) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final g in r.governorates)
                if (r.areas.any((a) => a.governorateId == g.id)) ...[
                  Padding(padding: const EdgeInsetsDirectional.only(top: GzSpace.s4, bottom: GzSpace.s2), child: GzText(g.name.of(lang), role: GzTextRole.label, color: c.textSecondary)),
                  GzChipGroup<String>.multiple(
                    label: g.name.of(lang),
                    values: <String>[for (final a in r.areas) if (a.governorateId == g.id && _ids.contains(a.id)) a.id],
                    onChanged: (next) => setState(() {
                      final inGov = <String>{for (final a in r.areas) if (a.governorateId == g.id) a.id};
                      _ids = <String>[..._ids.where((x) => !inGov.contains(x)), ...next];
                    }),
                    options: [for (final a in r.areas) if (a.governorateId == g.id) GzChipOption<String>(value: a.id, label: a.name.of(lang))],
                  ),
                ],
            ],
          ),
        ),
        _done(context, () => _commit(context, ref, WeddingProfileInput(areaIds: _ids), widget.onSaved)),
      ],
    );
  }
}

/// Opens one picker as a sheet.
void openWeddingSheet(BuildContext context, {required String title, required Widget child, bool fill = false}) {
  context.gzNav.openSheetBuilder((_) => fill ? Stack(children: [const GzSheetFill(), child]) : child, options: GzSheetOptions(title: title));
}
