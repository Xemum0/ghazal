import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, venuesRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show AppNotification, NotificationKind;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/notification_view.dart';
import 'widgets/ntf_row.dart';
import 'widgets/ntf_sheets.dart';

/// CL-MSGS-04 Notifications (pushed from the bell). Covers CA-NOTI-01 to 08, CA-VCH-13, CA-VIS-06.
///
/// The in-app record of request updates, voucher events, visit and group-chat events, messages and wedding planning, grouped by day,
/// newest first. Each row is a glyph, at most two words, the venue as a quiet line and the clock; each lands on the exact object. The filter
/// is a row of six glyphs, then `Unread` and `Read all`. The pre-prompt sheet opens when the route asks (after the first request, never at
/// launch); a denied system permission shows a quiet banner. A venue that is no longer listed says so with similar halls.
/// States: default, loading, empty, error, offline, unread-only, pre-prompt, os-denied-banner, target-missing.
class ClMsgs04Screen extends ConsumerStatefulWidget {
  const ClMsgs04Screen({super.key});

  @override
  ConsumerState<ClMsgs04Screen> createState() => _ClMsgs04ScreenState();
}

class _ClMsgs04ScreenState extends ConsumerState<ClMsgs04Screen> {
  NtfFilter _filter = NtfFilter.all;
  bool _unreadOnly = false;
  Set<String> _snap = <String>{};
  bool _promptAsked = false;

