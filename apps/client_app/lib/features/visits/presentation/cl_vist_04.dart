import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_domain/ghazal_domain.dart' show VisitRow;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/visits_view.dart';
import 'widgets/visit_widgets.dart';

/// CL-VIST-04 My visits. Covers CA-VIS-04, CA-PROF-12.
///
/// The client's visits by state (Upcoming, Past) with status chips and a way
/// into each chat. Reached from Profile and My Wedding.
/// States: default, empty, loading, error, offline.
class ClVist04Screen extends ConsumerStatefulWidget {
  const ClVist04Screen({super.key});

  @override
  ConsumerState<ClVist04Screen> createState() => _ClVist04ScreenState();
}

class _ClVist04ScreenState extends ConsumerState<ClVist04Screen> {
  bool _past = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = context.gzNav;
    // Reached from Profile ('CL-PROF-01') and My Wedding; a tap opens the visit chat ('CL-VIST-03').
    final visits = ref.watch(myVisitsProvider);
    return GzScreen(
      top: GzTopBar(title: l.clientVisitsListTitle),
      child: GzAsyncView<List<VisitRow>>(
        value: visits,
        loading: const _VisitsSkeleton(),
        onRetry: () => ref.invalidate(myVisitsProvider),
        isEmpty: (rows) => rows.isEmpty,
        empty: Padding(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s8),
          child: GzEmptyState(
            key: const ValueKey<String>('visits.empty'),
            illustration: GzIllustrationName.emptyVisits,
            title: l.clientVisitsEmptyTitle,
            action: GzStateAction(label: l.clientVisitsEmptyAction, variant: GzButtonVariant.primary, onPressed: () => nav.push('CL-DISC-03')),
          ),
        ),
        data: (rows) {
          final list = orderVisits(rows, DateTime.now().toUtc()).where((r) => visitIsUpcoming(r.visit, DateTime.now().toUtc()) != _past).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4, bottom: GzSpace.s4),
                child: GzIconSegmented<bool>(
                  label: l.clientVisitsListTitle,
                  value: _past,
                  onChanged: (v) => setState(() => _past = v),
                  options: [
                    GzIconSegmentedOption(value: false, icon: GzIcons.calendar, label: l.clientVisitsTabUpcoming),
                    GzIconSegmentedOption(value: true, icon: GzIcons.clock, label: l.clientVisitsTabPast),
                  ],
                ),
              ),
              if (list.isEmpty)
                GzEmptyState(
                  key: const ValueKey<String>('visits.filtered-empty'),
                  fill: false,
                  illustration: GzIllustrationName.emptyVisits,
                  title: context.gzL10n.commonStateTitleEmpty,
                  action: _past ? null : GzStateAction(label: l.clientVisitsEmptyAction, variant: GzButtonVariant.secondary, onPressed: () => nav.push('CL-DISC-03')),
                )
              else
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.s8),
                  child: Column(
                    children: [
                      for (final r in list)
                        RepaintBoundary(
                          child: VisitRowTile(row: r, onOpen: () => nav.push('CL-VIST-03', params: <String, Object?>{'visitId': r.visit.id})),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _VisitsSkeleton extends StatelessWidget {
  const _VisitsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
      child: Column(
        children: const [
          GzSkeleton(blockSize: 52),
          SizedBox(height: GzSpace.s3),
          GzSkeleton(blockSize: 112),
          SizedBox(height: GzSpace.s3),
          GzSkeleton(blockSize: 112),
        ],
      ),
    );
  }
}
