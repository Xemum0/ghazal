import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show Audience, Booking, BookingEvent, BookingEventKind, BookingStatus, ExpiredReason;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/chat_thread.dart';
import '../../application/messages_format.dart' show shortDuration;
import 'inbox_row.dart' show statusOfBooking;

/// The request's own events inside the conversation (sent, approved, confirmed, voucher redeemed, not accepted, no reply, time ran out).
enum SysKind { requested, approved, confirmed, redeemed, notAccepted, expired, cancelled }

class SysEvent {
  const SysEvent(this.kind, this.at, {this.clientLapsed = false});

  final SysKind kind;
  final DateTime at;
  final bool clientLapsed;
}

/// The knots of a request, from the status transitions of its history.
List<SysEvent> systemEventsOf(Booking b) {
  SysKind? kindOf(BookingStatus? s) => switch (s) {
    BookingStatus.pending => SysKind.requested,
    BookingStatus.approved => SysKind.approved,
    BookingStatus.confirmed => SysKind.confirmed,
    BookingStatus.redeemed => SysKind.redeemed,
    BookingStatus.declined => SysKind.notAccepted,
    BookingStatus.expired => SysKind.expired,
    BookingStatus.cancelled => SysKind.cancelled,
    _ => null,
  };
  final out = <SysEvent>[];
  for (final BookingEvent e in b.events) {
    if (e.kind != BookingEventKind.transition) continue;
    final k = kindOf(e.to);
    if (k == null) continue;
    out.add(SysEvent(k, e.at, clientLapsed: k == SysKind.expired && b.expiredReason == ExpiredReason.clientNoConfirmation));
  }
  return out;
}

/// A knot on a hairline: a glyph that states the event and one or two words, flanked by two rules, with the clock under it.
class SystemLine extends StatelessWidget {
  const SystemLine({required this.event, required this.venue, super.key});

  final SysEvent event;
  final String venue;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    final f = context.gzFormat;
    final k = event.kind;
    final label = switch (k) {
      SysKind.requested => l.clientMessagesSysRequestSent,
      SysKind.approved => l.clientMessagesSysApproved,
      SysKind.confirmed => l.clientMessagesSysConfirmed,
      SysKind.redeemed => l.clientMessagesSysRedeemed,
      SysKind.notAccepted => l.clientMessagesSysNotAccepted,
      SysKind.expired => event.clientLapsed ? l.clientMessagesSysLapsed : l.clientMessagesSysExpired,
      SysKind.cancelled => l.clientMessagesSysCancelled,
    };
    final icon = switch (k) {
      SysKind.requested => GzIcons.send,
      SysKind.approved || SysKind.confirmed => GzIcons.checkCircle,
      SysKind.redeemed => GzIcons.ticket,
      SysKind.notAccepted || SysKind.cancelled => GzIcons.xCircle,
      SysKind.expired => GzIcons.clockOff,
    };
    final tone = k == SysKind.confirmed || k == SysKind.redeemed ? c.iconSuccess : (k == SysKind.notAccepted ? c.iconDanger : c.iconSecondary);
    final info = k == SysKind.confirmed
        ? l.clientMessagesSysInfoPay(venue)
        : (k == SysKind.notAccepted || k == SysKind.expired ? l.clientMessagesSysInfoKept : null);
    Widget rule() => Expanded(child: Container(height: GzStroke.hair, color: c.borderHairline));
    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              rule(),
              const SizedBox(width: GzSpace.s3),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: GzSize.touchMin),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GzIcon(icon, size: GzIconSize.sm, color: tone),
                    const SizedBox(width: GzSpace.s2),
                    GzText(label, role: GzTextRole.bodyS, color: c.textPrimary, softWrap: false, semanticLabel: label),
                    if (k == SysKind.approved) ...[
                      const SizedBox(width: GzSpace.s2),
                      GzFactChip(icon: GzIcons.timer, label: l.clientMessagesFactTimeLeft, value: shortDuration(f, 24 * 3600000), small: true),
                    ],
                    if (info != null) GzInfoButton(title: l.clientMessagesSysInfoTitle, paragraphs: [info]),
                  ],
                ),
              ),
              const SizedBox(width: GzSpace.s3),
              rule(),
            ],
          ),
          const SizedBox(height: GzSpace.s1),
          Center(child: GzText(f.time(event.at), role: GzTextRole.caption, color: c.textSecondary, figures: true)),
        ],
      ),
    );
  }
}

/// The request a venue conversation belongs to, pinned under the header: date, reception glyph and guests as facts, the request's status as
/// a glyph (with the hours left and `Confirm` while approved) and a chevron into Booking detail.
class ContextBar extends StatelessWidget {
  const ContextBar({required this.booking, required this.onOpen, super.key});

