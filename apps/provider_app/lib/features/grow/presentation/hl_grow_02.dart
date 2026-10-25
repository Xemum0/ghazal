// HL-GROW-02 Voucher price window, step 1 of 2 (web `HL-GROW-02.tsx`): which packages and halls the window covers, the lower voucher price (never above
// the standard price) and the title in both languages, with the client's own card drawn live under the decisions. Windows replace offers, flash sales
// and coupons (ADR 0033 D4). Params: `from: 'list'`, `dates` (array) or `date` (a lapsed request's date): they arrive as the prefilled state.
// Requirements: HA-OFFR-01, HA-OFFR-02, HA-OFFR-03, HA-AUTH-02, HA-VMGT-11.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/grow_data.dart';
import '../application/grow_model.dart';
import 'widgets/grow_bits.dart';
import 'widgets/preview_parts.dart';

class HlGrow02Screen extends ConsumerStatefulWidget {
  const HlGrow02Screen({super.key});

  @override
  ConsumerState<HlGrow02Screen> createState() => _HlGrow02ScreenState();
}

class _HlGrow02ScreenState extends ConsumerState<HlGrow02Screen> {
  bool _seeded = false;
  int _rev = 0;

  void _seed(PackageCatalog cat) {
    if (_seeded) return;
    _seeded = true;
    final nav = GzNavigatorScope.of(context);
    final session = ref.read(growSessionProvider.notifier);
    final d = ref.read(growSessionProvider).draft;
    final params = nav.params;
    final fromList = params['from'] == 'list';
    final raw = params['dates'] ?? (params['date'] != null ? [params['date']] : null);
    final dates = raw is List ? [for (final x in raw) x.toString()] : const <String>[];
    Future.microtask(() {
      if (!mounted) return;
      setState(() => _rev++);
      session.setOrigin(list: fromList);
      if (d.packageIds.isEmpty && d.voucherKd.isEmpty && !d.dirty) session.reset(emptyDraftFor(cat));
      if (dates.isNotEmpty && !ref.read(growSessionProvider).draft.dirty && ref.read(growSessionProvider).draft.eventDates.isEmpty) {
        session.reset(ref.read(growSessionProvider).draft.copyWith(eventDates: dates, prefilled: true));
      }
    });
  }

