// HL-TODY-01 Today (the tab root; web `HL-TODY-01.tsx`): the first screen of the Partner app is already the inbox (ADR 0008 D2-D4). The status in
// the Ink band is a figure (how many requests, the time left on the first), then what needs a decision, the three quick actions, today's events, the
// next seven days, the voucher tiles, the messages waiting and the latest notifications. Role changes the content, never the navigation.
// Requirements: HA-DASH-01, HA-DASH-03..07, HA-AUTH-02, HA-AUTH-03, HA-VCH-01, HA-VIS-01, PA-ACC-02.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show StaffRole;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/today_data.dart';
import 'widgets/today_bits.dart';
import 'widgets/today_blocks.dart';
import 'widgets/today_blocks_b.dart';
import 'widgets/today_header.dart';
import 'widgets/today_overlays.dart';

class HlTody01Screen extends ConsumerWidget {
  const HlTody01Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.gzFormat;
    final nav = GzNavigatorScope.of(context);
    final lang = context.gz.locale.languageCode;
    final ctx = ref.watch(partnerContextProvider);
    final needs = ref.watch(needItemsProvider);
    final now = ref.watch(clockProvider)();
    final unread = ref.watch(unreadNotificationCountProvider);
    final role = ctx?.role ?? StaffRole.manager;
    final reception = role == StaffRole.reception;
    final roleWord = switch (role) {
      StaffRole.reception => l.hotelTodayRoleReception,
      StaffRole.accountant => l.hotelTodayRoleAccountant,
      StaffRole.marketing => l.hotelTodayRoleMarketing,
      _ => null,
    };
    final offline = needs.hasError && needs.error is ApiProblem && (needs.error as ApiProblem).code == ApiProblemCode.offline;
    final stamp = offline ? f.time(now) : null;

    final status = needs.when(
      data: (items) => TodayStatus(items: items),
      loading: () => const Padding(
        padding: EdgeInsetsDirectional.only(top: GzSpace.s3),
        child: GzSkeleton(inlineSize: 248, blockSize: 24),
      ),
      error: (_, _) => null,
    );
    final top = TodayBar(
      name: ctx?.accountName?.of(lang) ?? '',
      unread: unread,
      stamp: stamp,
      multiVenue: ctx?.isProvider != true,
      onBell: () => nav.push('HL-TODY-03'),
      onVenue: () => nav.openSheetBuilder((_) => const VenueSwitcherContent(), options: GzSheetOptions(title: l.hotelTodaySwitchTitle)),
    );

    Widget body(List<NeedItem> items) {
      if (ctx?.isProvider == true) {
        return Padding(
          padding: const EdgeInsetsDirectional.only(top: GzSpace.s6, bottom: GzSpace.s8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NeedsYouBlock(entries: items),
              const SizedBox(height: GzSpace.s8),
              const QuickActions(prices: false, block: false),
              const SizedBox(height: GzSpace.s8),
              const ProviderTilesBlock(),
              const SizedBox(height: GzSpace.s8),
              const NotificationsBlock(),
            ],
          ),
        );
      }
      final firstRequest = items.where((e) => e.kind == NeedKind.request && e.request != null).firstOrNull;
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s6, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NeedsYouBlock(entries: items, initiallyOpen: nav.params['open'] == true ? firstRequest?.request?.booking.id : null),
            const SizedBox(height: GzSpace.s8),
            QuickActions(prices: !reception),
            const SizedBox(height: GzSpace.s8),
            const EventsBlock(),
            if (!reception) ...[const SizedBox(height: GzSpace.s8), const StripBlock(), const SizedBox(height: GzSpace.s8), const VenueTilesBlock()],
            const SizedBox(height: GzSpace.s8),
            const MessagesBlock(),
            if (!reception) ...[const SizedBox(height: GzSpace.s8), const NotificationsBlock()],
          ],
        ),
      );
    }

    return GzPullToRefresh(
      onRefresh: () async => ref.read(partnerDataRevisionProvider.notifier).bump(),
      child: GzScreen(
        top: top,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FirstRunTrigger(),
            TodayIntro(dateLine: dayMonth(f, f.isoDay(now)), roleWord: roleWord, status: status),
            GzAsyncView<List<NeedItem>>(
              value: needs,
              loading: const Padding(
                padding: EdgeInsetsDirectional.only(top: GzSpace.s6),
                child: TodayBodySkeleton(),
              ),
              onRetry: () => ref.invalidate(partnerTodayProvider),
              data: body,
            ),
          ],
        ),
      ),
    );
  }
}
