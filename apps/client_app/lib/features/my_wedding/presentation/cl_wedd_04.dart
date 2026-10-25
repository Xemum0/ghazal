import 'package:client_app/app/state/state.dart' show clientDataRevisionProvider;
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/services.dart' show LengthLimitingTextInputFormatter;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart'
    show GateReason, GateResume, WidgetSessionGate, gzProblemMessage, sessionProvider, weddingRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'widgets/wd_common.dart' show WdGap, WdSheetTop, wdCatGlyph, wdCatName;
import '../application/wedding_data.dart';
import 'cl_wedd_03.dart' show BkBudgetAsync;

/// CL-WEDD-04 Add expense (sheet over Budget; also the edit and delete sheet of a manual expense). Covers CA-TOOL-10, CA-TOOL-11.
///
/// An amount (Eastern-Arabic digits normalised, up to three decimals), a category by glyph, an optional label, a date and Paid | Planned.
/// Validation is blameless and shows once, on Save. Save closes the sheet and the row lands in the budget with an Undo bar. A guest may
/// fill it in and signs in at Save (the account sheet 'CL-AUTH-01', opened by requireSignIn); the sheet stays underneath, so what was
/// typed is still there on return. Done closes the sheet over 'CL-WEDD-03' (Budget). Params: expenseId (edit).
class ClWedd04Screen extends ConsumerStatefulWidget {
  const ClWedd04Screen({super.key});

  @override
  ConsumerState<ClWedd04Screen> createState() => _ClWedd04State();
}

class _ClWedd04State extends ConsumerState<ClWedd04Screen> {
  String _amount = '';
  BudgetCategoryId _category = BudgetCategoryId.photoVideo;
  String _label = '';
  String? _date;
  bool _paid = true;
  bool _confirmDelete = false;
  bool _showError = false;
  bool _saving = false;

  /// "80", "80.5", "٨٠٫٥٠٠" -> integer fils, or null. At most three decimals.
  int? _toFils(String text) {
    final clean = text.replaceAll(RegExp(r'[\s,]'), '');
    final m = RegExp(r'^(\d+)(?:\.(\d{0,3}))?$').firstMatch(clean);
    if (m == null) return null;
    final fils = int.parse(m.group(1)!) * 1000 + int.parse((m.group(2) ?? '').padRight(3, '0'));
    return fils > 0 ? fils : null;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = context.gzNav;
    final guest = !ref.watch(sessionProvider.select((s) => s.isSignedIn));
    final editingId = nav.params['expenseId'] as String?;
    return Column(
      key: const ValueKey<String>('wedding.expense'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSheetPinnedHeader(child: WdSheetTop(title: editingId == null ? l.clientMyWeddingExpenseTitleAdd : l.clientMyWeddingExpenseTitleEdit)),
        BkBudgetAsync(
          value: ref.watch(weddingBudgetProvider),
          onRetry: () => ref.invalidate(weddingBudgetProvider),
          data: (view) => _form(context, view, editingId, guest),
        ),
      ],
    );
  }

