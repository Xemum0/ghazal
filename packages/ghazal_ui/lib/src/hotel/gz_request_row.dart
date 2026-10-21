import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show NeedsYouRow, PartnerRequestRow, RequestItem, SlaReading, SlaState, TriageType;

import '../brand/brand.dart';
import '../core/core.dart';
import '../foundation.dart';
import 'hotel_bits.dart';

IconData _kindIcon(TriageType t) => switch (t) {
  TriageType.message => GzIcons.chat,
  TriageType.awaitingClient => GzIcons.hourglass,
  TriageType.visitRequest => GzIcons.calendarPlus,
  TriageType.reviewReply => GzIcons.star,
  TriageType.calendarConfirm => GzIcons.calendarCheck,
  _ => GzIcons.calendarDots,
};

/// RequestRow: the compact queue row (hotel queue row 80): who, which date and how many, what it is worth, and how long is left,
/// with the disclosure chevron. Requests lead with their text (no leading element); the other Needs-you items (a message, a client
/// who has not confirmed, a review waiting for a reply, the weekly calendar check, a visit request) lead with a quiet icon disk.
/// Time left is text with an icon in the SLA tone (neutral ink, gold from 50%, danger from 80% or under an hour), never colour
/// alone. Pass [request] for a pending request, or [item] with its [sla] for any other Needs-you row. Web `RequestRow`.
class GzRequestRow extends StatelessWidget {
  const GzRequestRow({
    this.request,
    this.item,
    this.sla,
    this.isNew = false,
    this.onPressed,
    this.last = false,
    this.flush = false,
    super.key,
  }) : assert(request != null || item != null, 'GzRequestRow needs a request or an item');

  /// A pending request: name, date, total and the SLA reading are derived from it.
  final PartnerRequestRow? request;

  /// Any other Needs-you item (message, awaiting client, review, calendar check, visit).
  final RequestItem? item;

  /// The SLA reading of [item] (its deadline), when it has one.
  final SlaReading? sla;

  /// A gold bead before the name: arrived since the last visit.
  final bool isNew;
  final VoidCallback? onPressed;
  final bool last;

  /// No own gutter: the row sits inside a panel that already pads.
  final bool flush;

  /// The row of a [NeedsYouRow] as the API returns it.
  factory GzRequestRow.fromNeedsYou(
    NeedsYouRow row, {
    bool isNew = false,
    VoidCallback? onPressed,
    bool last = false,
    bool flush = false,
    Key? key,
  }) => GzRequestRow(item: row.item, sla: row.sla, isNew: isNew, onPressed: onPressed, last: last, flush: flush, key: key);

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l = context.gzL10n;
    final lang = gz.locale.languageCode;
    final booking = request?.booking;
    final reading = request != null ? request!.sla : sla;
    final kind = request != null ? TriageType.request : item!.type;
    final name = booking != null ? booking.clientName : item!.title.of(lang);
    final subText = booking != null ? f.date(booking.eventDate.toString(), DateStyle.short) : item?.subtitle?.of(lang);
    final live = reading != null && reading.state != SlaState.expired ? gzTimeLeft(f, l, reading.minutesLeft) : null;
    final left = reading == null ? null : (live != null ? live.visual : l.commonStatusHotelMissed);
    final leftName = reading == null ? null : (live != null ? l.uiHotelTimeLeft(live.spoken) : l.commonStatusHotelMissed);
    final leftColor = switch (reading?.state) {
      SlaState.gold => c.textGoldInk,
      SlaState.danger => c.textDanger,
      _ => c.textSecondary,
    };

    Widget row(bool pressed) => Container(
      constraints: const BoxConstraints(minHeight: GzSize.rowQueue),
      padding: EdgeInsetsDirectional.only(
        start: flush ? 0 : GzSpace.gutter,
        end: flush ? 0 : GzSpace.gutter,
        top: GzSpace.s3,
        bottom: GzSpace.s3,
      ),
      decoration: BoxDecoration(
        color: pressed ? c.surfaceQuiet : null,
        borderRadius: onPressed != null ? GzRadius.smAll : null,
        border: Border(
          bottom: BorderSide(color: last ? c.scrimClear : c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (kind != TriageType.request) ...[
            ExcludeSemantics(
              child: Container(
                width: GzSize.avatarSm,
                height: GzSize.avatarSm,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceQuiet),
                child: GzIcon(_kindIcon(kind), size: GzIconSize.sm, color: c.iconPrimary),
              ),
            ),
            const SizedBox(width: GzSpace.s4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (isNew) ...[const GzThreadBead(), const SizedBox(width: GzSpace.s2)],
                    Expanded(
                      child: GzUserText(name, role: GzTextRole.title, color: c.textStrong, maxLines: 2),
                    ),
                  ],
                ),
                if (subText != null && subText.isNotEmpty) GzText(subText, role: GzTextRole.caption, color: c.textSecondary, figures: true),
              ],
            ),
          ),
          if (booking != null || left != null) ...[
            const SizedBox(width: GzSpace.s4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (booking != null)
                  GzMoney(fils: booking.totals.voucherTotal.fils, amountRole: GzTextRole.priceStrong, filsRole: GzTextRole.priceStrong),
                if (booking != null && left != null) const SizedBox(height: GzSpace.s1),
                if (left != null)
                  ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GzIcon(GzIcons.clock, size: GzIconSize.xs, color: leftColor),
                        const SizedBox(width: GzSpace.s1),
                        GzText(left, role: GzTextRole.caption, color: leftColor, figures: true, softWrap: false),
                      ],
                    ),
                  ),
              ],
            ),
          ] else
            // The web ListRow always renders its (empty) trailing slot, so its gap still counts.
            const SizedBox(width: GzSpace.s4),
          const SizedBox(width: GzSpace.s4),
          GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
        ],
      ),
    );

    final label = [name, ?subText, ?leftName].join(', ');
    return GzPressable(
      onPressed: onPressed ?? () {},
      semanticLabel: label,
      borderRadius: GzRadius.smAll,
      scale: 1,
      minHeight: 0,
      builder: (context, st) => row(st.pressed),
    );
  }
}
