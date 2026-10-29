import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show chatRepositoryProvider, requestsRepositoryProvider, venuesRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show BookingDetail, ConversationKind, Venue;

import '../../../app/state/state.dart';

/// What the screen was opened for: an explicit conversation, Support, a request, or a venue (an existing thread or a fresh enquiry).
@immutable
class ThreadParams {
  const ThreadParams({this.conversationId, this.bookingId, this.venueId, this.support = false, this.draft});

  factory ThreadParams.from(Map<String, Object?> p) => ThreadParams(
    conversationId: p['conversationId'] as String?,
    bookingId: p['bookingId'] as String?,
    venueId: p['venueId'] as String?,
    support: p['support'] == true,
    draft: p['draft'] as String?,
  );

  final String? conversationId;
  final String? bookingId;
  final String? venueId;
  final bool support;
  final String? draft;

  @override
  bool operator ==(Object other) =>
      other is ThreadParams && other.conversationId == conversationId && other.bookingId == bookingId && other.venueId == venueId && other.support == support;

  @override
  int get hashCode => Object.hash(conversationId, bookingId, venueId, support);
}

/// Which conversation the screen is about. [conversationId] null means a thread that does not exist yet: a new enquiry to [venueId], or
/// (when Support has no thread yet) the Support welcome.
@immutable
class ResolvedThread {
  const ResolvedThread({this.conversationId, this.venueId, this.supportNew = false});

  final String? conversationId;
  final String? venueId;
  final bool supportNew;

  bool get isEnquiry => conversationId == null && !supportNew;
}

/// Order: an explicit id, support, a request, a venue (its existing thread, else a fresh enquiry), then the story's venue thread.
final resolveThreadProvider = FutureProvider.autoDispose.family<ResolvedThread, ThreadParams>((ref, p) async {
  ref.watch(clientDataRevisionProvider);
  if (p.conversationId != null) return ResolvedThread(conversationId: p.conversationId);
  final list = (await ref.watch(chatRepositoryProvider).listConversations(limit: 50)).items;
  if (p.support) {
    final s = list.where((c) => c.kind == ConversationKind.support).firstOrNull;
    if (s != null) return ResolvedThread(conversationId: s.id);
  }
  if (p.bookingId != null) {
    final b = list.where((c) => c.bookingId == p.bookingId).firstOrNull;
    if (b != null) return ResolvedThread(conversationId: b.id);
  }
  if (p.venueId != null) {
    final v = list.where((c) => c.venueId == p.venueId && c.kind != ConversationKind.support && c.kind != ConversationKind.visitGroup).firstOrNull;
    return v != null ? ResolvedThread(conversationId: v.id) : ResolvedThread(venueId: p.venueId);
  }
  final hero = list.where((c) => c.kind == ConversationKind.venue && c.bookingId != null).firstOrNull ?? list.firstOrNull;
  return hero != null ? ResolvedThread(conversationId: hero.id) : const ResolvedThread(supportNew: true);
});

/// The request a venue conversation belongs to (the context bar and the system lines).
final threadBookingProvider = FutureProvider.autoDispose.family<BookingDetail?, String>((ref, id) async {
  ref.watch(clientDataRevisionProvider);
  try {
    return await ref.watch(requestsRepositoryProvider).getRequest(requestId: id);
  } on Object {
    return null;
  }
});

/// A venue's face for a new enquiry: its name, cover and whether it offers visits.
final threadVenueProvider = FutureProvider.autoDispose.family<Venue?, String>((ref, id) async {
  try {
    return (await ref.watch(venuesRepositoryProvider).getVenue(venueId: id)).venue;
  } on Object {
    return null;
  }
});
