import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show BookingStatus, MessageKind, MessageStatus, VisitStatus;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/inbox.dart';
import '../../application/messages_format.dart';

/// The status of a request as the shared status vocabulary (null: no glyph).
GzStatus? statusOfBooking(BookingStatus s) => switch (s) {
  BookingStatus.pending => GzStatus.pending,
  BookingStatus.approved => GzStatus.approved,
  BookingStatus.declined => GzStatus.declined,
  BookingStatus.expired => GzStatus.expired,
  BookingStatus.confirmed => GzStatus.confirmed,
  BookingStatus.redeemed => GzStatus.redeemed,
  BookingStatus.completed => GzStatus.completed,
  BookingStatus.cancelled => GzStatus.cancelled,
  BookingStatus.unknown => null,
};

/// The status of a site visit as the shared status vocabulary.
GzStatus statusOfVisit(VisitStatus s) => switch (s) {
  VisitStatus.requested => GzStatus.visitRequested,
  VisitStatus.confirmed => GzStatus.visitConfirmed,
  VisitStatus.rescheduleProposed => GzStatus.visitReschedule,
  VisitStatus.arrived => GzStatus.visitArrived,
  VisitStatus.completed => GzStatus.visitCompleted,
  VisitStatus.declined => GzStatus.visitDeclined,
  VisitStatus.cancelled => GzStatus.visitCancelled,
  _ => GzStatus.visitMissed,
};

bool visitClosed(VisitStatus? s) => s == VisitStatus.completed || s == VisitStatus.declined || s == VisitStatus.cancelled || s == VisitStatus.missed;

/// One conversation of the Messages tab, as glyphs and a few words (ADR 0034): a monogram in the name's own script (never a face), the
/// name and the clock, one short line of the last message in its own language and direction, and the gold unread count. A visit group chat
/// swaps the monogram for a group glyph and shows the visit date as a fact plus the three roles as three glyphs.
class InboxRowTile extends StatelessWidget {
  const InboxRowTile({required this.row, required this.onOpen, this.last = false, this.guestSupport = false, super.key});

  final InboxRow row;
  final VoidCallback onOpen;
  final bool last;

  /// The guest's one row: Support with its welcome line.
  final bool guestSupport;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.l10n;
    final lang = gz.locale.languageCode;
    final f = context.gzFormat;
    final conv = row.conversation;
    final group = isVisitChat(conv);
    final unread = row.unread;
    final name = guestSupport ? context.gzL10n.commonRoleSupport : conversationName(context, conv);
    final m = row.last;
    final previewColor = unread > 0 ? c.textStrong : c.textPrimary;
    final mine = m != null && m.from.value == 'client';

