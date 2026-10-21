// HL-TODY-04 Messages (the Messages tab root; web `HL-TODY-04.tsx`): the shared inbox of client conversations. Who is waiting for me: unread
// counts, the booking each conversation belongs to with its own status glyph, `Needs reply` with the time waited once a client message is older than
// 30 minutes, Ghazal Support pinned on top. A press and hold opens Mark as read or unread (no swipe actions, ADR 0014 D4).
// Requirements: HA-MSG-01, HA-MSG-04, HA-MSG-05, HA-DASH-06, HA-NOTI-05.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_core/ghazal_core.dart' show clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show ConversationKind;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/today_data.dart';
import 'widgets/inbox_row.dart';

enum _Filter { all, unread, needs, linked, visit, enquiry }

class HlTody04Screen extends ConsumerStatefulWidget {
  const HlTody04Screen({super.key});

  @override
  ConsumerState<HlTody04Screen> createState() => _HlTody04ScreenState();
}

class _HlTody04ScreenState extends ConsumerState<HlTody04Screen> {
  _Filter _filter = _Filter.all;
  String _query = '';

  void _open(InboxEntry e) {
    final nav = GzNavigatorScope.of(context);
    ref.read(inboxLocalProvider.notifier).open(e.conversation.id);
    markConversationReadUpToLast(ref, e);
    if (e.conversation.kind == ConversationKind.visitGroup) {
      nav.push('HL-VIST-03', params: {'visitId': e.conversation.visitId});
    } else {
      nav.push('HL-TODY-05', params: {'conversationId': e.conversation.id, 'bookingId': e.conversation.bookingId});
    }
  }

  void _longPress(InboxEntry e, int unread) {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    final lang = context.gz.locale.languageCode;
    final isUnread = unread > 0;
    nav.openSheetBuilder(
      (sheetContext) => Padding(
        padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s2),
        child: GzButton(
          label: isUnread ? l.hotelTodayMarkRead : l.hotelTodayMarkUnread,
          variant: GzButtonVariant.secondary,
          fullWidth: true,
          iconStart: isUnread ? GzIcons.check : GzIcons.chat,
          onPressed: () {
            ref.read(inboxLocalProvider.notifier).setUnread(e.conversation.id, !isUnread);
            nav.closeSheet();
          },
        ),
      ),
      options: GzSheetOptions(title: e.conversation.kind == ConversationKind.support ? e.conversation.title.of(lang) : e.conversation.clientName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final now = ref.watch(clockProvider)();
    final local = ref.watch(inboxLocalProvider);
    final unreadNotifications = ref.watch(unreadNotificationCountProvider);
    final value = ref.watch(inboxProvider);
    final provider = ref.watch(partnerContextProvider)?.isProvider ?? false;

    bool needs(InboxEntry e) {
      final since = e.conversation.awaitingReplySince;
      return since != null && e.conversation.kind != ConversationKind.support && now.difference(since).inMinutes > kNeedsReplyAfterMinutes;
    }

    Widget skeletonRow() => const Padding(
          padding: EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4),
          child: Row(
            children: [
              GzSkeleton(variant: GzSkeletonVariant.circle, inlineSize: 48),
              SizedBox(width: GzSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [GzSkeleton(inlineSize: 160, blockSize: 24), SizedBox(height: GzSpace.s1), GzSkeleton(blockSize: 20), SizedBox(height: GzSpace.s1), GzSkeleton(inlineSize: 136, blockSize: 24)],
                ),
              ),
            ],
          ),
        );

