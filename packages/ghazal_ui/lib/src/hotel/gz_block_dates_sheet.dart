import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show BlockReason, CalendarClaim, Hall, Occasion;

import '../core/core.dart';
import '../foundation.dart';
import '../inputs/gz_calendar_model.dart';
import '../inputs/gz_chip_group.dart';
import '../overlays/gz_sheet.dart';
import 'gz_drag_affordance.dart';
import 'gz_hotel_month_grid.dart';

/// Where the sheet is drawn. `overlay`: the content of a sheet the caller opens with `showGzSheet(title: ..., builder: ...)` (the action
/// bar pins itself under the body of that sheet). `inline`: the sheet panel itself, in place (the gallery, a static frame).
enum GzBlockDatesPlacement { overlay, inline }

/// What the action bar hands back: the dates, the reason and the halls the block applies to.
class GzBlockDatesValue {
  const GzBlockDatesValue({required this.range, required this.reason, required this.hallIds});

  final GzDateRange range;
  final BlockReason reason;
  final List<String> hallIds;
}

const List<BlockReason> _reasons = [BlockReason.offlineBooking, BlockReason.maintenance, BlockReason.privateEvent, BlockReason.other];

/// Block (or open) a range of dates in three taps or fewer from anywhere (web `BlockDatesSheet`, ADR 0008 D9). The sheet carries the
/// hint ([GzDragAffordance]), the month grid in select mode (press-hold-drag or tap start and end; booked-out and past days refuse),
/// the Ramadan / Eid shortcuts as adjustable ranges (never fixed dates: they are approximate until announced, ADR 0011), the reason
/// (Booked offline by default, an offline sale carries no payment and no commission), the scope by hall, and the action bar: `N dates`
/// with ONE gold primary (Block) and equal-weight Open and Offer. A confirmed booking cannot be blocked over, so those days are not
/// selectable. The range is controlled ([value] with [onChanged]) or starts empty.
class GzBlockDatesSheet extends StatefulWidget {
  const GzBlockDatesSheet({
    required this.halls,
    required this.claims,
    this.occasions = const [],
    this.placement = GzBlockDatesPlacement.overlay,
    this.value,
    this.onChanged,
    this.onRequestClose,
    this.onBlock,
    this.onOpenDates,
    this.onOffer,
    this.defaultMonth,
    this.today,
    super.key,
  });

  final List<Hall> halls;
  final List<CalendarClaim> claims;

  /// The platform's occasions; the Ramadan and Eid ones (at most three) become shortcut chips.
  final List<Occasion> occasions;
  final GzBlockDatesPlacement placement;
  final GzDateRange? value;
  final ValueChanged<GzDateRange>? onChanged;
  final VoidCallback? onRequestClose;
  final ValueChanged<GzBlockDatesValue>? onBlock;
  final ValueChanged<GzBlockDatesValue>? onOpenDates;
  final ValueChanged<GzDateRange>? onOffer;

  /// Initial month shown.
  final GzYm? defaultMonth;
  final String? today;

  @override
  State<GzBlockDatesSheet> createState() => _GzBlockDatesSheetState();
}

class _GzBlockDatesSheetState extends State<GzBlockDatesSheet> {
  GzDateRange _inner = GzDateRange.empty;
  BlockReason _reason = BlockReason.offlineBooking;
  late List<String> _hallIds = [for (final h in widget.halls) h.id];

  GzDateRange get _range => widget.value ?? _inner;

  void _setRange(GzDateRange r) {
    if (widget.value == null) setState(() => _inner = r);
    widget.onChanged?.call(r);
  }

  List<String> get _dates {
    final r = _range;
    if (r.start == null) return const [];
    final e = r.end ?? r.start!;
    return r.start!.compareTo(e) <= 0 ? gzEachDay(r.start!, e) : gzEachDay(e, r.start!);
  }

  GzBlockDatesValue get _value => GzBlockDatesValue(range: _range, reason: _reason, hallIds: _hallIds);

