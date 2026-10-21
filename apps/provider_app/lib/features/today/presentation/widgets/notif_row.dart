// NotifRow: one notification of the partner list (web `NotifRow.tsx`, HA-NOTI-01..07, ADR 0008 D13). The glyph in the disk is the kind, the name
// is the title, the facts are the day and the guests (a notification row is a fragment, the icon says what kind). Absolute times only (ADR 0011
// D7): the group header carries the day, the row carries the clock. Unread = a strong name and an ink dot (never gold: a dot is not a verb). A new
// booking request is the one row that stands out: its glyph sits on a gold disk and, while it is pending, the time left follows its facts.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, DecimalOptions;
import 'package:ghazal_domain/ghazal_domain.dart' show AppNotification, NotificationKind, NotificationTone, SlaState;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/today_data.dart';
import 'today_bits.dart';

IconData _kindIcon(NotificationKind k) => switch (k) {
  NotificationKind.newRequest => GzIcons.bell,
  NotificationKind.clientConfirmed => GzIcons.checkCircle,
  NotificationKind.clientLapsed => GzIcons.hourglass,
  NotificationKind.bookingCancelled => GzIcons.xCircle,
  NotificationKind.voucherRedeemedByYou => GzIcons.ticket,
  NotificationKind.visitRequest => GzIcons.calendarPlus,
  NotificationKind.visitMessage => GzIcons.usersThree,
  NotificationKind.message => GzIcons.chat,
  NotificationKind.listingSubmitted || NotificationKind.listingApproved || NotificationKind.listingRejected => GzIcons.megaphone,
  NotificationKind.listingExpiring => GzIcons.clock,
  NotificationKind.reviewReceived => GzIcons.star,
  NotificationKind.calendarConfirm => GzIcons.calendarCheck,
  NotificationKind.invite => GzIcons.userPlus,
  _ => GzIcons.bell,
};

GzStatus? _listingStatus(NotificationKind k) => switch (k) {
  NotificationKind.listingSubmitted => GzStatus.listingReview,
  NotificationKind.listingApproved => GzStatus.listingApproved,
  NotificationKind.listingRejected => GzStatus.listingRejected,
  _ => null,
};

class NotifRow extends ConsumerWidget {
  const NotifRow({required this.notification, this.onOpen, this.last = false, this.disabled = false, super.key});

