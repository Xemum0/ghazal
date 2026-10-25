import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/voucher_model.dart';
import '../application/voucher_nav.dart';
import '../application/voucher_providers.dart';
import '../application/voucher_quote.dart' show isOffline;
import 'voucher_fmt.dart';
import 'voucher_why.dart';
import 'widgets/voucher_parts.dart';

/// CL-VCHR-05 Use again or ask support (sheet). What happened to a released
/// voucher and the choices that apply (ADR 0035 D5). Covers CA-VCH-11,
/// CA-VCH-14, CA-VCH-05.
///
/// The venue and why it is back as a glyph and one word (the sentence behind
/// the info glyph), then two equal choices: use it again at the same venue
/// until a date, or ask support for a credit voucher (venue-fault releases
/// only; no money goes back and the sheet promises nothing). Asking support is
/// one confirm step and then the support chat opens with the request already
/// written. A client-caused release offers the reuse only; a voucher used up
/// by a cancellation after confirming offers nothing. Once support has
/// answered the sheet shows the outcome: credit issued, or not issued.
// Opened over the wallet ('CL-VCHR-02') or a voucher: dismissing returns to the
// opener. The receipt of a credit grant lives with the payments ('CL-BKNG-05'),
// reached from the voucher the credit was issued for.
class ClVchr05Screen extends ConsumerStatefulWidget {
  const ClVchr05Screen({super.key});

  @override
  ConsumerState<ClVchr05Screen> createState() => _ClVchr05ScreenState();
}

