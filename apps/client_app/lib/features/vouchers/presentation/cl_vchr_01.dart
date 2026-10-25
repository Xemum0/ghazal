import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/voucher_nav.dart';
import '../application/voucher_providers.dart';
import '../application/voucher_quote.dart';
import 'voucher_fmt.dart';
import 'widgets/quote_plate.dart';
import 'widgets/voucher_parts.dart';
import 'widgets/voucher_terms.dart';

/// CL-VCHR-01 How the voucher works (sheet). The explainer and the binding
/// confirmation shown before the first purchase and on every Get voucher.
/// Covers CA-VCH-01..04, CA-VCH-10, CA-VCH-12.
///
/// The plate is the binding (venue, hall, package, date, the two prices and
/// the saving); three knots say the model (pay KD 2 now, request at the
/// voucher price, pay the venue directly); one line with a returns glyph and
/// its info carries the reuse and credit terms. One primary: Pay KD 2. A guest
/// sees the voucher price behind a lock and Sign in as the primary, returning
/// to this quote. A voucher is never offered when the saving does not beat its
/// price: a drawing, three words and Contact.
class ClVchr01Screen extends ConsumerWidget {
  const ClVchr01Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = context.gzNav;
    final args = QuoteArgs.fromParams(nav.params);
    final async = ref.watch(voucherQuoteProvider(args));
    final quote = async.value;
    final signedIn = ref.watch(sessionProvider.select((s) => s.isSignedIn));
    if (quote == null) {
      return Column(
        key: const ValueKey<String>('voucher.explainer'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VoucherSheetTop(title: l.clientVouchersExplainerTitle),
          const SizedBox(height: GzSpace.s3),
          GzAsyncView<VoucherQuote>(
            value: async,
            onRetry: () => ref.invalidate(voucherQuoteProvider(args)),
            loading: const QuotePlateSkeleton(),
            data: (_) => const SizedBox.shrink(),
          ),
        ],
      );
    }
    final offline = async.hasError && isOffline(async.error);
    final params = nav.params;
    final frame = params['scene'] is String && (params['scene'] as String).isNotEmpty ? params['scene'] as String : (params['state'] is String ? params['state'] as String : null);
    final changed = frame == 'quote-changed';
    final tooSmall = frame == 'saving-too-small' || !quote.offered;
    if (tooSmall) return _TooSmall(quote: quote, offline: offline);
    final wallet = ref.watch(walletProvider).value ?? const <WalletItem>[];
    final config = ref.watch(voucherConfigProvider).value;
    final owned = frame == 'already-owned' ? _heroOwned(wallet) : _matchingReady(wallet, quote, signedIn);
    final fee = context.gzFormat.moneyBrowse(quote.feeFils);
    return Column(
      key: const ValueKey<String>('voucher.explainer'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VoucherSheetTop(title: l.clientVouchersExplainerTitle),
        if (offline) ...[const SizedBox(height: GzSpace.s5), GzBanner(message: context.gzL10n.commonStateOffline, tone: GzBannerTone.offline, shape: GzBannerShape.flush)],
        if (changed) ...[const SizedBox(height: GzSpace.s5), GzBanner(message: l.clientVouchersPriceChanged, tone: GzBannerTone.info, shape: GzBannerShape.card)],
        const SizedBox(height: GzSpace.s5),
        if (owned != null) ...[
          GzSuccessState(illustration: GzIllustrationName.successVoucher, title: l.clientVouchersOwned, fill: false, size: GzIllustrationSize.lg),
          const SizedBox(height: GzSpace.s3),
          GzVoucherCard(
            voucher: owned,
            variant: GzVoucherCardVariant.compact,
            targetName: voucherText(context, quote.name),
            packageName: quote.packageName == null ? null : voucherText(context, quote.packageName),
            onOpen: () {
              nav.closeSheet();
              nav.push('CL-VCHR-03', params: <String, Object?>{'voucherId': owned.id});
            },
          ),
        ] else ...[
          QuotePlate(quote: quote),
          const SizedBox(height: GzSpace.s5),
          Padding(padding: const EdgeInsets.symmetric(vertical: GzSpace.s2), child: VoucherSteps(feeText: fee, provider: quote.isProvider)),
          const SizedBox(height: GzSpace.s5),
          if (config != null) _BackLine(quote: quote, config: config, replyHours: config.defaultReplyHours),
        ],
        // The sheet's footer slot carries the air above it (the web gap to the footer is 24 in all).
        GzSheetFooter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              GzButton(
                key: const ValueKey<String>('voucher.explainer.pay'),
                fullWidth: true,
                label: owned != null ? l.clientVouchersSendRequest : signedIn ? l.clientVouchersPayFee(fee) : l.clientVouchersCtaSignIn,
                variant: GzButtonVariant.primary,
                iconStart: signedIn ? null : GzIcons.lock,
                onPressed: offline
                    ? null
                    : () {
                        if (owned != null) {
                          nav.closeSheet();
                          openRequestFor(nav, owned);
                        } else if (!signedIn) {
                          // A guest meets the account sheet ('CL-AUTH-01', opened by the gate) and returns to this quote.
                          ref.requireSignIn(GateReason.voucher, resume: GateResume('CL-VCHR-01', quote.toParams()));
                        } else {
                          _toPayment(context, ref, nav, quote);
                        }
                      },
              ),
              if (owned == null) ...[
                const SizedBox(height: GzSpace.s3),
                GzButton(label: l.clientVouchersContact, variant: GzButtonVariant.tertiary, iconStart: GzIcons.chat, onPressed: () => _contact(nav, quote)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _toPayment(BuildContext context, WidgetRef ref, GzNavigator nav, VoucherQuote quote) async {
    final cl = context.gzL10n;
    // The checkout input IS the quote (no draft involved: see 'CL-PAYM-01').
    VoucherCheckoutInput input() => VoucherCheckoutInput(
      targetType: quote.isProvider ? VoucherTargetType.provider : VoucherTargetType.venue,
      targetId: quote.targetId,
      hallId: quote.hallId,
      packageId: quote.packageId,
      eventDate: quote.eventDate,
      guests: quote.guests,
    );
    String? id;
    try {
      final done = await ref.read(vouchersRepositoryProvider).startVoucherCheckout(body: input());
      ref.read(clientDataRevisionProvider.notifier).bump();
      ref.read(paymentProvider.notifier).prepare(voucherId: done.voucher.id, amount: done.amount, methods: done.methods);
      id = done.voucher.id;
    } on ApiProblem catch (p) {
      if (p.code != ApiProblemCode.voucherCheckoutExpired) {
        nav.toast(GzToastSpec(message: gzProblemMessage(cl, p), tone: GzToastTone.danger));
      }
    }
    nav.closeSheet();
    if (id != null) {
      nav.push('CL-PAYM-01', params: <String, Object?>{'voucherId': id});
    } else {
      nav.push('CL-PAYM-01', params: quote.toParams());
    }
  }

  void _contact(GzNavigator nav, VoucherQuote quote) {
    nav.closeSheet();
    nav.push('CL-MSGS-02', params: quote.isProvider ? <String, Object?>{'providerId': quote.targetId} : <String, Object?>{'venueId': quote.targetId});
  }

  Voucher? _matchingReady(List<WalletItem> wallet, VoucherQuote quote, bool signedIn) {
    if (!signedIn) return null;
    for (final i in wallet) {
      final v = i.voucher;
      if (v is Voucher && v.status == VoucherStatus.active && v.releaseReason == null && v.reuseUntil == null && v.venueOrProviderId == quote.targetId && v.packageId == quote.packageId && v.eventDate.toString() == quote.eventDate.toString()) {
        return v;
      }
    }
    return null;
  }

  Voucher? _heroOwned(List<WalletItem> wallet) {
    for (final i in wallet) {
      final v = i.voucher;
      if (v is Voucher && v.status == VoucherStatus.active) return v;
    }
    return null;
  }
}

class _BackLine extends StatelessWidget {
  const _BackLine({required this.quote, required this.config, required this.replyHours});

  final VoucherQuote quote;
  final PlatformConfig config;
  final int replyHours;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    return Container(
      key: const ValueKey<String>('voucher.back'),
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: GzSize.touchMin),
        child: Row(
          children: [
            GzIcon(GzIcons.undo, size: GzIconSize.sm, color: c.iconSecondary),
            const SizedBox(width: GzSpace.s2),
            Expanded(child: GzText(l.clientVouchersBackLine, role: GzTextRole.bodyS, color: c.textSecondary, figures: true)),
            const SizedBox(width: GzSpace.s2),
            GzInfoButton(
              title: l.clientVouchersTermsTitle,
              bleed: true,
              children: [VoucherTerms(name: voucherText(context, quote.name), replyHours: replyHours, config: config)],
            ),
          ],
        ),
      ),
    );
  }
}

class _TooSmall extends StatelessWidget {
  const _TooSmall({required this.quote, required this.offline});

  final VoucherQuote quote;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = context.gzNav;
    return Column(
      key: const ValueKey<String>('voucher.explainer'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VoucherSheetTop(title: l.clientVouchersExplainerTitle),
        const SizedBox(height: GzSpace.s3),
        QuotePlate(quote: quote, noPrices: true),
        const SizedBox(height: GzSpace.s3),
        GzEmptyState(illustration: GzIllustrationName.hall, title: l.clientVouchersTooSmallTitle, detail: l.clientVouchersTooSmallBody, detailTitle: l.clientVouchersTermsTitle, fill: false, size: GzIllustrationSize.lg),
        const SizedBox(height: GzSpace.s3),
        GzSheetFooter(
          child: GzButton(
            label: l.clientVouchersContact,
            variant: GzButtonVariant.primary,
            iconStart: GzIcons.chat,
            onPressed: offline
                ? null
                : () {
                    nav.closeSheet();
                    nav.push('CL-MSGS-02', params: quote.isProvider ? <String, Object?>{'providerId': quote.targetId} : <String, Object?>{'venueId': quote.targetId});
                  },
          ),
        ),
      ],
    );
  }
}
