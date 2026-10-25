// HL-VENU-06 Booking rules (web `HL-VENU-06.tsx`): how requests work under the voucher model: request to book only (read-only), the reply
// window, the fixed 24 hour confirm window (read-only), the minimum notice, the doors to voucher prices, visit availability and the calendar,
// and a live "What couples see" timeline. No instant booking, deposit, pay window, balance, cash or payout verification (ADR 0033).
// Requirements: HA-VMGT-10, HA-DASH-04, HA-AUTH-02, HA-VIS-05.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_core/ghazal_core.dart' show MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/venue_data.dart';
import 'widgets/rules_parts.dart';
import 'widgets/venue_bits.dart';

const List<int> kReplyWindows = <int>[12, 24, 48];

class HlVenu06Screen extends ConsumerStatefulWidget {
  const HlVenu06Screen({super.key});

  @override
  ConsumerState<HlVenu06Screen> createState() => _HlVenu06ScreenState();
}

class _HlVenu06ScreenState extends ConsumerState<HlVenu06Screen> {
  int? _hours;
  int? _notice;
  int _baseHours = 0;
  int _baseNotice = 2;
  String? _hall;

  bool get _dirty => _hours != null && (_hours != _baseHours || _notice != _baseNotice);

  void _seed(BookingRules r) {
    if (_hours != null) return;
    _hours = r.responseSlaHours;
    _baseHours = r.responseSlaHours;
    _notice = _baseNotice;
  }

  Future<void> _save(BookingRules rules) async {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final res = await ref
        .read(venueActionsProvider.notifier)
        .saveRules(BookingRules(responseSlaHours: _hours!, confirmWindowHours: rules.confirmWindowHours, visitsEnabled: rules.visitsEnabled));
    if (!mounted) return;
    toastResult(
      context,
      res,
      success: l.hotelVenueToastRulesSaved,
      then: (_) {
        _baseHours = _hours!;
        _baseNotice = _notice!;
        nav.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final nav = GzNavigatorScope.of(context);
    final value = ref.watch(venueRulesProvider);
    final rules = value.value;
    if (rules != null) _seed(rules);
    final venueName = ref.watch(partnerVenueProvider).value?.venue.name.of(context.gz.locale.languageCode);
    final saving = ref.watch(venueActionsProvider).busy.contains('save:rules');
    final notice = _notice ?? _baseNotice;
    final hours = _hours ?? _baseHours;
    final tooShort = _hours != null && notice * 24 < hours;
    final problem = tooShort ? l.hotelVenueNoticeShort : null;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await confirmDiscard(context, dirty: true) && context.mounted) nav.pop();
      },
      child: GzScreen(
        top: GzTopBar(title: l.hotelVenueRulesTitle, subtitle: venueName),
        bottom: (value.isLoading && rules == null) || value.hasError
            ? null
            : venueSaveBar(context, dirty: _dirty, problem: problem, saving: saving, onSave: () => _save(rules!)),
        child: GzAsyncView<BookingRules>(
          value: value,
          loading: const FormSkeleton(),
          onRetry: () => ref.invalidate(venueRulesProvider),
          data: (r) {
            String hoursText(int n) => context.l10n.commonCountHours(n);
            final sample = ref.watch(sampleBookingProvider).value;
            const exact = MoneyOptions(mode: MoneyMode.exact);
            final payText = sample == null
                ? null
                : l.hotelVenueTlPayText(f.money(sample.totals.voucherTotal.fils, exact), f.money(sample.totals.standardTotal.fils, exact));
            final shorter = hours < _baseHours;
            final halls = ref.watch(venueHallsProvider).value?.halls ?? const <Hall>[];
            final lang = context.gz.locale.languageCode;
            return VenuePage(
              children: [
                if (halls.length > 1)
                  GzSegmentedControl<String>(
                    label: l.hotelVenueRulesHall,
                    face: GzSegmentedFace.hall,
                    value: _hall ?? halls.first.id,
                    onChanged: (v) => setState(() => _hall = v),
                    options: [for (final h in halls) GzSegmentedOption<String>(value: h.id, label: h.name.of(lang))],
                  ),
                VenueSection(title: l.hotelVenueSecMode, children: const [BookingModeCard()]),
                VenueSection(
                  title: l.hotelVenueSecResponse,
                  children: [
                    GzChipGroup<int>(
                      label: l.hotelVenueRespondLabel,
                      value: hours,
                      onChanged: (v) => v == null ? null : setState(() => _hours = v),
                      options: [for (final h in kReplyWindows) GzChipOption<int>(value: h, label: hoursText(h))],
                    ),
                    if (shorter) FactLine(l.hotelVenueRespondWarn, icon: GzIcons.warningCircle),
                  ],
                ),
                VenueSection(
                  title: l.hotelVenueSecConfirm,
                  children: [
                    ReadOnlyRow(label: l.hotelVenueConfirmLabel, value: l.hotelVenueConfirmFixed(hoursText(r.confirmWindowHours)), last: true),
                    GzStepper(
                      label: l.hotelVenueNoticeDays,
                      value: notice,
                      min: 1,
                      max: 120,
                      onChanged: (v) => setState(() => _notice = v),
                      valueText: (n) => context.l10n.commonCountDays(n),
                    ),
                    if (tooShort) FactLine(l.hotelVenueNoticeShort, icon: GzIcons.warningCircle, danger: true),
                  ],
                ),
                VenueSection(
                  title: l.hotelVenueSecPreview,
                  children: [CouplesTimeline(replyHours: hoursText(hours), confirmHours: hoursText(r.confirmWindowHours), payText: payText)],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GzListRow(
                      flush: true,
                      leading: const GzIcon(GzIcons.ticket, size: GzIconSize.md),
                      title: l.hotelVenueLinkVoucher,
                      chevron: true,
                      onPressed: () => nav.push('HL-GROW-01'),
                    ),
                    GzListRow(
                      flush: true,
                      leading: const GzIcon(GzIcons.clock, size: GzIconSize.md),
                      title: l.hotelVenueLinkVisits,
                      chevron: true,
                      onPressed: () => nav.openSheet('HL-VIST-05'),
                    ),
                    GzListRow(
                      flush: true,
                      last: true,
                      leading: const GzIcon(GzIcons.calendar, size: GzIconSize.md),
                      title: l.hotelVenueLinkCalendar,
                      chevron: true,
                      onPressed: () => nav.switchTab('calendar'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
