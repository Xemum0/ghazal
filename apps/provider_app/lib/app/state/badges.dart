import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzTabBadgesProvider, partnerRequestsRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show localeProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show SlaState;
import 'package:ghazal_ui/ghazal_ui.dart' show GzCountTone, GzTabBadge;

import '../../l10n/l10n.dart';
import 'action_result.dart';
import 'partner_context.dart';

/// The numbers behind the partner tab bar (ADR 0008 D2): requests waiting for an answer, requests waiting for the client, unread messages,
/// and whether any waiting request is in the SLA danger state.
@immutable
final class PartnerBadgeCounts {
  const PartnerBadgeCounts({this.pending = 0, this.awaitingClient = 0, this.unreadMessages = 0, this.danger = false});

  static const PartnerBadgeCounts none = PartnerBadgeCounts();

  final int pending;
  final int awaitingClient;
  final int unreadMessages;
  final bool danger;

  @override
  bool operator ==(Object other) =>
      other is PartnerBadgeCounts && other.pending == pending && other.awaitingClient == awaitingClient && other.unreadMessages == unreadMessages && other.danger == danger;

  @override
  int get hashCode => Object.hash(pending, awaitingClient, unreadMessages, danger);
}

/// The counts for the active account, read from "Today" (`getPartnerToday`). Reloads on a context switch and after every request action.
/// Nothing is requested while nobody is signed in as partner staff.
final FutureProvider<PartnerBadgeCounts> partnerBadgeCountsProvider = FutureProvider<PartnerBadgeCounts>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  if (ref.watch(partnerContextProvider) == null) return PartnerBadgeCounts.none;
  final today = await ref.read(partnerRequestsRepositoryProvider).getPartnerToday();
  return PartnerBadgeCounts(
    pending: today.tiles.requests,
    awaitingClient: today.tiles.awaitingClient,
    unreadMessages: today.tiles.unreadMessages,
    danger: today.needsYou.any((r) => r.sla?.state == SlaState.danger),
  );
});

/// The partner tab badges by tab id: `bookings` (the pending count, danger-toned when a request is in SLA danger; always with text) and
/// `messages` (the unread count). A count that is loading or failed shows no badge: it never blocks the bar.
final Provider<Map<String, GzTabBadge>> partnerTabBadgesProvider = Provider<Map<String, GzTabBadge>>((ref) {
  final c = ref.watch(partnerBadgeCountsProvider).value ?? PartnerBadgeCounts.none;
  final l10n = lookupAppL10n(ref.watch(localeProvider));
  return <String, GzTabBadge>{
    if (c.pending > 0) 'bookings': GzTabBadge.count(c.pending, tone: c.danger ? GzCountTone.danger : GzCountTone.gold, label: l10n.hotelShellBadgePending(c.pending)),
    if (c.unreadMessages > 0) 'messages': GzTabBadge.count(c.unreadMessages),
  };
});

/// What the app root passes to `runGhazalApp(overrides: [...])` for this folder: the tab bar reads its badges from the partner state.
final List<Override> partnerStateOverrides = <Override>[
  gzTabBadgesProvider.overrideWith((ref) => ref.watch(partnerTabBadgesProvider)),
];

/// Refetch the counts now (a message arrived, the app resumed).
void refreshPartnerBadges(WidgetRef ref) => ref.read(partnerDataRevisionProvider.notifier).bump();
