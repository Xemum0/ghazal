import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show chatRepositoryProvider, requestsRepositoryProvider, visitsRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show BookingStatus, Conversation, ConversationKind, Message, VisitAppointment, VisitStatus;

import '../../../app/state/state.dart';

/// Which inbox chip a conversation belongs to.
enum InboxFilter { all, venues, visits, planner, providers, support }

InboxFilter filterOf(Conversation c) => switch (c.kind) {
  ConversationKind.visitGroup => InboxFilter.visits,
  ConversationKind.planner => InboxFilter.planner,
  ConversationKind.vendor => InboxFilter.providers,
  ConversationKind.support => InboxFilter.support,
  _ => InboxFilter.venues,
};

/// One row of the Messages tab: the conversation, its last message (the preview), and the status glyph facts.
@immutable
class InboxRow {
  const InboxRow({required this.conversation, this.last, this.booking, this.visit, this.visitSlot});

  final Conversation conversation;
  final Message? last;

  /// The status of the linked request (a venue thread), shown as a glyph after the name.
  final BookingStatus? booking;

  /// A visit group chat: the visit's status and slot.
  final VisitStatus? visit;
  final DateTime? visitSlot;

  int get unread => conversation.unread.client;
  DateTime get at => last?.at ?? conversation.lastMessageAt;
}

/// Every conversation of the signed-in client, pinned first then the most recent, each with its last message. Reloads after any request action and when a thread is read.
final AsyncNotifierProvider<InboxNotifier, List<InboxRow>> inboxProvider = AsyncNotifierProvider<InboxNotifier, List<InboxRow>>(InboxNotifier.new);

/// Bumped when a thread is opened or a message is sent, so the inbox refetches.
final NotifierProvider<InboxRevision, int> inboxRevisionProvider = NotifierProvider<InboxRevision, int>(InboxRevision.new);

class InboxRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

class InboxNotifier extends AsyncNotifier<List<InboxRow>> {
  @override
  Future<List<InboxRow>> build() async {
    ref.watch(clientDataRevisionProvider);
    ref.watch(inboxRevisionProvider);
    if (ref.watch(clientUserIdProvider) == null) return const <InboxRow>[];
    final chat = ref.read(chatRepositoryProvider);
    final page = await chat.listConversations(limit: 50);
    final reqF = ref.read(requestsRepositoryProvider).listRequests(limit: 50);
    final visF = ref.read(visitsRepositoryProvider).listVisits(limit: 50);
    final msgF = [for (final c in page.items) chat.listMessages(conversationId: c.id, limit: 50)];
    final reqs = await reqF;
    final vis = await visF;
    final msgs = await Future.wait(msgF);
    final bookings = <String, BookingStatus>{for (final r in reqs.items) r.booking.id: r.booking.status};
    final visits = <String, VisitAppointment>{for (final v in vis.items) v.visit.id: v.visit};
    final rows = <InboxRow>[];
    for (var i = 0; i < page.items.length; i++) {
      final c = page.items[i];
      final shown = msgs[i].items.where((m) => !m.draft).toList();
      final v = c.visitId == null ? null : visits[c.visitId];
      rows.add(
        InboxRow(
          conversation: c,
          last: shown.isEmpty ? null : shown.last,
          booking: c.bookingId == null ? null : bookings[c.bookingId],
          visit: v?.status,
          visitSlot: v?.slotStart,
        ),
      );
    }
    rows.sort((a, b) => a.conversation.pinned == b.conversation.pinned ? b.at.compareTo(a.at) : (a.conversation.pinned ? -1 : 1));
    return rows;
  }
}
