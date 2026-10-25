// Agenda (web `Agenda.tsx`): what the chosen day carries, under the month grid (HL-CALN-01). The heading is the date and it opens the Day view.
// One row per hall (64 minimum): the client as a monogram, the name and the one-word state pill on the first line, the facts as glyph and value
// under it. A held row adds the time left, a blocked row its reason, a free row the hall and Block. A booked row opens the booking, a blocked row
// the Open variant of the block sheet. Under the rows: the requests as a bead and a count (they claim nothing) and the day's own actions.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show Audience, BlockReason, CalendarClaim, Hall, StaffRole;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/calendar_data.dart';
import 'calendar_chrome.dart';

IconData audienceGlyph(Audience? a) => switch (a) {
  Audience.men => GzIcons.sectionMen,
  Audience.mixed => GzIcons.sectionMixed,
  _ => GzIcons.sectionWomen,
};

String audienceName(AppL10n l, Audience? a) => switch (a) {
  Audience.men => l.hotelCalendarAudienceMen,
  Audience.mixed => l.hotelCalendarAudienceMixed,
  _ => l.hotelCalendarAudienceWomen,
};

/// The session of the day as a glyph, by its start hour: sun (day), sunset (afternoon), moon (evening).
IconData sessionGlyph(String? start) {
  final h = int.tryParse((start ?? '21:00').split(':').first) ?? 21;
  return h < 15 ? GzIcons.sun : (h < 18 ? GzIcons.sunset : GzIcons.moon);
}

String reasonWord(AppL10n l, BlockReason? r) => switch (r) {
  BlockReason.maintenance => l.hotelCalendarReasonMaintenance,
  BlockReason.privateEvent => l.hotelCalendarReasonPrivate,
  BlockReason.other => l.hotelCalendarReasonOther,
  _ => l.hotelCalendarReasonOffline,
};

/// The leading disk of a row without a client: a glyph on the tint.
class CalDisk extends StatelessWidget {
  const CalDisk({required this.icon, this.secondary = false, super.key});

  final IconData icon;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(width: GzSize.avatarSm, height: GzSize.avatarSm, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint), child: GzIcon(icon, size: GzIconSize.md, color: secondary ? c.iconSecondary : c.iconPrimary));
  }
}

/// A compact time left (`3 h`): the largest unit only (the formatter joins the units with a plain space and keeps each number and unit together).
String leadMinutes(BuildContext context, int minutes) => context.gzFormat.duration(minutes.clamp(1, 1 << 30) * 60000).split(' ').first;

String leftLead(BuildContext context, DateTime until, DateTime now) => leadMinutes(context, until.difference(now).inMinutes);

class _Row extends StatelessWidget {
  const _Row({required this.leading, required this.title, this.userTitle = false, this.status, this.facts, this.trailing, this.onPressed, this.last = false});

  final Widget leading;
  final String title;
  final bool userTitle;
  final Widget? status;
  final Widget? facts;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final row = Container(
      constraints: const BoxConstraints(minHeight: GzSize.rowMin),
      padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: last ? c.borderHairline.withAlpha(0) : c.borderHairline, width: GzStroke.hair))),
      child: Row(
        children: [
          leading,
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: userTitle ? GzUserText(title, role: GzTextRole.title, color: c.textStrong, maxLines: 1) : GzText(title, role: GzTextRole.title, color: c.textStrong, maxLines: 1)),
                    if (status != null) ...[const SizedBox(width: GzSpace.s2), status!],
                  ],
                ),
                if (facts != null) ...[const SizedBox(height: GzSpace.s1), facts!],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: GzSpace.s3), trailing!],
          if (onPressed != null) ...[const SizedBox(width: GzSpace.s3), GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary)],
        ],
      ),
    );
    if (onPressed == null) return row;
    return GzPressable(onPressed: onPressed, borderRadius: GzRadius.smAll, scale: 1, minHeight: GzSize.rowMin, expand: true, child: row);
  }
}

class CalAgenda extends StatelessWidget {
  const CalAgenda({required this.date, required this.halls, required this.claims, required this.role, required this.today, required this.now, required this.offline, required this.onBlock, required this.onOpenDates, super.key});

  final String date;
  final List<Hall> halls;
  final List<CalendarClaim> claims;
  final StaffRole role;
  final String today;
  final DateTime now;
  final bool offline;
  final void Function(String? hallId) onBlock;
  final VoidCallback onOpenDates;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final nav = GzNavigatorScope.of(context);
    final short = shortHall(halls, lang);
    final past = date.compareTo(today) < 0;
    final mine = [for (final h in halls) (hall: h, claim: claimOf(claims, date, h.id))];
    final requests = requestsOn(claims, date, [for (final h in halls) h.id]);
    final sold = isSoldOut(claims, date, halls);
    final blocked = isFullyBlocked(claims, date, halls);
    final someFree = mine.any((m) => m.claim == null);
    final may = canBlock(role) && !past;
    final offerable = canOffer(role) && someFree && !blocked && !past;

    Widget? hallFact(Hall h) => halls.length > 1 ? GzFactChip(icon: GzIcons.hall, label: l.hotelCalendarHallFact, value: short(h.id)) : null;