    Widget preview() {
      if (guestSupport) return _text(l.clientMessagesSupportIntro, lang, unread);
      if (m == null) return const SizedBox.shrink();
      switch (m.kind) {
        case MessageKind.voice:
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GzIcon(GzIcons.mic, size: GzIconSize.xs, color: c.iconSecondary, semanticLabel: l.clientMessagesPreviewVoice),
              const SizedBox(width: GzSpace.s1),
              GzText(clockOf(context, m.voice?.seconds ?? 0), role: GzTextRole.bodyS, color: previewColor, figures: true),
            ],
          );
        case MessageKind.image:
          return GzIcon(GzIcons.image, size: GzIconSize.xs, color: c.iconSecondary, semanticLabel: l.clientMessagesPreviewPhoto);
        case MessageKind.document:
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GzIcon(GzIcons.document, size: GzIconSize.xs, color: c.iconSecondary, semanticLabel: l.clientMessagesPreviewDocument),
              const SizedBox(width: GzSpace.s1),
              Flexible(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: GzText(m.document?.name ?? '', role: GzTextRole.bodyS, color: previewColor, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          );
        case MessageKind.system:
          final lock = visitClosed(row.visit);
          return GzIcon(lock ? GzIcons.lock : GzIcons.usersThree, size: GzIconSize.xs, color: c.iconSecondary, semanticLabel: m.text?.of(lang) ?? '');
        default:
          final raw = m.card != null ? m.card!.title.of(lang) : messageText(m, lang);
          return _text(clipWords(raw), m.origin.value == 'ar' ? 'ar' : (m.card != null ? lang : (m.origin.value == 'en' ? 'en' : lang)), unread);
      }
    }

    final status = guestSupport
        ? null
        : (group ? (row.visit == null ? null : statusOfVisit(row.visit!)) : (row.booking == null ? null : statusOfBooking(row.booking!)));
    final time = guestSupport ? f.time(f.now()) : rowTime(context, row.at);
    final spoken = '$name, $time${unread > 0 ? ', ${l.clientMessagesUnreadCount(unread)}' : ''}';

    return Column(
      key: ValueKey<String>('messages.row.${conv.id}'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzPressable(
          onPressed: onOpen,
          semanticLabel: spoken,
          scale: 1,
          minHeight: 0,
          minWidth: 0,
          borderRadius: GzRadius.smAll,
          builder: (context, st) => ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.rowQueue),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
              child: Row(
                children: [
                  if (group)
                    Container(
                      width: GzSize.avatarMd,
                      height: GzSize.avatarMd,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
                      child: Center(
                        child: GzIcon(GzIcons.usersThree, size: GzIconSize.md, color: c.textStrong),
                      ),
                    )
                  else
                    GzAvatar(name: name, initial: gz.isAr ? conv.monogram : null, size: GzAvatarSize.md),
                  const SizedBox(width: GzSpace.s4),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Directionality(
                                      textDirection: autoDir(name),
                                      child: GzText(
                                        name,
                                        role: GzTextRole.title,
                                        color: c.textStrong,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.start,
                                      ),
                                    ),
                                  ),
                                  if (conv.pinned) ...[
                                    const SizedBox(width: GzSpace.s2),
                                    GzIcon(GzIcons.bookmarkFill, size: GzIconSize.xs, color: c.iconSecondary, semanticLabel: l.clientMessagesPinned),
                                  ],
                                  if (status != null) ...[const SizedBox(width: GzSpace.s2), GzStatusIcon(status: status)],
                                ],
                              ),
                            ),
                            const SizedBox(width: GzSpace.s3),
                            GzText(
                              time,
                              role: GzTextRole.caption,
                              color: unread > 0 ? c.textStrong : c.textSecondary,
                              figures: true,
                              softWrap: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: GzSpace.s1),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: GzSpace.s6),
                          child: Row(
                            children: [
                              if (mine) ...[
                                GzIcon(
                                  m.status == MessageStatus.sent ? GzIcons.check : GzIcons.checkDouble,
                                  size: GzIconSize.xs,
                                  color: m.status == MessageStatus.read ? c.iconAccent : c.iconSecondary,
                                  semanticLabel: l.clientMessagesYou,
                                ),
                                const SizedBox(width: GzSpace.s1),
                              ],
                              Expanded(
                                child: Align(alignment: AlignmentDirectional.centerStart, child: preview()),
                              ),
                              if (unread > 0) ...[
                                const SizedBox(width: GzSpace.s3),
                                GzCountBadge(count: unread, max: 9, label: l.clientMessagesUnreadCount(unread)),
                              ],
                            ],
                          ),
                        ),
                        if (group && row.visitSlot != null) ...[
                          const SizedBox(height: GzSpace.s1),
                          Row(
                            children: [
                              GzFactChip(
                                icon: GzIcons.calendarCheck,
                                label: l.clientMessagesInfoVisit,
                                value: dayMonthShort(context, row.visitSlot!),
                                small: true,
                              ),
                              const SizedBox(width: GzSpace.s4),
                              Semantics(
                                container: true,
                                label: l.clientMessagesVisitMembers,
                                child: Row(
                                  children: [
                                    for (final r in const [GzIcons.user, GzIcons.hotel, GzIcons.headset]) ...[
                                      GzIcon(r, size: GzIconSize.xs, color: c.iconSecondary),
                                      const SizedBox(width: GzSpace.s2),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!last) Container(height: GzStroke.hair, color: c.borderHairline),
      ],
    );
  }

  Widget _text(String text, String lang, int unread) {
    return Builder(
      builder: (context) {
        final gz = context.gz;
        final c = gz.colors;
        final strong = gz.text(GzTextRole.title).fontWeight;
        return Directionality(
          textDirection: autoDir(text),
          child: GzText.rich(
            TextSpan(
              style: unread > 0 ? TextStyle(fontWeight: strong) : null,
              children: GzFigures.spans(context, text, role: GzTextRole.bodyS),
            ),
            role: GzTextRole.bodyS,
            color: unread > 0 ? c.textStrong : c.textPrimary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
          ),
        );
      },
    );
  }
}
