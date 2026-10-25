import 'dart:async';

import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/pay_flow.dart';
import 'widgets/pay_parts.dart';

/// CL-PAYM-01 Pay for your voucher. The one payment a client makes inside
/// Ghazal: KD 2.000 for a voucher bound to one venue or provider and its quote
/// (ADR 0033). Covers CA-PAY-01..05, CA-VCH-05, CA-VCH-14.
///
/// A drawing-free column: what the voucher is bound to (photo, name, hall or
/// package, date, guests as icon + value), the amount under a voucher drawing
/// with the saving and the checkout clock as facts, the methods as three tiles
/// in platform order (the glyph and wordmark are the label; what each one
/// means in practice is behind the info glyph), the voucher in three glyphs
/// (price, pay direct, voucher returns; the full explainer CL-VCHR-01 is
/// behind the info glyph). One primary action, pinned and full width. Offline,
/// loading and expired lock the tiles in place; a failed session start is the
/// centred Outcome with "Not charged". Tab bar hidden.
class ClPaym01Screen extends ConsumerStatefulWidget {
  const ClPaym01Screen({super.key});

  @override
  ConsumerState<ClPaym01Screen> createState() => _ClPaym01State();
}

class _ClPaym01State extends ConsumerState<ClPaym01Screen> {
  GatewayMethod? _method;
  bool _busy = false;
  bool _sessionError = false;
  Timer? _tick;
  DateTime? _openedAt;
  bool _expiredPushed = false;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _armTicker(DateTime now) {
    _openedAt ??= now;
    _tick ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Map<String, Object?> _quoteParams(PayQuote q) => <String, Object?>{
    if (!q.isProvider) 'venueId': q.targetId else 'providerId': q.targetId,
    if (q.hallId != null) 'hallId': q.hallId,
    'packageId': q.packageId,
    'date': q.eventDate.toString(),
    if (q.guests != null) 'guests': q.guests,
  };

  Future<void> _pay(PayQuote q, {required bool signedIn}) async {
    final nav = context.gzNav;
    if (_busy) return;
    if (!signedIn) {
      ref.requireSignIn(GateReason.voucher, resume: GateResume('CL-PAYM-01', _quoteParams(q)));
      return;
    }
    setState(() {
      _busy = true;
      _sessionError = false;
    });
    // The checkout input IS the quote (no draft involved: the draft cannot name a
    // session or listing the pay screen never asked for, and checkout needs neither).
    VoucherCheckoutInput input() => VoucherCheckoutInput(
      targetType: q.isProvider ? VoucherTargetType.provider : VoucherTargetType.venue,
      targetId: q.targetId,
      hallId: q.hallId,
      packageId: q.packageId,
      eventDate: q.eventDate,
      guests: q.guests,
    );
    VoucherCheckout? done;
    try {
      done = await ref.read(vouchersRepositoryProvider).startVoucherCheckout(body: input());
    } on ApiProblem catch (p) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (p.code == ApiProblemCode.voucherCheckoutExpired) {
        nav.replace('CL-PAYM-04', params: <String, Object?>{..._quoteParams(q), 'scene': 'checkout-expired', 'depth': 1});
        return;
      }
      nav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, p), tone: GzToastTone.danger));
      return;
    }
    ref.read(clientDataRevisionProvider.notifier).bump();
    ref.read(paymentProvider.notifier).prepare(voucherId: done.voucher.id, amount: done.amount, methods: done.methods);
    if (!mounted) return;
    final method = _method ?? GatewayMethod.knet;
    final begun = await ref.read(paymentProvider.notifier).begin(method);
    if (!mounted) return;
    setState(() => _busy = false);
    final problem = begun.when(success: (_) => null, failure: (p) => p, gated: () => null);
    if (problem != null) {
      setState(() => _sessionError = true);
      return;
    }
    nav.push('CL-PAYM-02', params: <String, Object?>{'voucherId': done.voucher.id, 'method': method.value, 'attempt': 1, 'depth': 1});
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = context.gzNav;
    final args = PayArgs.fromParams(nav.params);
    final async = ref.watch(payQuoteProvider(args));
    final quote = async.value;
    final signedIn = ref.watch(sessionProvider.select((s) => s.isSignedIn));
    if (quote == null) {
      return GzScreen(
        top: GzTopBar(back: GzTopBarBack.show, title: l.clientPaymentTopTitle),
        child: GzAsyncView<PayQuote>(
          value: async,
          onRetry: () => ref.invalidate(payQuoteProvider(args)),
          loading: const _PaySkeleton(),
          data: (_) => const SizedBox.shrink(),
        ),
      );
    }
    _armTicker(context.gzFormat.now());
    final cfg = ref.watch(payConfigProvider).value;
    final minutes = cfg?.voucherCheckoutMinutes ?? 30;
    final now = context.gzFormat.now();
    final end = (_openedAt ?? now).add(Duration(minutes: minutes));
    final leftMs = end.difference(now).inMilliseconds;
    final ended = args.scene == 'checkout-expired' || leftMs <= 0;
    if (ended && !_expiredPushed) {
      _expiredPushed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.gzNav.replace('CL-PAYM-04', params: <String, Object?>{..._quoteParams(quote), 'scene': 'checkout-expired', 'depth': 1});
      });
    }
    final pay = ref.watch(paymentProvider);
    final afterKnetFailure = pay.outcome == PaymentOutcome.failed && pay.method == GatewayMethod.knet;
    final methods = pay.methods.isNotEmpty ? pay.methods : payMethods(afterKnetFailure: afterKnetFailure);
    final method = _method ?? (methods.contains(GatewayMethod.knet) && !afterKnetFailure ? GatewayMethod.knet : methods.first);
    _method = method;
    final offline = async.hasError && isPayOffline(async.error);
    // The wallet match counts only past a real quote (web: a bare hero open
    // shows no banner; the has-voucher frame does).
    final named = args.voucherId != null || args.venueId != null || args.providerId != null;
    final wallet = named ? ref.watch(_existingVoucherProvider((targetId: quote.targetId, packageId: quote.packageId, date: quote.eventDate.toString()))).value ?? false : false;
    final existing = args.scene == 'has-voucher' || wallet;
    final honest = switch (method) {
      GatewayMethod.knet => l.clientPaymentHonestKnet,
      GatewayMethod.card => l.clientPaymentHonestCard,
      _ => l.clientPaymentHonestWallet,
    };
    return GzScreen(
      top: GzTopBar(back: GzTopBarBack.show, title: l.clientPaymentTopTitle),
      bottom: _sessionError
          ? null
          : GzActionBar(
              action: existing
                  ? GzActionBarAction(label: l.clientPaymentViewVoucher, onPressed: () => nav.push('CL-VCHR-03', params: <String, Object?>{'voucherId': args.voucherId ?? kPayHeroVoucherId}))
                  : GzActionBarAction(
                      label: signedIn ? l.clientPaymentCtaPay : l.clientVouchersCtaSignIn,
                      loading: _busy,
                      disabled: offline || ended,
                      onPressed: () => _pay(quote, signedIn: signedIn),
                    ),
            ),
      child: _sessionError
          ? Padding(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s6),
              child: PayOutcome(
                illustration: GzIllustrationName.card,
                title: l.clientPaymentSessionErrorTitle,
                danger: true,
                meta: GzFactRow(children: [GzFactChip(icon: GzIcons.shieldCheck, label: l.clientPaymentNotChargedLabel, value: l.clientPaymentNotCharged)]),
                infoTitle: context.gzL10n.commonLabelDetails,
                infoBody: l.clientPaymentSessionError,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8),
                child: Column(
                  key: const ValueKey<String>('pay.body'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (offline) ...[GzBanner(message: context.gzL10n.commonStateOffline, tone: GzBannerTone.offline, shape: GzBannerShape.flush), const SizedBox(height: GzSpace.s3)],
                    if (ended) ...[GzBanner(message: l.clientPaymentExpiredBanner, tone: GzBannerTone.warning, shape: GzBannerShape.card), const SizedBox(height: GzSpace.s3)],
                    if (existing) ...[GzBanner(message: l.clientPaymentHasVoucherBanner, tone: GzBannerTone.info, shape: GzBannerShape.card), const SizedBox(height: GzSpace.s3)],
                    PayVenuePlate(quote: quote),
                    const SizedBox(height: GzSpace.s8),
                    _Amount(quote: quote, leftMs: leftMs, ended: ended),
                    const SizedBox(height: GzSpace.s8),
                    _Methods(
                      methods: methods,
                      method: method,
                      honest: honest,
                      suggestedFirst: afterKnetFailure,
                      disabled: offline || ended || _busy,
                      onSelect: (m) => setState(() => _method = m),
                    ),
                    const SizedBox(height: GzSpace.s8),
                    _Terms(quote: quote),
                  ],
                ),
              ),
            ),
    );
  }
}

