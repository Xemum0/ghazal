import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/pay_flow.dart';
import 'widgets/pay_parts.dart';

/// CL-PAYM-04 Payment not completed. One outcome layout for the voucher
/// payment (ADR 0013 D5, ADR 0034): the outcome first, the money status second,
/// the next step in the pinned bar. Covers CA-PAY-10, CA-PAY-01.
///
/// Scenes (params `scene`): declined (default), cancelled-by-user,
/// checkout-expired, late-payment-activated (the good outcome: the money
/// arrived after the checkout ended and the voucher is active), offline.
/// Support is one tap away on every one of them.
class ClPaym04Screen extends ConsumerWidget {
  const ClPaym04Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = context.gzNav;
    final args = PayArgs.fromParams(nav.params);
    final scene = switch (args.scene) {
      'cancelled-by-user' || 'checkout-expired' || 'late-payment-activated' || 'offline' => args.scene!,
      _ => 'declined',
    };
    final method = payMethodOf(args.method);
    final async = ref.watch(payQuoteProvider(args));
    final quote = async.value;
    final detailParams = quote == null
        ? null
        : (quote.isProvider
              ? <String, Object?>{'providerId': quote.targetId, 'vendorId': quote.targetId}
              : <String, Object?>{'venueId': quote.targetId});
    final view = _view(context, ref, scene: scene, args: args, method: method, quote: quote);
    final duo = view.secondary != null && quote != null;
    return GzScreen(
      fixed: true,
      top: GzTopBar(
        back: GzTopBarBack.close,
        backLabel: context.gzL10n.commonActionClose,
        onBack: detailParams == null
            ? null
            : () {
                final id = quote!.isProvider ? 'CL-SERV-03' : 'CL-VENU-01';
                if (nav.canGoBack) {
                  for (var i = 0; i < args.depth && nav.canGoBack; i++) {
                    nav.pop();
                  }
                } else {
                  nav.push(id, params: detailParams);
                }
              },
        title: l.clientPaymentTopTitle,
        rule: true,
        actions: [
          GzTopBarAction(
            icon: GzIcons.chat,
            label: l.clientPaymentSupport,
            onPressed: () => nav.push('CL-MSGS-02', params: const <String, Object?>{'support': true}),
          ),
        ],
      ),
      bottom: quote == null
          ? null
          : duo
          ? GzActionBar(
              action: GzActionBarAction(label: view.primary.$1, onPressed: view.primary.$2),
              secondary: GzActionBarAction(label: view.secondary!.$1, onPressed: view.secondary!.$2),
            )
          : GzActionBar(
              action: GzActionBarAction(label: view.primary.$1, onPressed: view.primary.$2),
            ),
      child: PayStage(
        child: Column(
          key: const ValueKey<String>('pay.notCompleted'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (quote == null)
              GzAsyncView<PayQuote>(
                value: async,
                onRetry: () => ref.invalidate(payQuoteProvider(args)),
                loading: const _NotCompletedSkeleton(),
                data: (_) => const SizedBox.shrink(),
              )
            else
              PayOutcome(
                illustration: view.art,
                title: view.title,
                danger: view.danger,
                meta: view.meta,
                infoTitle: context.gzL10n.commonLabelDetails,
                infoBody: view.detail,
              ),
          ],
        ),
      ),
    );
  }

  Map<String, Object?> _quoteParams(PayQuote q) => <String, Object?>{
    if (!q.isProvider) 'venueId': q.targetId else 'providerId': q.targetId,
    if (q.hallId != null) 'hallId': q.hallId,
    'packageId': q.packageId,
    'date': q.eventDate.toString(),
    if (q.guests != null) 'guests': q.guests,
  };

  String _methodName(BuildContext context, GatewayMethod method) {
    final l = context.l10n;
    return switch (method) {
      GatewayMethod.knet => l.clientPaymentMethodKnet,
      GatewayMethod.applePay => l.clientPaymentMethodApplePay,
      GatewayMethod.googlePay => l.clientPaymentMethodGooglePay,
      _ => l.clientPaymentMethodCardShort,
    };
  }

  ({
    GzIllustrationName art,
    bool danger,
    String title,
    String detail,
    Widget? meta,
    (String, VoidCallback) primary,
    (String, VoidCallback)? secondary,
  })
  _view(
    BuildContext context,
    WidgetRef ref, {
    required String scene,
    required PayArgs args,
    required GatewayMethod method,
    required PayQuote? quote,
  }) {
    final l = context.l10n;
    final cl = context.gzL10n;
    final nav = context.gzNav;
    final voucherId = args.voucherId ?? kPayHeroVoucherId;
    final depth = args.depth;
    void retry() => nav.replace(
      'CL-PAYM-02',
      params: <String, Object?>{'voucherId': voucherId, 'method': method.value, 'attempt': (args.attempt ?? 1) + 1, 'depth': depth},
    );
    void another() {
      if (depth >= 2 && nav.canGoBack) {
        nav.pop();
      } else if (quote != null) {
        nav.replace('CL-PAYM-01', params: <String, Object?>{..._quoteParams(quote), 'voucherId': voucherId, 'depth': 1});
      }
    }

    final none = GzFactRow(
      children: [GzFactChip(icon: GzIcons.shieldCheck, label: l.clientPaymentNotChargedLabel, value: l.clientPaymentNotCharged)],
    );
    switch (scene) {
      case 'cancelled-by-user':
        return (
          art: GzIllustrationName.card,
          danger: false,
          title: l.clientPaymentCancelTitle,
          detail: l.clientPaymentFailBodyCancelled,
          meta: none,
          primary: (cl.commonActionRetry, retry),
          secondary: (l.clientPaymentFailAnother, another),
        );
      case 'checkout-expired':
        return (
          art: GzIllustrationName.hourglass,
          danger: false,
          title: l.clientPaymentFailTitleExpired,
          detail: l.clientPaymentFailBodyExpired('', ''),
          meta: none,
          primary: (
            l.clientPaymentFailStartAgain,
            () {
              if (quote != null) nav.replace('CL-PAYM-01', params: _quoteParams(quote));
            },
          ),
          secondary: null,
        );
      case 'late-payment-activated':
        return (
          art: GzIllustrationName.successVoucher,
          danger: false,
          title: l.clientPaymentFailTitleLate,
          detail: l.clientPaymentFailBodyLate,
          meta: GzFactRow(
            children: [
              GzFactChip(
                icon: GzIcons.checkCircle,
                label: l.clientPaymentReceivedLabel,
                valueWidget: quote == null ? null : GzPrice(fils: quote.feeFils, mode: GzMoneyMode.exact, size: GzPriceSize.strong),
              ),
              GzFactChip(icon: payMethodIcon(method), label: l.clientPaymentLabelMethod, value: _methodName(context, method)),
            ],
          ),
          primary: (l.clientPaymentViewVoucher, () => nav.replace('CL-PAYM-05', params: <String, Object?>{'voucherId': voucherId, 'depth': depth})),
          secondary: null,
        );
      case 'offline':
        return (
          art: GzIllustrationName.wifiOff,
          danger: false,
          title: cl.commonStateOffline,
          detail: l.clientPaymentFailBodyOffline,
          meta: none,
          primary: (cl.commonActionRetry, () => nav.toast(GzToastSpec(message: cl.commonStateOffline, tone: GzToastTone.neutral))),
          secondary: null,
        );
      case 'declined':
      default:
        return (
          art: GzIllustrationName.card,
          danger: true,
          title: cl.commonStateTitlePayment,
          detail: l.clientPaymentFailBodyDeclined,
          meta: none,
          primary: (cl.commonActionRetry, retry),
          secondary: (l.clientPaymentFailAnother, another),
        );
    }
  }
}

class _NotCompletedSkeleton extends StatelessWidget {
  const _NotCompletedSkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: context.gzL10n.commonStateLoading,
    child: const ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 220)],
      ),
    ),
  );
}
