// CL-ONBD-06 Preferred areas (CA-ONB-06, CA-ONB-08, CA-ONB-09). Port of CL-ONBD-06.tsx.
// The last step: a one-word title, a search and the six governorates as groups of chips. Each group first shows the areas that have halls,
// the rest sit behind `+N`; a search (Arabic-normalised, with a small alias table) looks through all of them. The pinned gold CTA is the
// live count of halls the choice will show; with nothing chosen it counts every hall. It stores the Brief on the device and opens Home.
// Skip opens Home with no area. No location permission is asked here.
import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show Area, AreasResponse, Governorate;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/onboarding_data.dart';
import '../application/onboarding_profile.dart';
import 'widgets/step_bar.dart';
import 'widgets/step_head.dart';

/// Search aliases (ADR 0012 D8): other spellings people type for the same place. Read by the search only, never shown.
const Map<String, List<String>> _aliases = <String, List<String>>{
  'mishref': ['mishrif', 'meshref', 'مشرف'],
  'salmiya': ['salmiyah', 'سالمية'],
  'jleeb-al-shuyoukh': ['jleeb', 'jileeb', 'جليب'],
  'fahaheel': ['fahaheel', 'fahahil'],
  'al-rai': ['rai', 'الري'],
  'khaitan': ['kheitan', 'kaitan'],
};

class ClOnbd06Screen extends ConsumerStatefulWidget {
  const ClOnbd06Screen({super.key});

  @override
  ConsumerState<ClOnbd06Screen> createState() => _ClOnbd06State();
}

class _ClOnbd06State extends ConsumerState<ClOnbd06Screen> {
  List<String> _picked = const <String>[];
  String _query = '';
  final Set<String> _open = <String>{};
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    // Opened by the flow (`live`): what the couple answered. Opened on its own (a harness, a deep link): the hero story's areas.
    final live = context.gzNav.params['live'] == true;
    _picked = live ? List<String>.of(ref.read(weddingDraftProvider).areaIds ?? const <String>[]) : List<String>.of(ObdStory.areas);
  }

  void _toggle(String id) => setState(() => _picked = _picked.contains(id) ? _picked.where((x) => x != id).toList() : <String>[..._picked, id]);

  void _finish(List<String> ids) {
    ref.finishOnboarding(ids);
    final nav = context.gzNav..reset('CL-DISC-01');
    if (ids.isNotEmpty) nav.toast(GzToastSpec(message: context.l10n.commonStateSaved));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final f = ref.watch(gzFormatProvider);
    final c = context.gz.colors;
    final searching = _query.trim().isNotEmpty;
    final saved = ref.watch(weddingDraftProvider);
    final guests = (saved.guests?.women ?? 0) > 0 ? saved.guests!.women : null;
    final count = ref.watch(onboardingHallCountProvider((_picked.join(','), guests)));
    final offline = count.hasError && count.error is ApiProblem && (count.error! as ApiProblem).isOffline;
    final hallCount = count.value;
    final label = offline || hallCount == null ? l10n.commonActionContinue : l10n.commonCountHalls(hallCount);
    final areas = ref.watch(onboardingAreasProvider);

    return GzScreen(
      top: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ObdStepBar(step: 4, total: 4, onSkip: () => _finish(const <String>[])),
          ColoredBox(
            color: c.surfaceCanvas,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s1, bottom: GzSpace.s3),
              child: GzSearchField(
                value: _query,
                onValueChange: (v) => setState(() => _query = v),
                placeholder: l10n.clientOnboardingAreasSearch,
                label: l10n.clientOnboardingAreasSearch,
              ),
            ),
          ),
        ],
      ),
      bottom: GzActionBar(
        action: GzActionBarAction(label: label, iconEnd: offline ? null : GzIcons.arrowRight, onPressed: () => _finish(_picked)),
        note: !offline && _picked.isNotEmpty && hallCount == 0 ? l10n.clientOnboardingAreasNoHallsNote : null,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (offline) ...[
              GzBanner(message: l10n.commonStateOffline, tone: GzBannerTone.offline, shape: GzBannerShape.card),
              const SizedBox(height: GzSpace.s6),
            ],
            if (!searching) ...[ObdStepHead(title: l10n.clientOnboardingAreasTitle), const SizedBox(height: GzSpace.s6)],
            if (_picked.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: GzFactChip(
                        icon: GzIcons.pin,
                        label: l10n.clientOnboardingAreasSelected(_picked.length),
                        value: f.integer(_picked.length),
                      ),
                    ),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  GzButton(
                    label: l10n.commonActionClear,
                    variant: GzButtonVariant.tertiary,
                    flushInline: true,
                    onPressed: () => setState(() => _picked = const <String>[]),
                  ),
                ],
              ),
              const SizedBox(height: GzSpace.s6),
            ],
            GzAsyncView<AreasResponse>(
              value: areas,
              onRetry: () => ref.invalidate(onboardingAreasProvider),
              data: (data) => _groups(l10n, data, searching),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groups(AppL10n l10n, AreasResponse data, bool searching) {
    final f = ref.watch(gzFormatProvider);
    final lang = f.lang.name;
    final roster = ref.watch(onboardingRosterProvider).value ?? const [];
    final withHalls = <String>{for (final r in roster) r.venue.areaId};
    final rows = <Widget>[];
    for (final g in data.governorates) {
      final inGov = data.areas.where((a) => a.governorateId == g.id).toList();
      final matches = searching ? inGov.where((a) => _matches(a)).toList() : inGov;
      if (matches.isEmpty) continue;
      final expanded = searching || _open.contains(g.id);
      final shown = expanded ? matches : matches.where((a) => withHalls.contains(a.id) || _picked.contains(a.id)).toList();
      rows.add(
        _Governorate(
          governorate: g,
          name: g.name.of(lang),
          chosen: inGov.where((a) => _picked.contains(a.id)).length,
          shown: shown,
          hidden: matches.length - shown.length,
          expanded: expanded,
          searching: searching,
          picked: _picked,
          lang: lang,
          onToggle: _toggle,
          onToggleOpen: () => setState(() => _open.contains(g.id) ? _open.remove(g.id) : _open.add(g.id)),
          moreLabel: (n) => l10n.clientOnboardingAreasMore(n),
          moreText: (n) => '+${f.integer(n)}',
        ),
      );
    }
    if (rows.isEmpty) {
      return GzEmptyState(fill: false, flush: true, illustration: GzIllustrationName.noResult, title: l10n.commonStateTitleEmptySearch);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s6), rows[i]],
      ],
    );
  }

  bool _matches(Area a) {
    final hay = <String>[a.name.en ?? '', a.name.ar ?? '', ...(_aliases[a.id] ?? const <String>[])].join(' ');
    return gzMatchesSearch(_query, hay);
  }
}

