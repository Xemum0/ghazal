import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/voucher_model.dart';
import '../application/voucher_providers.dart';
import '../application/voucher_quote.dart';
import 'voucher_fmt.dart';
import 'widgets/quote_plate.dart' show QuotePlateSkeleton;
import 'widgets/voucher_parts.dart';

/// CL-VCHR-04 Voucher for this request (sheet). Which voucher is attached to
/// the request being reviewed, and whether it still matches the quote. Covers
/// CA-VCH-08, CA-VCH-09, CA-VCH-10, CA-VCH-03.
///
/// Attached (one voucher, the two prices and the saving through
/// `GzPriceCompare`), choose (single choice, only vouchers of this venue), or
/// none (a drawing and Get voucher). When the date, hall, package or guests
/// changed the sheet runs the saving test again: still valid keeps the voucher
/// with the new totals, invalid says in three words that it no longer fits and
/// offers to restore the earlier choice. One voucher per request.
class ClVchr04Screen extends ConsumerStatefulWidget {
  const ClVchr04Screen({super.key});

  @override
  ConsumerState<ClVchr04Screen> createState() => _ClVchr04ScreenState();
}

class _ClVchr04ScreenState extends ConsumerState<ClVchr04Screen> {
  String? _chosen;
  bool _chooseMode = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = context.gzNav;
    final params = nav.params;
    final frame = params['scene'] is String && (params['scene'] as String).isNotEmpty ? params['scene'] as String : (params['state'] is String ? params['state'] as String : null);
    final draft = ref.watch(bookingDraftProvider);
    final targetId = draft.venueId ?? draft.providerId;
    final wallet = ref.watch(walletProvider).value ?? const <WalletItem>[];
    final candidates = [
      for (final i in wallet)
        if (i.voucher is Voucher && (i.voucher as Voucher).status == VoucherStatus.active && (i.voucher as Voucher).venueOrProviderId == targetId) i.voucher as Voucher,
    ];
    final currentArgs = QuoteArgs(venueId: draft.venueId, providerId: draft.providerId, hallId: draft.hallId, packageId: draft.packageId, date: draft.eventDate?.toString(), guests: draft.guests, audience: draft.audience);
    final heroOpen = targetId == null && frame == null;
    final heroQuoteAsync = heroOpen ? ref.watch(voucherQuoteProvider(const QuoteArgs(voucherId: kVoucherHeroId))) : null;
    final heroDetail = heroOpen ? ref.watch(voucherDetailProvider(kVoucherHeroId)).value : null;
    final heroVoucher = heroDetail?.voucher;
    final currentAsync = currentArgs.namesTarget && currentArgs.packageId != null ? ref.watch(voucherQuoteProvider(currentArgs)) : heroQuoteAsync;
    final VoucherQuote? current = currentAsync?.value;
    Voucher? picked;
    if (frame == 'no-voucher') {
      picked = null;
    } else {
      picked = candidates.where((v) => v.id == draft.voucherId).firstOrNull ?? (candidates.length == 1 ? candidates.firstOrNull : null);
      picked ??= candidates.where((v) => v.id == _chosen).firstOrNull;
      if (picked == null && heroVoucher != null) {
        final ready = readyVariantOf(heroDetail!);
        picked = ready.voucher is Voucher ? ready.voucher as Voucher : null;
      }
    }
    final boundArgs = picked == null ? null : QuoteArgs(voucherId: picked.id);
    final boundAsync = boundArgs == null ? null : ref.watch(voucherQuoteProvider(boundArgs));
    final VoucherQuote? bound = boundAsync?.value;
    final fit = _fit(bound, current);
    final changed = fit.changed;
    final gap = fit.gap;
    final none = picked == null || frame == 'no-voucher';
    final choose = !none && (frame == 'choose-voucher' || _chooseMode);
    final invalid = !none && !choose && gap != null;
    final valid = !none && !choose && changed && gap == null;
    if (currentAsync != null && current == null) {
      return Column(
        key: const ValueKey<String>('voucher.request'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VoucherSheetTop(title: l.clientVouchersForRequestTitle),
          const SizedBox(height: GzSpace.s5),
          GzAsyncView<VoucherQuote>(
            value: currentAsync,
            onRetry: () => ref.invalidate(voucherQuoteProvider(currentArgs)),
            loading: const QuotePlateSkeleton(),
            data: (_) => const SizedBox.shrink(),
          ),
        ],
      );
    }
    // The picked voucher's own quote failed or loads: show that, not a half card.
    if (!none && bound == null && boundAsync != null) {
      return Column(
        key: const ValueKey<String>('voucher.request'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VoucherSheetTop(title: l.clientVouchersForRequestTitle),
          const SizedBox(height: GzSpace.s5),
          GzAsyncView<VoucherQuote>(
            value: boundAsync,
            onRetry: () => ref.invalidate(voucherQuoteProvider(boundArgs ?? currentArgs)),
            loading: const QuotePlateSkeleton(),
            data: (_) => const SizedBox.shrink(),
          ),
        ],
      );
    }
    final offline = (currentAsync?.hasError ?? false) && isOffline(currentAsync?.error);
    return Column(
      key: const ValueKey<String>('voucher.request'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VoucherSheetTop(
          title: l.clientVouchersForRequestTitle,
          infoTitle: invalid ? l.clientVouchersInfoFit : l.clientVouchersTermsTitle,
          infoParagraphs:  [if (invalid && gap == 'target' && bound != null && current != null) l.clientVouchersInvalidTarget(voucherText(context, bound.name), voucherText(context, current.name)), if (none) l.clientVouchersNoneBody('', ''), l.clientVouchersOnePer],
        ),
        if (offline) ...[const SizedBox(height: GzSpace.s5), GzBanner(message: context.gzL10n.commonStateOffline, tone: GzBannerTone.offline, shape: GzBannerShape.flush)],
        if (valid) ...[const SizedBox(height: GzSpace.s5), GzBanner(message: l.clientVouchersStillFits, tone: GzBannerTone.info, shape: GzBannerShape.card)],
        if (invalid) ...[const SizedBox(height: GzSpace.s5), GzBanner(message: l.clientVouchersNoLongerFits, tone: GzBannerTone.danger, shape: GzBannerShape.card)],
        const SizedBox(height: GzSpace.s5),
        if (none) ...[
          GzEmptyState(illustration: GzIllustrationName.voucher, title: l.clientVouchersNoneTitle, fill: false, size: GzIllustrationSize.lg),
        ] else if (choose) ...[
          _ChoiceList(candidates: candidates, chosen: _chosen ?? picked.id, onChoose: (id) => setState(() => _chosen = id), current: current ?? bound),
        ] else ...[
          _Attached(picked: picked, bound: bound, current: current, invalid: invalid, gap: gap),
        ],
        GzSheetFooter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (none)
                GzButton(label: l.clientVouchersGetVoucher, variant: GzButtonVariant.primary, iconStart: GzIcons.ticket, onPressed: offline ? null : () => _getVoucher(currentArgs))
              else if (invalid)
                GzButton(
                  label: l.clientVouchersRestore,
                  variant: GzButtonVariant.primary,
                  iconStart: GzIcons.undo,
                  onPressed: () {
                    ref.read(bookingDraftProvider.notifier).patch((d) => d.copyWith(voucherId: picked!.id, hallId: bound!.hallId, packageId: bound.packageId, eventDate: bound.eventDate, guests: bound.guests));
                    nav.closeSheet();
                    nav.toast(GzToastSpec(message: l.clientVouchersRestoredToast, tone: GzToastTone.success));
                  },
                )
              else
                GzButton(
                  label: l.clientVouchersUseThis,
                  variant: GzButtonVariant.primary,
                  onPressed: offline
                      ? null
                      : () {
                          final id = _chosen ?? picked!.id;
                          ref.read(bookingDraftProvider.notifier).patch((d) => d.copyWith(voucherId: id));
                          nav.closeSheet();
                          nav.toast(GzToastSpec(message: l.clientVouchersAttachedToast, tone: GzToastTone.success));
                        },
                ),
              if (!none && candidates.length > 1) ...[
                const SizedBox(height: GzSpace.s2),
                choose
                    ? GzButton(label: l.clientVouchersGetAnother, variant: GzButtonVariant.tertiary, iconStart: GzIcons.plus, onPressed: () => _getVoucher(currentArgs))
                    : GzButton(label: l.clientVouchersChooseAnother, variant: GzButtonVariant.tertiary, iconStart: GzIcons.swap, onPressed: () => setState(() => _chooseMode = true)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Closes back to the Review that opened the sheet ('CL-BOOK-05'): every
  // confirm path above ends in closeSheet for that reason.
  void _getVoucher(QuoteArgs a) {
    final nav = context.gzNav;
    final audience = a.audience;
    nav.closeSheet();
    nav.openSheet(
      'CL-VCHR-01',
      options: GzSheetOptions(
        params: <String, Object?>{
          if (a.venueId != null) 'venueId': a.venueId,
          if (a.providerId != null) 'providerId': a.providerId,
          if (a.hallId != null) 'hallId': a.hallId,
          if (a.packageId != null) 'packageId': a.packageId,
          if (a.date != null) 'date': a.date,
          if (a.guests != null) 'guests': a.guests,
          if (audience != null) 'audience': audience.value,
        },
      ),
    );
  }
}

/// Whether the request quote still fits the picked voucher: the bound quote
/// against the current one (web `misfit`). Null quotes mean "cannot tell", so
/// the sheet keeps the attached state.
({bool changed, String? gap}) _fit(VoucherQuote? bound, VoucherQuote? current) {
  if (bound == null || current == null) return (changed: false, gap: null);
  final differs =
      bound.eventDate.toString() != current.eventDate.toString() ||
      bound.hallId != current.hallId ||
      bound.packageId != current.packageId ||
      bound.guests != current.guests ||
      bound.targetId != current.targetId;
  if (!differs) return (changed: false, gap: null);
  final gap = bound.targetId != current.targetId ? 'target' : (current.savingsFils <= current.feeFils ? 'saving' : null);
  return (changed: true, gap: gap);
}

class _Attached extends StatelessWidget {
  const _Attached({required this.picked, required this.bound, required this.current, required this.invalid, required this.gap});

  final Voucher? picked;
  final VoucherQuote? bound;
  final VoucherQuote? current;
  final bool invalid;
  final String? gap;

  @override
  Widget build(BuildContext context) {
    final p = picked;
    final b = bound;
    final q = current ?? bound;
    // Unreachable while the sheet guards the quotes above; never a half card.
    if (p == null || b == null || q == null) return const SizedBox.shrink();
    final pkg = b.packageName;
    final g = gap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GzVoucherCard(voucher: p, variant: GzVoucherCardVariant.compact, targetName: voucherText(context, b.name), packageName: pkg == null ? null : voucherText(context, pkg)),
        const SizedBox(height: GzSpace.s5),
        Padding(padding: const EdgeInsetsDirectional.only(top: GzSpace.s1), child: _Summary(quote: q)),
        if (invalid && g != null) ...[
          const SizedBox(height: GzSpace.s3),
          _FitNote(gap: g, bound: b, current: q),
        ],
      ],
    );
  }
}

class _FitNote extends StatelessWidget {
  const _FitNote({required this.gap, required this.bound, required this.current});

  final String gap;
  final VoucherQuote bound;
  final VoucherQuote current;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final boundName = voucherText(context, bound.name);
    final currentName = voucherText(context, current.name);
    return GzFactRow(
      key: const ValueKey<String>('voucher.invalid'),
      children: [
        if (gap == 'target')
          GzFactChip(icon: GzIcons.venue, label: l.clientVouchersInvalidTarget(boundName, currentName), value: currentName, tone: GzFactTone.accent)
        else
          GzFactChip(icon: GzIcons.trendDown, label: l.clientVouchersNoLongerFits, value: context.gzL10n.commonYouSave(context.gzFormat.money(current.savingsFils)), tone: GzFactTone.accent),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.quote});

  final VoucherQuote quote;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: context.l10n.clientVouchersQuoteLabel,
    child: GzPriceCompare(
      key: const ValueKey<String>('voucher.summary'),
      standard: quote.standardFils,
      voucher: quote.voucherFils,
      structure: PriceStructure.package,
      guests: quote.isProvider ? null : quote.guests,
      fee: quote.feeFils,
    ),
  );
}

class _ChoiceList extends StatelessWidget {
  const _ChoiceList({required this.candidates, required this.chosen, required this.onChoose, required this.current});

