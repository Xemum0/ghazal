import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/pay_flow.dart';

/// CL-PAYM-05 Your voucher is ready. The success of the KD 2 payment: the
/// voucher with its single-use code and QR, what it is bound to, its validity
/// and the one next step. Covers CA-BOOK-13, CA-NOTI-07, CA-VCH-05, CA-VCH-07,
/// CA-VCH-14.
///
/// One calm celebration (the check draws inside the 640 ms success token, one
/// success haptic, no confetti): an ink hero with the title and the drawing,
/// the voucher ticket, the saving with the voucher terms behind an info glyph,
/// three icon rows (My vouchers, Receipt, Message). One pinned primary: Send
/// request, which opens the booking flow prefilled from the voucher.
class ClPaym05Screen extends ConsumerWidget {
  const ClPaym05Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = context.gzNav;
    final args = PayArgs.fromParams(nav.params);
    final voucherId = args.voucherId ?? kPayHeroVoucherId;
    final depth = args.depth;
    final late = args.scene == 'voucher-ready-late-payment';
    final offline = args.scene == 'offline';
    final async = ref.watch(_issuedVoucherProvider(voucherId));
    final detail = async.value;
    void goDone() {
      if (nav.canGoBack) {
        for (var i = 0; i < depth && nav.canGoBack; i++) {
          nav.pop();
        }
      } else if (detail != null) {
        final v = detail.voucher;
        final id = (v is Voucher && v.targetType == VoucherTargetType.provider) ? 'CL-SERV-03' : 'CL-VENU-01';
        final t = v is Voucher ? v.venueOrProviderId : '';
        nav.push(id, params: v is Voucher && v.targetType == VoucherTargetType.provider ? <String, Object?>{'providerId': t, 'vendorId': t} : <String, Object?>{'venueId': t});
      }
    }

    void sendRequest() {
      final v = detail?.voucher;
      if (v is! Voucher) return;
      ref.read(bookingDraftProvider.notifier).patch(
        (d) => d.copyWith(
          venueId: v.targetType == VoucherTargetType.venue ? v.venueOrProviderId : null,
          providerId: v.targetType == VoucherTargetType.provider ? v.venueOrProviderId : null,
          hallId: v.hallId,
          packageId: v.packageId,
          eventDate: v.eventDate,
          guests: v.guests,
          voucherId: v.id,
          clearVoucher: false,
        ),
      );
      nav.push(
        'CL-BOOK-01',
        params: <String, Object?>{
          'voucherId': v.id,
          if (v.targetType == VoucherTargetType.venue) 'venueId': v.venueOrProviderId else 'providerId': v.venueOrProviderId,
          'date': v.eventDate.toString(),
          if (v.hallId != null) 'hallId': v.hallId,
          if (v.guests != null) 'guests': v.guests,
        },
      );
    }

    return GzScreen(
      topOverlay: true,
      top: GzTopBar(variant: GzTopBarVariant.transparent, back: GzTopBarBack.close, backLabel: context.gzL10n.commonActionClose, onBack: goDone),
      bottom: detail == null
          ? null
          : GzActionBar(action: GzActionBarAction(label: l.clientPaymentDoneCta, onPressed: sendRequest)),
      child: GzAsyncView<VoucherDetail>(
        value: async,
        onRetry: () => ref.invalidate(_issuedVoucherProvider(voucherId)),
        loading: const _DoneSkeleton(),
        data: (d) => _Done(detail: args.voucherId == null ? payReadyVariant(d) : d, late: late, offline: offline, onSendRequest: sendRequest),
      ),
    );
  }
}

Future<void> _copy(BuildContext context, GzNavigator nav, String code) async {
  final text = context.gzL10n.commonStateCopied;
  await Clipboard.setData(ClipboardData(text: code));
  nav.toast(GzToastSpec(message: text, tone: GzToastTone.success));
}

final _issuedVoucherProvider = FutureProvider.autoDispose.family<VoucherDetail, String>((ref, id) async {
  ref.watch(clientDataRevisionProvider);
  return ref.watch(vouchersRepositoryProvider).getVoucher(voucherId: id);
});

