// HL-BOOK-06 Redeem a voucher (web `HL-BOOK-06.tsx`). Requirement IDs: HA-VCH-01, HA-VCH-02, HA-VCH-05, HA-AUTH-02.
// Redeem a client voucher at the venue (ADR 0033, voucher-model 8.2): scan the QR or type the code, see the bound quote and confirm. The check
// (R11 step one, `checkVoucher`) says whether the code belongs to this partner, whether the request is confirmed and whether it was used
// before, with specific calm errors that never reveal client data; the one confirmation is `redeem`. Never queued offline.
// Reachable from Bookings (header), Today (quick action) and the Booking detail bar, which opens it with the code prefilled (param `code`).
// The camera is a drawn viewfinder: "Simulate" reads the next live code and the demo chips reach every outcome by tapping.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemMessage;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/bookings_data.dart';
import '../application/detail_model.dart';
import '../application/redeem_data.dart';
import '../application/redeem_model.dart';
import 'widgets/redeem_parts.dart';

enum _Mode { scan, type }

class HlBook06Screen extends ConsumerStatefulWidget {
  const HlBook06Screen({super.key});

  @override
  ConsumerState<HlBook06Screen> createState() => _HlBook06State();
}

class _HlBook06State extends ConsumerState<HlBook06Screen> {
  _Mode _mode = _Mode.scan;
  String _typed = '';
  bool _torch = false;
  bool _unknown = false;
  bool _checking = false;
  String? _code;
  RedeemOutcome? _result;
  bool _redeeming = false;
  int _turn = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final prefill = context.gzNav.params['code'];
    if (prefill is String && prefill.isNotEmpty) {
      _mode = _Mode.type;
      _typed = typedPart(prefill);
      WidgetsBinding.instance.addPostFrameCallback((_) => _check(prefill));
    }
  }

  Future<void> _check(String code) async {
    setState(() {
      _unknown = false;
      _checking = true;
      _code = code;
      _result = null;
    });
    final r = await ref.read(requestActionsProvider.notifier).checkVoucher(code);
    if (!mounted) return;
    r.when(
      success: (check) {
        final o = outcomeOf(check);
        setState(() {
          _checking = false;
          if (o is OutcomeUnknown) {
            _unknown = true;
            _mode = _Mode.type;
            _result = null;
          } else {
            _result = o;
          }
        });
      },
      failure: (p) {
        setState(() {
          _checking = false;
          _result = null;
        });
        context.gzNav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, p), tone: GzToastTone.danger));
      },
      gated: () => setState(() => _checking = false),
    );
  }

  void _reset() => setState(() {
    _result = null;
    _typed = '';
    _unknown = false;
    _checking = false;
    _code = null;
  });

  Future<void> _redeem(String code, OutcomeReady ready) async {
    setState(() => _redeeming = true);
    final nav = context.gzNav;
    final r = await ref.read(requestActionsProvider.notifier).redeem(code);
    if (!mounted) return;
    setState(() => _redeeming = false);
    r.when(
      success: (done) {
        nav.openSheet('HL-BOOK-07', options: GzSheetOptions(params: {'bookingId': ready.booking.id, 'code': code}));
        _reset();
      },
      failure: (p) {
        nav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, p), tone: GzToastTone.danger));
        _check(code);
      },
      gated: () {},
    );
  }

  void _simulate(SampleCodes codes) {
    final pool = [codes.ready, codes.used, codes.notConfirmed].whereType<String>().toList();
    if (pool.isEmpty) return;
    final code = pool[_turn % pool.length];
    _turn++;
    _check(code);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cl = context.gzL10n;
    final nav = context.gzNav;
    final role = roleOf(ref.watch(partnerContextProvider));
    final top = GzTopBar(title: cl.commonRedeemVoucher);
    if (!canRedeem(role)) {
      return GzScreen(
        top: top,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s3),
          child: GzEmptyState(
            illustration: GzIllustrationName.shield,
            title: cl.commonStateTitleNoAccess,
            detail: l.hotelBookingsRoleHiddenBody,
            fill: false,
            size: GzIllustrationSize.lg,
            action: GzStateAction(label: l.hotelBookingsBackToList, onPressed: () => nav.pop()),
          ),
        ),
      );
    }
    final codes = ref.watch(sampleCodesProvider).value ?? const SampleCodes();
    final result = _result;
    Widget body;
    Widget? bottom;
    if (_checking) {
      body = Semantics(
        liveRegion: true,
        label: l.hotelBookingsChecking,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(alignment: AlignmentDirectional.centerStart, child: GzSkeleton(inlineSize: 160, blockSize: 20)),
            SizedBox(height: GzSpace.s4),
            Align(alignment: AlignmentDirectional.centerStart, child: GzSkeleton(inlineSize: 200, blockSize: 32)),
            SizedBox(height: GzSpace.s4),
            GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 220),
          ],
        ),
      );
      bottom = GzActionBar(action: GzActionBarAction(label: l.hotelBookingsChecking, loading: true));
    } else if (result != null) {
      if (result is OutcomeReady) {
        final b = result.booking;
        final s = b.sections.isEmpty ? null : b.sections.first;
        final venue = b.venueId == null ? null : ref.watch(venueDetailProvider(b.venueId!)).value;
        final lang = context.gz.locale.languageCode;
        final hall = s == null ? '' : (venue?.venue.halls.where((h) => h.id == s.hallId).map((h) => h.name.of(lang)).firstOrNull ?? '');
        final pkg = s == null ? '' : (venue?.packages.where((p) => p.package.id == s.packageId).map((p) => p.package.name.of(lang)).firstOrNull ?? '');
        body = QuoteCard(booking: b, voucher: result.voucher, hallName: hall, packageName: pkg);
        bottom = GzActionBar(
          action: GzActionBarAction(label: cl.commonRedeemVoucher, loading: _redeeming, onPressed: _redeeming ? null : () => _redeem(_code ?? result.voucher.code, result)),
          secondary: GzActionBarAction(label: l.hotelBookingsTryAnother, onPressed: _reset),
        );
      } else {
        body = ResultNotice(outcome: result, onAgain: _reset);
      }
    } else {
      final inType = _mode == _Mode.type;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzIconSegmented<_Mode>(
            label: l.hotelBookingsRedeemMode,
            value: _mode,
            onChanged: (m) => setState(() {
              _mode = m;
              _unknown = false;
            }),
            options: [
              GzIconSegmentedOption<_Mode>(value: _Mode.scan, icon: GzIcons.scan, label: l.hotelBookingsModeScan),
              GzIconSegmentedOption<_Mode>(value: _Mode.type, icon: GzIcons.key, label: l.hotelBookingsModeType),
            ],
          ),
          const SizedBox(height: GzSpace.s6),
          if (inType)
            CodeField(
              value: _typed,
              onChanged: (v) => setState(() {
                _typed = v;
                _unknown = false;
              }),
              error: _unknown ? l.hotelBookingsErrUnknownField : null,
              onSubmit: () {
                if (isComplete(_typed)) _check(fullCode(_typed));
              },
            )
          else
            Viewfinder(torch: _torch, onTorch: () => setState(() => _torch = !_torch), onScan: () => _simulate(codes)),
          const SizedBox(height: GzSpace.s6),
          ProtoShortcuts(
            codes: codes,
            onPick: (code) {
              setState(() {
                _typed = typedPart(code);
                _mode = _Mode.type;
              });
              _check(code);
            },
          ),
        ],
      );
      bottom = inType ? GzActionBar(action: GzActionBarAction(label: l.hotelBookingsCheckCode, disabled: !isComplete(_typed), onPressed: () => _check(fullCode(_typed)))) : null;
    }
    return GzScreen(
      top: top,
      bottom: bottom,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s3, bottom: GzSpace.section),
        child: body,
      ),
    );
  }
}