  final List<Voucher> candidates;
  final String chosen;
  final void Function(String id) onChoose;
  final VoucherQuote? current;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final q = current;
    return Semantics(
      container: true,
      label: l.clientVouchersChooseLabel,
      child: Column(
        key: const ValueKey<String>('voucher.choose'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < candidates.length; i++) ...[
            if (i > 0) const SizedBox(height: GzSpace.s2),
            GzPressable(
              key: ValueKey<String>('voucher.choice.${candidates[i].id}'),
              onPressed: () => onChoose(candidates[i].id),
              semanticLabel: candidates[i].code,
              borderRadius: GzRadius.mdAll,
              expand: true,
              minHeight: GzSize.rowMin,
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4, vertical: GzSpace.s3),
                decoration: BoxDecoration(
                  color: candidates[i].id == chosen ? context.gz.colors.surfaceTint : context.gz.colors.surfaceCanvas,
                  borderRadius: GzRadius.mdAll,
                  border: Border.all(color: candidates[i].id == chosen ? context.gz.colors.borderFocus : context.gz.colors.borderStrong, width: GzStroke.hair),
                ),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: GzSize.iconSm,
                        height: GzSize.iconSm,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: context.gz.colors.borderStrong, width: GzStroke.icon), color: candidates[i].id == chosen ? context.gz.colors.markKhayt : null),
                      ),
                    ),
                    const SizedBox(width: GzSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GzVoucherChip(code: candidates[i].code, tone: GzVoucherChipTone.ready),
                          if (q != null) ...[
                            const SizedBox(height: GzSpace.s2),
                            GzFactRow(
                              children: [
                                GzFactChip(icon: GzIcons.calendar, label: l.clientVouchersLabelEvent, value: f.dayMon(candidates[i].eventDate.toString())),
                                GzFactChip(icon: GzIcons.trendDown, label: context.gzL10n.commonYouSave(f.money(q.savingsFils)), value: f.money(q.savingsFils)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
