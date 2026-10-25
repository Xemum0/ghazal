// Reads of the Today flow (web `today/_components/data.ts`), over the repositories: the Today feed, the Needs-you queue joined to its
// requests, the notifications, the inbox and one thread. Lists refetch after a write by watching `partnerDataRevisionProvider`.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

import '../../../app/state/state.dart';

/// The hero constants of the web screens (`today/_components/model.ts`): what a screen opened without params shows.
const String kHeroConversationId = 'conv-aurelia-reem';
const String kHeroBookingId = 'bk-GZ-2611-0147';
const String kSupportConversationId = 'conv-support-aurelia';

/// The Today feed (`getPartnerToday`): tiles, the Needs-you rows, today's events.
final FutureProvider<PartnerToday> partnerTodayProvider = FutureProvider.autoDispose<PartnerToday>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  return ref.read(partnerRequestsRepositoryProvider).getPartnerToday();
});

Future<List<PartnerRequestRow>> _allRows(Ref ref, RequestSegment segment) async {
  final repo = ref.read(partnerRequestsRepositoryProvider);
  final rows = <PartnerRequestRow>[];
  String? cursor;
  do {
    final page = await repo.listPartnerRequests(segment: segment, cursor: cursor, limit: 50);
    rows.addAll(page.items);
    cursor = page.nextCursor;
  } while (cursor != null && rows.length < 200);
  return rows;
}

/// The requests of the queue by booking id: pending ones (the triage card) and the approved ones waiting for the client.
final FutureProvider<Map<String, PartnerRequestRow>> requestRowsProvider = FutureProvider.autoDispose<Map<String, PartnerRequestRow>>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  final pending = await _allRows(ref, RequestSegment.pending);
  final awaiting = await _allRows(ref, RequestSegment.awaitingClient);
  return <String, PartnerRequestRow>{
    for (final r in [...pending, ...awaiting]) r.booking.id: r,
  };
});

/// What a row of the Needs-you queue is about, with the request it carries.
enum NeedKind { request, awaiting, visit, message, review, calendar }

@immutable
final class NeedItem {
  const NeedItem({required this.kind, required this.item, this.sla, this.request});

  final NeedKind kind;
  final RequestItem item;
  final SlaReading? sla;

  /// The request behind a `request` or `awaiting` row.
  final PartnerRequestRow? request;

  String get id => item.id;
}

NeedKind? _kindOf(TriageType t) => switch (t) {
  TriageType.request => NeedKind.request,
  TriageType.awaitingClient => NeedKind.awaiting,
  TriageType.visitRequest => NeedKind.visit,
  TriageType.message => NeedKind.message,
  TriageType.reviewReply => NeedKind.review,
  TriageType.calendarConfirm => NeedKind.calendar,
  TriageType.unknown => null,
};

/// Order inside the queue: requests by deadline, then what needs a person without a clock, then what only waits for the client.
const Map<NeedKind, int> _rank = {
  NeedKind.request: 0,
  NeedKind.visit: 2,
  NeedKind.message: 3,
  NeedKind.review: 4,
  NeedKind.calendar: 6,
  NeedKind.awaiting: 7,
};

/// The whole Needs-you queue in the server's order made stable by kind (`getPartnerToday().needsYou`).
final FutureProvider<List<NeedItem>> needItemsProvider = FutureProvider.autoDispose<List<NeedItem>>((ref) async {
  final today = await ref.watch(partnerTodayProvider.future);
  final rows = await ref.watch(requestRowsProvider.future);
  final out = <NeedItem>[];
  for (final n in today.needsYou) {
    final kind = _kindOf(n.item.type);
    if (kind == null) continue;
    out.add(NeedItem(kind: kind, item: n.item, sla: n.sla, request: n.item.bookingId == null ? null : rows[n.item.bookingId]));
  }
  int minutes(NeedItem x) => x.sla?.minutesLeft ?? 0;
  out.sort((a, b) {
    if (a.kind == b.kind && (a.kind == NeedKind.request || a.kind == NeedKind.awaiting)) return minutes(a).compareTo(minutes(b));
    return _rank[a.kind]!.compareTo(_rank[b.kind]!);
  });
  return out;
});

/// The partner's notifications, newest first (`listNotifications`; the server scopes them to the signed-in staff member).
final FutureProvider<List<AppNotification>> partnerNotificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  final page = await ref.read(notificationsRepositoryProvider).listNotifications(limit: 50);
  return page.items;
});