  GzNavigator get _nav => context.gzNav;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_promptAsked) return;
    _promptAsked = true;
    final p = _nav.params;
    if (p['prompt'] == true && ref.read(ntfPermissionProvider) == NtfPermission.unknown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nav.openSheetBuilder((_) => const NtfPromptSheet(), options: const GzSheetOptions(dismissible: false));
      });
    }
    final missing = p['missingVenueId'];
    if (missing is String) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nav.openSheetBuilder((_) => NtfMissingSheet(venueId: missing));
      });
    }
  }

  Future<void> _land(AppNotification n) async {
    // Each row lands on its object; the wedding fallback enters the 'CL-WEDD-01' tab.
    final nav = _nav;
    unawaited(ref.read(notificationsProvider.notifier).markRead(n.id));
    switch (n.kind) {
      case NotificationKind.newVenue:
        final id = n.venueId;
        if (id == null) return;
        try {
          await ref.read(venuesRepositoryProvider).getVenue(venueId: id);
        } on Object {
          if (mounted) nav.openSheetBuilder((_) => NtfMissingSheet(venueId: id));
          return;
        }
        nav.push('CL-VENU-01', params: <String, Object?>{'venueId': id});
      case NotificationKind.requestApproved || NotificationKind.confirmReminder:
        nav.push('CL-BKNG-02', params: <String, Object?>{'bookingId': n.bookingId, 'section': 'confirm'});
      case NotificationKind.requestSent ||
          NotificationKind.requestConfirmed ||
          NotificationKind.requestDeclined ||
          NotificationKind.requestExpired ||
          NotificationKind.bookingCancelled ||
          NotificationKind.voucherRedeemed:
        nav.push('CL-BKNG-02', params: <String, Object?>{'bookingId': n.bookingId});
      case NotificationKind.voucherReady ||
          NotificationKind.voucherReleased ||
          NotificationKind.voucherExpiring ||
          NotificationKind.creditVoucherIssued ||
          NotificationKind.voucherForfeited:
        nav.push('CL-VCHR-03', params: <String, Object?>{'voucherId': n.voucherId});
      case NotificationKind.visitRequested || NotificationKind.visitConfirmed || NotificationKind.visitReminder || NotificationKind.visitMessage:
        nav.push('CL-VIST-03', params: <String, Object?>{'visitId': n.visitId, if (n.conversationId != null) 'conversationId': n.conversationId});
      case NotificationKind.message || NotificationKind.plannerAssigned:
        nav.push('CL-MSGS-02', params: <String, Object?>{if (n.conversationId != null) 'conversationId': n.conversationId});
      case NotificationKind.reviewPrompt:
        nav.push('CL-RVRW-02', params: <String, Object?>{'bookingId': n.bookingId});
      default:
        nav.switchTab('my-wedding');
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(notificationsProvider);
    try {
      await ref.read(notificationsProvider.future);
    } on Object {
      // the screen shows its own error state
    }
  }

  String _dayLabel(String day) {
    final f = context.gzFormat;
    return f.daysUntil(day) == 0 ? f.relativeDay(day) : f.date(day, DateStyle.dayMonth);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(notificationsProvider);
    final denied = ref.watch(ntfPermissionProvider) == NtfPermission.denied;
    final top = GzTopBar(
      title: l.clientMessagesNtfTitle,
      actions: [GzTopBarAction(icon: GzIcons.settings, label: l.clientMessagesNtfPrefs, onPressed: () => _nav.push('CL-PROF-04'))],
    );
    final emptyState = GzEmptyState(
      key: const ValueKey<String>('messages.ntf.empty'),
      illustration: GzIllustrationName.emptyNotifications,
      title: l.clientMessagesNtfEmptyTitle,
      action: GzStateAction(label: l.clientMessagesEmptyAction, variant: GzButtonVariant.primary, onPressed: () => _nav.switchTab('discover')),
    );
    final Widget body = GzAsyncView<NotificationsState>(
      value: async,
      loading: const _NtfSkeleton(),
      isEmpty: (s) => s.items.isEmpty,
      empty: emptyState,
      onRetry: () => ref.invalidate(notificationsProvider),
      data: (s) => _content(s, denied),
    );
    return GzPullToRefresh(
      onRefresh: _refresh,
      child: GzScreen(top: top, child: body),
    );
  }

  Widget _content(NotificationsState s, bool denied) {
    final l = context.l10n;
    final g = context.gzL10n;
    final items = s.items;
    final unreadCount = items.where((n) => !n.read).length;
    final shown = items
        .where((n) => (_filter == NtfFilter.all || filterOfKind(n.kind) == _filter) && (!_unreadOnly || _snap.contains(n.id)))
        .toList();
    final f = context.gzFormat;
    final groups = <(String, List<AppNotification>)>[];
    for (final n in shown) {
      final day = f.isoDay(n.at);
      if (groups.isNotEmpty && groups.last.$1 == day) {
        groups.last.$2.add(n);
      } else {
        groups.add((day, [n]));
      }
    }
    final c = context.gz.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (denied)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s3),
            child: GzBanner(
              message: l.clientMessagesNtfDeniedTitle,
              icon: GzIcons.bell,
              shape: GzBannerShape.card,
              actionLabel: l.clientMessagesNtfOpenSettings,
              onAction: () => _nav.toast(GzToastSpec(message: l.clientMessagesNtfSettingsToast)),
            ),
          ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.s2),
          child: GzIconTabs<NtfFilter>(
            label: l.clientMessagesNtfFilterGroup,
            value: _filter,
            onChanged: (v) => setState(() => _filter = v),
            items: [
              GzIconTabItem(value: NtfFilter.all, icon: GzIcons.list, label: g.commonFilterAll),
              GzIconTabItem(value: NtfFilter.bookings, icon: GzIcons.send, label: l.clientMessagesNtfBookings),
              GzIconTabItem(value: NtfFilter.vouchers, icon: GzIcons.ticket, label: l.clientMessagesNtfVouchers),
              GzIconTabItem(value: NtfFilter.visits, icon: GzIcons.calendarCheck, label: l.clientMessagesNtfVisits),
              GzIconTabItem(value: NtfFilter.messages, icon: GzIcons.chat, label: l.clientMessagesNtfMessages),
              GzIconTabItem(value: NtfFilter.planning, icon: GzIcons.checklist, label: l.clientMessagesNtfPlanning),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.s2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GzChip(
                key: const ValueKey<String>('messages.ntf.unreadonly'),
                label: l.clientMessagesNtfUnreadOnly,
                selected: _unreadOnly,
                onPressed: () => setState(() {
                  if (!_unreadOnly) {
                    _snap = {
                      for (final n in items)
                        if (!n.read) n.id,
                    };
                  }
                  _unreadOnly = !_unreadOnly;
                }),
              ),
              if (unreadCount > 0)
                GzButton(
                  key: const ValueKey<String>('messages.ntf.readall'),
                  label: l.clientMessagesNtfMarkAll,
                  variant: GzButtonVariant.tertiary,
                  iconStart: GzIcons.checkDouble,
                  onPressed: () async {
                    await ref.read(notificationsProvider.notifier).markAllRead();
                    if (!mounted) return;
                    setState(() => _snap = <String>{});
                    _nav.toast(GzToastSpec(message: l.clientMessagesNtfAllRead, tone: GzToastTone.success));
                  },
                ),
            ],
          ),
        ),
        if (shown.isEmpty)
          GzEmptyState(
            key: const ValueKey<String>('messages.ntf.filtered-empty'),
            fill: false,
            illustration: _unreadOnly ? GzIllustrationName.seal : GzIllustrationName.emptyNotifications,
            title: _unreadOnly ? l.clientMessagesNtfUnreadEmptyTitle : g.commonStateTitleEmpty,
            action: GzStateAction(
              label: l.clientMessagesNtfShowAll,
              onPressed: () => setState(() {
                _unreadOnly = false;
                _filter = NtfFilter.all;
              }),
            ),
          )
        else
          for (final (day, list) in groups) ...[
            Padding(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4, bottom: GzSpace.s1),
              child: GzText(_dayLabel(day), role: GzTextRole.label, color: c.textSecondary, header: true, figures: true),
            ),
            for (var i = 0; i < list.length; i++)
              RepaintBoundary(
                child: NtfRow(notification: list[i], last: i == list.length - 1, onOpen: () => _land(list[i])),
              ),
          ],
        const SizedBox(height: GzSpace.s8),
      ],
    );
  }
}

class _NtfSkeleton extends StatelessWidget {
  const _NtfSkeleton();

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
                      const GzSkeleton(variant: GzSkeletonVariant.circle, inlineSize: 40, blockSize: 40),
                      const SizedBox(width: GzSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GzSkeleton(inlineSize: i.isOdd ? 160 : 208, blockSize: 24),
                            const SizedBox(height: GzSpace.s1),
                            const GzSkeleton(inlineSize: 136, blockSize: 20),
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
