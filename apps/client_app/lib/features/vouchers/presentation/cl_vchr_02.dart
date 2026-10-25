import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/voucher_model.dart';
import '../application/voucher_nav.dart';
import '../application/voucher_providers.dart';
import 'voucher_fmt.dart';
import 'widgets/wallet_ticket.dart';

/// CL-VCHR-02 My vouchers: the wallet. Every voucher the client holds in three groups (Ready, In request, History) behind a glyph switch
/// that names only the chosen one. Each voucher is a ticket (venue, event date, saving, state; under the perforation the ONE date that
/// matters and the action that fits). Covers CA-VCH-06, CA-VCH-13, CA-PROF-12, CA-VCH-11. Guests see a drawing and Sign in.
class ClVchr02Screen extends ConsumerStatefulWidget {
  const ClVchr02Screen({super.key});

  @override
  ConsumerState<ClVchr02Screen> createState() => _ClVchr02State();
}

class _ClVchr02State extends ConsumerState<ClVchr02Screen> {
  WalletSegment _segment = WalletSegment.ready;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = context.gzNav;
    final signedIn = ref.watch(sessionProvider.select((s) => s.isSignedIn));
    final top = GzTopBar(title: l.clientVouchersWalletTitle);
    if (!signedIn) {
      // A guest meets the account sheet ('CL-AUTH-01', opened by the gate).
      // The wallet is entered from the Profile hub ('CL-PROF-01'); system back returns there.
      return GzScreen(
        top: top,
        child: GzEmptyState(
          illustration: GzIllustrationName.emptyVouchers,
          title: l.clientVouchersGuestTitle,
          action: GzStateAction(
            label: l.clientVouchersCtaSignIn,
            variant: GzButtonVariant.primary,
            iconStart: GzIcons.lock,
            onPressed: () => ref.requireSignIn(GateReason.voucher, resume: const GateResume('CL-VCHR-02', <String, Object?>{})),
          ),
        ),
      );
    }
    final async = ref.watch(walletProvider);
    return GzScreen(
      top: top,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GzIconSegmented<WalletSegment>(
              label: l.clientVouchersSegLabel,
              value: _segment,
              onChanged: (v) => setState(() => _segment = v),
              options: [
                GzIconSegmentedOption(value: WalletSegment.ready, icon: GzIcons.ticket, label: l.clientVouchersSegReady),
                GzIconSegmentedOption(value: WalletSegment.request, icon: GzIcons.send, label: l.clientVouchersSegRequest),
                GzIconSegmentedOption(value: WalletSegment.history, icon: GzIcons.clock, label: l.clientVouchersSegHistory),
              ],
            ),
            const SizedBox(height: GzSpace.s5),
            GzAsyncView<List<WalletItem>>(
              value: async,
              onRetry: () => ref.invalidate(walletProvider),
              loading: const _WalletSkeleton(),
              data: (items) => _List(items: [for (final i in items) if (segmentOf(i.voucher) == _segment) i], segment: _segment, nav: nav),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletSkeleton extends StatelessWidget {
  const _WalletSkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: context.gzL10n.commonStateLoading,
    child: const ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 176), SizedBox(height: GzSpace.listGap), GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 176)],
      ),
    ),
  );
}

class _List extends ConsumerWidget {
  const _List({required this.items, required this.segment, required this.nav});

