import 'dart:async';

import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/pay_flow.dart';
import 'widgets/pay_parts.dart';

/// CL-PAYM-02 Secure payment. Ghazal's chrome around the gateway-hosted page
/// (ADR 0027 D2). Covers CA-PAY-01..05.
///
/// Every Ghazal-side phase is one Outcome (the redirect interstitial with the
/// OS activity indicator, the return, the lost connection); the hosted page is
/// a neutral placeholder frame (KNET bank page or card page, a native sheet
/// for Apple Pay and Google Pay) because the real page is third-party. The
/// return URL is never trusted: every way out goes to CL-PAYM-03 except a
/// cancel, which returns to CL-PAYM-01 with "Cancelled, not charged."
class ClPaym02Screen extends ConsumerStatefulWidget {
  const ClPaym02Screen({super.key});

  @override
  ConsumerState<ClPaym02Screen> createState() => _ClPaym02State();
}

enum _Phase { redirecting, hosted, returned, lost, cancelled }

class _ClPaym02State extends ConsumerState<ClPaym02Screen> {
  _Phase _phase = _Phase.redirecting;
  Timer? _timer;
  bool _movedOn = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _after(Duration d, VoidCallback fn) {
    _timer?.cancel();
    _timer = Timer(d, () {
      if (mounted) fn();
    });
  }

  void _go03({required bool lost}) {
    if (_movedOn) return;
    _movedOn = true;
    final nav = context.gzNav;
    final p = nav.params;
    nav.replace(
      'CL-PAYM-03',
      params: <String, Object?>{'voucherId': p['voucherId'] ?? '', 'method': p['method'] ?? 'knet', 'attempt': p['attempt'] ?? 1, 'depth': p['depth'] ?? 2, if (lost) 'lost': true},
    );
  }

  Future<void> _askLeave() async {
    if (_phase == _Phase.cancelled || _phase == _Phase.returned || _phase == _Phase.lost) return;
    final l = context.l10n;
    final r = await context.gzNav.openDialog(GzDialogSpec(title: l.clientPaymentLeaveTitle, body: l.clientPaymentLeaveBody, icon: GzIcons.lock, confirmLabel: l.clientPaymentLeaveStay, cancelLabel: l.clientPaymentLeaveConfirm));
    if (!mounted) return;
    if (r == GzDialogResult.cancel) {
      setState(() => _phase = _Phase.cancelled);
      _after(const Duration(milliseconds: 1400), _backToPay);
    }
  }

