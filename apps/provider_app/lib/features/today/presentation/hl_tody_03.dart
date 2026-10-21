// HL-TODY-03 Notifications (web `HL-TODY-03.tsx`): everything the system told the venue, grouped by absolute day, with read and unread state. A new
// booking request is the one row that stands out; every other type is quiet ink. Each row opens its object with a rebuilt back stack (ADR 0008 D13).
// The filter is two glyph tabs (the unread count is a badge), mark all as read is a double tick, the empty states are a drawing and two words.
// Requirements: HA-NOTI-01..07, HA-DASH-05.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show AppNotification;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/today_data.dart';
import 'widgets/notif_row.dart';

enum _Filter { all, unread }

class HlTody03Screen extends ConsumerStatefulWidget {
  const HlTody03Screen({super.key});

  @override
  ConsumerState<HlTody03Screen> createState() => _HlTody03ScreenState();
}

class _HlTody03ScreenState extends ConsumerState<HlTody03Screen> {
  _Filter _filter = _Filter.all;

  /// The unread tab is a snapshot taken when you switch to it: rows do not jump under the thumb as they are read.
  Set<String> _snap = const <String>{};

  void _choose(_Filter next, List<AppNotification> all) {
    if (next == _Filter.unread) _snap = {for (final n in all.where((n) => !n.read)) n.id};
    setState(() => _filter = next);
  }

  Future<void> _markAll() async {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    await markNotificationsRead(ref);
    if (!mounted) return;
    setState(() => _snap = const <String>{});
    nav.toast(GzToastSpec(message: l.hotelTodayAllRead, tone: GzToastTone.success));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final nav = GzNavigatorScope.of(context);
    final now = ref.watch(clockProvider)();
    final today = f.isoDay(now);
    final value = ref.watch(partnerNotificationsProvider);
    Widget skeletonRow() => const Padding(
          padding: EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4),
          child: Row(
            children: [
              GzSkeleton(variant: GzSkeletonVariant.circle, inlineSize: 40),
              SizedBox(width: GzSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [GzSkeleton(inlineSize: 208, blockSize: 24), SizedBox(height: GzSpace.s1), GzSkeleton(blockSize: 20), SizedBox(height: GzSpace.s1), GzSkeleton(inlineSize: 136, blockSize: 20)],
                ),
              ),
            ],
          ),
        );
    return GzPullToRefresh(
      onRefresh: () async => ref.read(partnerDataRevisionProvider.notifier).bump(),
      child: GzScreen(
        top: GzTopBar(
          title: l.hotelTodayBell,
          actions: [GzTopBarAction(icon: GzIcons.settings, label: l.hotelTodayPrefs, onPressed: () => nav.push('HL-SETT-02'))],
        ),
        child: GzAsyncView<List<AppNotification>>(
          value: value,
          isEmpty: (list) => list.isEmpty,
          loading: Padding(padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter), child: Column(children: [for (var i = 0; i < 5; i++) skeletonRow()])),
          empty: GzEmptyState(illustration: GzIllustrationName.emptyNotifications, title: l.hotelTodayNotifEmptyTitle),
          onRetry: () => ref.invalidate(partnerNotificationsProvider),
          data: (all) {
            final unread = all.where((n) => !n.read).toList();
            final shown = _filter == _Filter.unread ? all.where((n) => _snap.contains(n.id)).toList() : all;
            final groups = <(String, List<AppNotification>)>[];
            for (final n in shown) {
              final day = f.isoDay(n.at);
              if (groups.isNotEmpty && groups.last.$1 == day) {
                groups.last.$2.add(n);
              } else {
                groups.add((day, [n]));
              }
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s3),
                  child: GzIconTabs<_Filter>(
                    label: l.hotelTodayNotifFilter,
                    value: _filter,
                    onChanged: (v) => _choose(v, all),
                    items: [
                      GzIconTabItem<_Filter>(value: _Filter.all, icon: GzIcons.list, label: context.gzL10n.commonFilterAll),
                      GzIconTabItem<_Filter>(value: _Filter.unread, icon: GzIcons.mail, label: l.hotelTodayInboxUnread, count: unread.isEmpty ? null : unread.length),
                    ],
                  ),
                ),
                if (shown.isEmpty)
                  GzEmptyState(
                    illustration: GzIllustrationName.seal,
                    title: l.hotelTodayNotifUnreadEmptyTitle,
                    fill: false,
                    action: GzStateAction(label: l.hotelTodayNotifShowAll, onPressed: () => _choose(_Filter.all, all)),
                  )
                else
                  for (var gi = 0; gi < groups.length; gi++) ...[
                    Container(
                      constraints: const BoxConstraints(minHeight: GzSize.controlSm),
                      margin: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s3),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderStrong, width: GzStroke.hair))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GzText(groups[gi].$1 == today ? context.gzL10n.commonLabelToday : f.date(groups[gi].$1, DateStyle.short), role: GzTextRole.label, color: c.textSecondary),
                          if (gi == 0 && unread.isNotEmpty) GzIconButton(icon: GzIcons.checkDouble, iconSize: GzIconSize.sm, label: l.hotelTodayMarkAllRead, onPressed: _markAll),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.s4),
                      child: Column(
                        children: [
                          for (var i = 0; i < groups[gi].$2.length; i++)
                            NotifRow(notification: groups[gi].$2[i], last: i == groups[gi].$2.length - 1, onOpen: () => openNotification(context, ref, groups[gi].$2[i])),
                        ],
                      ),
                    ),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}