  final List<WalletItem> items;
  final WalletSegment segment;
  final GzNavigator nav;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = ref.watch(gzFormatProvider);
    if (items.isEmpty) {
      return switch (segment) {
        WalletSegment.ready => GzEmptyState(
          illustration: GzIllustrationName.emptyVouchers,
          title: l.clientVouchersEmptyReady,
          fill: false,
          size: GzIllustrationSize.lg,
          action: GzStateAction(label: l.clientVouchersBrowseHalls, variant: GzButtonVariant.secondary, iconStart: GzIcons.search, onPressed: () => nav.push('CL-DISC-03')),
        ),
        WalletSegment.request => GzEmptyState(illustration: GzIllustrationName.emptyBookings, title: l.clientVouchersEmptyRequest, fill: false, size: GzIllustrationSize.lg),
        WalletSegment.history => GzEmptyState(illustration: GzIllustrationName.shelf, title: l.clientVouchersEmptyHistory, fill: false, size: GzIllustrationSize.lg),
      };
    }
    StubFact? stubOf(WalletItem item) {
      final v = item.voucher;
      final end = endsOnIso(f, v);
      final left = daysToEnd(f, v);
      final soon = left != null && left <= kExpiringDays;
      String day(Object d) => f.dayMon(d);
      if (v.status == VoucherStatus.active) {
        if (v is Voucher && v.reuseUntil != null) {
          return StubFact(icon: soon ? GzIcons.timer : GzIcons.undo, label: soon ? l.clientVouchersLabelExpires : l.clientVouchersLabelReuse, value: day(v.reuseUntil.toString()), accent: soon);
        }
        return end == null
            ? null
            : StubFact(icon: soon ? GzIcons.timer : GzIcons.hourglass, label: soon ? l.clientVouchersLabelExpires : l.clientVouchersLabelValid, value: day(end), accent: soon);
      }
      if (v is CreditVoucher) {
        return v.status == VoucherStatus.used
            ? StubFact(icon: GzIcons.checkDouble, label: l.clientVouchersLabelUsed, value: day(v.usedAt ?? v.validUntil ?? ''))
            : StubFact(icon: GzIcons.clockOff, label: l.clientVouchersLabelExpired, value: day(v.validUntil ?? ''));
      }
      final b = v as Voucher;
      return switch (v.status) {
        VoucherStatus.bound => null,
        VoucherStatus.used => StubFact(icon: GzIcons.checkDouble, label: l.clientVouchersLabelUsed, value: day(b.usedAt ?? '')),
        VoucherStatus.creditIssued => StubFact(icon: GzIcons.gift, label: context.gzL10n.commonVoucherStatusCreditIssued, value: day(b.releasedAt ?? b.usedAt ?? '')),
        VoucherStatus.forfeited => StubFact(icon: GzIcons.xCircle, label: context.gzL10n.commonVoucherStatusForfeited, value: day(b.forfeitedAt ?? '')),
        _ => StubFact(icon: GzIcons.clockOff, label: l.clientVouchersLabelExpired, value: day(b.validUntil ?? '')),
      };
    }

    List<Widget> actionsOf(WalletItem item) {
      final v = item.voucher;
      if (v.status != VoucherStatus.active) return const <Widget>[];
      if (v is CreditVoucher) {
        return [GzButton(label: l.clientVouchersUseThis, variant: GzButtonVariant.secondary, spill: true, onPressed: () => nav.push('CL-DISC-03'))];
      }
      final b = v as Voucher;
      final released = b.releaseReason != null || b.reuseUntil != null;
      return [
        GzButton(label: released ? l.clientVouchersUseAgain : l.clientVouchersSendRequest, variant: GzButtonVariant.secondary, spill: true, onPressed: () => openRequestFor(nav, b)),
        if (released && b.creditEligible)
          GzButton(label: context.gzL10n.commonAskSupport, variant: GzButtonVariant.tertiary, onPressed: () => nav.openSheet('CL-VCHR-05', options: GzSheetOptions(params: <String, Object?>{'voucherId': b.id}))),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: GzSpace.listGap),
          WalletTicket(
            key: ValueKey<String>('voucher.ticket.${items[i].voucher.id}'),
            item: items[i],
            stub: stubOf(items[i]),
            actions: actionsOf(items[i]),
            onOpen: () => nav.push('CL-VCHR-03', params: <String, Object?>{'voucherId': items[i].voucher.id}),
          ),
        ],
      ],
    );
  }
}
