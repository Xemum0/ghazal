import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Area;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../app/state/state.dart' show SearchBrief;
import '../../../../l10n/l10n.dart';
import 'brief_rows.dart';

/// The Brief card of Home (the system `GzBriefCard` anatomy: a paper panel, a hairline, four rows, one gold CTA), flow-local for two
/// reasons the system card cannot serve yet (`requests.md`): the Area value lists the names with a comma and clamps to one line, and the CTA
/// says the truth when no hall is free that day ("Nearest dates") instead of "Show 0 halls".
///
/// Every row is a glyph and its value; the row's name is the accessible name. [count] is the halls free on the date in the Brief's areas;
/// null before the first answer, offline or with no date: "Show halls".
class HomeBriefCard extends StatelessWidget {
  const HomeBriefCard({required this.brief, required this.areas, required this.count, this.loading = false, this.onEdit, this.onShow, super.key});

  final SearchBrief brief;
  final List<Area> areas;
  final int? count;
  final bool loading;
  final ValueChanged<GzBriefField>? onEdit;
  final VoidCallback? onShow;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l = context.l10n;
    final lang = gz.locale.languageCode;
    final area = briefAreaText(context, f, briefAreaNames(areas, brief.areaIds, lang));
    final date = briefDateText(f, brief);
    final guests = brief.guests == null || brief.guests == 0 ? null : f.integer(brief.guests!);
    final budget = brief.budget == null ? null : briefBudgetText(f, brief.budget!);
    final none = count == 0;
    final cta = none
        ? l.clientDiscoverCtaNearest
        : count != null
        ? f.digits(l.clientDiscoverCtaCount(count!))
        : l.clientDiscoverCtaShow;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l.clientDiscoverBriefLabel,
      child: Container(
        key: const ValueKey<String>('discover.briefcard'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderStrong, width: GzStroke.hair),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BriefRowTile(
              key: const ValueKey<String>('discover.row.date'),
              icon: briefDateIcon(brief),
              name: l.clientShellBriefDate,
              value: date,
              placeholder: l.clientDiscoverBriefChooseDate,
              onPressed: () => onEdit?.call(GzBriefField.date),
            ),
            // The web split row: flex 3 : 2 over a basis of 0, so each cell keeps its own 32 of padding and the rest (less the 1 dp rule)
            // is shared 3 : 2.
            LayoutBuilder(
              builder: (context, box) {
                final free = box.maxWidth - 1 - 2 * GzSpace.s4 * 2;
                final areaWidth = 2 * GzSpace.s4 + free * 3 / 5;
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: areaWidth,
                        child: BriefRowTile(
                          key: const ValueKey<String>('discover.row.area'),
                          icon: GzIcons.pin,
                          name: l.clientShellBriefArea,
                          value: area,
                          placeholder: l.clientDiscoverBriefChooseArea,
                          border: true,
                          onPressed: () => onEdit?.call(GzBriefField.area),
                        ),
                      ),
                      const GzDivider(vertical: true),
                      Expanded(
                        child: BriefRowTile(
                          key: const ValueKey<String>('discover.row.guests'),
                          icon: GzIcons.usersThree,
                          name: l.clientShellBriefGuests,
                          value: guests,
                          placeholder: l.clientDiscoverBriefAddGuests,
                          border: true,
                          onPressed: () => onEdit?.call(GzBriefField.guests),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            BriefRowTile(
              key: const ValueKey<String>('discover.row.budget'),
              icon: GzIcons.wallet,
              name: l.clientShellBriefBudget,
              value: budget,
              placeholder: l.clientDiscoverBriefSetBudget,
              border: true,
              onPressed: () => onEdit?.call(GzBriefField.budget),
            ),
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
              padding: const EdgeInsetsDirectional.all(GzSpace.s4),
              child: GzButton(
                key: const ValueKey<String>('discover.cta'),
                label: cta,
                fullWidth: true,
                loading: loading,
                iconStart: none ? GzIcons.calendar : null,
                onPressed: onShow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