/// Marks one or all notifications read, then refetches.
Future<void> markNotificationsRead(WidgetRef ref, {String? id}) async {
  final repo = ref.read(notificationsRepositoryProvider);
  if (id == null) {
    await repo.markAllNotificationsRead();
  } else {
    await repo.markNotificationRead(notificationId: id);
  }
  ref.read(partnerDataRevisionProvider.notifier).bump();
}

/// One conversation of the inbox with its last visible message (the preview line).
@immutable
final class InboxEntry {
  const InboxEntry({required this.conversation, this.last, this.booking});

  final Conversation conversation;
  final Message? last;

  /// The booking the conversation belongs to (its day and status glyph), when it has one.
  final PartnerRequestRow? booking;
}

/// The shared inbox: pinned first, then the newest conversation first.
final FutureProvider<List<InboxEntry>> inboxProvider = FutureProvider.autoDispose<List<InboxEntry>>((ref) async {
  ref.watch(partnerDataRevisionProvider);

  final chat = ref.read(chatRepositoryProvider);
  final conversations = <Conversation>[];
  String? cursor;
  do {
    final page = await chat.listConversations(cursor: cursor, limit: 50);
    conversations.addAll(page.items);
    cursor = page.nextCursor;
  } while (cursor != null && conversations.length < 200);
  conversations.sort((a, b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    return b.lastMessageAt.compareTo(a.lastMessageAt);
  });
  // The booking of a conversation shows its day and status glyph whatever its status: pending and awaiting rows come first, a confirmed or past
  // booking is looked up in the upcoming and past segments (only when a conversation needs it).
  final rows = {...await ref.watch(requestRowsProvider.future)};
  bool unresolved() => conversations.any((c) => c.bookingId != null && !rows.containsKey(c.bookingId));
  for (final segment in const [RequestSegment.upcoming, RequestSegment.past]) {
    if (!unresolved()) break;
    for (final r in await _allRows(ref, segment)) {
      rows.putIfAbsent(r.booking.id, () => r);
    }
  }
  final entries = <InboxEntry>[];
  for (final c in conversations) {
    final messages = (await chat.listMessages(conversationId: c.id, limit: 50)).items.where((m) => !m.draft).toList();
    entries.add(InboxEntry(conversation: c, last: messages.isEmpty ? null : messages.last, booking: c.bookingId == null ? null : rows[c.bookingId]));
  }
  return entries;
});

/// The unread notification count of the bell.
final Provider<int> unreadNotificationCountProvider = Provider.autoDispose<int>(
  (ref) => (ref.watch(partnerNotificationsProvider).value ?? const <AppNotification>[]).where((n) => !n.read).length,
);

/// One thread: the conversation, its messages (drafts included, they sit last) and the request behind it.
@immutable
final class ThreadData {
  const ThreadData({required this.conversation, required this.messages, this.request});

  final Conversation conversation;
  final List<Message> messages;
  final PartnerRequestRow? request;
}

/// The thread of conversation [id] (`kHeroConversationId` when the screen is opened without one).
final threadProvider = FutureProvider.autoDispose.family<ThreadData, String>((ref, id) async {
  ref.watch(partnerDataRevisionProvider);
  final chat = ref.read(chatRepositoryProvider);
  final conversation = await chat.getConversation(conversationId: id);
  final messages = <Message>[];
  String? cursor;
  do {
    final page = await chat.listMessages(conversationId: id, cursor: cursor, limit: 50);
    messages.addAll(page.items);
    cursor = page.nextCursor;
  } while (cursor != null && messages.length < 500);
  // Only the staged text reply is still a draft; the voice note and the quotation went out, so they read as delivered and the draft sits last.
  final shown = [for (final m in messages) (m.draft && m.kind != MessageKind.text) ? m.copyWith(draft: false, status: MessageStatus.delivered) : m];
  shown.sort((a, b) {
    if (a.draft != b.draft) return a.draft ? 1 : -1;
    return a.seq.compareTo(b.seq);
  });
  messages
    ..clear()
    ..addAll(shown);
  PartnerRequestRow? request;
  final bookingId = conversation.bookingId;
  if (bookingId != null) request = (await ref.watch(requestRowsProvider.future))[bookingId];
  return ThreadData(conversation: conversation, messages: messages, request: request);
});

/// Venue-local `HH:MM` of an instant (Kuwait, a fixed +03:00).
String kuwaitHhmm(DateTime instant) {
  final k = instant.toUtc().add(const Duration(hours: 3));
  return '${k.hour.toString().padLeft(2, '0')}:${k.minute.toString().padLeft(2, '0')}';
}

