import 'dart:async';

import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/pay_flow.dart';
import 'widgets/pay_parts.dart';

/// CL-PAYM-03 Confirming with your bank. The pending-bank-confirmation state
/// (ADR 0027 D2, ADR 0033): the server is the truth, the app polls and then
/// reassures. Covers CA-PAY-10, CA-NOTI-07.
///
/// A 2 px thread fills while the status is polled; after a while the screen
/// says it is safe to leave. Success moves to 'CL-PAYM-05', failure to
/// CL-PAYM-04. Leaving never cancels the payment. No Back: a second payment
/// must not be one tap away.
class ClPaym03Screen extends ConsumerStatefulWidget {
  const ClPaym03Screen({super.key});

  @override
  ConsumerState<ClPaym03Screen> createState() => _ClPaym03State();
}

class _ClPaym03State extends ConsumerState<ClPaym03Screen> {
  String? _phase;
  Timer? _timer;
  double _progress = 0.3;
  bool _settled = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _runVerify() {
    if (_settled) return;
    _settled = true;
    unawaited(_verify());
  }

  Future<void> _verify() async {
    final outcome = await ref.read(paymentProvider.notifier).verify();
    if (!mounted) return;
    if (outcome == PaymentOutcome.success) {
      _to05();
    } else if (outcome == PaymentOutcome.failed) {
      _to04('declined');
    } else if (outcome == PaymentOutcome.cancelled) {
      _to04('cancelled-by-user');
    } else {
      setState(() {
        _phase = 'long-wait';
        _progress = 0.92;
      });
    }
  }

  void _to05() {
    final p = context.gzNav.params;
    context.gzNav.replace('CL-PAYM-05', params: <String, Object?>{'voucherId': p['voucherId'] ?? '', 'depth': p['depth'] ?? 2});
  }

  void _to04(String scene) {
    final p = context.gzNav.params;
    context.gzNav.replace(
      'CL-PAYM-04',
      params: <String, Object?>{
        'voucherId': p['voucherId'] ?? '',
        'method': p['method'] ?? 'knet',
        'attempt': p['attempt'] ?? 1,
        'depth': p['depth'] ?? 2,
        'scene': scene,
      },
    );
  }

  void _leave() {
    // Leaving never cancels the payment; the request it belongs to lives under
    // My bookings ('CL-BKNG-02', reached from the wallet and the booking list).
    // The prototype has no direct tap from this screen there either.
    final nav = context.gzNav;
    nav.toast(GzToastSpec(message: context.l10n.clientPaymentConfirmNotify, tone: GzToastTone.neutral));
    final depth = (nav.params['depth'] as num?)?.toInt() ?? 2;
    for (var i = 0; i < depth && nav.canGoBack; i++) {
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = context.gzNav;
    final p = nav.params;
    final args = PayArgs.fromParams(p);
    final forced = args.scene;
    final method = payMethodOf(args.method);
    final inFlight = ref.watch(paymentProvider.select((s) => s.paymentId != null && !s.outcome.isFinal));
    final phase = forced ?? _phase ?? 'polling';
    if (forced == null && _phase == null) {
      if (inFlight) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _runVerify());
      } else {
        _phase = 'polling';
        _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() => _progress = (_progress + 0.15).clamp(0.0, 0.9));
        });
      }
    }
    final async = ref.watch(payQuoteProvider(args));
    final quote = async.value;
    final offline = phase == 'offline';
    final done = phase == 'success';
    final failed = phase == 'failed';
    final longWait = phase == 'long-wait';
    if (done && forced != null && _progress < 1) _progress = 1;
    if (failed && forced != null && _progress < 0.64) _progress = 0.64;
    final title = done
        ? l.clientPaymentConfirmSuccessTitle
        : failed
        ? context.gzL10n.commonStateTitlePayment
        : offline
        ? context.gzL10n.commonStateOffline
        : longWait
        ? l.clientPaymentConfirmLongTitle
        : l.clientPaymentConfirmTitle;
    final art = done
        ? GzIllustrationName.successPayment
        : failed
        ? GzIllustrationName.card
        : offline
        ? GzIllustrationName.wifiOff
        : GzIllustrationName.hourglass;
    final meta = failed
        ? GzFactRow(
            children: [GzFactChip(icon: GzIcons.shieldCheck, label: l.clientPaymentNotChargedLabel, value: l.clientPaymentNotCharged)],
          )
        : (longWait || offline)
        ? GzFactRow(
            children: [GzFactChip(icon: GzIcons.bell, label: l.clientPaymentConfirmNotifyLabel, value: l.clientPaymentConfirmNotify)],
          )
        : null;
    return GzScreen(
      fixed: true,
      top: GzTopBar(back: GzTopBarBack.hide, title: l.clientPaymentTopTitle, rule: true),
      bottom: longWait
          ? GzActionBar(
              action: GzActionBarAction(label: l.clientPaymentConfirmKeep, onPressed: () => setState(() => _phase = 'polling')),
              secondary: GzActionBarAction(label: l.clientPaymentConfirmLeave, onPressed: _leave),
            )
          : offline
          ? GzActionBar(
              action: GzActionBarAction(label: l.clientPaymentConfirmLeave, onPressed: _leave),
            )
          : done
          ? GzActionBar(
              action: GzActionBarAction(label: l.clientPaymentViewVoucher, onPressed: _to05),
            )
          : failed
          ? GzActionBar(
              action: GzActionBarAction(label: context.gzL10n.commonActionRetry, onPressed: () => _to04('declined')),
              secondary: GzActionBarAction(label: l.clientPaymentFailAnother, onPressed: () => nav.pop()),
            )
          : null,
      child: PayStage(
        child: Column(
          key: const ValueKey<String>('pay.confirming'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            PayOutcome(
              illustration: art,
              title: title,
              danger: failed,
              size: GzIllustrationSize.lg,
              meta: meta,
              infoTitle: offline ? context.gzL10n.commonLabelDetails : null,
              infoBody: offline ? l.clientPaymentConfirmOffline : null,
            ),
            if (!failed) ...[
              const SizedBox(height: GzSpace.s4),
              _Thread(progress: done ? 1 : _progress, done: done),
              const SizedBox(height: GzSpace.s4),
              if (quote != null) PayFacts(quote: quote, method: method),
            ],
          ],
        ),
      ),
    );
  }
}

/// The 2 px thread that fills while the gateway is asked (web `pm-prog`).
class _Thread extends StatelessWidget {
  const _Thread({required this.progress, required this.done});

  final double progress;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      label: context.l10n.clientPaymentConfirmProgress,
      value: '${(progress * 100).round()}%',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: GzSpace.s2),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: GzRadius.pillAll,
                  child: SizedBox(
                    height: GzStroke.threadMax,
                    child: Row(
                      children: [
                        if (progress > 0)
                          Expanded(
                            flex: (progress * 1000).round().clamp(1, 1000),
                            child: ColoredBox(color: c.markKhayt),
                          ),
                        if (progress < 1)
                          Expanded(
                            flex: (1000 - (progress * 1000).round()).clamp(1, 1000),
                            child: ColoredBox(color: c.markTrack),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: GzSpace.s2),
              GzThreadKnot(state: done ? GzKnotState.tied : GzKnotState.open),
            ],
          ),
        ),
      ),
    );
  }
}
