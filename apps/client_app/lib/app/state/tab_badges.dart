import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show chatRepositoryProvider, gzTabBadgesProvider, requestsRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show localeProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show BookingStatus;
import 'package:ghazal_ui/ghazal_ui.dart' show GzTabBadge;

import '../../l10n/l10n.dart';
import 'action_result.dart';
import 'client_scope.dart';

/// My Wedding shows a dot when something waits for the client: an approved request to confirm inside 24 hours (ADR 0007 D4).
final FutureProvider<bool> clientActionDueProvider = FutureProvider<bool>((ref) async {
  ref.watch(clientDataRevisionProvider);
  if (ref.watch(clientUserIdProvider) == null) return false;
  final page = await ref.read(requestsRepositoryProvider).listRequests(status: const [BookingStatus.approved], limit: 1);
  return page.items.isNotEmpty;
});

/// The unread messages of the client's conversations (the Messages tab count).
final FutureProvider<int> clientUnreadMessagesProvider = FutureProvider<int>((ref) async {
  ref.watch(clientDataRevisionProvider);
  if (ref.watch(clientUserIdProvider) == null) return 0;
  final page = await ref.read(chatRepositoryProvider).listConversations(unread: true, limit: 50);
  return page.items.fold<int>(0, (n, c) => n + c.unread.client);
});

/// The client tab badges by tab id (`my-wedding`: dot, `messages`: count), the value `gzTabBadgesProvider` carries in the running app.
/// While a count loads (or failed) its badge is absent: a badge never blocks the bar.
final Provider<Map<String, GzTabBadge>> clientTabBadgesProvider = Provider<Map<String, GzTabBadge>>((ref) {
  final due = ref.watch(clientActionDueProvider).value ?? false;
  final unread = ref.watch(clientUnreadMessagesProvider).value ?? 0;
  final l10n = lookupAppL10n(ref.watch(localeProvider));
  return <String, GzTabBadge>{
    if (due) 'my-wedding': const GzTabBadge.dot(),
    if (unread > 0) 'messages': GzTabBadge.count(unread, label: l10n.clientShellTabUnread(unread)),
  };
});

/// Everything the app root passes to `runGhazalApp(overrides: [...])` for this folder: the tab bar reads its badges from the client state.
final List<Override> clientStateOverrides = <Override>[
  gzTabBadgesProvider.overrideWith((ref) => ref.watch(clientTabBadgesProvider)),
];

/// Refetch the badge counts now (a message arrived, the app resumed).
void refreshClientBadges(WidgetRef ref) => ref.read(clientDataRevisionProvider.notifier).bump();