/// The events of the app's today (the feed lists the next 30 days; Today shows the day).
List<PartnerRequestRow> eventsOnDay(PartnerToday? today, DateTime now) {
  if (today == null) return const <PartnerRequestRow>[];
  final k = now.toUtc().add(const Duration(hours: 3));
  final day = '${k.year.toString().padLeft(4, '0')}-${k.month.toString().padLeft(2, '0')}-${k.day.toString().padLeft(2, '0')}';
  return today.events.where((e) => e.booking.eventDate.toString() == day).toList();
}

/// The next event of today that has not started: its start (`HH:MM`) and its hall name in [lang].
({String start, String hall})? nextEventOf(PartnerToday? today, DateTime now, String lang) {
  if (today == null) return null;
  final nowHm = kuwaitHhmm(now);
  for (final PartnerRequestRow e in eventsOnDay(today, now)) {
    final s = e.booking.sections.isEmpty ? null : e.booking.sections.first;
    if (s == null) continue;
    final start = s.start.toString();
    if (start.compareTo(nowHm) > 0) {
      return (start: start, hall: e.halls.where((h) => h.id == s.hallId).map((h) => h.name.of(lang)).firstOrNull ?? '');
    }
  }
  return null;
}

/// One visit, one review and one conversation by id (the Needs-you and notification rows name them).
final visitProvider = FutureProvider.autoDispose.family<VisitAppointment, String>(
  (ref, id) => ref.read(partnerVisitsRepositoryProvider).getPartnerVisit(visitId: id),
);
final reviewProvider = FutureProvider.autoDispose.family<Review, String>(
  (ref, id) => ref.read(partnerReviewsRepositoryProvider).getPartnerReview(reviewId: id),
);
final conversationProvider = FutureProvider.autoDispose.family<Conversation, String>(
  (ref, id) => ref.read(chatRepositoryProvider).getConversation(conversationId: id),
);


/// Which conversations the manager opened or marked unread again from the long-press menu in this run of the app (the server only stores a read
/// marker: a conversation marked unread is shown with at least one unread until it is opened).
@immutable
final class InboxLocal {
  const InboxLocal({this.opened = const <String>{}, this.markedUnread = const <String>{}});

  final Set<String> opened;
  final Set<String> markedUnread;

  /// The unread count as the inbox shows it: opened clears it, marked-unread restores at least one.
  int unreadOf(Conversation c) {
    final server = c.unread.hotel;
    if (markedUnread.contains(c.id)) return server < 1 ? 1 : server;
    return opened.contains(c.id) ? 0 : server;
  }
}

class InboxLocalNotifier extends Notifier<InboxLocal> {
  @override
  InboxLocal build() => const InboxLocal();

  void open(String id) => state = InboxLocal(opened: {...state.opened, id}, markedUnread: {...state.markedUnread}..remove(id));
  void setUnread(String id, bool unread) => unread
      ? state = InboxLocal(opened: {...state.opened}..remove(id), markedUnread: {...state.markedUnread, id})
      : state = InboxLocal(opened: {...state.opened, id}, markedUnread: {...state.markedUnread}..remove(id));
}

final NotifierProvider<InboxLocalNotifier, InboxLocal> inboxLocalProvider = NotifierProvider<InboxLocalNotifier, InboxLocal>(InboxLocalNotifier.new);

/// Tells the server the thread was read up to its last message, then refetches the lists.
Future<void> markConversationReadUpToLast(WidgetRef ref, InboxEntry e) async {
  final last = e.last;
  if (last == null) return;
  await ref.read(chatRepositoryProvider).markConversationRead(conversationId: e.conversation.id, body: ReadMarkerInput(upToSeq: last.seq));
  ref.read(partnerDataRevisionProvider.notifier).bump();
}

/// One request with its booking, voucher and SLA reading (the context bar of a thread, any status).
final requestDetailProvider = FutureProvider.autoDispose.family<PartnerRequestDetail, String>((ref, bookingId) {
  ref.watch(partnerDataRevisionProvider);
  return ref.read(partnerRequestsRepositoryProvider).getPartnerRequest(requestId: bookingId);
});

/// The venue behind a thread: its name and its area name (the Address quick reply).
final venueNamesProvider = FutureProvider.autoDispose.family<({LocalizedText venue, LocalizedText? area}), String>((ref, venueId) async {
  final repo = ref.read(venuesRepositoryProvider);
  final venue = (await repo.getVenue(venueId: venueId)).venue;
  final areas = (await repo.listAreas()).areas;
  final area = areas.where((a) => a.id == venue.areaId).firstOrNull;
  return (venue: venue.name, area: area?.name);
});
