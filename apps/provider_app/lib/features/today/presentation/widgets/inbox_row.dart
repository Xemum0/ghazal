// InboxRow: one conversation of the shared inbox (web `InboxRow.tsx`, HA-MSG-01, HA-MSG-04). A monogram in the client's own script (never a face),
// the name, one line of the last message in its own script and direction, the clock (today) or the short date, the unread count and, in the full
// variant, the booking context as facts: the event day with the booking's own status glyph, an Enquiry glyph when there is no booking, and the time a
// client message has waited once it is over 30 minutes. Ghazal Support is pinned and never has a booking. A visit group leads with a group glyph.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show ConversationKind, Message, MessageFrom, MessageKind, VisitStatus, WireLang;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/today_data.dart';
import 'today_bits.dart';

const int kNeedsReplyAfterMinutes = 30;

GzStatus _visitStatus(VisitStatus s) => switch (s) {
      VisitStatus.confirmed => GzStatus.visitConfirmed,
      VisitStatus.rescheduleProposed => GzStatus.visitReschedule,
      VisitStatus.arrived => GzStatus.visitArrived,
      VisitStatus.completed => GzStatus.visitCompleted,
      VisitStatus.declined => GzStatus.visitDeclined,
      VisitStatus.cancelled => GzStatus.visitCancelled,
      VisitStatus.missed => GzStatus.visitMissed,
      _ => GzStatus.visitRequested,
    };

/// A preview is a glimpse, not the message: about one phone line (docs/design/02-text-diet.md section 1).
/// Counted in code points like the web's `Array.from`, not in grapheme clusters: an Arabic mark (tanween) is one more character, so the cut falls where the web's does.
String _glimpse(String text) {
  final runes = text.runes;
  return runes.length > 34 ? '${String.fromCharCodes(runes.take(34)).trimRight()}…' : text;
}

class InboxRow extends ConsumerWidget {
  const InboxRow({required this.entry, this.compact = false, this.unread, this.onOpen, this.onLongPress, this.last = false, super.key});

  final InboxEntry entry;

  /// `compact` is the Today preview; the inbox shows the booking context too.
  final bool compact;
  final int? unread;
  final VoidCallback? onOpen;
  final VoidCallback? onLongPress;
  final bool last;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final now = ref.watch(clockProvider)();
    final conv = entry.conversation;
    final support = conv.kind == ConversationKind.support;
    final group = conv.kind == ConversationKind.visitGroup;
    final name = support ? conv.title.of(lang) : conv.clientName;
    final count = unread ?? conv.unread.hotel;
    final msg = entry.last;
    var preview = conv.subtitle.of(lang);
    if (msg != null) {
      if (msg.kind == MessageKind.voice) {
        preview = l.hotelTodayPreviewVoice;
      } else if (msg.kind == MessageKind.image) {
        preview = l.hotelTodayPreviewPhoto;
      } else if (msg.kind == MessageKind.document) {
        preview = msg.document?.name ?? l.hotelTodayPreviewDocument;
      } else if (msg.text != null) {
        preview = msg.text!.of(msg.origin == WireLang.ar ? 'ar' : 'en');
      }
    }
    final own = msg != null && msg.from == MessageFrom.venue;
    final at = msg?.at ?? conv.lastMessageAt;
    final today = f.isoDay(now);
    final time = f.isoDay(at) == today ? f.time(at) : dayMonth(f, f.isoDay(at), weekday: false);

    final waited = conv.awaitingReplySince == null ? 0 : now.difference(conv.awaitingReplySince!).inMinutes;
    final needsReply = waited > kNeedsReplyAfterMinutes;
    final wait = needsReply ? TimeLeft(minutes: waited, tone: LeftTone.gold, glyph: GzIcons.hourglass, say: l.hotelTodayWaitingLong) : null;