    return GzPullToRefresh(
      onRefresh: () async => ref.read(partnerDataRevisionProvider.notifier).bump(),
      child: GzScreen(
        top: GzTopBar(
          variant: GzTopBarVariant.largeTitle,
          title: l.hotelTodayInboxTitle,
          back: GzTopBarBack.hide,
          actions: [
            GzTopBarAction(
              icon: GzIcons.bell,
              label: unreadNotifications > 0 ? l.hotelTodayBellUnread(unreadNotifications) : l.hotelTodayBell,
              count: unreadNotifications > 0 ? unreadNotifications : null,
              onPressed: () => nav.push('HL-TODY-03'),
            ),
          ],
        ),
        child: GzAsyncView<List<InboxEntry>>(
          value: value,
          isEmpty: (list) => list.isEmpty,
          loading: Padding(padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter), child: Column(children: [for (var i = 0; i < 4; i++) skeletonRow()])),
          empty: GzEmptyState(illustration: GzIllustrationName.emptyMessages, title: l.hotelTodayInboxEmptyTitle),
          onRetry: () => ref.invalidate(inboxProvider),
          data: (all0) {
            final all = provider ? all0.where((e) => e.conversation.kind == ConversationKind.support).toList() : all0;
            final counts = (unread: all.where((e) => local.unreadOf(e.conversation) > 0).length, needs: all.where(needs).length);
            final rows = all.where((e) {
              final cv = e.conversation;
              if (_filter == _Filter.unread && local.unreadOf(cv) == 0) return false;
              if (_filter == _Filter.needs && !needs(e)) return false;
              if (_filter == _Filter.linked && cv.bookingId == null) return false;
              if (_filter == _Filter.visit && cv.kind != ConversationKind.visitGroup) return false;
              if (_filter == _Filter.enquiry && cv.kind != ConversationKind.enquiry) return false;
              return gzMatchesSearch(_query, cv.clientName, cv.title.en, cv.title.ar) || gzMatchesSearch(_query, e.booking?.booking.ref);
            }).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!provider) ...[
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.s3),
                    child: GzSearchField(label: l.hotelTodayInboxSearchLabel, placeholder: l.hotelTodayInboxSearch, value: _query, onValueChange: (v) => setState(() => _query = v)),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.s1),
                    child: GzIconTabs<_Filter>(
                      label: l.hotelTodayInboxFilters,
                      value: _filter,
                      onChanged: (v) => setState(() => _filter = v),
                      items: [
                        GzIconTabItem(value: _Filter.all, icon: GzIcons.list, label: context.gzL10n.commonFilterAll),
                        GzIconTabItem(value: _Filter.unread, icon: GzIcons.mail, label: l.hotelTodayInboxUnread, count: counts.unread == 0 ? null : counts.unread),
                        GzIconTabItem(value: _Filter.needs, icon: GzIcons.reply, label: l.hotelTodayInboxNeedsReply, count: counts.needs == 0 ? null : counts.needs),
                        GzIconTabItem(value: _Filter.linked, icon: GzIcons.link, label: l.hotelTodayInboxLinked),
                        GzIconTabItem(value: _Filter.visit, icon: GzIcons.usersThree, label: l.hotelTodayInboxVisits),
                        GzIconTabItem(value: _Filter.enquiry, icon: GzIcons.help, label: l.hotelTodayInboxEnquiries),
                      ],
                    ),
                  ),
                ],
                if (rows.isEmpty)
                  _query.isNotEmpty
                      ? GzEmptyState(
                          illustration: GzIllustrationName.noResult,
                          title: l.hotelTodayInboxNoResultsTitle,
                          fill: false,
                          action: GzStateAction(label: l.hotelTodayClearSearch, onPressed: () => setState(() => _query = '')),
                        )
                      : GzEmptyState(
                          illustration: GzIllustrationName.emptyMessages,
                          title: l.hotelTodayInboxEmptyTitle,
                          fill: false,
                          action: GzStateAction(label: l.hotelTodayNotifShowAll, onPressed: () => setState(() => _filter = _Filter.all)),
                        )
                else
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.s8),
                    child: Column(
                      children: [
                        for (var i = 0; i < rows.length; i++)
                          InboxRow(
                            entry: rows[i],
                            unread: local.unreadOf(rows[i].conversation),
                            last: i == rows.length - 1,
                            onOpen: () => _open(rows[i]),
                            onLongPress: () => _longPress(rows[i], local.unreadOf(rows[i].conversation)),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
