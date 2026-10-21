import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';
import '../inputs/inputs.dart';

/// Where a voucher-price window stands.
enum GzValidityStatus { scheduled, active, ended }

/// The windows a time-boxed price can run for, in hours.
const List<int> gzValidityWindows = [6, 12, 24, 48];

/// ValidityRange: step 2 of the voucher-price window editor (HL-GROW-03): when the voucher price applies and when it runs. The event
/// dates are a range picked in the shared date field (the screen opens the calendar sheet from [onDatesTap]; never the native
/// picker); a time-boxed window also takes a duration chip (6 / 12 / 24 / 48 hours) that resolves to an absolute end time, shown as
/// a line under it; the status says whether the window is Scheduled, Active or Ended with a pill (icon + label). Times are absolute
/// and in Kuwait time; nothing counts down for couples.
class GzValidityRange extends StatelessWidget {
  const GzValidityRange({
    required this.value,
    this.onDatesTap,
    this.datesOpen = false,
    this.windowHours,
    this.onWindowChange,
    this.endsAt,
    this.startsAt,
    this.status,
    this.error,
    super.key,
  });

  /// The event dates the offer covers.
  final GzDateRange value;

  /// Opens the date range sheet (null disables the field).
  final VoidCallback? onDatesTap;
  final bool datesOpen;

  /// Flash sale only: the window in hours (6, 12, 24, 48) and the absolute end it resolves to.
  final int? windowHours;
  final ValueChanged<int>? onWindowChange;
  final DateTime? endsAt;
  final DateTime? startsAt;
  final GzValidityStatus? status;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final line = status == GzValidityStatus.scheduled && startsAt != null
        ? l.uiHotelValidityStarts(f.dateTime(startsAt!))
        : endsAt != null
        ? l.uiHotelValidityEnds(f.dateTime(endsAt!))
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GzDateField.range(
          value: value,
          label: l.uiHotelValidityEventDates,
          helper: l.uiHotelValidityHelper,
          error: error,
          open: datesOpen,
          onTap: onDatesTap,
        ),
        if (windowHours != null) ...[
          const SizedBox(height: GzSpace.s4),
          GzText(l.uiHotelValidityWindow, role: GzTextRole.label, color: c.textPrimary),
          const SizedBox(height: GzSpace.s2),
          GzChipGroup<int>(
            label: l.uiHotelValidityWindow,
            value: windowHours,
            onChanged: (v) {
              if (v != null) onWindowChange?.call(v);
            },
            options: [for (final h in gzValidityWindows) GzChipOption<int>(value: h, label: l.uiHotelValidityHours(f.integer(h)))],
          ),
        ],
        if (status != null || endsAt != null) ...[
          const SizedBox(height: GzSpace.s4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: GzSpace.s3,
            runSpacing: GzSpace.s2,
            children: [
              if (status != null)
                GzStatusPill(
                  status: switch (status!) {
                    GzValidityStatus.active => GzStatus.confirmed,
                    GzValidityStatus.scheduled => GzStatus.requested,
                    GzValidityStatus.ended => GzStatus.expired,
                  },
                  label: switch (status!) {
                    GzValidityStatus.active => l.uiHotelValidityActive,
                    GzValidityStatus.scheduled => l.uiHotelValidityScheduled,
                    GzValidityStatus.ended => l.uiHotelValidityEnded,
                  },
                ),
              GzText(line, figures: true, role: GzTextRole.caption, color: c.textSecondary),
            ],
          ),
        ],
      ],
    );
  }
}