    Widget factsOf(Hall h, CalendarClaim cl, GzLaneMark mark) => GzFactRow(
      children: [
        ?hallFact(h),
        if (cl.guests != null && cl.guests! > 0) GzFactChip(icon: GzIcons.usersThree, label: l.hotelCalendarGuestsFact, value: f.integer(cl.guests!)),
        GzFactChip(icon: sessionGlyph(cl.start?.toString() ?? h.sessions.firstOrNull?.start.toString()), label: l.hotelCalendarSessionFact),
        if (cl.audience != null) GzFactChip(icon: audienceGlyph(cl.audience), label: audienceName(l, cl.audience)),
        if (mark == GzLaneMark.held && cl.holdUntil != null) GzFactChip(icon: GzIcons.timer, tone: GzFactTone.accent, label: l.hotelCalendarHoldLeft, value: leftLead(context, cl.holdUntil!, now)),
      ],
    );

    final rows = <Widget>[];
    for (var i = 0; i < mine.length; i++) {
      final h = mine[i].hall;
      final cl = mine[i].claim;
      final mark = markOf(cl);
      final last = i == mine.length - 1 && requests == 0;
      if (cl != null && (mark == GzLaneMark.booked || mark == GzLaneMark.held)) {
        rows.add(
          _Row(
            last: last,
            leading: cl.clientName != null ? GzAvatar(name: cl.clientName!, size: GzAvatarSize.sm, voice: GzAvatarVoice.sans) : const CalDisk(icon: GzIcons.hall),
            title: cl.clientName ?? short(h.id),
            userTitle: cl.clientName != null,
            status: GzStatusPill(status: mark == GzLaneMark.booked ? GzStatus.confirmed : GzStatus.held, audience: GzStatusAudience.hotel),
            facts: factsOf(h, cl, mark!),
            onPressed: cl.bookingId == null ? null : () => nav.push('HL-BOOK-03', params: <String, Object?>{'bookingId': cl.bookingId}),
          ),
        );
      } else if (cl != null) {
        rows.add(
          _Row(
            last: last,
            leading: const CalDisk(icon: GzIcons.lock),
            title: reasonWord(l, cl.blockReason),
            status: const GzStatusPill(status: GzStatus.blocked, audience: GzStatusAudience.hotel),
            facts: GzFactRow(children: [?hallFact(h)]),
            onPressed: may ? onOpenDates : null,
          ),
        );
      } else {
        rows.add(
          _Row(
            last: last,
            leading: CalDisk(icon: past ? GzIcons.calendar : GzIcons.door, secondary: true),
            title: short(h.id),
            status: past ? const GzStatusPill(status: GzStatus.past) : GzText(l.hotelCalendarOpenLabel, role: GzTextRole.caption, color: c.textSecondary),
            trailing: !past && may ? GzButton(label: l.hotelCalendarBlock, variant: GzButtonVariant.tertiary, iconStart: GzIcons.lock, onPressed: offline ? null : () => onBlock(h.id)) : null,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzPressable(
          onPressed: () => nav.push('HL-CALN-03', params: <String, Object?>{'date': date}),
          semanticLabel: '${l.hotelCalendarAgendaTitle(f.date(date, DateStyle.short))}. ${l.hotelCalendarOpenDay}',
          borderRadius: GzRadius.smAll,
          scale: 1,
          expand: true,
          child: Row(
            children: [
              Expanded(child: GzText(f.date(date, DateStyle.short), role: GzTextRole.uiTitle, color: c.textStrong, figures: true)),
              GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
            ],
          ),
        ),
        const SizedBox(height: GzSpace.s2),
        Container(decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))), child: Column(children: rows)),
        if (requests > 0)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSpace.s12),
            child: Row(children: [const GzThreadBead(), const SizedBox(width: GzSpace.s2), GzText(l.hotelCalendarRequestedLabel, role: GzTextRole.bodyS, color: c.textPrimary), const SizedBox(width: GzSpace.s2), GzText(f.integer(requests), role: GzTextRole.figBodyS, color: c.textPrimary, figures: true)]),
          ),
        if (!past && ((may && blocked) || (may && sold) || offerable)) ...[
          const SizedBox(height: GzSpace.s2),
          Wrap(
            spacing: GzSpace.s5,
            runSpacing: GzSpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (may && blocked) GzButton(label: l.hotelCalendarOpenThisDate, variant: GzButtonVariant.secondary, iconStart: GzIcons.lock, onPressed: offline ? null : onOpenDates),
              if (may && sold)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GzButton(label: l.hotelCalendarBlock, variant: GzButtonVariant.secondary, iconStart: GzIcons.lock),
                    const SizedBox(width: GzSpace.s1),
                    GzInfoButton(title: l.hotelCalendarWhyTitle, paragraphs: [l.hotelCalendarSoldOutReason]),
                  ],
                ),
              if (offerable) GzButton(label: l.hotelCalendarOffer, variant: GzButtonVariant.tertiary, iconStart: GzIcons.offer, onPressed: offline ? null : () => nav.push('HL-GROW-02', params: <String, Object?>{'date': date})),
            ],
          ),
        ],
      ],
    );
  }
}
