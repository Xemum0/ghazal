/// BriefCard (Home, ADR 0018 B, CA-HOME-01..06): the structured search. Port of design/src/system/domain-client/BriefCard.tsx.
///
/// A paper panel with a hairline and no shadow (ADR 0018 D9): four rows of 64 that are each a button (Date full width; Area and Guests
/// side by side; the venue and catering Budget), then the one gold primary of the screen: `Show 38 halls`, a live count, never the word
/// Search (ADR 0034: each row is a glyph and its value, the row's name is the accessible name). A prefilled summary of the couple's
/// brief; a skipped answer shows a muted placeholder. Each row opens its sheet (the screen's job); there are no text fields.
/// States: default, filled, partly empty (muted placeholders), pressed row, focus, loading (the CTA draws its thread), offline (no count).
library;

import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;

import '../core/core.dart';
import '../foundation.dart';
import 'client_a_kit.dart';
import 'client_bits.dart';

class GzBriefCard extends StatelessWidget {
  const GzBriefCard({required this.brief, this.count, this.onEdit, this.onShow, this.loading = false, super.key});

  final GzBrief brief;

  /// Halls matching the brief (and free on its date): the live count in the button. Null offline or before the first answer.
  final int? count;

  /// One row tapped: the screen opens the matching sheet.
  final ValueChanged<GzBriefField>? onEdit;
  final VoidCallback? onShow;

  /// The count is being fetched: the button draws its thread once and ignores taps.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l = context.gzL10n;
    final lang = gz.locale.languageCode;

    final names = [for (final a in brief.areas) a.of(lang)];
    final area = names.isEmpty
        ? null
        : names.length <= 2
        ? f.list(names)
        : '${names.first} ${l.uiClientBriefCardMore(f.integer(names.length - 1))}';
    final date = brief.date == null ? null : f.date(brief.date.toString(), DateStyle.short);
    final guests = brief.guests == null || brief.guests == 0 ? null : f.integer(brief.guests!);
    final min = brief.budgetMinFils;
    final max = brief.budgetMaxFils;
    final budget = min == null ? null : (max != null && max != 0 ? f.moneyRange(min, max) : gzOpenBudget(f, min));

    Widget row(GzBriefField field, String name, String? value, String placeholder, IconData icon, {bool border = true}) =>
        _BriefRow(icon: icon, name: name, value: value, placeholder: placeholder, border: border, onPressed: () => onEdit?.call(field));

    final countText = count == null ? null : f.digits(l.commonCountHalls(count!));
    final cta = countText == null ? l.uiClientBriefCardShowHalls : l.uiClientBriefCardShowCount(countText);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l.uiClientBriefCardTitle,
      child: Container(
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
            row(GzBriefField.date, l.uiClientBriefCardNameDate, date, l.uiClientBriefCardDate, GzIcons.calendar, border: false),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: row(GzBriefField.area, l.uiClientBriefCardNameArea, area, l.uiClientBriefCardArea, GzIcons.pin)),
                  const GzDivider(vertical: true),
                  Expanded(child: row(GzBriefField.guests, l.uiClientBriefCardNameGuests, guests, l.uiClientBriefCardGuests, GzIcons.guests)),
                ],
              ),
            ),
            row(GzBriefField.budget, l.uiClientBriefCardNameBudget, budget, l.uiClientBriefCardBudget, GzIcons.wallet),
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
              padding: const EdgeInsetsDirectional.all(GzSpace.s4),
              child: GzButton(label: cta, fullWidth: true, loading: loading, onPressed: onShow),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row: glyph at inline-start, value beside it (the row's name is the accessible name), 64 high, quiet fill while pressed.
class _BriefRow extends StatelessWidget {
  const _BriefRow({required this.icon, required this.name, required this.value, required this.placeholder, required this.border, required this.onPressed});

  final IconData icon;
  final String name;
  final String? value;
  final String placeholder;

  /// The hairline above the row (every row but the first); it takes its 1 dp out of the 64 minimum like a border-box.
  final bool border;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final empty = value == null;
    final shown = value ?? placeholder;
    final body = gz.text(GzTextRole.body);
    final style = body.copyWith(
      color: empty ? c.textSecondary : c.textStrong,
      fontWeight: empty ? body.fontWeight : gz.text(GzTextRole.title).fontWeight,
      decoration: TextDecoration.none,
    );
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: l.uiClientBriefCardRow(name, shown),
      builder: (context, st) => Container(
        constraints: const BoxConstraints(minHeight: GzSize.briefRow),
        decoration: BoxDecoration(
          color: st.pressed ? c.surfaceQuiet : null,
          border: border ? Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair)) : null,
        ),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4, vertical: GzSpace.s3),
        child: Row(
          children: [
            GzIcon(icon, size: GzIconSize.md, color: c.iconSecondary),
            const SizedBox(width: GzSpace.s3),
            Expanded(child: Text.rich(TextSpan(children: GzFigures.spans(context, shown, role: GzTextRole.body)), style: style)),
          ],
        ),
      ),
    );
  }
}