class _Done extends StatelessWidget {
  const _Done({required this.detail, required this.late, required this.offline, required this.onSendRequest});

  final VoucherDetail detail;
  final bool late;
  final bool offline;
  final VoidCallback onSendRequest;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final nav = context.gzNav;
    final v = detail.voucher;
    final name = v is Voucher ? (detail.target?.name.of(context.gz.locale.languageCode) ?? '') : context.gzL10n.commonVoucherCredit;
    final savings = v is Voucher ? (v.quoteFils.standard - v.quoteFils.voucher).clamp(0, 1 << 40) : 0;
    final paidAt = v is Voucher ? v.payment?.at ?? v.purchasedAt : null;
    return Column(
      key: const ValueKey<String>('pay.done'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: MediaQuery.paddingOf(context).top + GzSpace.s2, bottom: GzSpace.s4),
          color: c.surfaceDark,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Semantics(header: true, child: GzText(l.clientPaymentDoneTitle, role: GzTextRole.d2, color: c.textOnDark)),
              ),
              const SizedBox(width: GzSpace.s3),
              GzDrawOnce(
                child: ExcludeSemantics(child: GzIllustration(GzIllustrationName.successVoucher, size: GzIllustrationSize.lg, tone: GzIllustrationTone.onDark)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s6, bottom: GzSpace.s8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (offline) ...[GzBanner(message: context.gzL10n.commonStateOffline, tone: GzBannerTone.offline, shape: GzBannerShape.flush), const SizedBox(height: GzSpace.s6)],
              if (late) ...[GzBanner(message: l.clientPaymentDoneLate, tone: GzBannerTone.info, shape: GzBannerShape.card), const SizedBox(height: GzSpace.s6)],
              GzVoucherCard(voucher: v, variant: GzVoucherCardVariant.full, targetName: name, onCopy: () => _copy(context, nav, v.code), packageName: detail.packageName?.of(context.gz.locale.languageCode)),
              const SizedBox(height: GzSpace.s6),
              Row(
                children: [
                  if (savings > 0)
                    Expanded(
                      child: GzFactRow(
                        label: l.clientPaymentLabelSaving,
                        children: [GzFactChip(icon: GzIcons.offer, label: l.clientPaymentLabelSaving, value: l.clientPaymentSave(context.gzFormat.money(savings)))],
                      ),
                    ),
                  GzInfoButton(
                    title: l.clientPaymentTermsTitle,
                    paragraphs: [l.clientPaymentDoneReuse, if (late) l.clientPaymentDoneLateNote],
                    bleed: true,
                  ),
                ],
              ),
              const SizedBox(height: GzSpace.s6),
              GzIconListRow(flush: true, icon: GzIcons.ticket, title: l.clientPaymentDoneRowVouchers, chevron: true, onPressed: () => nav.push('CL-VCHR-02', params: <String, Object?>{'voucherId': v.id})),
              GzIconListRow(
                flush: true,
                icon: GzIcons.receipt,
                title: l.clientPaymentDoneRowReceipt,
                chevron: !offline,
                onPressed: offline ? null : () => nav.push('CL-BKNG-05', params: <String, Object?>{'voucherId': v.id}),
                trailing: paidAt == null ? null : GzFactChip(icon: GzIcons.calendar, label: l.clientPaymentLabelDate, value: context.gzFormat.date(paidAt.toString().substring(0, 10), DateStyle.compact), tone: GzFactTone.muted),
              ),
              GzIconListRow(
                flush: true,
                last: true,
                icon: GzIcons.chat,
                title: context.gzL10n.commonActionMessage,
                chevron: true,
                onPressed: () {
                  if (v is Voucher) {
                    nav.push('CL-MSGS-02', params: v.targetType == VoucherTargetType.provider ? <String, Object?>{'providerId': v.venueOrProviderId, 'vendorId': v.venueOrProviderId} : <String, Object?>{'venueId': v.venueOrProviderId});
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DoneSkeleton extends StatelessWidget {
  const _DoneSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      container: true,
      label: context.gzL10n.commonStateLoading,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 240, color: c.surfaceDark),
            const Padding(
              padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s5),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 320)]),
            ),
          ],
        ),
      ),
    );
  }
}
