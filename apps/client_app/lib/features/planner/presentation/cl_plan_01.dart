import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemKind, gzProblemMessage;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode;
import 'package:ghazal_domain/ghazal_domain.dart' show LocalDate, PlannerPackage, PlannerTier;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/planner_data.dart';
import 'widgets/planner_parts.dart';

/// CL-PLAN-01 Wedding planner packages (screen). Covers CA-PLAN-01, CA-PLAN-02, CA-PLAN-03, CA-PLAN-04, CA-PLAN-09.
///
/// Silver | Gold | Royal in a segmented control above one full-width plate
/// (photograph, name and marks, from-price with its terms behind the info
/// glyph, inclusions as glyph + short-label rows), or all three side by side
/// in the compare table built from the same rows. The one gold action is the
/// pinned "Request consultation"; "Not now" dismisses with no penalty. Entry
/// from a booking or My Wedding shows the context line; browsing is open to
/// guests. States: default, from-booking, from-my-wedding, compare-table,
/// loading, error, offline, guest.
class ClPlan01Screen extends ConsumerStatefulWidget {
  const ClPlan01Screen({super.key});

  @override
  ConsumerState<ClPlan01Screen> createState() => _ClPlan01ScreenState();
}

class _ClPlan01ScreenState extends ConsumerState<ClPlan01Screen> {
  bool _compare = false;
  bool _seeded = false;

  GzNavigator get _nav => context.gzNav;

  String _entryOf() {
    // Entry from 'CL-SERV-01' (the services hub) or 'CL-WEDD-01' (My Wedding) shows
    // the context line; system back returns there, so there is no push.
    final from = _nav.params['from'];
    if (from == 'booking' || from == 'my-wedding' || from == 'services') return from as String;
    return 'services';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lg = context.gzL10n;
    final lang = context.gz.locale.languageCode;
    final brief = ref.watch(searchBriefProvider);
    final params = _nav.params;
    if (!_seeded) {
      _seeded = true;
      final tierParam = params['tier'];
      if (tierParam is String) {
        final tier = PlannerTier.values.where((t) => t.value == tierParam).firstOrNull;
        if (tier != null && tier != PlannerTier.unknown) {
          WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(plannerTierProvider.notifier).set(tier));
        }
      }
      if (params['compare'] == true || params['compare'] == 'true') _compare = true;
    }
    final entry = _entryOf();
    final tier = ref.watch(plannerTierProvider);
    final async = ref.watch(plannerPackagesProvider);
    final problem = async.hasError && !async.hasValue
        ? (async.error is ApiProblem ? async.error! as ApiProblem : const ApiProblem(status: 0, code: ApiProblemCode.unknown))
        : null;
    final offline = problem?.isOffline ?? false;
    final pkgs = (async.value ?? const <PlannerPackage>[]).where((p) => p.tier != PlannerTier.unknown).toList()
      ..sort((a, b) => a.from.fils.compareTo(b.from.fils));
    final pkg = pkgs.where((p) => p.tier == tier).firstOrNull ?? pkgs.firstOrNull;

    final top = _compare
        ? GzTopBar(title: l.clientPlannerCompareTitle, onBack: () => setState(() => _compare = false))
        : GzTopBar(
            title: entry == 'booking' ? l.clientPlannerOfferTitle : l.clientPlannerTitle,
            back: entry == 'booking' ? GzTopBarBack.close : GzTopBarBack.auto,
            onBack: entry == 'booking' ? _notNow : null,
            actions: [
              if (pkgs.isNotEmpty && problem == null)
                GzTopBarAction(icon: GzIcons.compare, label: l.clientPlannerCompareLabel, onPressed: () => setState(() => _compare = true)),
            ],
          );