final _existingVoucherProvider = FutureProvider.autoDispose.family<bool, ({String targetId, String packageId, String date})>((ref, key) async {
  ref.watch(clientDataRevisionProvider);
  if (!ref.watch(sessionProvider.select((s) => s.isSignedIn))) return false;
  final page = await ref.watch(vouchersRepositoryProvider).listVouchers(limit: 50);
  return page.items.any((i) {
    final v = i.voucher;
    return v is Voucher && (v.status == VoucherStatus.active || v.status == VoucherStatus.bound) && v.venueOrProviderId == key.targetId && v.packageId == key.packageId && v.eventDate.toString() == key.date;
  });
});

class _Amount extends StatelessWidget {
  const _Amount({required this.quote, required this.leftMs, required this.ended});

  final PayQuote quote;
  final int leftMs;
  final bool ended;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final now = f.now();
    return Semantics(
      container: true,
      label: l.clientPaymentAmountLabel,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GzPrice(fils: quote.feeFils, mode: GzMoneyMode.exact, size: GzPriceSize.hero),
                const SizedBox(height: GzSpace.s4),
                GzFactRow(
                  children: [
                    if (quote.savingsFils > 0) GzFactChip(icon: GzIcons.offer, label: l.clientPaymentLabelSaving, value: l.clientPaymentSave(f.money(quote.savingsFils))),
                    if (!ended && leftMs <= 60000) PayTimer(ms: leftMs) else GzFactChip(icon: GzIcons.timer, label: l.clientPaymentLabelOpenUntil, value: f.time(now.add(Duration(milliseconds: leftMs > 0 ? leftMs : 0)).toIso8601String())),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: GzSpace.s2),
          ExcludeSemantics(child: GzIllustration(GzIllustrationName.voucher, size: GzIllustrationSize.lg)),
        ],
      ),
    );
  }
}