  Future<void> _guard() async {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    final d = ref.read(growSessionProvider).draft;
    if (!d.dirty) return nav.pop();
    final answer = await nav.openDialog(
      GzDialogSpec(
        title: l.hotelGrowGuardTitle,
        icon: GzIcons.warning,
        tone: GzDialogTone.destructive,
        confirmLabel: l.hotelGrowGuardDiscard,
        cancelLabel: l.hotelGrowGuardKeep,
      ),
    );
    if (answer == GzDialogResult.confirm) {
      final cat = ref.read(growCatalogProvider).value;
      ref.read(growSessionProvider.notifier).reset(cat == null ? const GrowDraft() : emptyDraftFor(cat));
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final nav = GzNavigatorScope.of(context);
    final catValue = ref.watch(growCatalogProvider);
    final cat = catValue.value;
    final draft = ref.watch(growSessionProvider.select((s) => s.draft));
    final hallList = ref.watch(growHallsProvider).value ?? const <Hall>[];
    final config = ref.watch(growConfigProvider).value;
    final soft = ref.watch(growSoftDatesProvider).value ?? const <String>[];
    final today = ref.watch(growTodayProvider);
    final weekend = config?.weekendTierDays ?? const [4, 5, 6];
    final fee = config?.voucherFeeFils ?? kFallbackFee;
    if (cat != null) _seed(cat);
    final top = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GzTopBar(back: GzTopBarBack.close, onBack: _guard, title: l.hotelGrowEditorTitle),
        const StepThread(step: 1),
      ],
    );
    if (cat == null) {
      return GzScreen(
        top: top,
        child: GzAsyncView<PackageCatalog>(
          value: catValue,
          loading: const _Skeleton(),
          onRetry: () => ref.invalidate(growCatalogProvider),
          data: (_) => const _Skeleton(),
        ),
      );
    }
    final fallback = soft.isNotEmpty ? LocalDate.parse(soft.first) : today.addDays(14);
    final problem = priceProblem(cat, draft, fallback, weekend);
    final warning = priceWarning(cat, draft, fallback, weekend, fee);
    final b = bounds(cat, draft, fallback, weekend);
    final fils = draftFils(draft);
    final titles = suggestedTitles();
    final titleEn = draft.titleTouched ? draft.titleEn : titles.en;
    final titleAr = draft.titleTouched ? draft.titleAr : titles.ar;
    final titleReady = titleEn.trim().isNotEmpty && titleAr.trim().isNotEmpty;
    final ex = exampleOf(ref, problem != null ? b.standard : fils, draft.packageIds, draft.eventDates);
    final reason = !titleReady ? l.hotelGrowNextReasonTitles : (problem != null ? l.hotelGrowNextReasonValue : null);
    final pkgs = voucherPackages(cat);
    final session = ref.read(growSessionProvider.notifier);
    final showError = draft.dirty;
    final amountError = showError && problem == PriceProblem.over
        ? l.hotelGrowOverError(f.money(b.standard))
        : (showError && problem == PriceProblem.empty ? l.hotelGrowEmptyValueError : null);
    return PopScope(
      canPop: !draft.dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _guard();
      },
      child: GzScreen(
        top: top,
        bottom: GzActionBar(
          summaryValue: ex == null
              ? null
              : Semantics(
                  label: l.hotelGrowCouplesSee,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GzIcon(GzIcons.ticket, size: GzIconSize.xs, color: c.iconSecondary),
                      GzPrice(fils: ex.voucher, size: GzPriceSize.strong, was: ex.saving > 0 ? ex.standard : null),
                    ],
                  ),
                ),
          action: GzActionBarAction(
            label: l.commonActionNext,
            iconEnd: GzIcons.chevronRight,
            disabled: reason != null,
            reason: reason,
            onPressed: () {
              if (!draft.titleTouched) session.patch((d) => d.copyWith(titleEn: titleEn, titleAr: titleAr, titleTouched: true));
              nav.push('HL-GROW-03');
            },
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4, bottom: GzSpace.s8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (draft.prefilled && draft.eventDates.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
                      child: GzIcon(GzIcons.calendarCheck, size: GzIconSize.sm, color: c.iconPrimary),
                    ),
                    const SizedBox(width: GzSpace.s3),
                    Expanded(
                      child: GzFactRow(
                        label: l.hotelGrowPrefilledTitle,
                        children: [
                          for (final d in draft.eventDates)
                            GzFactChip(
                              icon: GzIcons.calendar,
                              valueWidget: GzText(dm(f, d), role: GzTextRole.figBodyS, color: c.textPrimary, figures: true),
                              label: l.hotelGrowFactDate,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GzSpace.section),
              ],
              GrowHead(icon: GzIcons.package, title: l.hotelGrowScopeTitle),
              const SizedBox(height: GzSpace.s3),
              GrowPickRow(
                icon: GzIcons.package,
                label: l.hotelGrowPackagesLabel,
                allLabel: l.hotelGrowAppliesAll,
                options: [for (final p in pkgs) PickOption(p.id, p.name.of(lang))],
                value: draft.packageIds,
                onChanged: (next) => session.patch((d) => d.copyWith(packageIds: next)),
              ),
              if (hallList.length > 1) ...[
                const SizedBox(height: GzSpace.s3),
                GrowPickRow(
                  icon: GzIcons.hall,
                  label: l.hotelGrowHallsLabel,
                  allLabel: l.hotelGrowAllHalls,
                  options: [for (final h in hallList) PickOption(h.id, h.name.of(lang))],
                  value: draft.hallIds,
                  onChanged: (next) => session.patch((d) => d.copyWith(hallIds: next)),
                ),
              ],
              const SizedBox(height: GzSpace.section),
              GrowHead(icon: GzIcons.coins, title: l.hotelGrowValueTitle),
              const SizedBox(height: GzSpace.s3),
              GzTextField(
                key: ValueKey('grow.price.$_rev'),
                label: b.flat ? l.hotelGrowPriceLabelFlat : l.hotelGrowPriceLabel,
                dir: GzFieldDir.ltr,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                defaultValue: draft.voucherKd,
                onValueChange: (s) => session.patch((d) => d.copyWith(voucherKd: cleanKd(s))),
                startAdornment: GzText(f.moneyParts(0).currency, role: GzTextRole.caption, color: c.textSecondary),
                endAdornment: Semantics(
                  label: b.flat ? l.hotelGrowUnitPackage : l.hotelGrowUnitGuest,
                  child: GzIcon(b.flat ? GzIcons.package : GzIcons.perGuest, size: GzIconSize.sm, color: c.iconSecondary),
                ),
                error: amountError,
              ),
              const SizedBox(height: GzSpace.s2),
              GzFactRow(
                label: l.hotelGrowBoundsLabel,
                children: [
                  GzFactChip(icon: GzIcons.coins, value: f.money(b.standard), label: l.hotelGrowStandardPrice, small: true, tone: GzFactTone.muted),
                  GzFactChip(icon: GzIcons.ticket, value: f.money(b.standing), label: l.hotelGrowStandingPrice, small: true, tone: GzFactTone.muted),
                ],
              ),
              if (warning == PriceWarning.noEffect) ...[
                const SizedBox(height: GzSpace.s3),
                GrowNote(
                  icon: GzIcons.warningCircle,
                  text: NoteText(l.hotelGrowNoEffectShort),
                  info: GzInfoButton(title: l.hotelGrowNoEffectTitle, paragraphs: [l.hotelGrowNoEffect(f.money(b.standing))]),
                ),
              ],
              if (warning == PriceWarning.belowFee) ...[
                const SizedBox(height: GzSpace.s3),
                GrowNote(
                  icon: GzIcons.warningCircle,
                  text: NoteText(l.hotelGrowBelowFeeShort(f.money(fee))),
                  info: GzInfoButton(title: l.hotelGrowBelowFeeTitle, paragraphs: [l.hotelGrowBelowFee(f.money(fee))]),
                ),
              ],
              const SizedBox(height: GzSpace.section),
              GrowHead(
                icon: GzIcons.eye,
                title: l.hotelGrowPreviewTitle,
                trailing: GzInfoButton(title: l.hotelGrowRulesTitle, paragraphs: [l.hotelGrowBestOnly]),
              ),
              const SizedBox(height: GzSpace.s3),
              if (problem != null)
                Semantics(
                  label: l.hotelGrowPreviewWaiting,
                  child: const Center(child: GzIllustration(GzIllustrationName.voucher, tone: GzIllustrationTone.quiet)),
                )
              else
                PreviewStrip(card: true, rate: fils, packageIds: draft.packageIds, dates: draft.eventDates),
              const SizedBox(height: GzSpace.section),
              GrowHead(icon: GzIcons.edit, title: l.hotelGrowTitleTitle),
              const SizedBox(height: GzSpace.s3),
              _TitleField(
                key: ValueKey('grow.title.en.$_rev'),
                label: l.hotelGrowTitleEn,
                value: titleEn,
                onChanged: (s) => session.patch((d) => d.copyWith(titleEn: s, titleAr: titleAr, titleTouched: true)),
              ),
              const SizedBox(height: GzSpace.s3),
              _TitleField(
                key: ValueKey('grow.title.ar.$_rev'),
                label: l.hotelGrowTitleAr,
                value: titleAr,
                onChanged: (s) => session.patch((d) => d.copyWith(titleAr: s, titleEn: titleEn, titleTouched: true)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField({required this.label, required this.value, required this.onChanged, super.key});

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final done = value.trim().isNotEmpty;
    return GzTextField(
      label: label,
      defaultValue: value,
      maxLength: 60,
      onValueChange: onChanged,
      endAdornment: done
          ? Semantics(
              label: l.hotelGrowTitleComplete,
              child: GzIcon(GzIcons.checkCircle, size: GzIconSize.sm, color: c.iconSuccess),
            )
          : null,
      helper: done ? null : l.commonLabelRequired,
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s3),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 56),
        SizedBox(height: GzSpace.s4),
        GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 56),
        SizedBox(height: GzSpace.s4),
        GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 200),
        SizedBox(height: GzSpace.s4),
        GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 56),
        SizedBox(height: GzSpace.s4),
        GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 56),
      ],
    ),
  );
}
