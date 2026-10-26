import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show sessionProvider, vouchersRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/bookings_data.dart';
import 'widgets/bk_common.dart';

/// CL-BKNG-05 Receipts. Covers CA-PROF-05, CA-NOTI-07, CA-VCH-14.
///
/// Every Ghazal receipt in one place: the KD 2 voucher payments (grouped by month, newest first) and the credit vouchers support granted
/// (no money refunds: a credit grant is a wallet entry, no credit note). A row opens the bilingual PDF preview (Download, Share, Open in).
/// There are no scheduled payments, no balances and no event invoices: event payments are between the couple and the venue. Params:
/// voucherId or receipt (lands on that document once the screen is on).
class ClBkng05Screen extends ConsumerStatefulWidget {
  const ClBkng05Screen({super.key});

  @override
  ConsumerState<ClBkng05Screen> createState() => _ClBkng05State();
}

enum _RowKind { receipt, credit }

class _DocRow {
  const _DocRow({required this.id, required this.kind, required this.at, required this.fils, this.receipt, this.credit});
  final String id;
  final _RowKind kind;
  final DateTime at;
  final int fils;
  final Receipt? receipt;
  final WalletItem? credit;
}

class _ClBkng05State extends ConsumerState<ClBkng05Screen> {
  bool _landed = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = context.gzNav;
    final guest = !ref.watch(sessionProvider.select((s) => s.isSignedIn));
    final async = ref.watch(bookingsReceiptsProvider);
    final credits = ref.watch(bookingsCreditProvider);
    final top = GzTopBar(
      title: l.clientBookingsReceiptsTitle,
      actions: guest
          ? const []
          : [
              GzTopBarAction(
                icon: GzIcons.info,
                label: l.clientBookingsReceiptsInfoTitle,
                onPressed: () => showGzInfoSheet(context, title: l.clientBookingsReceiptsInfoTitle, paragraphs: [l.clientBookingsReceiptsNote]),
              ),
            ],
    );
    if (guest) {
      return GzScreen(
        top: top,
        child: GzEmptyState(
          illustration: GzIllustrationName.key,
          title: l.clientBookingsGuestTitle,
          action: GzStateAction(label: l.clientBookingsGuestAction, onPressed: () => nav.openSheet('CL-AUTH-01')),
        ),
      );
    }
    return GzScreen(
      top: top,
      child: BkAsync<List<Receipt>>(
        value: async,
        onRetry: () => ref.invalidate(bookingsReceiptsProvider),
        loading: const _ReceiptsSkeleton(),
        data: (receipts) {
          final rows = _rows(receipts, credits.value ?? const <WalletItem>[]);
          if (rows.isEmpty) return _empty(context);
          _maybeLand(rows);
          return _list(context, rows);
        },
      ),
    );
  }

  List<_DocRow> _rows(List<Receipt> receipts, List<WalletItem> creditVouchers) {
    final out = <_DocRow>[
      for (final r in receipts) _DocRow(id: r.receiptNo, kind: _RowKind.receipt, at: r.at, fils: r.amount.fils, receipt: r),
      for (final w in creditVouchers)
        _DocRow(
          id: '${w.voucher.id}-credit',
          kind: _RowKind.credit,
          at: w.voucher is Voucher ? (w.voucher as Voucher).purchasedAt ?? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.fromMillisecondsSinceEpoch(0),
          fils: w.voucher.priceFils,
          credit: w,
        ),
    ];
    out.sort((a, b) => b.at.compareTo(a.at));
    return out;
  }

  void _maybeLand(List<_DocRow> rows) {
    if (_landed) return;
    final landing = context.gzNav.params['receipt'] as String? ?? context.gzNav.params['voucherId'] as String?;
    if (landing == null) return;
    final _DocRow? row = rows.where((r) => r.id == landing).firstOrNull ?? rows.where((r) => (r.receipt?.voucherId ?? r.credit?.voucher.id) == landing).firstOrNull;
    if (row == null) return;
    _landed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _open(row);
    });
  }

  Widget _empty(BuildContext context) {
    final l = context.l10n;
    return GzEmptyState(
      illustration: GzIllustrationName.emptyVouchers,
      title: l.clientBookingsReceiptsEmptyTitle,
      action: GzStateAction(label: l.clientBookingsVouchers, iconStart: GzIcons.ticket, onPressed: () => context.gzNav.push('CL-VCHR-02')),
    );
  }

  Widget _list(BuildContext context, List<_DocRow> rows) {
    final f = context.gzFormat;
    final c = context.gz.colors;
    final months = <String>[];
    for (final r in rows) {
      final m = '${r.at.year}-${r.at.month.toString().padLeft(2, '0')}-01';
      if (!months.contains(m)) months.add(m);
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s4, bottom: GzSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var mi = 0; mi < months.length; mi++) ...[
            if (mi > 0) const SizedBox(height: GzSpace.section),
            BkPad(child: GzSectionHeader(title: f.date(months[mi], DateStyle.monthYear), draw: GzDraw.mount)),
            const SizedBox(height: GzSpace.s2),
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final r in rows.where((x) => '${x.at.year}-${x.at.month.toString().padLeft(2, '0')}-01' == months[mi]))
                    RepaintBoundary(child: _ReceiptRow(row: r, onOpen: () => _open(r))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _open(_DocRow row) {
    final nav = context.gzNav;
    if (row.kind == _RowKind.credit) {
      nav.push('CL-VCHR-03', params: <String, Object?>{'voucherId': row.receipt?.voucherId ?? row.credit?.voucher.id});
      return;
    }
    nav.openSheetBuilder((_) => _DocViewer(row: row), options: GzSheetOptions(title: context.l10n.clientBookingsReceiptsReceipt));
  }
}

/// The credit vouchers support granted (no money moved): each opens its wallet entry.
final FutureProvider<List<WalletItem>> bookingsCreditProvider = FutureProvider<List<WalletItem>>((ref) async {
  if (!ref.watch(sessionProvider.select((s) => s.isSignedIn))) return const <WalletItem>[];
  try {
    final page = await ref.watch(vouchersRepositoryProvider).listVouchers(limit: 50);
    return <WalletItem>[for (final w in page.items) if (w.voucher.status == VoucherStatus.creditIssued) w];
  } on Object {
    return const <WalletItem>[];
  }
});

/// One Ghazal document: a receipt glyph (gift for a credit grant), the venue, `[calendar] 12` and the method, the amount.
class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.row, required this.onOpen});

  final _DocRow row;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final credit = row.kind == _RowKind.credit;
    final target = row.receipt?.target ?? row.credit?.target;
    final title = target == null ? '' : context.bi(target.name);
    final method = _method(context, row.receipt?.method);
    final label = credit ? l.clientBookingsReceiptsCredit : l.clientBookingsReceiptsReceipt;
    return GzPressable(
      onPressed: onOpen,
      semanticLabel: '$label, $title',
      builder: (context, st) => Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox.square(dimension: GzSize.iconLg, child: Center(child: GzIcon(credit ? GzIcons.gift : GzIcons.receipt, size: GzIconSize.md, color: c.iconSecondary))),
              const SizedBox(width: GzSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GzUserText(title, role: GzTextRole.bodyS, color: c.textStrong),
                    const SizedBox(height: GzSpace.s1),
                    Row(
                      children: [
                        GzFactChip(icon: GzIcons.calendar, label: l.clientBookingsFactDate, value: f.integer(row.at.day), small: true, tone: GzFactTone.muted),
                        if (method != null) ...[
                          const SizedBox(width: GzSpace.s3),
                          GzFactChip(icon: method.icon, label: method.label, value: method.value, small: true, tone: GzFactTone.muted),
                        ],
                      ],
                    ),
                    if (credit) ...[
                      const SizedBox(height: GzSpace.s2),
                      GzStatusPill(status: GzStatus.voucherCreditIssued, label: l.clientBookingsReceiptsCredit),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: GzSpace.s3),
              GzPrice(fils: row.fils, mode: GzMoneyMode.exact, size: GzPriceSize.strong),
              const SizedBox(width: GzSpace.s3),
              GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
            ],
          ),
        ),
      ),
    );
  }

  ({IconData icon, String label, String? value})? _method(BuildContext context, GatewayMethod? m) {
    final l = context.l10n;
    return switch (m) {
      GatewayMethod.knet => (icon: GzIcons.card, label: l.clientBookingsMethodKnet, value: null),
      GatewayMethod.applePay => (icon: GzIcons.apple, label: l.clientBookingsMethodApplePay, value: null),
      GatewayMethod.googlePay => (icon: GzIcons.google, label: l.clientBookingsMethodGooglePay, value: null),
      GatewayMethod.card => (icon: GzIcons.card, label: l.clientBookingsMethodCard, value: null),
      _ => null,
    };
  }
}