class _Methods extends StatelessWidget {
  const _Methods({required this.methods, required this.method, required this.honest, required this.suggestedFirst, required this.disabled, required this.onSelect});

  final List<GatewayMethod> methods;
  final GatewayMethod method;
  final String honest;
  final bool suggestedFirst;
  final bool disabled;
  final void Function(GatewayMethod m) onSelect;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      key: const ValueKey<String>('pay.methods'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: GzSectionHeader(title: l.clientPaymentMethodsTitle)),
            GzInfoButton(title: l.clientPaymentSecureTitle, paragraphs: [honest], bleed: true),
          ],
        ),
        const SizedBox(height: GzSpace.s4),
        Semantics(
          container: true,
          label: l.clientPaymentMethodsLabel,
          explicitChildNodes: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < methods.length; i++) ...[
                if (i > 0) const SizedBox(width: GzSpace.s3),
                Expanded(child: PayMethodTile(method: methods[i], selected: methods[i] == method, suggested: suggestedFirst && i == 0, disabled: disabled, onSelect: () => onSelect(methods[i]))),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The model in three glyphs on a ruled line (web `TermsStrip`): the voucher
/// price, paying the venue direct, the voucher coming back; the whole strip
/// opens the explainer, the info glyph names it.
class _Terms extends StatelessWidget {
  const _Terms({required this.quote});

  final PayQuote quote;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final nav = context.gzNav;
    void how() => nav.openSheet(
      'CL-VCHR-01',
      options: GzSheetOptions(
        params: <String, Object?>{
          if (!quote.isProvider) 'venueId': quote.targetId else 'providerId': quote.targetId,
          if (quote.hallId != null) 'hallId': quote.hallId,
          'packageId': quote.packageId,
          'date': quote.eventDate.toString(),
          if (quote.guests != null) 'guests': quote.guests,
        },
      ),
    );
    return GzPressable(
      key: const ValueKey<String>('pay.terms'),
      onPressed: how,
      semanticLabel: l.clientPaymentHowLink,
      borderRadius: GzRadius.mdAll,
      expand: true,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair), bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (icon, label) in [(GzIcons.ticket, l.clientPaymentTermPrice), (quote.isProvider ? GzIcons.package : GzIcons.hall, l.clientPaymentTermDirect), (GzIcons.undo, l.clientPaymentTermReturns)])
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: GzSize.avatarSm,
                      height: GzSize.avatarSm,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.surfaceTint, shape: BoxShape.circle),
                      child: GzIcon(icon, size: GzIconSize.sm, color: c.iconPrimary),
                    ),
                    const SizedBox(height: GzSpace.s2),
                    GzText(label, role: GzTextRole.caption, color: c.textPrimary, textAlign: TextAlign.center, softWrap: false),
                  ],
                ),
              ),
            GzInfoButton(title: l.clientPaymentSecureTitle, paragraphs: [l.clientPaymentHowLink], bleed: true),
          ],
        ),
      ),
    );
  }
}

class _PaySkeleton extends StatelessWidget {
  const _PaySkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: context.gzL10n.commonStateLoading,
    child: const ExcludeSemantics(
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 148), SizedBox(height: GzSpace.s5), GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 120), SizedBox(height: GzSpace.s3), GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 88)],
        ),
      ),
    ),
  );
}
