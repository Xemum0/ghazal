import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show ChecklistItem, LocalDate;
import 'package:intl/intl.dart' show Bidi;

import '../core/core.dart';
import '../foundation.dart';

/// ChecklistItem: a 64 row, a 24 box in a 44 target, the task, its due date in absolute words, a trailing action that opens the
/// matching service category. Done is ink and quiet (no strike-through); overdue says "Overdue" with a glyph, not colour alone; a
/// task the system completes ([ChecklistItem.auto], the Venue at confirmation) shows a lock and cannot be ticked by hand.
/// [today] is the civil date of the overdue test (the formatter's clock by default).
class GzChecklistItem extends StatelessWidget {
  const GzChecklistItem({required this.item, this.today, this.onToggle, this.onChoose, this.actionLabel, this.last = false, super.key});

  final ChecklistItem item;
  final LocalDate? today;
  final ValueChanged<bool>? onToggle;

  /// Opens the service category this task points at ("Choose a photographer").
  final VoidCallback? onChoose;

  /// The category name for the action label ("Photography").
  final String? actionLabel;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l = context.gzL10n;
    final lang = gz.locale.languageCode;
    final now = today ?? LocalDate.parse(f.isoDay(f.now()));
    final due = item.dueOn;
    final overdue = !item.done && due != null && due.isBefore(now);
    final locked = item.auto;
    final title = item.title.of(lang);
    final String? meta;
    if (item.done) {
      meta = item.doneAt == null ? null : l.uiClientChecklistCompletedOn(f.date(item.doneAt!, DateStyle.short));
    } else if (locked) {
      meta = l.uiClientChecklistAuto;
    } else if (due != null) {
      final d = f.date(due.toString(), DateStyle.short);
      meta = overdue ? l.uiClientChecklistOverdue(d) : l.uiClientChecklistDue(d);
    } else {
      meta = item.custom ? l.uiClientChecklistYours : l.uiClientChecklistNoDate;
    }
    final showGo = !item.done && item.serviceCategoryId != null && onChoose != null;
    final on = item.done;
    final box = Semantics(
      container: true,
      checked: on,
      enabled: !locked,
      label: title,
      onTap: locked ? null : () => onToggle?.call(!on),
      excludeSemantics: true,
      child: GzPressable(
        onPressed: locked ? null : () => onToggle?.call(!on),
        borderRadius: GzRadius.pillAll,
        scale: 1,
        child: SizedBox(
          width: GzSize.touchMin,
          height: GzSize.touchMin,
          child: Center(
            child: AnimatedContainer(
              duration: GzMotion.durationBase,
              curve: GzMotion.easeStandard,
              width: GzSize.iconMd,
              height: GzSize.iconMd,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? c.controlToggleOn : c.surfaceRaised,
                borderRadius: GzRadius.xsAll,
                border: Border.all(color: on ? c.controlToggleOn : c.borderControl, width: GzStroke.icon),
              ),
              child: on ? GzIcon(GzIcons.check, size: GzIconSize.xs, color: c.controlToggleKnob) : null,
            ),
          ),
        ),
      ),
    );
    final text = Padding(
      padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Directionality(
            textDirection: Bidi.detectRtlDirectionality(title) ? TextDirection.rtl : TextDirection.ltr,
            child: GzText(title, role: GzTextRole.title, color: on ? c.textSecondary : c.textStrong),
          ),
          if (meta != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (overdue) ...[GzIcon(GzIcons.warningCircle, size: GzIconSize.xs, color: c.iconDanger), const SizedBox(width: GzSpace.s1)],
                if (locked && !on && !overdue) ...[GzIcon(GzIcons.lock, size: GzIconSize.xs, color: c.iconSecondary), const SizedBox(width: GzSpace.s1)],
                Flexible(
                  child: GzText(meta, role: GzTextRole.caption, color: overdue ? c.textDanger : c.textSecondary, figures: true),
                ),
              ],
            ),
        ],
      ),
    );
    return Container(
      constraints: const BoxConstraints(minHeight: GzSize.rowMin),
      decoration: BoxDecoration(
        border: Border(
          bottom: last ? BorderSide.none : BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          box,
          const SizedBox(width: GzSpace.s2),
          Expanded(child: text),
          if (showGo) GzIconButton(icon: GzIcons.chevronRight, label: '${l.uiClientChecklistChoose}: ${actionLabel ?? title}', onPressed: onChoose),
        ],
      ),
    );
  }
}
