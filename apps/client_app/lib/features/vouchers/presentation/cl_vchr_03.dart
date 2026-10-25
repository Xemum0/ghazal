import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/voucher_model.dart';
import '../application/voucher_nav.dart';
import '../application/voucher_providers.dart';
import 'voucher_fmt.dart';
import 'widgets/voucher_detail_parts.dart';
import 'widgets/voucher_strips.dart';

/// CL-VCHR-03 Voucher: one voucher. The ticket (the venue, what it is bound to, the code and QR the venue scans, how long it is valid)
/// under ONE phase strip that says what the voucher is doing now in a glyph, a word and facts; the sentences are behind the strip's info
/// glyph and an ended voucher gets a drawing. History is a glyph, a word and a date per event; the paid event opens the receipt. The one
/// pinned action fits the state. A credit voucher from support is unbound (any hall, hotel or service). Covers CA-VCH-07, CA-VCH-08,
/// CA-VCH-11, CA-VCH-14, CA-STAT-13. params: voucherId (else the hero voucher).
class ClVchr03Screen extends ConsumerWidget {
  const ClVchr03Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Opened from the wallet ('CL-VCHR-02'), a booking or the pay flow; the bar
    // back returns to the opener.
    final l = context.l10n;
    final nav = context.gzNav;
    final id = voucherIdParam(nav.params);
    final heroFallback = nav.params['voucherId'] == null;
    final async = ref.watch(voucherViewProvider(id));
    final raw = async.hasValue ? async.requireValue : null;
    final view = raw == null || !heroFallback ? raw : (detail: readyVariantOf(raw.detail), config: raw.config);
    return GzScreen(
      top: GzTopBar(title: l.clientVouchersDetailTitle),
      bottom: view == null ? null : _bar(context, ref, nav, view),
      child: GzAsyncView<VoucherView>(
        value: async,
        onRetry: () => ref.invalidate(voucherViewProvider(id)),
        loading: const _DetailSkeleton(),
        data: (v) {
          final shown = heroFallback ? (detail: readyVariantOf(v.detail), config: v.config) : v;
          return shown.detail.voucher is CreditVoucher ? _CreditDetail(view: shown, nav: nav) : _BoundDetail(view: shown, nav: nav);
        },
      ),
    );
  }

  Widget? _bar(BuildContext context, WidgetRef ref, GzNavigator nav, VoucherView view) {
    final l = context.l10n;
    final v = view.detail.voucher;
    if (v is CreditVoucher) {
      return v.status == VoucherStatus.active ? GzActionBar(action: GzActionBarAction(label: l.clientVouchersBrowseHalls, onPressed: () => nav.push('CL-DISC-03'))) : null;
    }
    final b = v as Voucher;
    final phase = phaseOf(b, view.detail.booking);
    switch (phase) {
      case VoucherPhase.ready:
      case VoucherPhase.released:
        return GzActionBar(
          action: GzActionBarAction(label: phase == VoucherPhase.released ? l.clientVouchersUseAgain : l.clientVouchersSendRequest, onPressed: () => openRequestFor(nav, b)),
        );
      case VoucherPhase.pending:
      case VoucherPhase.approved:
        final booking = view.detail.booking;
        return GzActionBar(
          action: GzActionBarAction(
            label: l.clientVouchersViewRequest,
            onPressed: booking == null ? null : () => nav.push('CL-BKNG-02', params: <String, Object?>{'bookingId': booking.id}),
          ),
        );
      case VoucherPhase.confirmed:
        return GzActionBar(
          action: GzActionBarAction(label: l.clientVouchersShowCode, iconEnd: GzIcons.qrCode, onPressed: () => _showFull(context, nav, view)),
        );
      default:
        return null;
    }
  }
}

void _showFull(BuildContext context, GzNavigator nav, VoucherView view) {
  final v = view.detail.voucher;
  final name = v is CreditVoucher ? context.gzL10n.commonVoucherCredit : voucherText(context, view.detail.target?.name);
  nav.openSheetBuilder((_) => QrFullBody(voucher: v, name: name), options: const GzSheetOptions());
}