    final booking = entry.booking?.booking;
    final facts = <Widget>[];
    final visitId = conv.visitId;
    final visit = (group && visitId != null) ? ref.watch(visitProvider(visitId)).value : null;
    if (group) {
      if (visit != null) {
        facts.add(TextFact(icon: GzIcons.calendar, label: l.hotelTodayFactDate, text: f.dateTime(visit.slotStart, DateStyle.short)));
        facts.add(GzStatusIcon(status: _visitStatus(visit.status), audience: GzStatusAudience.hotel));
      }
      facts.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (icon, i) in [(GzIcons.user, 0), (GzIcons.hotel, 1), (GzIcons.headset, 2)]) ...[
              if (i > 0) const SizedBox(width: GzSpace.s1),
              Container(
                width: GzSpace.s6,
                height: GzSpace.s6,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceQuiet),
                child: GzIcon(icon, size: GzIconSize.xs, color: c.iconSecondary),
              ),
            ],
          ],
        ),
      );
    } else if (!compact && (booking != null || conv.kind == ConversationKind.enquiry || wait != null)) {
      if (booking != null) {
        final isToday = booking.eventDate.toString() == today;
        final first = booking.sections.isEmpty ? null : booking.sections.first;
        final when = isToday && first != null
            ? f.time(gzClockInstant(f, booking.eventDate.toString(), first.start.toString()))
            : dayMonth(f, booking.eventDate.toString());
        facts.add(TextFact(icon: isToday ? GzIcons.clock : GzIcons.calendar, label: l.hotelTodayFactDate, text: when));
        facts.add(GzStatusIcon(status: gzStatusOfBooking(booking.status), audience: GzStatusAudience.hotel));
      }
      if (booking == null && conv.kind == ConversationKind.enquiry) {
        facts.add(
          Semantics(
            label: l.hotelTodayEnquiry,
            child: Container(
              width: GzSpace.s6,
              height: GzSpace.s6,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.statusNeutralBg),
              child: GzIcon(GzIcons.help, size: GzIconSize.xs, color: c.statusNeutralText),
            ),
          ),
        );
      }
      if (wait != null) facts.add(wait);
    } else if (compact && wait != null) {
      facts.add(wait);
    }

    final avatar = group
        ? Container(
            width: GzSize.avatarSm,
            height: GzSize.avatarSm,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceQuiet),
            child: GzIcon(GzIcons.usersThree, size: GzIconSize.sm, color: c.iconPrimary),
          )
        : GzAvatar(name: name, initial: support ? 'غ' : null, size: GzAvatarSize.sm, voice: GzAvatarVoice.sans);

    final nameW = support
        ? GzText(name, role: GzTextRole.title, color: c.textStrong, maxLines: 2)
        : GzUserText(name, role: GzTextRole.title, color: c.textStrong, maxLines: 2);
    final previewColor = count > 0 ? c.textStrong : c.textSecondary;
    final body = Row(
      children: [
        avatar,
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
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(child: nameW),
                        if (conv.pinned) ...[
                          const SizedBox(width: GzSpace.s2),
                          Semantics(
                            label: l.hotelTodayPinned,
                            child: GzIcon(GzIcons.bookmarkFill, size: GzIconSize.xs, color: c.iconSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  GzText(time, role: GzTextRole.caption, color: c.textSecondary, figures: true, softWrap: false),
                ],
              ),
              const SizedBox(height: GzSpace.s1),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (own) ...[
                          Semantics(
                            label: l.hotelTodayYou,
                            child: GzIcon(GzIcons.reply, size: GzIconSize.xs, color: c.iconSecondary),
                          ),
                          const SizedBox(width: GzSpace.s1),
                        ],
                        Flexible(
                          child: Directionality(
                            textDirection: gzFirstStrongOr(preview, Directionality.of(context)),
                            child: GzText(
                              _glimpse(preview),
                              role: GzTextRole.bodyS,
                              color: previewColor,
                              figures: true,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (count > 0) ...[const SizedBox(width: GzSpace.s3), GzCountBadge(count: count, label: l.hotelTodayUnreadCount(count))],
                ],
              ),
              if (facts.isNotEmpty) ...[
                const SizedBox(height: GzSpace.s1),
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: GzSpace.s1),
                  child: Semantics(container: true, child: Wrap(spacing: GzSpace.s3, runSpacing: GzSpace.s2, crossAxisAlignment: WrapCrossAlignment.center, children: facts)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GzPressable(
          onPressed: onOpen,
          onLongPress: onLongPress,
          semanticLabel: '$name, ${_glimpse(preview)}',
          borderRadius: GzRadius.smAll,
          minHeight: GzSize.rowQueue,
          scale: 1,
          child: Container(
            constraints: const BoxConstraints(minHeight: GzSize.rowQueue),
            padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4),
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

/// The message that closes a conversation row as the Today preview needs it.
bool awaitsReply(InboxEntry e) =>
    e.conversation.awaitingReplySince != null &&
    e.conversation.kind != ConversationKind.support &&
    e.conversation.kind != ConversationKind.visitGroup;

typedef InboxMessage = Message;