  void _backToPay() {
    final nav = context.gzNav;
    final pay = ref.read(paymentProvider);
    // A dead gateway ends on the outcome layout (CL-PAYM-04); a live one goes
    // back to the pay screen (CL-PAYM-01), pushing it when opened directly.
    if (pay.outcome == PaymentOutcome.failed) {
      nav.replace('CL-PAYM-04', params: <String, Object?>{'voucherId': pay.voucherId ?? '', 'method': pay.method?.value ?? 'knet', 'depth': 1, 'scene': 'declined'});
      return;
    }
    if (pay.outcome == PaymentOutcome.success) {
      nav.replace('CL-PAYM-05', params: <String, Object?>{'voucherId': pay.voucherId ?? '', 'depth': 1});
      return;
    }
    nav.toast(GzToastSpec(message: context.l10n.clientPaymentCancelledToast, tone: GzToastTone.neutral));
    if (nav.canGoBack) {
      nav.pop();
    } else {
      final p = nav.params;
      nav.push('CL-PAYM-01', params: <String, Object?>{if (p['voucherId'] != null) 'voucherId': p['voucherId']!});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = context.gzNav;
    final args = PayArgs.fromParams(nav.params);
    final method = payMethodOf(args.method);
    final wallet = method == GatewayMethod.applePay || method == GatewayMethod.googlePay;
    final forced = args.scene;
    final phase = switch (forced) {
      'bank-page' => _Phase.hosted,
      'wallet-sheet' => _Phase.hosted,
      'cancelled-by-user' => _Phase.cancelled,
      'connection-lost' => _Phase.lost,
      'returned' => _Phase.returned,
      'redirecting' => _Phase.redirecting,
      _ => _phase,
    };
    if (forced == 'leave-prompt' && !_movedOn) {
      _movedOn = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _askLeave());
    }
    if (forced == null) {
      if (_phase == _Phase.redirecting) _after(const Duration(milliseconds: 900), () => setState(() => _phase = _Phase.hosted));
      if (_phase == _Phase.returned) _after(const Duration(milliseconds: 900), () => _go03(lost: false));
      if (_phase == _Phase.lost) _after(const Duration(milliseconds: 1800), () => _go03(lost: true));
      if (_phase == _Phase.cancelled) _after(const Duration(milliseconds: 1400), _backToPay);
    }
    final async = ref.watch(payQuoteProvider(args));
    final quote = async.value;
    final secured = phase == _Phase.redirecting || phase == _Phase.hosted;
    return GzScreen(
      fixed: true,
      top: GzTopBar(
        back: GzTopBarBack.close,
        backLabel: l.clientPaymentGatewayBack,
        onBack: _askLeave,
        rule: true,
        titleWidget: Padding(
          // The slot centres a widget 2 dp lower than the web's inline-flex title.
          padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [GzIcon(GzIcons.lock, size: GzIconSize.xs, color: context.gz.colors.iconSecondary), const SizedBox(width: GzSpace.s2), Flexible(child: GzText(l.clientPaymentGatewayTitle, role: GzTextRole.title, color: context.gz.colors.textStrong))],
          ),
        ),
        actions: secured ? [GzTopBarAction(icon: GzIcons.info, label: context.gzL10n.commonA11yInfo, onPressed: () => showGzInfoSheet(context, title: l.clientPaymentSecureTitle, paragraphs: [l.clientPaymentRedirectBody, l.clientPaymentRedirectPrivacy]))] : const [],
      ),
      child: phase == _Phase.hosted
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s6, bottom: GzSpace.s8),
                child: Column(
                  key: const ValueKey<String>('pay.gateway'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (wallet)
                      _WalletSheet(method: method, feeFils: quote?.feeFils ?? 2000, onConfirm: () => setState(() => _phase = _Phase.returned))
                    else
                      _BankPage(method: method, feeFils: quote?.feeFils ?? 2000, onCancel: () => setState(() => _phase = _Phase.cancelled), onSubmit: () => setState(() => _phase = _Phase.returned)),
                  ],
                ),
              ),
            )
          : PayStage(
              child: Column(
                key: const ValueKey<String>('pay.gateway'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  switch (phase) {
                    _Phase.redirecting => PayOutcome(illustration: GzIllustrationName.card, title: l.clientPaymentRedirectTitle, busy: true, meta: quote == null ? null : PayFacts(quote: quote, method: method)),
                    _Phase.returned => PayOutcome(illustration: GzIllustrationName.hourglass, title: l.clientPaymentReturnedTitle, busy: true),
                    _Phase.lost => PayOutcome(
                      illustration: GzIllustrationName.wifiOff,
                      title: l.clientPaymentLostTitle,
                      busy: true,
                      infoTitle: context.gzL10n.commonLabelDetails,
                      infoBody: l.clientPaymentLostBody,
                    ),
                    _Phase.cancelled => PayOutcome(
                      illustration: GzIllustrationName.card,
                      title: l.clientPaymentCancelTitle,
                      meta: GzFactRow(children: [GzFactChip(icon: GzIcons.shieldCheck, label: l.clientPaymentNotChargedLabel, value: l.clientPaymentNotCharged)]),
                    ),
                    _Phase.hosted => const SizedBox.shrink(),
                  },
                ],
              ),
            ),
    );
  }
}