class _Governorate extends StatelessWidget {
  const _Governorate({
    required this.governorate,
    required this.name,
    required this.chosen,
    required this.shown,
    required this.hidden,
    required this.expanded,
    required this.searching,
    required this.picked,
    required this.lang,
    required this.onToggle,
    required this.onToggleOpen,
    required this.moreLabel,
    required this.moreText,
  });

  final Governorate governorate;
  final String name;
  final int chosen;
  final List<Area> shown;
  final int hidden;
  final bool expanded;
  final bool searching;
  final List<String> picked;
  final String lang;
  final ValueChanged<String> onToggle;
  final VoidCallback onToggleOpen;
  final String Function(int) moreLabel;
  final String Function(int) moreText;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l10n = context.l10n;
    final showMore = !searching && (hidden > 0 || expanded);
    return Semantics(
      container: true,
      label: name,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(top: GzSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Flexible(
                    child: GzText(name, role: GzTextRole.body, color: c.textStrong, header: true),
                  ),
                  if (chosen > 0) ...[
                    const SizedBox(width: GzSpace.s2),
                    Semantics(
                      label: l10n.clientOnboardingAreasSelected(chosen),
                      child: ExcludeSemantics(child: GzCountBadge(count: chosen)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: GzSpace.s3),
              Wrap(
                spacing: GzSpace.s2,
                runSpacing: GzSpace.s2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final a in shown) GzChip(label: a.name.of(lang), selected: picked.contains(a.id), onPressed: () => onToggle(a.id)),
                  if (showMore)
                    Semantics(
                      expanded: expanded,
                      label: expanded ? l10n.commonActionShowLess : moreLabel(hidden),
                      excludeSemantics: true,
                      onTap: onToggleOpen,
                      child: GzButton(
                        label: expanded ? '' : moreText(hidden),
                        variant: GzButtonVariant.tertiary,
                        iconEnd: expanded ? GzIcons.chevronUp : GzIcons.chevronDown,
                        onPressed: onToggleOpen,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