  Widget _group(BuildContext context, String label, Widget chips) {
    final c = context.gz.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzText(label, role: GzTextRole.label, color: c.textPrimary),
        const SizedBox(height: GzSpace.s2),
        chips,
      ],
    );
  }

  Widget _bar(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final count = _dates.length;
    final none = count == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: GzFigures.spans(context, none ? l.uiHotelCalSheetNone : l.uiHotelCalSheetDates(count), role: GzTextRole.bodyS),
          ),
          style: gz
              .text(GzTextRole.bodyS)
              .copyWith(color: c.textStrong, fontWeight: gz.text(GzTextRole.title).fontWeight, decoration: TextDecoration.none),
        ),
        const SizedBox(height: GzSpace.s3),
        GzButton(
          label: l.uiHotelCalBlock,
          size: GzButtonSize.cta,
          fullWidth: true,
          onPressed: none ? null : () => widget.onBlock?.call(_value),
        ),
        const SizedBox(height: GzSpace.s3),
        Row(
          children: [
            Expanded(
              child: GzButton(
                label: l.uiHotelCalSheetOpen,
                variant: GzButtonVariant.secondary,
                fullWidth: true,
                onPressed: none ? null : () => widget.onOpenDates?.call(_value),
              ),
            ),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: GzButton(
                label: l.uiHotelCalSheetOffer,
                variant: GzButtonVariant.secondary,
                fullWidth: true,
                onPressed: none ? null : () => widget.onOffer?.call(_range),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final lang = context.gz.locale.languageCode;
    final shortcuts = [
      for (final o in widget.occasions)
        if (o.id == 'ramadan-1448' || o.id.startsWith('eid')) o,
    ].take(3).toList();
    final reasonLabels = {
      BlockReason.offlineBooking: l.uiHotelCalReasonOfflineBooking,
      BlockReason.maintenance: l.uiHotelCalReasonMaintenance,
      BlockReason.privateEvent: l.uiHotelCalReasonPrivateEvent,
      BlockReason.other: l.uiHotelCalReasonOther,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const GzDragAffordance(),
        const SizedBox(height: GzSpace.s4),
        GzHotelMonthGrid(
          halls: widget.halls,
          claims: widget.claims,
          mode: GzHotelMonthMode.select,
          range: _range,
          onRangeChange: _setRange,
          legend: false,
          label: l.uiHotelCalSheetGrid,
          defaultMonth: widget.defaultMonth,
          today: widget.today,
        ),
        if (shortcuts.isNotEmpty) ...[
          const SizedBox(height: GzSpace.s4),
          _group(
            context,
            l.uiHotelCalSheetShortcuts,
            GzChipGroup<String>(
              label: l.uiHotelCalSheetShortcuts,
              deselectable: true,
              options: [for (final o in shortcuts) GzChipOption(value: o.id, label: o.name.of(lang))],
              onChanged: (id) {
                for (final o in shortcuts) {
                  if (o.id == id) _setRange(GzDateRange(start: o.from.toString(), end: o.to.toString()));
                }
              },
            ),
          ),
        ],
        const SizedBox(height: GzSpace.s4),
        _group(
          context,
          l.uiHotelCalSheetReason,
          GzChipGroup<BlockReason>(
            label: l.uiHotelCalSheetReason,
            value: _reason,
            onChanged: (v) {
              if (v != null) setState(() => _reason = v);
            },
            options: [for (final r in _reasons) GzChipOption(value: r, label: reasonLabels[r]!)],
          ),
        ),
        if (widget.halls.length > 1) ...[
          const SizedBox(height: GzSpace.s4),
          _group(
            context,
            l.uiHotelCalSheetHalls,
            GzChipGroup<String>.multiple(
              label: l.uiHotelCalSheetHalls,
              values: _hallIds,
              onChanged: (v) => setState(() => _hallIds = v),
              options: [for (final h in widget.halls) GzChipOption(value: h.id, label: h.name.of(lang))],
            ),
          ),
        ],
        const SizedBox(height: GzSpace.s4),
        GzText(l.uiHotelCalSheetNote, role: GzTextRole.caption, color: c.textSecondary),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _body(context);
    if (widget.placement == GzBlockDatesPlacement.inline) {
      return GzSheet(title: context.gzL10n.uiHotelCalSheetTitle, footer: _bar(context), onRequestClose: widget.onRequestClose, child: body);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        GzSheetFooter(child: _bar(context)),
      ],
    );
  }
}
