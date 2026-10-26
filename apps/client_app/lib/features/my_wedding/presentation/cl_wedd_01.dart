import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemKind, gzProblemMessage, sessionProvider;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, ScreenState, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'widgets/wd_common.dart' show WdBi, WdGap, WdPad, wdStamp;
import '../application/wedding_data.dart';
import 'widgets/wedding_bits.dart';
import 'widgets/wedding_hero.dart';

/// CL-WEDD-01 My Wedding (tab root). Covers CA-TOOL-17, CA-TOOL-18, CA-TOOL-19, CA-TOOL-16, CA-STAT-01, CA-PLAN-02, CA-PLAN-09,
/// CA-PROF-02, CA-ONB-09, CA-NOTI-08, CA-AUTH-10, CA-STAT-11, CA-VCH-06.
///
/// The phase-aware home of the wedding file: the countdown hero (whole days only), up to three Next up actions, the Bookings card, the
/// planner offer or card, and the tools row (Checklist, Budget, Saved, Services). Calm figures, glyphs and one drawing per state; no
/// sentence on the screen. A guest sees the sample structure and is asked to sign in at the first write.
class ClWedd01Screen extends ConsumerWidget {
  const ClWedd01Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = context.gzNav;
    final guest = !ref.watch(sessionProvider.select((s) => s.isSignedIn));
    final unread = ref.watch(unreadNotificationsProvider);
    final async = ref.watch(weddingOverviewProvider);
    final top = GzTopBar(
      variant: GzTopBarVariant.largeTitle,
      title: l.clientMyWeddingHubTitle,
      actions: [
        GzTopBarAction(
          icon: GzIcons.bell,
          label: l.clientMyWeddingHubNotifications,
          count: guest || unread == 0 ? null : unread,
          onPressed: () => nav.push('CL-MSGS-04'),
        ),
      ],
      back: GzTopBarBack.hide,
    );
    if (guest) return GzScreen(top: top, child: _guest(context));
    final state = ScreenState.from<WeddingOverview?>(async);
    return GzScreen(
      top: top,
      child: state.when(
        loading: () => const WdHubSkeleton(),
        data: (overview) => overview == null ? _noFile(context) : _hub(context, ref, overview),
        empty: () => _noFile(context),
        error: (p) => GzErrorState(
          kind: gzProblemKind(p),
          body: gzProblemMessage(context.gzL10n, p),
          onRetry: () => ref.invalidate(weddingOverviewProvider),
          fill: false,
        ),
        offline: (stale) => stale == null
            ? GzOfflineState(onRetry: () => ref.invalidate(weddingOverviewProvider), fill: false)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GzBanner(message: context.gzL10n.commonStateOffline, tone: GzBannerTone.offline, shape: GzBannerShape.flush),
                  _hub(context, ref, stale),
                ],
              ),
      ),
    );
  }

  /// A guest sees the structure with sample values and signs in at the first write.
  Widget _guest(BuildContext context) {
    final l = context.l10n;
    final nav = context.gzNav;
    return WdPad(
      child: WdGap(
        children: [
          WdLeadCard(
            illustration: GzIllustrationName.key,
            title: l.clientMyWeddingSample,
            actionLabel: l.clientMyWeddingGuestAction,
            onAction: () => nav.openSheet('CL-AUTH-01'),
          ),
          GzSectionHeader(title: l.clientMyWeddingToolsLabel),
          _toolsRow(context, checklist: null, budget: null, saved: 0),
        ],
      ),
    );
  }

  /// Signed in but no wedding file yet: set the date, then the hub fills in.
  Widget _noFile(BuildContext context) {
    return WdPad(child: WeddingHero.noDate(onSetDate: () => context.gzNav.openSheet('CL-DISC-02')));
  }

  Widget _hub(BuildContext context, WidgetRef ref, WeddingOverview overview) {
    final now = ref.watch(clockProvider)();
    final rows = ref.watch(weddingRequestsProvider).value ?? overview.openRequests;
    final profile = overview.profile;
    final phase = weddingPhaseOf(guest: false, profile: profile, rows: rows, now: now);
    final booking = hubBooking(rows);
    final days = overview.daysToWedding ?? weddingDaysLeft(profile?.weddingDate, now);
    final weddingDate = profile?.weddingDate;
    final unbound = ref.watch(unboundVoucherProvider).value;
    final hero = weddingDate == null
        ? WeddingHero.noDate(onSetDate: () => context.gzNav.openSheet('CL-DISC-02'))
        : phase == WeddingPhase.postEvent
        ? WeddingHero.done(eventDate: weddingDate, onDate: () => context.gzNav.push('CL-PROF-02'))
        : WeddingHero.count(
            days: days,
            eventDate: weddingDate,
            onDate: () => context.gzNav.push('CL-PROF-02'),
            children: days == 0 ? wdDayOfActions(context) : const <Widget>[],
          );
    final top = <Widget>[
      hero,
      if (phase == WeddingPhase.awaitingConfirm && booking?.booking.confirmBy != null) WdConfirmLead(confirmBy: booking!.booking.confirmBy!),
      if (unbound != null && phase == WeddingPhase.preVenue) _VoucherLead(item: unbound),
      ..._leads(context, phase, booking),
    ];
    final sections = <Widget>[
      WdPad(child: WdGap(gap: GzSpace.s4, children: top)),
      _nextUp(context, ref, overview, phase, booking),
      _bookingsSection(context, rows, booking),
      _plannerSection(context, overview),
      WdPad(
        child: _toolsRow(
          context,
          checklist: overview.checklist,
          budget: overview.budget,
          saved: ref.watch(favouritesProvider.select((a) => a.value?.total ?? 0)),
        ),
      ),
    ];
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < sections.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.section), sections[i]],
        ],
      ),
    );
  }

  /// The one lead action of a phase (voucher waiting for its request, halls free on the date, the post-event review).
  List<Widget> _leads(BuildContext context, WeddingPhase phase, BookingRow? booking) {
    final l = context.l10n;
    final nav = context.gzNav;
    return switch (phase) {
      WeddingPhase.postEvent => [
        WdPad(
          child: WdLeadCard(
            illustration: GzIllustrationName.successBooking,
            title: booking == null ? '' : context.bi(booking.target.name),
            actionLabel: l.clientMyWeddingDoneReviewAction,
            onAction: () => nav.push('CL-RVRW-02', params: <String, Object?>{'bookingId': booking!.booking.id}),
          ),
        ),
      ],
      WeddingPhase.preVenue => [
        WdPad(
          child: WdLeadCard(
            illustration: GzIllustrationName.hall,
            title: l.clientMyWeddingNextHalls,
            actionLabel: l.clientMyWeddingNextHalls,
            onAction: () => nav.switchTab('discover'),
          ),
        ),
      ],
      _ => const <Widget>[],
    };
  }

  /// Next up: at most three actions, due first. The request's own step first (waiting for the venue, as time left), then the
  /// next dated checklist tasks with a service (soonest first). What has its own card (the 24 h confirmation, the hall search, the
  /// planner) is never repeated as a row.
  Widget _nextUp(BuildContext context, WidgetRef ref, WeddingOverview overview, WeddingPhase phase, BookingRow? booking) {
    final l = context.l10n;
    final f = context.gzFormat;
    final now = ref.watch(clockProvider)();
    final items = <NextUp>[];
    if (phase == WeddingPhase.pending && booking?.booking.respondBy != null) {
      final replyBy = booking!.booking.respondBy!;
      final left = replyBy.difference(now);
      final when = left.isNegative ? wdStamp(f, replyBy) : f.duration(left.inMilliseconds);
      items.add(
        NextUp(
          icon: GzIcons.hourglass,
          title: l.clientMyWeddingNextWaiting,
          fact: when,
          factLabel: l.clientMyWeddingNextWaitingLabel(when),
          route: 'CL-BKNG-02',
          params: <String, Object?>{'bookingId': booking.booking.id},
        ),
      );
    }
    if (phase == WeddingPhase.dayOf || phase == WeddingPhase.postEvent) return const SizedBox.shrink();
    if (phase == WeddingPhase.weddingWeek) {
      final remaining = overview.checklist.total - overview.checklist.done;
      if (remaining <= 0) return const SizedBox.shrink();
      final countRow = NextUp(
        icon: GzIcons.checklist,
        title: l.clientMyWeddingToolChecklist,
        fact: f.integer(remaining),
        factLabel: l.clientMyWeddingTasksLeft(remaining),
        route: 'CL-WEDD-02',
      );
      return _nextUpList(context, [countRow]);
    }
    final tasks = ref.watch(weddingChecklistProvider).value?.items ?? const <ChecklistItem>[];
    final open = tasks.where((t) => !t.done && !t.auto && t.serviceCategoryId != null).toList()
      ..sort((a, b) => (a.dueOn?.toString() ?? '9999').compareTo(b.dueOn?.toString() ?? '9999'));
    for (final t in open) {
      if (items.length >= 3) break;
      items.add(
        NextUp(
          icon: _taskGlyph(t.id),
          title: _taskTitle(context, t),
          fact: t.dueOn == null ? '' : f.date(t.dueOn.toString(), DateStyle.dayMonth),
          factLabel: t.dueOn == null ? '' : l.clientMyWeddingChecklistDue(f.date(t.dueOn.toString(), DateStyle.short)),
          route: 'CL-SERV-02',
          params: <String, Object?>{'categoryId': t.serviceCategoryId!.value},
        ),
      );
    }
    final next = items.take(3).toList();
    if (next.isEmpty) return const SizedBox.shrink();
    return _nextUpList(context, next);
  }

  Widget _nextUpList(BuildContext context, List<NextUp> next) {
    final l = context.l10n;
    final nav = context.gzNav;
    void go(NextUp n) => n.sheet ? nav.openSheet(n.route, options: GzSheetOptions(params: n.params)) : nav.push(n.route, params: n.params);
    return WdPad(
      child: WdGap(
        gap: GzSpace.s3,
        children: [
          GzSectionHeader(title: l.clientMyWeddingNextTitle, draw: GzDraw.mount),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final n in next)
                GzIconListRow(
                  flush: true,
                  chevron: true,
                  last: n == next.last,
                  icon: n.icon,
                  title: n.title,
                  trailing: n.fact.isEmpty ? null : GzFactChip(icon: GzIcons.calendar, label: n.factLabel, value: n.fact, small: true),
                  onPressed: () => go(n),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _taskGlyph(String id) => switch (id) {
    'chk-venue' => GzIcons.hall,
    'chk-photographer' => GzIcons.camera,
    'chk-dress' => GzIcons.dress,
    'chk-invitations' => GzIcons.mail,
    'chk-cake' => GzIcons.cake,
    'chk-music' => GzIcons.music,
    'chk-flowers' => GzIcons.flower,
    'chk-transport' => GzIcons.car,
    'chk-bukhoor' => GzIcons.incense,
    _ => GzIcons.notes,
  };

  String _taskTitle(BuildContext context, ChecklistItem item) {
    final l = context.l10n;
    return switch (item.id) {
      'chk-venue' => l.clientMyWeddingTaskVenue,
      'chk-photographer' => l.clientMyWeddingTaskPhotographer,
      'chk-dress' => l.clientMyWeddingTaskDress,
      'chk-invitations' => l.clientMyWeddingTaskInvitations,
      'chk-cake' => l.clientMyWeddingTaskCake,
      'chk-music' => l.clientMyWeddingTaskMusic,
      'chk-flowers' => l.clientMyWeddingTaskFlowers,
      'chk-transport' => l.clientMyWeddingTaskTransport,
      _ => context.bi(item.title),
    };
  }

  /// The Bookings card (top, one per booking with its status) and All bookings.
  Widget _bookingsSection(BuildContext context, List<BookingRow> rows, BookingRow? booking) {
    final l = context.l10n;
    final nav = context.gzNav;
    return WdPad(
      child: WdGap(
        gap: GzSpace.s3,
        children: [
          GzSectionHeader(
            title: l.clientMyWeddingBookingsTitle,
            draw: GzDraw.mount,
            onSeeAll: () => nav.push('CL-BKNG-01'),
            seeAllLabel: context.gzL10n.commonFilterAll,
          ),
          if (booking != null)
            RepaintBoundary(
              child: GzBookingCard(
                booking: booking.booking,
                target: booking.target,
                halls: booking.halls,
                onOpen: () => nav.push('CL-BKNG-02', params: <String, Object?>{'bookingId': booking.booking.id}),
              ),
            )
          else
            GzIconListRow(
              flush: true,
              chevron: true,
              last: true,
              illustration: GzIllustrationName.emptyBookings,
              title: l.clientMyWeddingBookingsEmptyAction,
              onPressed: () => nav.switchTab('discover'),
            ),
        ],
      ),
    );
  }

  /// The planner offer (until dismissed or after a booking event) or the assigned planner card.
  Widget _plannerSection(BuildContext context, WeddingOverview overview) {
    final l = context.l10n;
    final nav = context.gzNav;
    final request = overview.plannerRequest;
    if (request == null) {
      return WdPad(
        child: WdGap(
          gap: GzSpace.s3,
          children: [
            GzSectionHeader(title: l.clientMyWeddingPlannerTitle, draw: GzDraw.mount),
            const WdPlannerOffer(),
          ],
        ),
      );
    }
    return WdPad(
      child: WdGap(
        gap: GzSpace.s3,
        children: [
          GzSectionHeader(title: l.clientMyWeddingPlannerTitle, draw: GzDraw.mount),
          GzIconListRow(
            flush: true,
            chevron: true,
            last: true,
            icon: GzIcons.sparkle,
            title: l.clientMyWeddingPlannerTitle,
            onPressed: () => nav.push('CL-PLAN-03'),
          ),
        ],
      ),
    );
  }

  /// The tools row: Checklist (percent, fraction, gold line), Budget (remaining), Saved, Services.
  Widget _toolsRow(BuildContext context, {required ChecklistProgress? checklist, required BudgetSummary? budget, required int saved}) {
    final l = context.l10n;
    final f = context.gzFormat;
    final nav = context.gzNav;
    final over = budget != null && budget.remaining.fils < 0;
    return WdGap(
      gap: GzSpace.s3,
      children: [
        GzSectionHeader(title: l.clientMyWeddingToolsLabel, draw: GzDraw.mount),
        Row(
          children: [
            Expanded(
              child: WdToolTile(
                icon: GzIcons.checklist,
                label: l.clientMyWeddingToolChecklist,
                value: checklist == null ? null : f.percent(checklist.percent),
                share: checklist == null || checklist.total == 0 ? 0 : checklist.done / checklist.total,
                onPressed: () => nav.push('CL-WEDD-02'),
              ),
            ),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: WdToolTile(
                icon: over ? GzIcons.warningCircle : GzIcons.coins,
                label: over ? l.clientMyWeddingToolBudgetOver : l.clientMyWeddingToolBudget,
                value: budget == null ? null : f.money(budget.remaining.fils.abs()),
                onPressed: () => nav.push('CL-WEDD-03'),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: WdToolTile(
                icon: GzIcons.heart,
                label: l.clientMyWeddingToolSaved,
                value: f.integer(saved),
                onPressed: () => nav.switchTab('saved'),
              ),
            ),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: WdToolTile(icon: GzIcons.sparkle, label: l.clientMyWeddingToolServices, onPressed: () => nav.push('CL-SERV-01')),
            ),
          ],
        ),
      ],
    );
  }
}

/// A paid voucher waits for its request: the ticket drawing, the hall it is bound to, the day it lapses, one verb.
class _VoucherLead extends StatelessWidget {
  const _VoucherLead({required this.item});

  final WalletItem item;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final name = item.target == null ? '' : context.bi(item.target!.name);
    final until = item.voucher.validUntil;
    return WdLeadCard(
      illustration: GzIllustrationName.voucher,
      title: name,
      actionLabel: l.clientMyWeddingVoucherOpen,
      onAction: () => context.gzNav.push('CL-VCHR-02'),
      fact: until == null ? null : (GzIcons.calendar, l.commonValidUntil(f.date(until.toString(), DateStyle.short)), f.date(until.toString(), DateStyle.dayMonth)),
    );
  }
}

/// The 24 h confirm window as one figure and one verb (the largest numeral below the hero).
