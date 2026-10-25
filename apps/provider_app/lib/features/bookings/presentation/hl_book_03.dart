// HL-BOOK-03 Booking detail (web `HL-BOOK-03.tsx`). Requirement IDs: HA-BOOK-02, HA-BOOK-03, HA-BOOK-04, HA-BOOK-06, HA-BOOK-07, HA-BOOK-10,
// HA-BOOK-11, HA-AUTH-02, HA-VCH-01, HA-VCH-03, HA-VCH-05.
// The canonical request screen of the partner (ADR 0033): who, when, what, the voucher price and what happens next. One set of sections, a
// variant per status; the pinned bar carries only the action of the status and role; the decisions run in the Decisions flow (HL-DCSN-01 to
// 04) and the redemption in HL-BOOK-06. No payment, cash, invoice or payout exists: the venue collects the voucher price directly.
// Params: `bookingId` (default: the hero request), `section: voucher` (scroll to the voucher panel), `conflict`, `offerPrompt`.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/bookings_data.dart';
import '../application/detail_model.dart';
import 'widgets/booking_actions.dart';
import 'widgets/decision_bar.dart';
import 'widgets/detail_header.dart';
import 'widgets/detail_outcome.dart';
import 'widgets/detail_sections.dart';

class HlBook03Screen extends ConsumerStatefulWidget {
  const HlBook03Screen({super.key});

  @override
  ConsumerState<HlBook03Screen> createState() => _HlBook03State();
}

class _HlBook03State extends ConsumerState<HlBook03Screen> {
  final GlobalKey _voucherKey = GlobalKey();
  bool _scrolled = false;

  void _revealVoucher(Map<String, Object?> params) {
    if (_scrolled || params['section'] != 'voucher') return;
    _scrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _voucherKey.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, duration: Duration.zero);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final params = context.gzNav.params;
    final id = (params['bookingId'] as String?) ?? kHeroBookingId;
    final async = ref.watch(bookingDetailProvider(id));
    final role = roleOf(ref.watch(partnerContextProvider));
    final act = BookingActions(context, ref);
    final detail = async.value;
    final review = detail == null ? null : ref.watch(reviewToReplyProvider(detail.booking)).value;
    final m = detail == null ? null : DetailModel(detail: detail, role: role, params: params, review: review);
    final ref0 = detail?.booking.ref;

    final top = GzTopBar(title: l.hotelBookingsDetailTitle, subtitle: ref0);
    return GzScreen(
      top: top,
      bottom: m == null ? null : decisionBar(context, m, act),
      child: GzAsyncView<PartnerRequestDetail>(
        value: async,
        loading: const _Skeleton(),
        onRetry: () => ref.invalidate(bookingDetailProvider),
        data: (d) {
          final model = DetailModel(detail: d, role: role, params: params, review: review);
          _revealVoucher(params);
          return _Body(m: model, act: act, voucherKey: _voucherKey);
        },
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: AlignmentDirectional.centerStart, child: GzSkeleton(inlineSize: 120, blockSize: 24)),
        SizedBox(height: GzSpace.s4),
        Align(alignment: AlignmentDirectional.centerStart, child: GzSkeleton(inlineSize: 200, blockSize: 32)),
        SizedBox(height: GzSpace.s4),
        GzSkeleton(blockSize: 24),
        SizedBox(height: GzSpace.s4),
        GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 96),
        SizedBox(height: GzSpace.s4),
        GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 180),
        SizedBox(height: GzSpace.s4),
        GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 140),
      ],
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body({required this.m, required this.act, required this.voucherKey});

  final DetailModel m;
  final BookingActions act;
  final GlobalKey voucherKey;

  @override
  Widget build(BuildContext context) {
    final b = m.booking;
    final closed = const {BookingStatus.declined, BookingStatus.expired, BookingStatus.cancelled, BookingStatus.completed}.contains(b.status);
    final notices = detailNotices(context, m, act);
    final actions = detailActions(context, m, act);
    final children = <Widget>[
      DetailThread(b: b),
      ?notices,
      if (closed) DetailOutcome(m: m),
      if (b.specialRequests != null && b.specialRequests!.isNotEmpty) DetailSpecial(text: b.specialRequests!),
      DetailClient(m: m, act: act),
      if (b.proposal != null) DetailProposal(m: m),
      DetailEvent(m: m),
      DetailPrice(m: m),
      if (voucherVisible(m)) KeyedSubtree(key: voucherKey, child: DetailVoucher(m: m)),
      ?actions,
      DetailAudit(b: b),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DetailHeader(m: m),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s5, bottom: GzSpace.section),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.listGap), children[i]]],
          ),
        ),
      ],
    );
  }
}
