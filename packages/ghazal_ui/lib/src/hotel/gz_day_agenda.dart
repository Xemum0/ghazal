import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show CalendarClaim, ClaimKind, Hall;

import '../brand/brand.dart';
import '../core/core.dart';
import '../foundation.dart';
import 'hotel_bits.dart';
import 'hotel_calendar_model.dart';

/// The agenda strip under the month grid for the selected day (web `DayAgenda`, ADR 0008 D9). One row per hall (64 minimum): the hall,
/// what it carries as a status pill (booked, on hold with its deadline, blocked with its reason, open) and the facts that matter (guest,
/// guests, session; the hold deadline; who blocked it). A booked row opens the booking; an open row offers Block (3 taps from anywhere,
/// ADR 0008 D9). Pending requests for the date are a count, never identities.
class GzDayAgenda extends StatelessWidget {
  const GzDayAgenda({required this.date, required this.halls, required this.claims, this.onOpenBooking, this.onBlock, super.key});

  /// `YYYY-MM-DD`.
  final String date;
  final List<Hall> halls;
  final List<CalendarClaim> claims;
  final ValueChanged<String>? onOpenBooking;
  final ValueChanged<String>? onBlock;

  /// Up to two caption lines per claim: who and how many, then when; the hold deadline; the reason and who blocked it.
  Widget _lines(BuildContext context, CalendarClaim c) {
    final gz = context.gz;
    final col = gz.colors;
    final f = context.gzFormat;
    final l = context.gzL10n;
    final lang = gz.locale.languageCode;
    final rows = <Widget>[];
    if (c.kind == ClaimKind.booking) {
      final who = c.clientName;
      rows.add(GzClaimWho(name: who, guests: f.guests(c.guests ?? 0), color: col.textSecondary));
      if (c.start != null && c.end != null) {
        rows.add(
          GzText(
            gzTimeRangeText(f, date, c.start.toString(), c.end.toString()),
            role: GzTextRole.caption,
            color: col.textSecondary,
            figures: true,
          ),
        );
      }
    } else if (c.kind == ClaimKind.hold) {
      rows.add(
        GzText(
          c.holdUntil != null ? l.uiHotelCalHoldUntil(f.dateTime(c.holdUntil!)) : '',
          role: GzTextRole.caption,
          color: col.textSecondary,
          figures: true,
        ),
      );
    } else {
      final reason = gzBlockReasonWord(l, c.blockReason);
      final note = c.blockNote?.of(lang) ?? '';
      rows.add(
        GzText(
          [reason, if (note.isNotEmpty && note != reason) note].join(' · '),
          role: GzTextRole.caption,
          color: col.textSecondary,
          figures: true,
        ),
      );
      if (c.blockedBy != null) rows.add(GzText(l.uiHotelCalBy(c.blockedBy!), role: GzTextRole.caption, color: col.textSecondary));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: rows);
  }

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l = context.gzL10n;
    final lang = gz.locale.languageCode;
    final requests = gzRequestsOf(claims, date);
    return Semantics(
      container: true,
      label: l.uiHotelCalAgenda(f.plain(f.date(date, DateStyle.short))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // The figures voice has taller metrics than the title face: the strut keeps the line at the role's own height.
          Builder(
            builder: (context) {
              final style = gz.text(GzTextRole.uiTitle).copyWith(color: c.textStrong, decoration: TextDecoration.none);
              return Semantics(
                header: true,
                child: Text.rich(
                  TextSpan(children: GzFigures.spans(context, f.date(date, DateStyle.full), role: GzTextRole.uiTitle)),
                  style: style,
                  strutStyle: StrutStyle.fromTextStyle(style, forceStrutHeight: true),
                ),
              );
            },
          ),
          const SizedBox(height: GzSpace.s2),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < halls.length; i++)
                  () {
                    final h = halls[i];
                    final claim = gzClaimOf(claims, date, h.id);
                    final booking = claim?.kind == ClaimKind.booking;
                    return GzListRow(
                      flush: true,
                      last: i == halls.length - 1 && requests == 0,
                      title: h.name.of(lang),
                      subtitle: claim == null ? l.uiHotelCalOpen : null,
                      subtitleWidget: claim == null ? null : _lines(context, claim),
                      chevron: booking,
                      onPressed: booking && claim!.bookingId != null ? () => onOpenBooking?.call(claim.bookingId!) : null,
                      trailing: claim != null
                          ? GzStatusPill(
                              status: claim.kind == ClaimKind.booking
                                  ? GzStatus.confirmed
                                  : (claim.kind == ClaimKind.hold ? GzStatus.held : GzStatus.blocked),
                              audience: GzStatusAudience.hotel,
                            )
                          : GzButton(
                              label: l.uiHotelCalBlock,
                              variant: GzButtonVariant.tertiary,
                              iconStart: GzIcons.lock,
                              onPressed: () => onBlock?.call(h.id),
                            ),
                    );
                  }(),
                if (requests > 0)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: GzSpace.s12),
                    child: Row(
                      children: [
                        const GzThreadBead(),
                        const SizedBox(width: GzSpace.s2),
                        Expanded(
                          child: GzText(l.uiHotelCalRequests(requests), role: GzTextRole.caption, color: c.textPrimary, figures: true),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