  Widget _form(BuildContext context, BudgetView view, String? editingId, bool guest) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final editing = editingId == null ? null : view.budget.expenses.where((e) => e.id == editingId).firstOrNull;
    final manual = editing != null && editing.bookingId == null;
    if (_confirmDelete && editing != null) return _deleteConfirm(context, editing);
    if (editing != null) {
      _date ??= editing.date?.toString();
      if (_category == BudgetCategoryId.photoVideo && editing.categoryId != BudgetCategoryId.photoVideo) _category = editing.categoryId;
    }
    final day = _date ?? f.isoDay(f.now());
    final fils = _toFils(_amount);
    final error = _showError && fils == null ? l.clientMyWeddingExpenseAmountError : null;
    final cats = view.budget.categories.where((c) => !c.autoLinked).toList();
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final cur = GzText(f.moneyParts(0).currency, role: GzTextRole.bodyS, color: c.textSecondary);
    return WdGap(
      gap: GzSpace.s4,
      children: [
        const SizedBox(height: GzSpace.s1),
        GzTextField(
          label: l.clientMyWeddingExpenseAmount,
          value: _amount,
          onValueChange: (v) => setState(() => _amount = v),
          error: error,
          keyboardType: TextInputType.number,
          dir: GzFieldDir.ltr,
          startAdornment: rtl ? null : cur,
          endAdornment: rtl ? cur : null,
        ),
        _CategoryRail(categories: cats, value: _category, onChanged: (v) => setState(() => _category = v)),
        Semantics(
          label: l.clientMyWeddingExpenseNote,
          container: true,
          child: GzTextField(
            placeholder: l.clientMyWeddingExpenseNote,
            value: _label,
            onValueChange: (v) => setState(() => _label = v),
            inputFormatters: [LengthLimitingTextInputFormatter(120)],
            startAdornment: GzIcon(GzIcons.edit, size: GzIconSize.sm, color: c.iconSecondary),
          ),
        ),
        GzPressable(
          onPressed: _pickDate,
          semanticLabel: '${l.clientMyWeddingExpenseDate}, ${f.date(day, DateStyle.dayMonth)}',
          builder: (context, st) => GzFieldShell(
            child: Row(
              children: [
                GzIcon(GzIcons.calendar, size: GzIconSize.sm, color: c.iconSecondary),
                const SizedBox(width: GzSpace.s2),
                Expanded(
                  child: GzText(f.date(day, DateStyle.dayMonth), role: GzTextRole.body, color: c.textStrong, figures: true),
                ),
              ],
            ),
          ),
        ),
        GzIconSegmented<bool>(
          labels: GzIconSegmentedLabels.all,
          options: [
            GzIconSegmentedOption(value: true, icon: GzIcons.checkCircle, label: l.clientMyWeddingExpensePaid),
            GzIconSegmentedOption(value: false, icon: GzIcons.calendar, label: l.clientMyWeddingExpensePlanned),
          ],
          label: l.clientMyWeddingExpenseStatus,
          value: _paid,
          onChanged: (v) => setState(() => _paid = v),
        ),
        const SizedBox.shrink(),
        WdGap(
          gap: GzSpace.s3,
          children: [
            GzButton(
              variant: GzButtonVariant.primary,
              fullWidth: true,
              loading: _saving,
              onPressed: () => _save(context, editing, manual, guest),
              label: guest ? l.clientMyWeddingGuestAction : context.gzL10n.commonActionSave,
            ),
            if (manual)
              GzButton(
                variant: GzButtonVariant.secondary,
                fullWidth: true,
                onPressed: () => setState(() => _confirmDelete = true),
                label: l.clientMyWeddingExpenseDelete,
              ),
          ],
        ),
      ],
    );
  }

  void _pickDate() {
    final f = context.gzFormat;
    final nav = context.gzNav;
    nav.openSheetBuilder(
      (_) => GzDateFieldSheetContent(
        value: _date ?? f.isoDay(f.now()),
        onConfirm: (v) {
          if (v != null) setState(() => _date = v);
          nav.closeSheet();
        },
      ),
      options: GzSheetOptions(title: gzDateFieldSheetTitle(context)),
    );
  }

  Future<void> _save(BuildContext context, BudgetExpense? editing, bool manual, bool guest) async {
    if (_saving) return;
    final fils = _toFils(_amount);
    if (fils == null) {
      setState(() => _showError = true);
      return;
    }
    if (guest && !ref.requireSignIn(GateReason.planner, resume: GateResume('CL-WEDD-04'))) return;
    final nav = context.gzNav;
    final l10n = context.l10n;
    final common = context.gzL10n;
    setState(() => _saving = true);
    final repo = ref.read(weddingRepositoryProvider);
    try {
      if (editing != null && manual) {
        await repo.updateExpense(
          expenseId: editing.id,
          body: ExpensePatch(label: _label.isEmpty ? null : _label),
        );
      } else {
        await repo.addExpense(
          body: ExpenseInput(
            categoryId: _category,
            label: _label.isEmpty ? l10n.clientMyWeddingExpenseSampleLabel : _label,
            amount: MoneyAmount(fils),
            status: _paid ? ExpenseStatus.paid : ExpenseStatus.planned,
            date: _date == null ? null : LocalDate.parse(_date!),
          ),
        );
      }
      ref.read(clientDataRevisionProvider.notifier).bump();
      if (!mounted) return;
      nav.closeSheet();
      nav.toast(GzToastSpec(message: l10n.clientMyWeddingExpenseSuccessTitle, tone: GzToastTone.success));
    } on ApiProblem catch (p) {
      if (!mounted) return;
      setState(() => _saving = false);
      nav.toast(GzToastSpec(message: gzProblemMessage(common, p), tone: GzToastTone.danger));
    }
  }

  Widget _deleteConfirm(BuildContext context, BudgetExpense editing) {
    final l = context.l10n;
    return WdGap(
      children: [
        GzText(
          l.clientMyWeddingExpenseDeleteTitle,
          role: GzTextRole.title,
          color: context.gz.colors.textStrong,
          header: true,
          textAlign: TextAlign.center,
        ),
        WdGap(
          gap: GzSpace.s3,
          children: [
            GzButton(
              variant: GzButtonVariant.destructive,
              fullWidth: true,
              iconStart: GzIcons.close,
              onPressed: () async {
                final nav = context.gzNav;
                final common = context.gzL10n;
                try {
                  await ref.read(weddingRepositoryProvider).deleteExpense(expenseId: editing.id);
                  ref.read(clientDataRevisionProvider.notifier).bump();
                  if (!mounted) return;
                  nav.closeSheet();
                  nav.toast(GzToastSpec(message: l.clientMyWeddingExpenseDeleted, tone: GzToastTone.success));
                } on ApiProblem catch (p) {
                  if (mounted) nav.toast(GzToastSpec(message: gzProblemMessage(common, p), tone: GzToastTone.danger));
                }
              },
              label: l.clientMyWeddingExpenseDelete,
            ),
            GzButton(
              variant: GzButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => setState(() => _confirmDelete = false),
              label: l.clientMyWeddingExpenseKeep,
            ),
          ],
        ),
      ],
    );
  }
}

