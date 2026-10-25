import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The conversations this device blocked or muted (prototype store in the
/// web: `useMsgStore`; the server has no block/mute endpoint in the MVP).
final blockedConversationsProvider = NotifierProvider<BlockedConversations, Set<String>>(BlockedConversations.new);

class BlockedConversations extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void set(String id, bool blocked) {
    final next = {...state};
    if (blocked) {
      next.add(id);
    } else {
      next.remove(id);
    }
    state = next;
  }
}

final mutedConversationsProvider = NotifierProvider<MutedConversations, Set<String>>(MutedConversations.new);

class MutedConversations extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void set(String id, bool muted) {
    final next = {...state};
    if (muted) {
      next.add(id);
    } else {
      next.remove(id);
    }
    state = next;
  }
}