class _ClVchr05ScreenState extends ConsumerState<ClVchr05Screen> {
  bool _confirm = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = context.gzNav;
    final params = nav.params;
    final frame = params['scene'] is String && (params['scene'] as String).isNotEmpty ? params['scene'] as String : (params['state'] is String ? params['state'] as String : null);
    final id = voucherIdParam(params, fallback: kVoucherReleasedId);
    final async = ref.watch(voucherDetailProvider(id));
    final detail = async.value;
    if (detail == null) {
      return Column(
        key: const ValueKey<String>('voucher.refund'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VoucherSheetTop(title: l.clientVouchersAskTitle),
          const SizedBox(height: GzSpace.s3),
          GzAsyncView<VoucherDetail>(value: async, onRetry: () => ref.invalidate(voucherDetailProvider(id)), data: (_) => const SizedBox.shrink()),
        ],
      );
    }
    final v = detail.voucher;
    if (v is! Voucher) {
      return _Frame(
        title: l.clientVouchersAskTitle,
        body: GzEmptyState(illustration: GzIllustrationName.hourglass, title: l.clientVouchersPhaseUsedUp, detail: l.clientVouchersConsumedBody(''), detailTitle: l.clientVouchersInfoUsedUp, fill: false, size: GzIllustrationSize.lg),
      );
    }
    final rr = detail.refundRequest;
    final declined = frame == 'request-declined' || rr?.status == RefundRequestStatus.declined;
    final sent = frame == 'request-sent' || (rr != null && rr.status != RefundRequestStatus.declined && rr.status != RefundRequestStatus.granted);
    final granted = frame == 'credit-granted' || v.status == VoucherStatus.creditIssued || rr?.status == RefundRequestStatus.granted;
    final consumed = frame == 'consumed-no-refund' || v.usedReason == VoucherUsedReason.cancelledAfterConfirm;
    final offline = async.hasError && isOffline(async.error);
    if (consumed) return _consumed(context, voucherText(context, detail.target?.name));
    if (granted) return _granted(context, detail);
    if (declined || sent) return _waiting(context, declined: declined, voucher: v);
    final confirm = frame == 'request-confirm' || _confirm;
    if (confirm) return _confirmFrame(context, offline: offline, onBack: () => setState(() => _confirm = false), onAsk: () => _askSupport(v.id));
    return _choices(context, detail: detail, offline: offline, onConfirm: () => setState(() => _confirm = true));
  }

  Future<void> _askSupport(String voucherId) async {
    final nav = context.gzNav;
    await ref.read(voucherActionsProvider.notifier).askSupportCredit(voucherId);
    if (!mounted) return;
    final v = ref.read(voucherDetailProvider(voucherIdParam(nav.params, fallback: kVoucherReleasedId))).value?.voucher;
    final code = v is Voucher ? v.code : '';
    nav.closeSheet();
    nav.push('CL-MSGS-02', params: <String, Object?>{'support': true, 'draft': context.l10n.clientVouchersAskText(code)});
  }

  Widget _consumed(BuildContext context, String name) {
    final l = context.l10n;
    return _Frame(
      title: l.clientVouchersAskTitle,
      body: GzEmptyState(illustration: GzIllustrationName.hourglass, title: l.clientVouchersPhaseUsedUp, detail: l.clientVouchersConsumedBody(name), detailTitle: l.clientVouchersInfoUsedUp, fill: false, size: GzIllustrationSize.lg),
      footer: GzButton(label: context.gzL10n.commonActionDone, variant: GzButtonVariant.secondary, onPressed: context.gzNav.closeSheet),
    );
  }

  Widget _granted(BuildContext context, VoucherDetail detail) {
    final l = context.l10n;
    final cl = context.gzL10n;
    final nav = context.gzNav;
    final creditId = detail.refundRequest?.creditVoucherId;
    return _Frame(
      title: l.clientVouchersAskTitle,
      state: 'credit-granted',
      body: Column(
        key: const ValueKey<String>('voucher.granted'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: ExcludeSemantics(child: GzIllustration(GzIllustrationName.successPayment, size: GzIllustrationSize.lg))),
          const SizedBox(height: GzSpace.s4),
          GzText(cl.commonVoucherStatusCreditIssued, role: GzTextRole.d2, color: context.gz.colors.textStrong, header: true, textAlign: TextAlign.center),
          const SizedBox(height: GzSpace.s3),
          GzFactRow(
            children: [
              GzFactChip(icon: GzIcons.globe, label: cl.commonVoucherAnyVenue, value: cl.commonVoucherCredit, tone: GzFactTone.muted),
              if (detail.refundRequest?.decidedAt != null) GzFactChip(icon: GzIcons.calendar, label: cl.commonVoucherStatusCreditIssued, value: context.gzFormat.dayMon(detail.refundRequest!.decidedAt.toString()), tone: GzFactTone.muted),
            ],
          ),
        ],
      ),
      footer: creditId == null
          ? null
          : GzButton(
              label: cl.commonVoucherCredit,
              variant: GzButtonVariant.primary,
              onPressed: () {
                nav.closeSheet();
                nav.push('CL-VCHR-03', params: <String, Object?>{'voucherId': creditId});
              },
            ),
    );
  }

  Widget _waiting(BuildContext context, {required bool declined, required Voucher voucher}) {
    final l = context.l10n;
    return _Frame(
      title: l.clientVouchersAskTitle,
      state: declined ? 'request-declined' : 'request-sent',
      body: Column(
        key: const ValueKey<String>('voucher.sent'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: ExcludeSemantics(child: GzIllustration(declined ? GzIllustrationName.hourglass : GzIllustrationName.envelope, size: GzIllustrationSize.lg))),
          const SizedBox(height: GzSpace.s4),
          GzText(declined ? l.clientVouchersCreditDeclined : context.gzL10n.commonCreditRequested, role: GzTextRole.d2, color: context.gz.colors.textStrong, header: true, textAlign: TextAlign.center),
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GzButton(label: l.clientVouchersAskOpen, variant: GzButtonVariant.primary, iconStart: GzIcons.headset, onPressed: () => _openSupport()),
          if (declined && (voucher.reuseUntil != null)) ...[
            const SizedBox(height: GzSpace.s2),
            GzButton(label: l.clientVouchersUseAgain, variant: GzButtonVariant.secondary, onPressed: () => _reuse(voucher)),
          ],
        ],
      ),
    );
  }

  Widget _confirmFrame(BuildContext context, {required bool offline, required VoidCallback onBack, required VoidCallback onAsk}) {
    final l = context.l10n;
    return _Frame(
      title: l.clientVouchersAskTitle,
      state: 'request-confirm',
      showInfo: false,
      body: Column(
        key: const ValueKey<String>('voucher.confirm'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (offline) ...[GzBanner(message: context.gzL10n.commonStateOffline, tone: GzBannerTone.offline, shape: GzBannerShape.flush), const SizedBox(height: GzSpace.s3)],
          Center(child: ExcludeSemantics(child: GzIllustration(GzIllustrationName.envelope, size: GzIllustrationSize.lg))),
          const SizedBox(height: GzSpace.s4),
          GzText(context.gzL10n.commonAskSupport, role: GzTextRole.d2, color: context.gz.colors.textStrong, header: true, textAlign: TextAlign.center),
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GzButton(label: l.clientVouchersAskOpen, variant: GzButtonVariant.primary, iconStart: GzIcons.headset, onPressed: offline ? null : onAsk),
          const SizedBox(height: GzSpace.s2),
          GzButton(label: context.gzL10n.commonActionBack, variant: GzButtonVariant.tertiary, onPressed: onBack),
        ],
      ),
    );
  }

  Widget _choices(BuildContext context, {required VoucherDetail detail, required bool offline, required VoidCallback onConfirm}) {
    final l = context.l10n;
    final v = detail.voucher as Voucher;
    final name = voucherText(context, detail.target?.name);
    final why = voucherWhy(context, v.releaseReason, name);
    final f = context.gzFormat;
    final eligible = detail.options?.creditEligible ?? v.creditEligible;
    final reuseOnly = !eligible;
    return _Frame(
      title: l.clientVouchersAskTitle,
      showInfo: true,
      infoTitle: l.clientVouchersInfoBack,
      infoParagraphs: [why.sentence, if (reuseOnly) l.clientVouchersReuseOnly else l.clientVouchersBackCredit(v.reuseUntil == null ? '' : f.dayMon(v.reuseUntil.toString()))],
      body: Column(
        key: const ValueKey<String>('voucher.choices'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (offline) ...[GzBanner(message: context.gzL10n.commonStateOffline, tone: GzBannerTone.offline, shape: GzBannerShape.flush), const SizedBox(height: GzSpace.s3)],
          Row(
            children: [
              VoucherThumb(name: name, cover: detail.target?.cover, monogram: detail.target?.monogram),
              const SizedBox(width: GzSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GzText(name, role: GzTextRole.d1, color: context.gz.colors.textStrong),
                    const SizedBox(height: GzSpace.s1),
                    GzFactRow(children: [GzFactChip(icon: why.icon, label: why.sentence, value: why.word, tone: GzFactTone.accent)]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GzSpace.s5),
          VoucherChoiceRow(
            icon: GzIcons.ticket,
            title: l.clientVouchersUseAgain,
            facts: v.reuseUntil == null ? null : GzFactRow(children: [GzFactChip(icon: GzIcons.calendar, label: l.clientVouchersLabelReuse, value: f.dayMon(v.reuseUntil.toString()), tone: GzFactTone.muted)]),
            onPressed: () => _reuse(v),
            disabled: offline,
          ),
          if (!reuseOnly) ...[
            const SizedBox(height: GzSpace.s3),
            VoucherChoiceRow(icon: GzIcons.headset, title: context.gzL10n.commonAskSupport, onPressed: onConfirm, disabled: offline),
          ],
        ],
      ),
    );
  }

  void _reuse(Voucher v) {
    final nav = context.gzNav;
    nav.closeSheet();
    openRequestFor(nav, v);
  }

  void _openSupport() {
    final nav = context.gzNav;
    nav.closeSheet();
    nav.push('CL-MSGS-02', params: const <String, Object?>{'support': true});
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.title, required this.body, this.footer, this.state, this.showInfo = false, this.infoTitle, this.infoParagraphs = const <String>[]});

  final String title;
  final Widget body;
  final Widget? footer;
  final String? state;
  final bool showInfo;
  final String? infoTitle;
  final List<String> infoParagraphs;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey<String>('voucher.refund'),
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      VoucherSheetTop(title: title, infoTitle: showInfo ? infoTitle : null, infoParagraphs: showInfo ? infoParagraphs : const <String>[]),
      const SizedBox(height: GzSpace.s5),
      body,
      if (footer != null) ...[const SizedBox(height: GzSpace.s5), GzSheetFooter(child: footer!)],
    ],
  );
}
