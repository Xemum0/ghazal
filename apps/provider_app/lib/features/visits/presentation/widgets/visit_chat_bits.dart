// Pieces of the visit chat (web `ChatPinned.tsx`, `chat.ts`): the visit card pinned under the header, the read-only strip that replaces the
// composer, and the system lines the visit's own history implies. Nothing here types a digit or a date: both come from the formatter.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart'
    show LocalizedText, Message, MessageFrom, MessageKind, MessageStatus, ThreadMember, ThreadRole, VisitAppointment, VisitStatus, WireLang;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/visits_data.dart';

class VisitPinned extends StatelessWidget {
  const VisitPinned({
    required this.visit,
    required this.canAct,
    required this.canArrive,
    required this.onOpen,
    required this.onConfirm,
    required this.onPropose,
    required this.onArrived,
    super.key,
  });

  final VisitAppointment visit;
  final bool canAct;
  final bool canArrive;
  final VoidCallback onOpen;
  final VoidCallback onConfirm;
  final VoidCallback onPropose;
  final VoidCallback onArrived;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final v = visit;
    final requested = v.status == VisitStatus.requested;
    return Container(
      margin: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
      // The head row is the web's 24 dp line; its tap area grows by 8 dp above and below (taken out of the card padding, so the layout is the web's).
      padding: const EdgeInsetsDirectional.only(start: GzSpace.s3, end: GzSpace.s3, top: GzSpace.s3 - GzSpace.s2, bottom: GzSpace.s3),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: c.borderStrong, width: GzStroke.hair),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: l.hotelVisitsOpenVisit(firstName(v.clientName), f.plain(f.dateTime(v.slotStart, DateStyle.short))),
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: GzSpace.s2),
                child: Row(
                  children: [
                    GzStatusPill(status: visitPill(v.status), audience: GzStatusAudience.hotel),
                    const SizedBox(width: GzSpace.s3),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GzIcon(GzIcons.calendarCheck, size: GzIconSize.xs, color: c.iconSecondary),
                          const SizedBox(width: GzSpace.s2),
                          Flexible(
                            child: GzText(f.dateTime(v.slotStart, DateStyle.short), role: GzTextRole.figBodyS, color: c.textStrong, figures: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (canAct && (requested || canArrive)) ...[
            const SizedBox(height: GzSpace.s3 - GzSpace.s2),
            Row(
              children: [
                if (requested) ...[
                  Expanded(
                    child: GzButton(
                      label: l.hotelVisitsConfirm,
                      size: GzButtonSize.sm,
                      iconStart: GzIcons.check,
                      fullWidth: true,
                      spill: true,
                      onPressed: onConfirm,
                    ),
                  ),
                  const SizedBox(width: GzSpace.s2),
                  Expanded(
                    child: GzButton(
                      label: l.hotelVisitsProposeShort,
                      variant: GzButtonVariant.secondary,
                      size: GzButtonSize.sm,
                      fullWidth: true,
                      spill: true,
                      onPressed: onPropose,
                    ),
                  ),
                ] else
                  Expanded(
                    child: GzButton(
                      label: l.hotelVisitsMarkArrived,
                      size: GzButtonSize.sm,
                      iconStart: GzIcons.pin,
                      fullWidth: true,
                      spill: true,
                      onPressed: onArrived,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Why there is no composer: the chat is closed, or the role only reads it.
class VisitReadOnlyBar extends StatelessWidget {
  const VisitReadOnlyBar({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: EdgeInsetsDirectional.only(
          start: GzSpace.gutter,
          end: GzSpace.gutter,
          top: GzSpace.s4,
          bottom: GzSpace.s4 + MediaQuery.paddingOf(context).bottom,
        ),
        color: c.surfaceQuiet,
        child: Row(
          children: [
            GzIcon(GzIcons.lock, size: GzIconSize.sm, color: c.iconSecondary),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: GzText(text, role: GzTextRole.bodyS, color: c.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatRow {
  const ChatRow(this.message, {this.icon});

  final Message message;
  final IconData? icon;
}

/// The lines of one visit group chat: the server's messages, then the system lines the history implies (the server may already carry them as
/// `system` messages, then none are added), then the closing line of a read-only chat.
List<ChatRow> chatRowsOf(BuildContext context, VisitAppointment v, List<Message> base, String conversationId, String repName, DateTime now) {
  final l = context.l10n;
  final f = context.gzFormat;
  final lang = context.gz.locale.languageCode;
  final hasSystem = base.any((m) => m.kind == MessageKind.system);
  final hasCard = base.any((m) => m.kind == MessageKind.visitCard);
  Message sys(String id, DateTime at, String text) => Message(
    id: id,
    conversationId: conversationId,
    seq: 0,
    from: MessageFrom.system,
    senderName: null,
    at: at,
    kind: MessageKind.system,
    text: LocalizedText.same(text),
    origin: lang == 'ar' ? WireLang.ar : WireLang.en,
    status: MessageStatus.read,
    draft: false,
  );
  final lines = <ChatRow>[];
  if (!hasSystem) {
    for (var i = 0; i < v.history.length; i++) {
      final h = v.history[i];
      final id = 'hist-${v.id}-$i';
      final when = f.dateTime(v.slotStart, DateStyle.short);
      switch (h.status) {
        case VisitStatus.confirmed:
          if (!hasCard) lines.add(ChatRow(sys(id, h.at, l.hotelVisitsLineConfirmed(when)), icon: GzIcons.calendarCheck));
        case VisitStatus.rescheduleProposed:
          final p = v.proposedSlotStart;
          lines.add(
            ChatRow(
              sys(id, h.at, l.hotelVisitsLineReschedule(repName, p == null ? when : f.dateTime(p, DateStyle.short))),
              icon: GzIcons.calendarDots,
            ),
          );
        case VisitStatus.arrived:
          lines.add(ChatRow(sys(id, h.at, l.hotelVisitsLineArrived(firstName(v.clientName))), icon: GzIcons.checkCircle));
        case VisitStatus.completed:
          lines.add(ChatRow(sys(id, h.at, l.hotelVisitsLineCompleted), icon: GzIcons.checkDouble));
        case VisitStatus.declined:
          lines.add(ChatRow(sys(id, h.at, l.hotelVisitsLineDeclined), icon: GzIcons.lock));
        case VisitStatus.cancelled:
          lines.add(ChatRow(sys(id, h.at, l.hotelVisitsLineCancelled), icon: GzIcons.lock));
        case VisitStatus.missed:
          lines.add(ChatRow(sys(id, h.at, l.hotelVisitsLineMissed), icon: GzIcons.clockOff));
        default:
      }
    }
  }
  if (visitChatClosed(v, now) &&
      !lines.any((r) => r.icon == GzIcons.lock) &&
      v.status != VisitStatus.declined &&
      v.status != VisitStatus.cancelled &&
      !hasSystem) {
    lines.add(ChatRow(sys('close-${v.id}', v.closedAt ?? now, l.hotelVisitsLineClosed), icon: GzIcons.lock));
  }
  final all = [for (final m in base) ChatRow(m, icon: m.kind == MessageKind.system ? GzIcons.info : null), ...lines];
  all.sort((a, b) => a.message.at.compareTo(b.message.at));
  return all;
}

ThreadMember? memberOf(List<ThreadMember> members, ThreadRole role) => members.where((m) => m.role == role).firstOrNull;
