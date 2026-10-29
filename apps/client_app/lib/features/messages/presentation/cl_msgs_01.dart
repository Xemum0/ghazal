import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_domain/ghazal_domain.dart' show ConversationKind;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/inbox.dart';

import 'widgets/inbox_row.dart';

/// CL-MSGS-01 Messages (Messages tab root). Covers CA-CHAT-01, CA-CHAT-05, CA-CHAT-10, CA-NOTI-06, CA-VIS-03.
///
/// One thread per counterpart (venue, planner, service provider, Ghazal Support) plus one group chat per site visit, each a monogram, a
/// name, a clock, one short line of the last message and the unread count. The filter is a row of glyphs; the Visits glyph holds the group
/// chats, which open CL-VIST-03. Support is pinned on top and always available. The bell opens the notification centre. An empty inbox is a drawing,
/// three words and one action.
/// States: default, loading, empty, error, offline, support-refund-request.
class ClMsgs01Screen extends ConsumerStatefulWidget {
  const ClMsgs01Screen({super.key});

  @override
  ConsumerState<ClMsgs01Screen> createState() => _ClMsgs01ScreenState();
}

class _ClMsgs01ScreenState extends ConsumerState<ClMsgs01Screen> {
  InboxFilter _filter = InboxFilter.all;

  GzNavigator get _nav => context.gzNav;

  void _open(InboxRow r) {
    final c = r.conversation;
    if (c.kind == ConversationKind.support) {
      _nav.push('CL-MSGS-02', params: <String, Object?>{'conversationId': c.id, 'support': true});
    } else if (c.kind == ConversationKind.visitGroup) {
      _nav.push('CL-VIST-03', params: <String, Object?>{'visitId': c.visitId, 'conversationId': c.id});
    } else {
      _nav.push('CL-MSGS-02', params: <String, Object?>{'conversationId': c.id, if (c.venueId != null) 'venueId': c.venueId});
    }
  }

  void _openSupport() => _nav.push('CL-MSGS-02', params: const <String, Object?>{'support': true});
  // The empty state lands on the Discover tab root ('CL-DISC-01').

  Future<void> _refresh() async {
    ref.invalidate(inboxProvider);
    try {
      await ref.read(inboxProvider.future);
    } on Object {
      // the screen shows its own error state
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final unread = ref.watch(unreadNotificationsProvider);
    final inbox = ref.watch(inboxProvider);

    final top = GzTopBar(
      variant: GzTopBarVariant.largeTitle,
      title: l.clientMessagesInboxTitle,
      back: GzTopBarBack.hide,
      actions: [
        GzTopBarAction(
          icon: GzIcons.bell,
          label: l.clientMessagesBellUnread(unread),
          count: unread > 0 ? unread : null,
          onPressed: () => _nav.push('CL-MSGS-04'),
        ),
      ],
    );

    final Widget body = GzAsyncView<List<InboxRow>>(
      value: inbox,
      loading: const _InboxSkeleton(),
      isEmpty: (rows) => rows.isEmpty,
      empty: GzEmptyState(
        key: const ValueKey<String>('messages.empty'),
        illustration: GzIllustrationName.emptyMessages,
        title: l.clientMessagesEmptyTitle,
        action: GzStateAction(label: l.clientMessagesEmptyAction, variant: GzButtonVariant.primary, onPressed: () => _nav.switchTab('discover')),
        secondary: GzStateAction(label: l.clientMessagesEmptySupport, iconStart: GzIcons.headset, onPressed: _openSupport),
      ),
      onRetry: () => ref.invalidate(inboxProvider),
      data: _list,
    );
    return GzPullToRefresh(
      onRefresh: _refresh,
      child: GzScreen(top: top, child: body),
    );
  }

  Widget _tabs(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.s2),
      child: GzIconTabs<InboxFilter>(
        label: l.clientMessagesFilterGroup,
        labels: GzIconTabsLabels.selected,
        value: _filter,
        onChanged: (v) => setState(() => _filter = v),
        items: [
          GzIconTabItem(value: InboxFilter.all, icon: GzIcons.list, label: context.gzL10n.commonFilterAll),
          GzIconTabItem(value: InboxFilter.venues, icon: GzIcons.hall, label: l.clientMessagesFilterVenues),
          GzIconTabItem(value: InboxFilter.visits, icon: GzIcons.calendarCheck, label: l.clientMessagesFilterVisits),
          GzIconTabItem(value: InboxFilter.planner, icon: GzIcons.user, label: l.clientMessagesFilterPlanner),
          GzIconTabItem(value: InboxFilter.providers, icon: GzIcons.sparkle, label: l.clientMessagesFilterProviders),
          GzIconTabItem(value: InboxFilter.support, icon: GzIcons.headset, label: l.clientMessagesFilterSupport),
        ],
      ),
    );
  }

  Widget _list(List<InboxRow> rows) {
    final shown = _filter == InboxFilter.all ? rows : rows.where((r) => filterOf(r.conversation) == _filter).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tabs(context),
        if (shown.isEmpty)
          GzEmptyState(
            key: const ValueKey<String>('messages.filtered-empty'),
            illustration: GzIllustrationName.emptyMessages,
            title: context.gzL10n.commonStateTitleEmpty,
            fill: false,
            action: GzStateAction(label: context.gzL10n.commonFilterAll, onPressed: () => setState(() => _filter = InboxFilter.all)),
          )
        else
          Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.s8),
            child: Column(
              children: [
                for (var i = 0; i < shown.length; i++)
                  RepaintBoundary(
                    child: InboxRowTile(row: shown[i], last: i == shown.length - 1, onOpen: () => _open(shown[i])),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InboxSkeleton extends StatelessWidget {
  const _InboxSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      container: true,
      label: context.gzL10n.commonStateLoading,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
          child: Column(
            children: [
              for (var i = 0; i < 5; i++)
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GzSkeleton(variant: GzSkeletonVariant.circle, inlineSize: 56, blockSize: 56),
                      const SizedBox(width: GzSpace.s4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GzSkeleton(inlineSize: i.isOdd ? 176 : 216, blockSize: 24),
                            const SizedBox(height: GzSpace.s1),
                            const GzSkeleton(blockSize: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
