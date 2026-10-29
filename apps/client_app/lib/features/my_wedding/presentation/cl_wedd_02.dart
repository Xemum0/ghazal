import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_app/app/state/state.dart' show clientDataRevisionProvider, weddingProfileProvider;
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemMessage, weddingRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'widgets/wd_checklist_parts.dart';
import 'widgets/wd_common.dart' show WdGap, WdPad;
import '../application/wedding_data.dart';

/// CL-WEDD-02 Checklist. Covers CA-TOOL-12, CA-TOOL-13, CA-TOOL-14, CA-TOOL-15, CA-TOOL-16, CA-AUTH-10.
///
/// The rules-based checklist with the PRD defaults (pushed from My Wedding 'CL-WEDD-01'), due dates counted back from the wedding date,
/// custom items, a completion percentage and deep links into Services. The Venue item completes automatically when a booking is
/// confirmed. Ticking draws the check and moves the row to Completed with an Undo snackbar; finishing everything earns one quiet line;
/// offline the list is read only.
class ClWedd02Screen extends ConsumerWidget {
  const ClWedd02Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(weddingChecklistProvider);
    final top = GzTopBar(
      title: l.clientMyWeddingChecklistTitle,
      actions: [GzTopBarAction(icon: GzIcons.plus, label: l.clientMyWeddingChecklistAdd, onPressed: () => _add(context, ref))],
    );
    return GzScreen(
      top: top,
      child: BkChecklistAsync(
        value: async,
        onRetry: () => ref.invalidate(weddingChecklistProvider),
        data: (view) => _list(context, ref, view),
        empty: _emptyNoDate(context),
        showEmpty: ref.watch(weddingProfileProvider).value == null,
      ),
    );
  }

  void _add(BuildContext context, WidgetRef ref) {
    context.gzNav.openSheet('CL-WEDD-04', options: GzSheetOptions(params: <String, Object?>{'task': true}));
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, ChecklistItem item, bool next) async {
    final repo = ref.read(weddingRepositoryProvider);
    try {
      await repo.updateChecklistItem(itemId: item.id, body: ChecklistItemPatch(done: next));
      ref.read(clientDataRevisionProvider.notifier).bump();
      if (next && context.mounted) {
        context.gzNav.toast(
          GzToastSpec(
            message: context.l10n.clientMyWeddingChecklistToastDone,
            undo: true,
            action: GzToastAction(
              label: context.gzL10n.commonActionUndo,
              onPressed: () async {
                try {
                  await repo.updateChecklistItem(itemId: item.id, body: const ChecklistItemPatch(done: false));
                  ref.read(clientDataRevisionProvider.notifier).bump();
                } on ApiProblem catch (p) {
                  if (context.mounted) context.gzNav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, p), tone: GzToastTone.danger));
                }
              },
            ),
          ),
        );
      }
    } on ApiProblem catch (p) {
      if (context.mounted) context.gzNav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, p), tone: GzToastTone.danger));
    }
  }

  /// No wedding date yet: add it to see due dates.
  Widget _emptyNoDate(BuildContext context) {
    final l = context.l10n;
    return WdPad(
      child: GzEmptyState(
        illustration: GzIllustrationName.calendar,
        title: l.clientMyWeddingChecklistEmptyTitle,
        action: GzStateAction(label: l.clientMyWeddingChecklistEmptyAction, onPressed: () => context.gzNav.openSheet('CL-DISC-02')),
      ),
    );
  }

  Widget _list(BuildContext context, WidgetRef ref, ChecklistView view) {
    final f = context.gzFormat;
    final done = view.items.where((i) => i.done).length;
    final weddingDate = ref.watch(weddingProfileProvider).value?.weddingDate;
    final groups = _bands(view.items.where((i) => !i.done).toList(), weddingDate);
    final doneItems = view.items.where((i) => i.done).toList();
    final today = LocalDate.parse(f.isoDay(f.now()));
    // The Venue row says where its booking stands (pending or approved) until the booking is confirmed.
    final overview = ref.watch(weddingOverviewProvider).value;
    GzStatus? statusOf(ChecklistItem item) {
      final id = item.bookingId;
      if (id == null) return null;
      final status = overview?.openRequests.where((r) => r.booking.id == id).firstOrNull?.booking.status;
      return switch (status) {
        BookingStatus.pending => GzStatus.pending,
        BookingStatus.approved => GzStatus.approved,
        _ => null,
      };
    }

    Widget section(_Band band, List<ChecklistItem> rows) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _bandHeader(context, band),
        for (final item in rows) _row(context, ref, item, today: today, status: statusOf(item), last: item == rows.last),
      ],
    );
    final allDone = view.items.isNotEmpty && view.items.length == done;
    // The web page is a 20 gap column: the head, then each band, 8 above and 40 below.
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s10),
      child: WdGap(
        gap: GzSpace.s5,
        children: [
          WdPad(
            child: WdGap(
              gap: GzSpace.s3,
              children: [
                WdProgressHead(done: done, total: view.items.length),
                if (allDone)
                  Row(
                    children: [
                      const GzIllustration(GzIllustrationName.seal, size: GzIllustrationSize.lg),
                      const SizedBox(width: GzSpace.s3),
                      Expanded(child: GzText(context.l10n.clientMyWeddingChecklistAllDone, role: GzTextRole.d2, color: context.gz.colors.textStrong)),
                    ],
                  ),
              ],
            ),
          ),
          for (final g in groups) section(g.band, g.rows),
          if (doneItems.isNotEmpty) section(_Band.done, doneItems),
        ],
      ),
    );
  }

  /// The countdown band of a task by how long before the wedding it falls due (PRD bands).
  List<({ _Band band, List<ChecklistItem> rows })> _bands(List<ChecklistItem> open, LocalDate? weddingDate) {
    _Band bandOf(ChecklistItem item) {
      if (item.auto) return _Band.booking;
      final due = item.dueOn;
      if (due == null || weddingDate == null) return _Band.noDate;
      final before = DateTime(weddingDate.year, weddingDate.month, weddingDate.day).difference(DateTime(due.year, due.month, due.day)).inDays;
      if (before > 180) return _Band.more;
      if (before > 30) return _Band.months;
      if (before > 7) return _Band.month;
      return _Band.week;
    }

    const order = [_Band.booking, _Band.more, _Band.months, _Band.month, _Band.week, _Band.noDate];
    return [
      for (final b in order)
        if (open.where((i) => bandOf(i) == b).isNotEmpty) (band: b, rows: open.where((i) => bandOf(i) == b).toList()),
    ];
  }

  Widget _bandHeader(BuildContext context, _Band band) {
    final l = context.l10n;
    final f = context.gzFormat;
    final String title;
    final IconData icon;
    switch (band) {
      case _Band.booking:
        title = l.clientMyWeddingChecklistBandBooking;
        icon = GzIcons.hall;
      case _Band.more:
        title = l.clientMyWeddingChecklistBandMore(f.integer(6));
        icon = GzIcons.calendarDots;
      case _Band.months:
        title = l.clientMyWeddingChecklistBandMonths(f.integer(1), f.integer(6));
        icon = GzIcons.calendarDots;
      case _Band.month:
        title = l.clientMyWeddingChecklistBandMonth;
        icon = GzIcons.calendar;
      case _Band.week:
        title = l.clientMyWeddingChecklistBandWeek;
        icon = GzIcons.timer;
      case _Band.noDate:
        title = l.clientMyWeddingChecklistBandNoDate;
        icon = GzIcons.calendarX;
      case _Band.done:
        title = l.clientMyWeddingChecklistBandDone;
        icon = GzIcons.checkCircle;
    }
    return WdBand(icon: icon, title: title);
  }

  Widget _row(BuildContext context, WidgetRef ref, ChecklistItem item, {required LocalDate today, required GzStatus? status, required bool last}) {
    final nav = context.gzNav;
    final category = item.serviceCategoryId;
    final bookingId = item.bookingId;
    return WdTaskRow(
      item: item,
      title: wdTaskTitle(context, item),
      today: today,
      venueStatus: status,
      last: last,
      onToggle: (next) => _toggle(context, ref, item, next),
      onBrowse: category == null ? null : () => nav.push('CL-SERV-02', params: <String, Object?>{'categoryId': category.value}),
      onOpenBooking: bookingId == null ? null : () => nav.push('CL-BKNG-02', params: <String, Object?>{'bookingId': bookingId}),
    );
  }
}