/// The bilingual preview of one document with Download, Share and Open (handed to the phone).
class _DocViewer extends ConsumerStatefulWidget {
  const _DocViewer({required this.row});

  final _DocRow row;

  @override
  ConsumerState<_DocViewer> createState() => _DocViewerState();
}

class _DocViewerState extends ConsumerState<_DocViewer> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = context.gzNav;
    final receipt = widget.row.receipt!;
    final target = receipt.target == null ? '' : context.bi(receipt.target!.name);
    final detail = ref.watch(_voucherDetailProvider(receipt.voucherId));
    final voucher = detail.value?.voucher;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSheetPinnedHeader(child: BkSheetTop(title: '${l.clientBookingsReceiptsReceipt} ${receipt.receiptNo}')),
        if (voucher is Voucher)
          Semantics(
            container: true,
            label: l.clientBookingsViewerPreview,
            child: GzReceiptSheet(voucher: voucher, targetName: target),
          )
        else
          const GzSkeleton(blockSize: 220),
        const SizedBox(height: GzSpace.s4),
        if (_saved)
          GzButton(variant: GzButtonVariant.secondary, iconStart: GzIcons.checkCircle, onPressed: () {}, label: l.clientBookingsViewerDownloaded)
        else
          GzButton(variant: GzButtonVariant.primary, iconStart: GzIcons.download, onPressed: () => setState(() => _saved = true), label: l.clientBookingsViewerDownload),
        const SizedBox(height: GzSpace.s3),
        Row(
          children: [
            Expanded(child: GzButton(variant: GzButtonVariant.secondary, iconStart: GzIcons.share, onPressed: () => nav.toast(GzToastSpec(message: l.clientBookingsViewerShareToast)), label: context.gzL10n.commonActionShare)),
            const SizedBox(width: GzSpace.s3),
            Expanded(child: GzButton(variant: GzButtonVariant.secondary, iconStart: GzIcons.externalLink, onPressed: () => nav.toast(GzToastSpec(message: l.clientBookingsViewerOpenToast)), label: l.clientBookingsViewerOpen)),
          ],
        ),
        const SizedBox(height: GzSpace.s3),
        GzButton(
          variant: GzButtonVariant.tertiary,
          iconStart: GzIcons.ticket,
          onPressed: () {
            nav.closeSheet();
            nav.push('CL-VCHR-03', params: <String, Object?>{'voucherId': receipt.voucherId});
          },
          label: l.clientBookingsViewerOpenVoucher,
        ),
      ],
    );
  }
}

/// One Ghazal document preview loader.
final _voucherDetailProvider = FutureProvider.autoDispose.family<VoucherDetail, String>((ref, id) async {
  return ref.watch(vouchersRepositoryProvider).getVoucher(voucherId: id);
});

class _ReceiptsSkeleton extends StatelessWidget {
  const _ReceiptsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const BkPad(
      child: BkGap(
        children: [GzSkeleton(blockSize: 64), GzSkeleton(blockSize: 64), GzSkeleton(blockSize: 64)],
      ),
    );
  }
}
