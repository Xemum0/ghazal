import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Governorate, RegionMatchKind;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../app/state/state.dart' show SearchBrief;
import '../../../../l10n/l10n.dart';
import '../../application/discover_regions.dart';
import 'brief_rows.dart';
import 'discover_labels.dart';

/// The Brief as the facts it holds (Results header): date, guests with the section glyph, area, each a glyph and its value, a quiet pencil
/// at inline-end. One 44+ target that opens the Brief sheet. A fact that is not known is omitted; with none set the muted word "Date".
class BriefFacts extends StatelessWidget {
  const BriefFacts({required this.brief, required this.governorates, required this.onEdit, super.key});

  final SearchBrief brief;
  final List<Governorate> governorates;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    final l = context.l10n;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final date = briefDateText(f, brief);
    final names = briefGovernorateNames(governorates, brief.governorateIds, lang);
    final areaText = names.join(f.isArabic ? '، ' : ', ');
    final spoken = <String>[?date, if (brief.guests != null) f.integer(brief.guests!), if (areaText.isNotEmpty) areaText].join(', ');
    final facts = <Widget>[
      if (date != null) _textFact(c, briefDateIcon(brief), l.clientShellBriefDate, date),
      if (brief.guests != null && brief.guests != 0)
        GzFactChip(
          icon: GzIcons.usersThree,
          label: l.clientShellBriefGuests,
          value: f.integer(brief.guests!),
          unit: null,
          valueWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              gzFigText(context, f.integer(brief.guests!), role: GzTextRole.figBodyS, color: c.textStrong),
              if (brief.audience != null) ...[const SizedBox(width: GzSpace.s1), GzIcon(arrangementIcon(brief.audience!), size: GzIconSize.xs, color: c.iconSecondary)],
            ],
          ),
        ),
      if (areaText.isNotEmpty) _textFact(c, GzIcons.pin, l.clientDiscoverBriefChooseGovernorate, areaText),
      if (date == null && brief.guests == null && areaText.isEmpty)
        _textFact(c, GzIcons.calendar, l.clientShellBriefDate, l.clientDiscoverBriefChooseDate, muted: true),
    ];
    return GzPressable(
      onPressed: onEdit,
      semanticLabel: '${l.clientShellBriefTitle}: $spoken',
      borderRadius: GzRadius.smAll,
      builder: (context, st) => Container(
        key: const ValueKey<String>('discover.facts'),
        constraints: const BoxConstraints(minHeight: GzSize.touchMin),
        padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s2),
        decoration: BoxDecoration(color: st.pressed ? c.surfaceQuiet : null, borderRadius: GzRadius.smAll),
        child: Row(
          children: [
            Expanded(child: GzFactRow(children: facts)),
            const SizedBox(width: GzSpace.s3),
            GzIcon(GzIcons.edit, size: GzIconSize.sm, color: c.iconSecondary),
          ],
        ),
      ),
    );
  }
}

/// The web TextFact: the chip anatomy (glyph, value) for a value that carries words, drawn in the body-s text role with its digit runs as figure islands.
Widget _textFact(GzColors c, IconData icon, String label, String value, {bool muted = false}) => GzFactChip(
  icon: icon,
  label: label,
  tone: muted ? GzFactTone.muted : GzFactTone.normal,
  valueWidget: GzText(value, role: GzTextRole.bodyS, color: muted ? c.textSecondary : c.textStrong, figures: true, softWrap: false),
);

/// What the list becomes while the name search has focus. Empty field: recent searches (the Brief's governorates). Typing: the governorates and
/// halls that match (the server folds alef, ya, ta marbuta and tashkeel, and finds a hall by its address, so «مشرف» finds the halls of
/// Mishref). Choosing a governorate narrows Results (no exact area is chosen, ADR 0038); a hall opens.
class Typeahead extends ConsumerWidget {
  const Typeahead({required this.query, required this.brief, required this.onPickGovernorate, required this.onPickVenue, required this.onPickRecent, required this.onClearRecent, super.key});

  final String query;
  final SearchBrief brief;
  final ValueChanged<String> onPickGovernorate;
  final ValueChanged<String> onPickVenue;
  final ValueChanged<String> onPickRecent;
  final VoidCallback onClearRecent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final governorates = ref.watch(areasProvider).value?.governorates ?? const <Governorate>[];
    Widget row(IconData icon, String text, VoidCallback onTap, {Widget? trailing, Key? key}) => GzPressable(
      key: key,
      onPressed: onTap,
      semanticLabel: text,
      builder: (context, st) => Container(
        constraints: const BoxConstraints(minHeight: GzSize.touchMin),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s2),
        color: st.pressed ? c.surfaceQuiet : null,
        child: Row(
          children: [
            GzIcon(icon, size: GzIconSize.sm, color: c.iconSecondary),
            const SizedBox(width: GzSpace.s3),
            Expanded(child: GzText(text, role: GzTextRole.body, color: c.textPrimary, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ?trailing,
          ],
        ),
      ),
    );

    if (query.trim().isEmpty) {
      final recents = briefGovernorateNames(governorates, brief.governorateIds, lang);
      return Column(
        key: const ValueKey<String>('discover.typeahead'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: GzSpace.gutter, top: GzSpace.s2),
              child: GzPressable(
                onPressed: onClearRecent,
                semanticLabel: l.clientDiscoverSearchClearRecent,
                child: Padding(padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s2), child: GzText(l.clientDiscoverSearchClearRecent, role: GzTextRole.caption, color: c.textSecondary)),
              ),
            ),
          ),
          for (final r in recents) row(GzIcons.clock, r, () => onPickRecent(r)),
        ],
      );
    }
    final matches = ref.watch(regionSearchProvider(query));
    return matches.when(
      loading: () => const SizedBox(height: GzSpace.s16),
      error: (e, _) => const SizedBox.shrink(),
      data: (items) {
        final regions = items.where((m) => m.kind == RegionMatchKind.governorate).toList();
        final halls = items.where((m) => m.kind == RegionMatchKind.venue).take(5).toList();
        if (regions.isEmpty && halls.isEmpty) {
          return Padding(
            padding: const EdgeInsetsDirectional.only(top: GzSpace.s4),
            child: GzEmptyState(illustration: GzIllustrationName.noResult, title: context.gzL10n.commonStateTitleEmptySearch, fill: false),
          );
        }
        return Column(
          key: const ValueKey<String>('discover.typeahead'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final m in regions)
              row(
                GzIcons.pin,
                m.name.of(lang),
                () => onPickGovernorate(m.id),
                trailing: GzFactChip(icon: GzIcons.hall, label: l.clientDiscoverResultsTitle, value: f.integer(m.venueCount)),
                key: ValueKey<String>('discover.match.governorate.${m.id}'),
              ),
            for (final m in halls) row(GzIcons.hall, m.name.of(lang), () => onPickVenue(m.id), key: ValueKey<String>('discover.match.venue.${m.id}')),
          ],
        );
      },
    );
  }
}