/// The checklist states: skeleton while loading, the problem with retry, the offline banner over the list, never blank.
class BkChecklistAsync extends StatelessWidget {
  const BkChecklistAsync({required this.value, required this.data, this.onRetry, this.empty, this.showEmpty = false, super.key});

  final AsyncValue<ChecklistView> value;
  final Widget Function(ChecklistView data) data;
  final VoidCallback? onRetry;
  final Widget? empty;
  final bool showEmpty;

  @override
  Widget build(BuildContext context) {
    final v = value;
    if (v.isLoading && !v.hasValue) {
      return const WdPad(
        child: WdGap(
          children: [GzSkeleton(blockSize: 24), GzSkeleton(blockSize: 200)],
        ),
      );
    }
    if (v.hasError && !v.hasValue) {
      final p = v.error;
      return GzErrorState(kind: GzErrorKind.load, body: p is ApiProblem ? gzProblemMessage(context.gzL10n, p) : null, onRetry: onRetry, fill: false);
    }
    if (showEmpty && empty != null) return empty!;
    final stale = v.value;
    if (stale == null) return const WdPad(child: GzSkeleton(blockSize: 200));
    if (v.hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzBanner(message: context.gzL10n.commonStateOffline, tone: GzBannerTone.offline, shape: GzBannerShape.flush),
          data(stale),
        ],
      );
    }
    return data(stale);
  }
}

/// The countdown band of the checklist (PRD bands + done).
enum _Band { booking, more, months, month, week, noDate, done }
