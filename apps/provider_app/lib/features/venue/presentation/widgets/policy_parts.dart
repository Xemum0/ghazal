// The pieces of the policies screen (web `PolicyParts.tsx`): the voucher terms Ghazal sets (read only), the opening-hours rows and the sheet that
// edits one set of days. Times and day names come from the formatter.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show MoneyMode, MoneyOptions, NameStyle;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import 'venue_bits.dart';
import 'venue_fields.dart';

/// `Sun to Thu` for a run of days, else the list (`Fri and Sat`).
String daysLabel(BuildContext context, List<int> days) {
  final f = context.gzFormat;
  final sorted = [...days]..sort();
  if (sorted.isEmpty) return '';
  final run = sorted.length > 2 && sorted.last - sorted.first == sorted.length - 1;
  String name(int d) => f.weekdayName(d, NameStyle.short);
  return run ? context.l10n.hotelVenueHoursRun(name(sorted.first), name(sorted.last)) : f.list(sorted.map(name).toList());
}

/// What Ghazal sets for every voucher, stated beside the venue's own terms. Configuration, never typed.
class VoucherTerms extends StatelessWidget {
  const VoucherTerms({required this.config, super.key});

  final PlatformConfig? config;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final cfg = config;
    return Container(
      padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
      decoration: BoxDecoration(color: c.surfaceTint, borderRadius: GzRadius.mdAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GzIcon(GzIcons.ticket, size: GzIconSize.sm, color: c.iconSecondary),
              const SizedBox(width: GzSpace.s2),
              Expanded(
                child: GzText(l.hotelVenueVoucherTermsTitle, role: GzTextRole.title, color: c.textStrong),
              ),
            ],
          ),
          const SizedBox(height: GzSpace.s3),
          if (cfg != null) ...[
            ReadOnlyRow(
              label: l.hotelVenueVtFee,
              value: f.money(cfg.voucherFeeFils, const MoneyOptions(mode: MoneyMode.browse)),
            ),
            ReadOnlyRow(label: l.hotelVenueVtValidity, value: l.commonCountDays(cfg.voucherValidityDays)),
            ReadOnlyRow(label: l.hotelVenueVtConfirm, value: l.commonCountHours(cfg.confirmWindowHours)),
            ReadOnlyRow(label: l.hotelVenueVtRedeem, value: l.hotelVenueVtRedeemValue, last: true),
          ],
        ],
      ),
    );
  }
}

/// One set of days with its hours; tapping opens the sheet.
class HoursRow extends StatelessWidget {
  const HoursRow({required this.rule, required this.onOpen, super.key});

  final HoursRule rule;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final days = daysLabel(context, rule.days);
    final line = l.hotelVenueHoursLine(kuwaitTime(f, rule.open.toString()), kuwaitTime(f, rule.close.toString()));
    return GzPressable(
      onPressed: onOpen,
      semanticLabel: '$days, $line',
      minHeight: GzSize.rowMin,
      child: Container(
        constraints: const BoxConstraints(minHeight: GzSize.rowMin),
        padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GzText(days, role: GzTextRole.title, color: c.textPrimary),
                  const SizedBox(height: GzSpace.s1),
                  GzText(line, role: GzTextRole.bodyS, color: c.textSecondary, figures: true),
                ],
              ),
            ),
            const SizedBox(width: GzSpace.s3),
            GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary, mirror: true),
          ],
        ),
      ),
    );
  }
}

/// The sheet that edits the opening and closing time of one set of days.
class HoursSheet extends StatefulWidget {
  const HoursSheet({required this.rule, required this.onSave, super.key});

  final HoursRule rule;
  final ValueChanged<HoursRule> onSave;

  @override
  State<HoursSheet> createState() => _HoursSheetState();
}

class _HoursSheetState extends State<HoursSheet> {
  late String _open = widget.rule.open.toString();
  late String _close = widget.rule.close.toString();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final nav = GzNavigatorScope.of(context);
    final slots = [for (final t in kTimeSlots) GzSelectOption<String>(value: t, label: kuwaitTime(f, t))];
    return SheetColumn(
      footer: GzButton(
        label: l.commonActionSave,
        fullWidth: true,
        onPressed: () {
          widget.onSave(HoursRule(days: widget.rule.days, open: LocalTime.parse(_open), close: LocalTime.parse(_close)));
          nav.closeSheet();
        },
      ),
      children: [
        GzText(daysLabel(context, widget.rule.days), role: GzTextRole.body, color: context.gz.colors.textStrong),
        PickRow<String>(label: l.hotelVenueHoursOpen, value: _open, options: slots, onChanged: (v) => setState(() => _open = v)),
        PickRow<String>(
          label: l.hotelVenueHoursClose,
          value: _close,
          options: slots,
          onChanged: (v) => setState(() => _close = v),
          helper: _close.compareTo(_open) <= 0 ? l.hotelVenueSessionAfterMidnight : null,
        ),
      ],
    );
  }
}
