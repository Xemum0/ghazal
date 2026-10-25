import 'package:client_app/app/state/state.dart' show clientDataRevisionProvider, weddingProfileProvider;
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemMessage, weddingRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'widgets/wd_common.dart' show WdGap, WdSheetTop, wdCatGlyph, wdCatName;
import '../application/wedding_data.dart';
import 'cl_wedd_03.dart' show BkBudgetAsync;

/// CL-WEDD-05 Set budget (sheet over Budget). Covers CA-TOOL-05, CA-TOOL-08, CA-TOOL-09, CA-ONB-04.
///
/// The total for the whole wedding (asked here; onboarding only gives the venue and catering band, shown as a reference on that category),
/// three suggested totals, and the split by category with steppers. A live figure says what is left to allocate; allocating more than
/// the total is a calm glyph and a figure, never a block. Save returns to Budget.
class ClWedd05Screen extends ConsumerStatefulWidget {
  const ClWedd05Screen({super.key});

  @override
  ConsumerState<ClWedd05Screen> createState() => _ClWedd05State();
}

class _ClWedd05State extends ConsumerState<ClWedd05Screen> {
  String _total = '';
  final Map<BudgetCategoryId, int> _allocKd = {};
  bool _saving = false;
  bool _failed = false;
  bool _showError = false;
  bool _init = false;

