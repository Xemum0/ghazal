// HL-VIST-01 Visit requests (web `HL-VIST-01.tsx`): every visit of the venue in three segments, Requested (needs a reply) / Upcoming / Past,
// nearest slot first. A requested card carries "Confirm" and "Another time" inline; the card opens the visit (HL-VIST-02). Visits are free and
// carry no voucher (ADR 0033 D9). Admin, Manager and Reception reply; Accountant and Marketing do not see the screen.
// Requirements: HA-VIS-01, HA-VIS-02, HA-AUTH-02.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_core/ghazal_core.dart' show clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show VisitAppointment;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/visits_data.dart';
import 'widgets/visit_actions.dart';
import 'widgets/visit_queue_card.dart';

class HlVist01Screen extends ConsumerStatefulWidget {
  const HlVist01Screen({super.key});

  @override
  ConsumerState<HlVist01Screen> createState() => _HlVist01ScreenState();
}

class _HlVist01ScreenState extends ConsumerState<HlVist01Screen> {
  VisitSegment? _segment;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final role = ref.watch(visitRoleProvider);
    final see = canSeeVisits(role);
    final value = ref.watch(venueVisitsProvider);
    final now = ref.watch(clockProvider)();
    final act = VisitUi(context, ref);
    final all = value.value ?? const <VisitAppointment>[];
    final groups = <VisitSegment, List<VisitAppointment>>{for (final s in VisitSegment.values) s: <VisitAppointment>[]};
    for (final v in all) {
      groups[segmentOf(v, now)]!.add(v);
    }
    groups[VisitSegment.past] = groups[VisitSegment.past]!.reversed.toList();
    final segment = _segment ?? (value.hasValue && groups[VisitSegment.requested]!.isEmpty ? VisitSegment.upcoming : VisitSegment.requested);
    final requestedCount = groups[VisitSegment.requested]!.length;
    final ready = value.hasValue;

    Widget seg() {
      const order = VisitSegment.values;
      final words = [l.hotelVisitsSegRequested, l.hotelVisitsSegUpcoming, l.hotelVisitsSegPast];
      return GzSegmentTrack(
        label: l.hotelVisitsSegments,
        active: order.indexOf(segment),
        count: order.length,
        itemBuilder: (context, i, selected) {
          final c = context.gz.colors;
          final color = selected ? c.actionSelectedLabel : c.textPrimary;
          return GzPressable(
            onPressed: () => setState(() => _segment = order[i]),
            semanticLabel: words[i],
            selected: selected,
            borderRadius: GzRadius.smAll,
            builder: (context, st) => SizedBox(
              width: double.infinity,
              height: GzSize.controlSm,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: GzText(words[i], role: GzTextRole.button, color: color, maxLines: 1, softWrap: false),
                    ),
                    if (i == 0 && requestedCount > 0) ...[
                      const SizedBox(width: GzSpace.s1),
                      Center(
                        child: SizedBox(
                          height: GzSize.badge,
                          child: GzCountBadge(count: requestedCount, max: 9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    final top = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzTopBar(
          variant: GzTopBarVariant.largeTitle,
          title: l.hotelVisitsQueueTitle,
          actions: [if (see) GzTopBarAction(icon: GzIcons.sliders, label: l.hotelVisitsAvailabilityAction, onPressed: () => nav.push('HL-VIST-05'))],
        ),
        if (see && ready)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.s3),
            child: seg(),
          ),
      ],
    );

    Widget body() {
      if (!see) return GzErrorState(kind: GzErrorKind.noAccess, title: l.hotelVisitsNoAccessTitle, body: l.hotelVisitsNoAccessBody);
      return GzAsyncView<List<VisitAppointment>>(
        value: value,
        loading: Padding(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
          child: Column(
            children: const [
              GzSkeleton(blockSize: 56),
              SizedBox(height: GzSpace.s3),
              GzSkeleton(blockSize: 168),
              SizedBox(height: GzSpace.s3),
              GzSkeleton(blockSize: 168),
            ],
          ),
        ),
        onRetry: () => ref.invalidate(venueVisitsProvider),
        data: (_) {
          final items = groups[segment]!;
          if (items.isEmpty) {
            return switch (segment) {
              VisitSegment.requested => GzEmptyState(
                icon: GzIcons.calendarCheck,
                title: l.hotelVisitsEmptyRequestedTitle,
                body: l.hotelVisitsEmptyRequestedBody,
                secondary: groups[VisitSegment.upcoming]!.isNotEmpty
                    ? GzStateAction(
                        label: l.hotelVisitsSeeUpcoming,
                        variant: GzButtonVariant.secondary,
                        onPressed: () => setState(() => _segment = VisitSegment.upcoming),
                      )
                    : null,
              ),
              VisitSegment.upcoming => GzEmptyState(
                icon: GzIcons.calendar,
                title: l.hotelVisitsEmptyUpcomingTitle,
                body: l.hotelVisitsEmptyUpcomingBody,
              ),
              VisitSegment.past => GzEmptyState(icon: GzIcons.clock, title: l.hotelVisitsEmptyPastTitle, body: l.hotelVisitsEmptyPastBody),
            };
          }
          return Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s1, bottom: GzSpace.s6),
            child: Column(
              key: ValueKey<VisitSegment>(segment),
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(height: GzSpace.s3),
                  RepaintBoundary(
                    child: VisitQueueCard(
                      visit: items[i],
                      requestedTab: segment == VisitSegment.requested,
                      locked: false,
                      onOpen: () => act.open(items[i]),
                      onConfirm: () => act.confirm(items[i]),
                      onPropose: () => act.propose(items[i]),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    }

    return GzPullToRefresh(
      onRefresh: () async => ref.read(partnerDataRevisionProvider.notifier).bump(),
      child: GzScreen(top: top, child: body()),
    );
  }
}
