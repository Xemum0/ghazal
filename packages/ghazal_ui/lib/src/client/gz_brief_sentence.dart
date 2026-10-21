/// BriefSentence (direction section 3, "Brief sentence"; ADR 0007 D3): the couple's brief set as one typeset sentence: audience,
/// guests, date, area, budget. Port of design/src/system/domain-client/BriefSentence.tsx.
///
/// It is the read-only echo on results, compare and booking headers (the whole block is one 44+ button that opens the Brief sheet) and,
/// in its `edit` form, the sentence at the top of the Brief sheet where each of the four decisions is its own target underlined with a
/// 1 dp gold rule (the only gold on it: place, not decoration). Variants: results (display d1, up to four lines), compare (body, two
/// lines, no budget), booking (body, two lines, no budget and no area), edit (display brief, tokens underlined). The Arabic clause order
/// and prepositions are written natively in the l10n part, never translated word for word.
library;

import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show Audience;

import '../core/core.dart';
import '../foundation.dart';
import 'client_a_kit.dart';
import 'client_bits.dart';

enum GzBriefSentenceVariant { results, compare, booking, edit }

class GzBriefSentence extends StatelessWidget {
  const GzBriefSentence({required this.brief, this.variant = GzBriefSentenceVariant.results, this.onEdit, this.onEditField, super.key});

  final GzBrief brief;
  final GzBriefSentenceVariant variant;

  /// Echo variants: opens the Brief sheet.
  final VoidCallback? onEdit;

  /// `edit` variant: one decision tapped.
  final ValueChanged<GzBriefField>? onEditField;

  bool get _edit => variant == GzBriefSentenceVariant.edit;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final ar = gz.isAr;
    final lang = gz.locale.languageCode;
    final showArea = variant != GzBriefSentenceVariant.booking;
    final showBudget = variant == GzBriefSentenceVariant.results || _edit;
    final role = switch (variant) {
      GzBriefSentenceVariant.results => GzTextRole.d1,
      GzBriefSentenceVariant.edit => GzTextRole.brief,
      _ => GzTextRole.body,
    };
    final base = gz.text(role).copyWith(color: c.textPrimary, decoration: TextDecoration.none);

    final names = [for (final a in brief.areas) a.of(lang)];
    final min = brief.budgetMinFils;
    final max = brief.budgetMaxFils;
    final audience = switch (brief.audience) {
      Audience.women => l.uiClientBriefSentenceWomen,
      Audience.men => l.uiClientBriefSentenceMen,
      Audience.mixed => l.uiClientBriefSentenceMixed,
      _ => l.uiClientBriefSentenceReception,
    };
    final guests = brief.guests == null || brief.guests == 0 ? null : f.guests(brief.guests!, afterPreposition: ar);
    final date = brief.date == null ? null : f.date(brief.date.toString(), _edit ? DateStyle.full : DateStyle.short);
    final area = names.isEmpty ? null : f.list(names, or: true);
    final budget = min == null ? null : (max != null && max != 0 ? f.moneyRange(min, max) : gzOpenBudget(f, min));

    // A comma travels with the clause it introduces and is glued to the word before it (word joiner), so a line never starts with a
    // comma in Arabic.
    final comma = ar ? '⁠، ' : '⁠, ';
    final clauses = <_Clause>[
      _Clause(GzBriefField.guests, ' ${l.uiClientBriefSentenceForGuests} ', guests, l.uiClientBriefSentenceChooseGuests, l.uiClientBriefSentenceWhatGuests, nowrap: true),
      _Clause(GzBriefField.date, ' ${l.uiClientBriefSentenceOn} ', date, l.uiClientBriefSentenceChooseDate, l.uiClientBriefSentenceWhatDate, nowrap: true),
      if (showArea) _Clause(GzBriefField.area, '$comma${l.uiClientBriefSentenceIn} ', area, l.uiClientBriefSentenceChooseArea, l.uiClientBriefSentenceWhatArea),
      if (showBudget) _Clause(GzBriefField.budget, '$comma${l.uiClientBriefSentenceBudgetOf} ', budget, l.uiClientBriefSentenceChooseBudget, l.uiClientBriefSentenceWhatBudget, nowrap: true),
    ];

    final spans = <InlineSpan>[TextSpan(text: audience, style: TextStyle(color: c.textStrong))];
    for (final cl in clauses) {
      if (!_edit && cl.value == null) continue;
      spans.add(TextSpan(text: cl.pre));
      final empty = cl.value == null;
      final shown = cl.value ?? cl.placeholder;
      final color = empty ? c.textSecondary : c.textStrong;
      final text = cl.nowrap && !_edit ? shown.replaceAll(' ', ' ') : shown;
      final figures = GzFigures.spans(context, text, role: role);
      if (_edit) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _EditToken(
              label: l.uiClientBriefSentenceField(cl.what),
              onPressed: () => onEditField?.call(cl.field),
              child: Text.rich(TextSpan(children: figures), style: base.copyWith(color: color), softWrap: false),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(children: figures, style: TextStyle(color: color)));
      }
    }
    spans.add(const TextSpan(text: '.'));

    final sentence = Text.rich(
      TextSpan(children: spans),
      style: base,
      maxLines: switch (variant) {
        GzBriefSentenceVariant.results => 4,
        GzBriefSentenceVariant.edit => null,
        _ => 2,
      },
      overflow: _edit ? TextOverflow.clip : TextOverflow.ellipsis,
      textAlign: TextAlign.start,
      // CSS: the figure islands carry `line-height: 0`, so a line is exactly the line-height of the role. Flutter lets a run of another
      // face stretch the line by its own metrics (up to 3 dp), so the echo forces the strut. The edit form must not: its buttons set the pitch.
      strutStyle: _edit ? null : StrutStyle.fromTextStyle(base, forceStrutHeight: true),
    );
    if (_edit) return sentence;
    return GzPressable(
      onPressed: onEdit,
      borderRadius: GzRadius.smAll,
      builder: (context, st) => DecoratedBox(
        decoration: BoxDecoration(color: st.pressed ? c.surfaceQuiet : null, borderRadius: GzRadius.smAll),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.touchMin),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: sentence),
                const SizedBox(width: GzSpace.s3),
                Semantics(
                  label: l.uiClientBriefSentenceEditLabel,
                  child: const SizedBox.square(dimension: GzSize.iconMd, child: Center(child: GzIcon(GzIcons.edit, size: GzIconSize.sm))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Clause {
  const _Clause(this.field, this.pre, this.value, this.placeholder, this.what, {this.nowrap = false});

  final GzBriefField field;
  final String pre;
  final String? value;
  final String placeholder;
  final String what;
  final bool nowrap;
}

/// One decision of the edit form: a button with a 1 dp gold rule under it (the rule sits at the padding edge, 8 below the text; the
/// padding also lifts the target to 44). Pressed it takes the pending tint and the deeper rule.
class _EditToken extends StatelessWidget {
  const _EditToken({required this.label, required this.onPressed, required this.child});

  final String label;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: label,
      borderRadius: GzRadius.xsAll,
      minHeight: 0,
      builder: (context, st) => Container(
        decoration: BoxDecoration(
          color: st.pressed ? c.statusPendingBg : null,
          borderRadius: GzRadius.xsAll,
          border: Border(bottom: BorderSide(color: st.pressed ? c.markState : c.markKhayt, width: GzStroke.hair)),
        ),
        padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s2),
        child: child,
      ),
    );
  }
}