  /// Categories move in steps of KD 100; the venue, most of the budget, in steps of KD 500.
  int _stepOf(BudgetCategoryId id) => id == BudgetCategoryId.venueCatering ? 500 : 100;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      key: const ValueKey<String>('wedding.setup'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSheetPinnedHeader(child: WdSheetTop(title: l.clientMyWeddingSetupTitle)),
        const SizedBox(height: GzSpace.s5),
        BkBudgetAsync(
          value: ref.watch(weddingBudgetProvider),
          onRetry: () => ref.invalidate(weddingBudgetProvider),
          data: (view) => _form(context, view),
        ),
        GzSheetFooter(
          child: GzButton(
            variant: GzButtonVariant.primary,
            fullWidth: true,
            loading: _saving,
            onPressed: () {
              final totalKd = int.tryParse(_total.replaceAll(RegExp(r'[^\d]'), ''));
              if (totalKd != null) _save(context, totalKd);
            },
            label: context.gzL10n.commonActionSave,
          ),
        ),
      ],
    );
  }

  void _seed(BudgetView view) {
    if (_init) return;
    _init = true;
    _total = view.budget.total.fils <= 0 ? '' : (view.budget.total.fils ~/ 1000).toString();
    for (final cat in view.budget.categories) {
      _allocKd[cat.id] = cat.allocated.fils ~/ 1000;
    }
  }

  Widget _form(BuildContext context, BudgetView view) {
    final l = context.l10n;
    final f = context.gzFormat;
    _seed(view);
    const presets = [40000, 60000, 80000];
    final totalKd = int.tryParse(_total.replaceAll(RegExp(r'[^\d]'), ''));
    final allocated = _allocKd.values.fold<int>(0, (a, b) => a + b);
    final left = (totalKd ?? 0) - allocated;
    final over = totalKd != null && left < 0;
    final c = context.gz.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final cur = GzText(f.moneyParts(0).currency, role: GzTextRole.bodyS, color: c.textSecondary);
    final share = (totalKd == null || totalKd <= 0) ? 0.0 : (allocated / totalKd).clamp(0.0, 1.0);
    final cats = view.budget.categories;
    return WdGap(
      gap: GzSpace.s5,
      children: [
        if (_failed) GzBanner(message: l.clientMyWeddingSetupError, tone: GzBannerTone.danger, shape: GzBannerShape.card),
        WdGap(
          children: [
            GzTextField(
              label: l.clientMyWeddingSetupTotal,
              value: _total,
              onValueChange: (v) => setState(() => _total = v.replaceAll(RegExp(r'[^\d]'), '').substring(0, v.length > 7 ? 7 : v.length)),
              error: _showError && totalKd == null ? l.clientMyWeddingExpenseAmountError : null,
              keyboardType: TextInputType.number,
              dir: GzFieldDir.ltr,
              startAdornment: rtl ? null : cur,
              endAdornment: rtl ? cur : null,
            ),
            GzChipGroup<int>(
              options: [
                for (final preset in presets)
                  GzChipOption(
                    value: preset,
                    label: f.integer(preset),
                    labelWidget: GzText(f.integer(preset), role: GzTextRole.body, color: c.textStrong, figures: true),
                  ),
              ],
              label: l.clientMyWeddingSetupPresets,
              value: totalKd != null && presets.contains(totalKd) ? totalKd : null,
              onChanged: (v) {
                if (v != null) setState(() => _total = v.toString());
              },
            ),
          ],
        ),
        WdGap(
          gap: GzSpace.s2,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: GzSpace.s1),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: GzSize.controlSm),
                child: Row(
                  children: [
                    Expanded(
                      child: GzText(l.clientMyWeddingSetupCategories, role: GzTextRole.title, color: c.textStrong, header: true),
                    ),
                    const SizedBox(width: GzSpace.s3),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 56,
                            height: GzStroke.threadMax,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: (share * 1000).round().clamp(0, 1000),
                                  child: ColoredBox(color: c.markKhayt),
                                ),
                                Expanded(
                                  flex: 1000 - (share * 1000).round().clamp(0, 1000),
                                  child: ColoredBox(color: c.markTrack),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: GzSpace.s2),
                          GzIcon(over ? GzIcons.info : GzIcons.coins, size: GzIconSize.sm, color: over ? c.iconAccent : c.iconSecondary),
                          const SizedBox(width: GzSpace.s2),
                          GzText(f.integer(left.abs()), role: GzTextRole.figBody, color: over ? c.textGoldInk : c.textStrong, figures: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final cat in cats)
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: cat == cats.last ? c.borderHairline.withAlpha(0) : c.borderHairline, width: GzStroke.hair),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [_allocRow(context, cat), if (cat.id == BudgetCategoryId.venueCatering) _venueReference(context)],
                    ),
                  ),
              ],
            ),
          ],
        ),
        _alertsNote(context),
      ],
    );
  }

  /// What the alerts do: a bell and the two percents, each with the glyph the Budget screen uses for it.
  Widget _alertsNote(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    return Row(
      children: [
        GzIcon(GzIcons.bell, size: GzIconSize.sm, color: context.gz.colors.iconSecondary),
        const SizedBox(width: GzSpace.s2),
        Expanded(
          child: Row(
            children: [
              GzFactChip(
                icon: GzIcons.info,
                label: l.clientMyWeddingSetupAlertSoft(f.percent(80, maxFraction: 0)),
                value: f.percent(80, maxFraction: 0),
                small: true,
                tone: GzFactTone.muted,
              ),
              const SizedBox(width: GzSpace.s3),
              GzFactChip(
                icon: GzIcons.warningCircle,
                label: l.clientMyWeddingSetupAlertHard(f.percent(100, maxFraction: 0)),
                value: f.percent(100, maxFraction: 0),
                small: true,
                tone: GzFactTone.muted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _allocRow(BuildContext context, BudgetCategory cat) {
    final name = wdCatName(context.l10n, cat.id);
    return GzStepper(
      value: _allocKd[cat.id] ?? 0,
      min: 0,
      step: _stepOf(cat.id),
      labelWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GzIcon(wdCatGlyph(cat.icon), size: GzIconSize.sm, color: context.gz.colors.iconSecondary),
          const SizedBox(width: GzSpace.s2),
          Flexible(
            child: GzText(name, role: GzTextRole.bodyS, color: context.gz.colors.textStrong, maxLines: 1),
          ),
        ],
      ),
      semanticLabel: name,
      valueWidth: 76,
      onChanged: (v) => setState(() => _allocKd[cat.id] = v),
    );
  }

  /// The onboarding venue-and-catering band as a reference under its category.
  Widget _venueReference(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final band = ref.watch(weddingProfileProvider).value?.venueBudget;
    if (band == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.s8, bottom: GzSpace.s3),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: GzFactChip(
          icon: GzIcons.info,
          label: l.clientMyWeddingSetupVenueReference,
          value: '${f.integer(band.min.fils ~/ 1000)}–${f.integer(band.max.fils ~/ 1000)}',
          small: true,
          tone: GzFactTone.muted,
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, int totalKd) async {
    if (totalKd <= 0) {
      setState(() => _showError = true);
      return;
    }
    if (_saving) return;
    final nav = context.gzNav;
    final l10n = context.l10n;
    final common = context.gzL10n;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await ref
          .read(weddingRepositoryProvider)
          .setBudget(
            body: SetBudgetInput(
              total: MoneyAmount(totalKd * 1000),
              allocations: [for (final e in _allocKd.entries) BudgetAllocation(categoryId: e.key, allocated: MoneyAmount(e.value * 1000))],
            ),
          );
      ref.read(clientDataRevisionProvider.notifier).bump();
      if (!mounted) return;
      nav.closeSheet();
      nav.toast(GzToastSpec(message: l10n.clientMyWeddingSetupSaved, tone: GzToastTone.success));
    } on ApiProblem catch (p) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _failed = true;
      });
      nav.toast(GzToastSpec(message: gzProblemMessage(common, p), tone: GzToastTone.danger));
    }
  }
}