/// The neutral placeholder of the hosted bank or card page (third-party, not
/// designed): the brand, the item and the exact amount, inert fields, Cancel
/// and Submit. Submit stands for the bank's approval in this frame.
class _BankPage extends StatelessWidget {
  const _BankPage({required this.method, required this.feeFils, required this.onCancel, required this.onSubmit});

  final GatewayMethod method;
  final int feeFils;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final knet = method == GatewayMethod.knet;
    final fields = knet
        ? [l.clientPaymentBankBank, l.clientPaymentBankCard, l.clientPaymentBankExpiry, l.clientPaymentBankPin]
        : [l.clientPaymentBankCard, l.clientPaymentCardHolder, l.clientPaymentBankExpiry, l.clientPaymentCardCvv];
    return Column(
      key: const ValueKey<String>('pay.hosted'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GzText(knet ? l.clientPaymentBankNote : l.clientPaymentCardPageNote, role: GzTextRole.caption, color: c.textSecondary),
        const SizedBox(height: GzSpace.s3),
        Container(
          padding: GzSpace.panel,
          decoration: BoxDecoration(color: c.surfaceCanvas, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3, vertical: GzSpace.s2),
                    decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.smAll),
                    child: GzText(knet ? 'KNET' : 'VISA · MC', role: GzTextRole.title, color: c.textStrong, figures: true),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(child: GzText(l.clientPaymentBankItemName, role: GzTextRole.title, color: c.textStrong)),
                ],
              ),
              const SizedBox(height: GzSpace.s3),
              Align(alignment: AlignmentDirectional.centerStart, child: GzPrice(fils: feeFils, mode: GzMoneyMode.exact, size: GzPriceSize.total)),
              const SizedBox(height: GzSpace.s3),
              for (final label in fields) ...[
                const SizedBox(height: GzSpace.s2),
                GzText(label, role: GzTextRole.caption, color: c.textSecondary),
                const SizedBox(height: GzSpace.s1),
                Container(height: GzSize.controlSm, decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.smAll)),
              ],
              const SizedBox(height: GzSpace.s4),
              Row(
                children: [
                  Expanded(child: GzButton(label: context.gzL10n.commonActionCancel, variant: GzButtonVariant.secondary, onPressed: onCancel)),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(child: GzButton(label: l.clientPaymentBankSubmit, variant: GzButtonVariant.primary, onPressed: onSubmit)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The native wallet sheet over the dimmed redirect (Apple Pay, Google Pay).
class _WalletSheet extends StatelessWidget {
  const _WalletSheet({required this.method, required this.feeFils, required this.onConfirm});

  final GatewayMethod method;
  final int feeFils;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final name = method == GatewayMethod.applePay ? l.clientPaymentMethodApplePay : l.clientPaymentMethodGooglePay;
    return Semantics(
      container: true,
      label: name,
      child: Column(
        key: const ValueKey<String>('pay.hosted'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: ExcludeSemantics(child: GzIllustration(GzIllustrationName.card, size: GzIllustrationSize.lg))),
          const SizedBox(height: GzSpace.s4),
          Container(
            padding: GzSpace.panel,
            decoration: BoxDecoration(color: c.surfaceCanvas, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    GzIcon(payMethodIcon(method), size: GzIconSize.md, color: c.iconPrimary),
                    const SizedBox(width: GzSpace.s2),
                    GzText('Pay', role: GzTextRole.title, color: c.textStrong, figures: true),
                    const Spacer(),
                    GzText(l.clientPaymentBankItemName, role: GzTextRole.title, color: c.textStrong),
                  ],
                ),
                const SizedBox(height: GzSpace.s3),
                Center(child: GzPrice(fils: feeFils, mode: GzMoneyMode.exact, size: GzPriceSize.total)),
                const SizedBox(height: GzSpace.s4),
                GzButton(label: context.gzL10n.commonActionConfirm, variant: GzButtonVariant.primary, onPressed: onConfirm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