/// The category rail: glyph tiles in rows of four (the fixture order, read by glyph), the chosen tile with the gold diamond, its
/// short name below the rail.
class _CategoryRail extends StatelessWidget {
  const _CategoryRail({required this.categories, required this.value, required this.onChanged});

  final List<BudgetCategory> categories;
  final BudgetCategoryId value;
  final ValueChanged<BudgetCategoryId> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final chosen = categories.where((cat) => cat.id == value).firstOrNull;
    Widget tile(BudgetCategory cat) {
      final selected = cat.id == value;
      return Expanded(
        child: Semantics(
          label: wdCatName(l, cat.id),
          checked: selected,
          inMutuallyExclusiveGroup: true,
          excludeSemantics: true,
          child: GzPressable(
            onPressed: () => onChanged(cat.id),
            builder: (context, st) => DecoratedBox(
              decoration: BoxDecoration(
                color: c.surfaceRaised,
                borderRadius: GzRadius.smAll,
                border: Border.all(color: selected ? c.controlChipBorderSelected : c.controlChipBorder, width: GzStroke.hair),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: GzSize.controlMd,
                    child: Center(
                      child: GzIcon(wdCatGlyph(cat.icon), size: GzIconSize.md, color: c.textPrimary),
                    ),
                  ),
                  if (selected)
                    PositionedDirectional(
                      top: GzSpace.s1,
                      end: GzSpace.s1,
                      child: ExcludeSemantics(
                        child: Transform.rotate(
                          angle: 0.785,
                          child: Container(width: GzSize.knotBead, height: GzSize.knotBead, color: c.markKhayt),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < categories.length; i += 4) {
      rows.add(
        Row(
          children: [
            for (var j = i; j < i + 4 && j < categories.length; j++) ...[if (j > i) const SizedBox(width: GzSpace.s2), tile(categories[j])],
          ],
        ),
      );
    }
    return Semantics(
      container: true,
      label: l.clientMyWeddingExpenseCategory,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s2), rows[i]],
          if (chosen != null) ...[
            const SizedBox(height: GzSpace.s2),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: GzSize.iconSm),
              child: GzText(wdCatName(l, chosen.id), role: GzTextRole.caption, color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