Future<void> _copy(BuildContext context, GzNavigator nav, String code) async {
  final text = context.l10n.clientVouchersCodeCopied;
  await Clipboard.setData(ClipboardData(text: code));
  nav.toast(GzToastSpec(message: text, tone: GzToastTone.success));
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: context.gzL10n.commonStateLoading,
    child: const ExcludeSemantics(
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 72),
            SizedBox(height: GzSpace.s5),
            GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 380),
            SizedBox(height: GzSpace.s5),
            GzSkeleton(inlineSize: 220, blockSize: 24),
          ],
        ),
      ),
    ),
  );
}

class _Frame extends StatelessWidget {
  const _Frame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8),
    child: Column(
      key: const ValueKey<String>('voucher.detail'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s5), children[i]],
      ],
    ),
  );
}

class _SupportRow extends StatelessWidget {
  const _SupportRow({required this.nav});

  final GzNavigator nav;

  @override
  Widget build(BuildContext context) => GzIconListRow(
    flush: true,
    last: true,
    chevron: true,
    icon: GzIcons.headset,
    title: context.l10n.clientVouchersSupport,
    onPressed: () => nav.push('CL-MSGS-02', params: const <String, Object?>{'support': true}),
  );
}

class _CreditDetail extends StatelessWidget {
  const _CreditDetail({required this.view, required this.nav});

  final VoucherView view;
  final GzNavigator nav;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cl = context.gzL10n;
    final f = context.gzFormat;
    final v = view.detail.voucher as CreditVoucher;
    final live = v.status == VoucherStatus.active;
    final body = l.clientVouchersCreditBody(f.digits(l.commonCountDays(view.config.voucherValidityDays)), f.digits(l.commonCountHours(view.config.confirmWindowHours)));
    return _Frame(
      children: [
        if (live)
          PhaseStripCredit(body: body, until: v.validUntil == null ? null : f.dayMon(v.validUntil!))
        else
          PhaseStripEnded(used: v.status == VoucherStatus.used, label: v.status == VoucherStatus.used ? cl.commonVoucherStatusUsed : cl.commonVoucherStatusExpired),
        GzVoucherCard(voucher: v, onCopy: live ? () => _copy(context, nav, v.code) : null),
        _SupportRow(nav: nav),
      ],
    );
  }
}

class _BoundDetail extends ConsumerWidget {
  const _BoundDetail({required this.view, required this.nav});

  final VoucherView view;
  final GzNavigator nav;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = view.detail;
    final v = d.voucher as Voucher;
    final name = voucherText(context, d.target?.name);
    final phase = phaseOf(v, d.booking);
    final withQr = phase == VoucherPhase.ready || phase == VoucherPhase.released || phase == VoucherPhase.confirmed;
    void askSupport() => nav.openSheet('CL-VCHR-05', options: GzSheetOptions(params: <String, Object?>{'voucherId': v.id}));
    return _Frame(
      children: [
        phaseStripOf(context, view: view, phase: phase, name: name, askSupport: askSupport, openCredit: (id) => nav.push('CL-VCHR-03', params: <String, Object?>{'voucherId': id})),
        GzVoucherCard(
          voucher: v,
          variant: withQr ? GzVoucherCardVariant.full : GzVoucherCardVariant.compact,
          targetName: name,
          packageName: d.packageName == null ? null : voucherText(context, d.packageName),
          onCopy: withQr ? () => _copy(context, nav, v.code) : null,
          onShowFull: withQr ? () => _showFull(context, nav, view) : null,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
          child: VoucherHistory(detail: d, onReceipt: () => nav.push('CL-BKNG-05', params: <String, Object?>{'voucherId': v.id})),
        ),
        _SupportRow(nav: nav),
      ],
    );
  }
}