  final AppNotification notification;
  final VoidCallback? onOpen;
  final bool last;
  final bool disabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final n = notification;
    final unread = !n.read;
    final p = n.params;
    final person = (p['client'] ?? p['reviewer'] ?? p['staff']) as String?;
    final name = person ?? n.title.of(lang);
    final isRequest = n.kind == NotificationKind.newRequest;
    final rows = isRequest ? ref.watch(requestRowsProvider).value : null;
    final bookingKey = n.bookingId;
    final request = (bookingKey == null || rows == null) ? null : rows[bookingKey];
    final reading = isRequest ? request?.sla : null;
    final disk = isRequest ? c.statusPendingBg : (n.tone == NotificationTone.success ? c.statusSuccessBg : c.surfaceQuiet);
    final diskTone = isRequest ? c.iconAccent : (n.tone == NotificationTone.success ? c.iconSuccess : c.iconPrimary);
    final visitId = n.visitId;
    final visit = visitId == null ? null : ref.watch(visitProvider(visitId)).value;
    final day = p['eventDate'] as String?;
    final guests = p['guests'] as int?;
    final visitors = p['visitors'] as int?;
    final rating = p['rating'] as num?;
    final status = _listingStatus(n.kind);
    final facts = <Widget>[
      if (day != null) TextFact(icon: GzIcons.calendar, label: l.hotelTodayFactDate, text: dayMonth(f, day)),
      if (visit != null) TextFact(icon: GzIcons.calendar, label: l.hotelTodayFactDate, text: f.dateTime(visit.slotStart, DateStyle.short)),
      if (guests != null && guests > 0) GzFactChip(icon: GzIcons.usersThree, label: l.hotelTodayFactGuests, value: f.integer(guests)),
      if (visitors != null && visitors > 0) GzFactChip(icon: GzIcons.usersThree, label: l.hotelTodayFactVisitors, value: f.integer(visitors)),
      if (rating != null)
        GzFactChip(
          icon: GzIcons.star,
          label: l.hotelTodayFactRating,
          value: f.number(rating, const DecimalOptions(maxFraction: 1)),
          tone: GzFactTone.accent,
        ),
      if (status != null) GzStatusIcon(status: status, audience: GzStatusAudience.hotel),
      if (reading != null && reading.state != SlaState.expired)
        TimeLeft(minutes: reading.minutesLeft, tone: leftToneOf(reading.state), say: l.hotelTodayWindowEnds),
    ];
    final titleStyleWeight = c.textStrong;
    final nameW = person != null
        ? GzUserText(name, role: GzTextRole.title, color: unread ? titleStyleWeight : c.textPrimary, maxLines: 2)
        : GzText(name, role: GzTextRole.title, color: unread ? titleStyleWeight : c.textPrimary, maxLines: 2);
    final body = Row(
      children: [
        Container(
          width: GzSize.avatarSm,
          height: GzSize.avatarSm,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: disk),
          child: GzIcon(_kindIcon(n.kind), size: GzIconSize.sm, color: diskTone),
        ),
        const SizedBox(width: GzSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(child: nameW),
                  const SizedBox(width: GzSpace.s3),
                  GzText(f.time(n.at), role: GzTextRole.caption, color: c.textSecondary, figures: true, softWrap: false),
                ],
              ),
              if (facts.isNotEmpty) ...[const SizedBox(height: GzSpace.s1), GzFactRow(children: facts)],
            ],
          ),
        ),
        if (unread) ...[
          const SizedBox(width: GzSpace.s3),
          Container(
            width: GzSpace.s2,
            height: GzSpace.s2,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceDark),
          ),
        ],
      ],
    );
    final label = '${unread ? '${l.hotelTodayUnread}. ' : ''}${n.title.of(lang)}. ${n.body.of(lang)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GzPressable(
          onPressed: disabled ? null : onOpen,
          semanticLabel: label,
          borderRadius: GzRadius.smAll,
          minHeight: GzSize.rowMin,
          scale: 1,
          child: Container(
            constraints: const BoxConstraints(minHeight: GzSize.rowMin),
            padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
            child: body,
          ),
        ),
        if (!last)
          SizedBox(
            height: GzStroke.hair,
            child: ColoredBox(color: c.borderHairline),
          ),
      ],
    );
  }
}

/// Where a notification lands: its object with a rebuilt back stack (ADR 0008 D13).
void openNotification(BuildContext context, WidgetRef ref, AppNotification n) {
  final nav = GzNavigatorScope.of(context);
  markNotificationsRead(ref, id: n.id);
  switch (n.kind) {
    case NotificationKind.message:
      nav.switchTab('messages');
      nav.push('HL-TODY-05', params: {'conversationId': n.conversationId, 'bookingId': n.bookingId});
    case NotificationKind.visitMessage:
      nav.switchTab('messages');
      nav.push('HL-VIST-03', params: {'visitId': n.visitId});
    case NotificationKind.visitRequest:
      nav.push('HL-VIST-02', params: {'visitId': n.visitId});
    case NotificationKind.reviewReceived:
      nav.push('HL-GROW-06', params: const {});
    case NotificationKind.listingSubmitted ||
        NotificationKind.listingApproved ||
        NotificationKind.listingRejected ||
        NotificationKind.listingExpiring:
      nav.push('HL-PROV-06', params: {'listingId': n.listingId});
    case NotificationKind.calendarConfirm:
      nav.switchTab('calendar');
    case NotificationKind.invite:
      nav.push('HL-SETT-03', params: const {});
    default:
      if (n.bookingId != null) {
        nav.switchTab('bookings');
        nav.push('HL-BOOK-03', params: {'bookingId': n.bookingId, if (n.kind == NotificationKind.bookingCancelled) 'offerPrompt': true});
      }
  }
}