    Widget body;
    if (problem != null && !offline) {
      body = GzErrorState(
        key: const ValueKey<String>('planner.error'),
        kind: gzProblemKind(problem),
        body: gzProblemMessage(lg, problem),
        fill: false,
        onRetry: () => ref.invalidate(plannerPackagesProvider),
      );
    } else if (pkgs.isEmpty) {
      body = Column(
        key: const ValueKey<String>('planner.loading'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Padding(
            padding: EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
            child: GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 52),
          ),
          GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 220),
          SizedBox(height: GzSpace.s3),
          GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 120),
        ],
      );
    } else if (_compare) {
      body = _compareTable(context, pkgs);
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (entry != 'services')
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s4),
              child: PlannerContextLine(venueId: _venueIdOf(params, brief.date), date: _dateOf(params, brief.date), countdown: entry == 'my-wedding'),
            ),
          Semantics(
            label: l.clientPlannerTierPickerLabel,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s3),
              child: GzSegmentedControl<PlannerTier>(
                key: const ValueKey<String>('planner.tiers'),
                label: l.clientPlannerTierPickerLabel,
                value: pkg!.tier,
                options: [for (final p in pkgs) GzSegmentedOption<PlannerTier>(value: p.tier, label: p.name.of(lang))],
                onChanged: (t) => ref.read(plannerTierProvider.notifier).set(t),
              ),
            ),
          ),
          TierPlate(key: ValueKey<String>('planner.plate.live.${pkg.tier.value}'), pkg: pkg, previousName: _previousName(pkgs, pkg, lang)),
          const SizedBox(height: GzSpace.s4),
          const SizedBox(height: GzSpace.s4),
          GzIconListRow(
            flush: true,
            icon: GzIcons.search,
            title: l.clientPlannerOtherPlanners,
            chevron: true,
            last: true,
            onPressed: () => _nav.push('CL-SERV-02', params: const <String, Object?>{'categoryId': 'event_planning'}),
          ),
        ],
      );
    }

    return GzScreen(
      top: top,
      bottom: GzActionBar(
        action: GzActionBarAction(
          label: l.clientPlannerRequestConsultation,
          onPressed: offline || pkgs.isEmpty
              ? null
              : () => _nav.push('CL-PLAN-02', params: <String, Object?>{'tier': (pkg?.tier ?? tier).value, 'from': entry}),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (offline) GzBanner(message: lg.commonStateOffline, tone: GzBannerTone.offline),
          body,
          const SizedBox(height: GzSpace.s6),
        ],
      ),
    );
  }

  void _notNow() {
    _nav.toast(GzToastSpec(message: context.l10n.clientPlannerNotNowToast));
    if (_nav.canGoBack) {
      _nav.pop();
    } else {
      // The offer is answered: land on 'CL-WEDD-01' (the my-wedding tab root).
      _nav.switchTab('my-wedding');
    }
  }

  String _venueIdOf(Map<String, Object?> params, LocalDate? briefDate) {
    final v = params['venueId'];
    if (v is String && v.isNotEmpty) return v;
    return ref.read(currentPlannerRequestProvider).value?.venueId ?? 'V01';
  }

  LocalDate _dateOf(Map<String, Object?> params, LocalDate? briefDate) {
    final d = params['date'];
    if (d is String && d.isNotEmpty) {
      try {
        return LocalDate.parse(d);
      } on Object {
        // fall through to the Brief
      }
    }
    return briefDate ?? ref.read(currentPlannerRequestProvider).value?.eventDate ?? LocalDate(2027, 1, 14);
  }

  String? _previousName(List<PlannerPackage> pkgs, PlannerPackage pkg, String lang) {
    final order = [for (final p in pkgs) p.tier];
    final i = order.indexOf(pkg.tier);
    if (i <= 0) return null;
    return pkgs[i - 1].name.of(lang);
  }

  /// The three tiers side by side: header radios (photo, name, marks), the
  /// from-price cells, then one tick row per inclusion: Silver's four, then
  /// what Gold adds, then what Royal adds (the prototype's inclusion matrix).
  Widget _compareTable(BuildContext context, List<PlannerPackage> pkgs) {
    final l = context.l10n;
    final lang = context.gz.locale.languageCode;
    final c = context.gz.colors;
    final order = [for (final p in pkgs) p.tier];
    final rows = <(String, int)>[
      for (var i = 0; i < 4; i++) (tierShortLabel(l, pkgs.first.tier, i), 0),
      if (order.contains(PlannerTier.gold) || order.contains(PlannerTier.royal))
        for (var i = 0; i < 4; i++) (tierShortLabel(l, PlannerTier.gold, i), 1),
      if (order.contains(PlannerTier.royal))
        for (var i = 0; i < 4; i++) (tierShortLabel(l, PlannerTier.royal, i), 2),
    ];
    final maxFrom = pkgs.map((p) => p.from.fils).reduce((a, b) => a > b ? a : b);
    return Semantics(
      key: const ValueKey<String>('planner.compare'),
      container: true,
      label: l.clientPlannerCompareTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final p in pkgs)
                Expanded(
                  child: GzPressable(
                    onPressed: () => ref.read(plannerTierProvider.notifier).set(p.tier),
                    semanticLabel: p.tier == ref.watch(plannerTierProvider)
                        ? l.clientPlannerCompareChosen(p.name.of(lang))
                        : l.clientPlannerCompareChoose(p.name.of(lang)),
                    selected: p.tier == ref.watch(plannerTierProvider),
                    minWidth: 0,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s1),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: GzRadius.smAll,
                            child: GzPhoto(src: tierPhotoSrc(p.tier), alt: '', aspectRatio: 1),
                          ),
                          const SizedBox(height: GzSpace.s2),
                          GzText(p.name.of(lang), role: GzTextRole.bodyS, color: c.textStrong, maxLines: 2),
                          const SizedBox(height: GzSpace.s1),
                          TierMarks(count: p.marks, label: l.clientPlannerMarks(p.marks)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: GzSpace.s3),
          _row(context, l.clientPlannerFromPrefix, [for (final p in pkgs) _FromCell(from: p.from.fils, max: maxFrom)]),
          for (final row in rows)
            _row(context, row.$1, [
              for (final p in pkgs)
                Center(
                  child: Semantics(
                    label: _included(p.tier, row.$2) ? l.clientPlannerIncluded : l.clientPlannerNotIncluded,
                    child: ExcludeSemantics(
                      child: GzIcon(
                        _included(p.tier, row.$2) ? GzIcons.check : GzIcons.minus,
                        size: GzIconSize.sm,
                        color: _included(p.tier, row.$2) ? c.iconAccent : c.iconDisabled,
                      ),
                    ),
                  ),
                ),
            ]),
        ],
      ),
    );
  }

  bool _included(PlannerTier tier, int from) {
    final rank = switch (tier) {
      PlannerTier.silver => 0,
      PlannerTier.gold => 1,
      PlannerTier.royal => 2,
      _ => -1,
    };
    return rank >= from;
  }

  Widget _row(BuildContext context, String label, List<Widget> cells) {
    final c = context.gz.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: GzText(label, role: GzTextRole.caption, color: c.textSecondary),
            ),
            for (final cell in cells) Expanded(child: cell),
          ],
        ),
      ),
    );
  }
}

/// One from-price cell of the compare table: the figure over the gold range bar.
class _FromCell extends StatelessWidget {
  const _FromCell({required this.from, required this.max});

  final int from;
  final int max;

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: GzPrice(fils: from, size: GzPriceSize.card),
        ),
        const SizedBox(height: GzSpace.s1),
        GzRangeBar(decorative: true, value: from, max: max, label: f.money(from)),
      ],
    );
  }
}
