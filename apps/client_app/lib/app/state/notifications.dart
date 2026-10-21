import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show notificationsRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart' show AppNotification;

import 'action_result.dart';
import 'client_scope.dart';

/// The notification centre of the client: the loaded pages and the unread total (the number of the bell and any badge).
@immutable
final class NotificationsState {
  const NotificationsState({this.items = const <AppNotification>[], this.unread = 0, this.nextCursor});

  static const NotificationsState empty = NotificationsState();

  final List<AppNotification> items;

  /// The server's unread count (not only the loaded pages).
  final int unread;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  NotificationsState copyWith({List<AppNotification>? items, int? unread, String? nextCursor, bool clearCursor = false}) =>
      NotificationsState(items: items ?? this.items, unread: unread ?? this.unread, nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor));

  @override
  bool operator ==(Object other) => other is NotificationsState && listEquals(other.items, items) && other.unread == unread && other.nextCursor == nextCursor;

  @override
  int get hashCode => Object.hash(Object.hashAll(items), unread, nextCursor);
}

const int _pageSize = 20;

/// The client's notifications. A guest has none (nothing is requested). Reloads when a request or payment action finishes
/// (`clientDataRevisionProvider`), because those create notifications. `markRead` and `markAllRead` are optimistic.
final AsyncNotifierProvider<NotificationsNotifier, NotificationsState> notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, NotificationsState>(NotificationsNotifier.new);

class NotificationsNotifier extends AsyncNotifier<NotificationsState> {
  @override
  Future<NotificationsState> build() async {
    ref.watch(clientDataRevisionProvider);
    if (ref.watch(clientUserIdProvider) == null) return NotificationsState.empty;
    final repo = ref.read(notificationsRepositoryProvider);
    final page = await repo.listNotifications(limit: _pageSize);
    final count = await repo.getUnreadNotificationCount();
    return NotificationsState(items: page.items, unread: count.count, nextCursor: page.nextCursor);
  }

  /// The next page (the list scrolled to its end). No-op without a cursor.
  Future<void> loadMore() async {
    final cur = state.value;
    if (cur == null || !cur.hasMore) return;
    final page = await ref.read(notificationsRepositoryProvider).listNotifications(cursor: cur.nextCursor, limit: _pageSize);
    final latest = state.value ?? cur;
    state = AsyncData(latest.copyWith(items: [...latest.items, ...page.items], nextCursor: page.nextCursor, clearCursor: page.nextCursor == null));
  }

  /// Marks one notification read (the unread count drops at once; a refusal restores it).
  Future<ActionResult<void>> markRead(String id) async {
    final cur = state.value;
    if (cur == null) return const ActionGated();
    final target = cur.items.where((n) => n.id == id && !n.read);
    if (target.isEmpty) return const ActionSuccess<void>(null);
    state = AsyncData(cur.copyWith(items: [for (final n in cur.items) n.id == id ? n.copyWith(read: true) : n], unread: (cur.unread - 1).clamp(0, 1 << 30)));
    try {
      await ref.read(notificationsRepositoryProvider).markNotificationRead(notificationId: id);
      return const ActionSuccess<void>(null);
    } on ApiProblem catch (p) {
      state = AsyncData(cur);
      return ActionFailure(p);
    }
  }

  /// Marks everything read.
  Future<ActionResult<void>> markAllRead() async {
    final cur = state.value;
    if (cur == null) return const ActionGated();
    state = AsyncData(cur.copyWith(items: [for (final n in cur.items) n.copyWith(read: true)], unread: 0));
    try {
      await ref.read(notificationsRepositoryProvider).markAllNotificationsRead();
      return const ActionSuccess<void>(null);
    } on ApiProblem catch (p) {
      state = AsyncData(cur);
      return ActionFailure(p);
    }
  }

  /// Refetch now (pull to refresh, the app came back to the front).
  void refresh() => ref.read(clientDataRevisionProvider.notifier).bump();
}

/// The unread notification count (0 while loading, for a guest or after an error).
final Provider<int> unreadNotificationsProvider = Provider<int>((ref) => ref.watch(notificationsProvider.select((a) => a.value?.unread ?? 0)));