  final Booking booking;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    final f = context.gzFormat;
    final approved = booking.status == BookingStatus.approved && booking.confirmBy != null;
    final label = approved ? l.clientMessagesContextConfirm : l.clientMessagesContextView;
    final now = f.now();
    final hours = approved ? (booking.confirmBy!.difference(now).inMinutes / 60).ceil().clamp(0, 1 << 20) : 0;
    final audience = booking.sections.isEmpty ? Audience.women : booking.sections.first.audience;
    final guests = booking.sections.fold<int>(0, (n, s) => n + s.guests);
    final status = statusOfBooking(booking.status);
    return Container(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s1, bottom: GzSpace.s2),
      decoration: BoxDecoration(color: c.surfaceCanvas),
      // The web hairline is an overlay (::after, absolute): it paints on the bar's last pixel row and adds no height (the bar is 56).
      foregroundDecoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
      child: GzPressable(
        onPressed: onOpen,
        semanticLabel: '$label: ${f.date(booking.eventDate.toString(), DateStyle.short)}',
        scale: 1,
        minHeight: GzSize.touchMin,
        minWidth: 0,
        borderRadius: GzRadius.smAll,
        child: Row(
          children: [
            Expanded(
              child: GzFactRow(
                label: l.clientMessagesInfoBooking,
                children: [
                  GzFactChip(icon: GzIcons.calendar, label: l.clientMessagesFactDate, value: f.date(booking.eventDate.toString(), DateStyle.dayMonth)),
                  GzFactChip(
                    icon: switch (audience) {
                      Audience.men => GzIcons.sectionMen,
                      Audience.mixed => GzIcons.sectionMixed,
                      _ => GzIcons.sectionWomen,
                    },
                    label: switch (audience) {
                      Audience.men => l.clientMessagesAudienceMen,
                      Audience.mixed => l.clientMessagesAudienceMixed,
                      _ => l.clientMessagesAudienceWomen,
                    },
                  ),
                  GzFactChip(icon: GzIcons.usersThree, label: l.clientMessagesFactGuests, value: f.integer(guests)),
                ],
              ),
            ),
            const SizedBox(width: GzSpace.s3),
            if (approved && status != null) ...[
              GzStatusPill(status: status, hours: hours),
              const SizedBox(width: GzSpace.s2),
              GzText(label, role: GzTextRole.bodyS, color: c.textGoldInk, semanticLabel: label),
            ] else if (status != null)
              GzStatusIcon(status: status, large: true),
            const SizedBox(width: GzSpace.s2),
            GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
          ],
        ),
      ),
    );
  }
}

/// What sits under a bubble: the clock and (own messages) the delivery tick at the end of a run, or the state of a message still on its way.
class MessageMeta extends StatelessWidget {
  const MessageMeta({required this.own, required this.showTime, required this.time, required this.read, required this.delivered, this.local, this.onRetry, this.onCancel, super.key});

  final bool own;
  final bool showTime;
  final DateTime time;
  final bool read;
  final bool delivered;
  final LocalMsg? local;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    final f = context.gzFormat;
    final loc = local;
    if (loc != null && loc.state == LocalState.uploading) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: SizedBox(
          width: GzSize.chatMedia,
          child: Semantics(
            container: true,
            label: l.clientMessagesUploading,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: GzRadius.pillAll,
                    child: SizedBox(
                      height: GzStroke.thread,
                      child: Stack(
                        children: [
                          Container(color: c.markTrack),
                          FractionallySizedBox(widthFactor: loc.progress.clamp(0.05, 1), alignment: AlignmentDirectional.centerStart, child: Container(color: c.markKhayt)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: GzSpace.s2),
                GzText(f.percent(loc.progress * 100), role: GzTextRole.figCaption, color: c.textSecondary, figures: true),
                GzIconButton(icon: GzIcons.close, label: l.clientMessagesUploadCancel, onPressed: onCancel),
              ],
            ),
          ),
        ),
      );
    }
    if (loc != null) {
      final failed = loc.state == LocalState.failed;
      final color = failed ? c.textDanger : c.textSecondary;
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GzIcon(
                failed ? GzIcons.warningCircle : (loc.state == LocalState.queued ? GzIcons.offline : GzIcons.clock),
                size: GzIconSize.xs,
                color: color,
                semanticLabel: loc.state == LocalState.sending ? l.clientMessagesMsgSending : null,
              ),
              if (loc.state != LocalState.sending) ...[
                const SizedBox(width: GzSpace.s1),
                GzText(failed ? l.clientMessagesMsgFailed : l.clientMessagesMsgQueued, role: GzTextRole.caption, color: color),
              ],
              if (failed) GzButton(label: context.gzL10n.commonActionRetry, variant: GzButtonVariant.tertiary, onPressed: onRetry),
            ],
          ),
        ),
      );
    }
    if (!showTime) return const SizedBox.shrink();
    final status = read ? l.clientMessagesStatusRead : (delivered ? l.clientMessagesStatusDelivered : context.gzL10n.commonStateSent);
    return Align(
      alignment: own ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s1),
        child: Semantics(
          container: true,
          excludeSemantics: true,
          label: '${f.time(time)}${own ? ', $status' : ''}',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GzText(f.time(time), role: GzTextRole.caption, color: c.textSecondary, figures: true),
              if (own) ...[
                const SizedBox(width: GzSpace.s1),
                GzIcon(read || delivered ? GzIcons.checkDouble : GzIcons.check, size: GzIconSize.xs, color: read ? c.iconAccent : c.iconSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
