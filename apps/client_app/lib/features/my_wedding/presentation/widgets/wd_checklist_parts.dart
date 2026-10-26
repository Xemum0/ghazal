import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show ChecklistItem, LocalDate;
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:intl/intl.dart' show Bidi;

import 'wd_common.dart' show WdBi;

/// ProgressHead (the web CL-WEDD-02 head): how far the checklist is as a figure. The percent in the inline icon stat, the fraction quietly
/// at the end, one gold line as long as the share done. No words: "1 of 9 done" is the accessible name.
class WdProgressHead extends StatelessWidget {
  const WdProgressHead({required this.done, required this.total, super.key});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    final c = context.gz.colors;
    final label = context.l10n.clientMyWeddingChecklistProgress(f.integer(done), f.integer(total));
    final share = total == 0 ? 0 : (done / total * 1000).round();
    return Semantics(
      image: true,
      label: label,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GzIconStat(
                icon: GzIcons.checklist,
                label: label,
                value: f.percent(total == 0 ? 0 : done / total * 100, maxFraction: 0),
                layout: GzFactLayout.inline,
              ),
              const SizedBox(width: GzSpace.s3),
              gzFigText(context, '${f.integer(done)}/${f.integer(total)}', role: GzTextRole.figBodyS, color: c.textSecondary),
            ],
          ),
          const SizedBox(height: GzSpace.s3),
          SizedBox(
            height: GzStroke.threadMax,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (share > 0)
                  Expanded(
                    flex: share,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: c.markKhayt, borderRadius: GzRadius.pillAll),
                    ),
                  ),
                if (share < 1000)
                  Expanded(
                    flex: 1000 - share,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: c.markTrack, borderRadius: GzRadius.pillAll),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A band: the countdown window its tasks fall in. A label on the quiet tone (glyph and the title weight), full-bleed, not a card.
class WdBand extends StatelessWidget {
  const WdBand({required this.icon, required this.title, super.key});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: GzSize.controlSm),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
      color: c.surfaceQuiet,
      child: Row(
        children: [
          GzIcon(icon, size: GzIconSize.xs, color: c.iconSecondary),
          const SizedBox(width: GzSpace.s2),
          Expanded(
            child: GzText.rich(
              TextSpan(text: title, style: const TextStyle(fontWeight: FontWeight.w500)),
              role: GzTextRole.bodyS,
              color: c.textPrimary,
              header: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// The glyph of a checklist task (the Next up rows of the hub read the same drawing); a task the couple added takes the notes glyph.
IconData wdTaskGlyph(String id) => switch (id) {
  'chk-venue' => GzIcons.hall,
  'chk-photographer' => GzIcons.camera,
  'chk-dress' => GzIcons.dress,
  'chk-invitations' => GzIcons.mail,
  'chk-cake' => GzIcons.cake,
  'chk-music' => GzIcons.music,
  'chk-flowers' => GzIcons.flower,
  'chk-transport' => GzIcons.car,
  'chk-bukhoor' => GzIcons.incense,
  _ => GzIcons.notes,
};

/// ChecklistRow (the web local build): a 44 check target around a 24 box, the task glyph, the task in one word with its due date as a
/// calendar fact (an overdue date carries the warning glyph, never colour alone), and at the end one glyph: search (opens the service
/// category), edit (a task the couple added) or the chevron (the Venue row opens its booking). Done is ink and quiet.
class WdTaskRow extends StatelessWidget {
  const WdTaskRow({
    required this.item,
    required this.title,
    required this.today,
    this.venueStatus,
    this.last = false,
    this.readOnly = false,
    this.onToggle,
    this.onBrowse,
    this.onOpenBooking,
    this.onEdit,
    super.key,
  });

  final ChecklistItem item;
  final String title;
  final LocalDate today;

  /// The story booking exists but is not confirmed yet: the Venue row shows its status instead of a lock.
  final GzStatus? venueStatus;
  final bool last;
  final bool readOnly;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onBrowse;
  final VoidCallback? onOpenBooking;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    final f = context.gzFormat;
    final due = item.dueOn;
    final done = item.done;
    final overdue = !done && due != null && due.isBefore(today);
    final locked = item.auto;
    final chipHeight = context.gz.isAr ? 22.0 : 20.0;

    Widget? meta;
    if (done) {
      meta = null;
    } else if (locked) {
      meta = venueStatus != null
          ? GzStatusPill(status: venueStatus!)
          : Semantics(
              label: l.clientMyWeddingChecklistAuto,
              child: GzIcon(GzIcons.lock, size: GzIconSize.xs, color: c.iconSecondary),
            );
    } else if (due != null && overdue) {
      meta = Semantics(
        label: l.clientMyWeddingChecklistOverdue(f.date(due.toString(), DateStyle.short)),
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GzIcon(GzIcons.warningCircle, size: GzIconSize.xs, color: c.iconDanger),
            const SizedBox(width: GzSpace.s1),
            gzFigText(context, f.date(due.toString(), DateStyle.dayMonth), role: GzTextRole.figCaption, color: c.textDanger),
          ],
        ),
      );
    } else if (due != null) {
      meta = ConstrainedBox(
        constraints: BoxConstraints(minHeight: chipHeight),
        child: GzFactChip(
          icon: GzIcons.calendar,
          label: l.clientMyWeddingChecklistDue(f.date(due.toString(), DateStyle.short)),
          value: f.date(due.toString(), DateStyle.dayMonth),
          small: true,
        ),
      );
    }

    final canBrowse = !done && item.serviceCategoryId != null && onBrowse != null;
    final Widget? end = item.custom && onEdit != null && !readOnly
        ? GzIconButton(icon: GzIcons.edit, iconSize: GzIconSize.sm, label: '${l.clientMyWeddingChecklistEdit}: $title', onPressed: onEdit)
        : canBrowse
        ? GzIconButton(icon: GzIcons.search, iconSize: GzIconSize.sm, label: l.clientMyWeddingChecklistBrowseLabel(title), onPressed: onBrowse)
        : item.auto && onOpenBooking != null
        ? GzIconButton(icon: GzIcons.chevronRight, iconSize: GzIconSize.sm, label: l.clientMyWeddingChecklistViewBookingLabel(title), onPressed: onOpenBooking)
        : null;

    final blocked = locked || readOnly || onToggle == null;
    final box = Semantics(
      container: true,
      checked: done,
      enabled: !blocked,
      label: title,
      onTap: blocked ? null : () => onToggle?.call(!done),
      excludeSemantics: true,
      child: GzPressable(
        onPressed: blocked ? null : () => onToggle?.call(!done),
        borderRadius: GzRadius.pillAll,
        scale: 1,
        child: SizedBox(
          width: GzSize.touchMin,
          height: GzSize.touchMin,
          child: Center(
            child: AnimatedContainer(
              duration: GzMotion.durationFast,
              curve: GzMotion.easeStandard,
              width: GzSize.iconMd,
              height: GzSize.iconMd,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done ? c.controlToggleOn : c.surfaceRaised,
                borderRadius: GzRadius.xsAll,
                border: Border.all(color: done ? c.controlToggleOn : c.borderControl, width: GzStroke.icon),
              ),
              child: done ? GzIcon(GzIcons.check, size: GzIconSize.xs, color: c.controlToggleKnob) : null,
            ),
          ),
        ),
      ),
    );

    return Container(
      constraints: const BoxConstraints(minHeight: GzSize.rowMin),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: last ? c.borderHairline.withAlpha(0) : c.borderHairline, width: GzStroke.hair)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          box,
          const SizedBox(width: GzSpace.s3),
          GzIcon(wdTaskGlyph(item.id), size: GzIconSize.md, color: c.iconSecondary),
          const SizedBox(width: GzSpace.s1),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.s1, top: GzSpace.s3, bottom: GzSpace.s3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection: Bidi.detectRtlDirectionality(title) ? TextDirection.rtl : TextDirection.ltr,
                    child: GzText(title, role: GzTextRole.title, color: done ? c.textSecondary : c.textStrong),
                  ),
                  ?meta,
                ],
              ),
            ),
          ),
          if (end != null) ...[const SizedBox(width: GzSpace.s1), end],
        ],
      ),
    );
  }
}

/// The title of a task: the one-word copy of the default tasks, else the couple's own words.
String wdTaskTitle(BuildContext context, ChecklistItem item) {
  final l = context.l10n;
  return switch (item.id) {
    'chk-venue' => l.clientMyWeddingTaskVenue,
    'chk-photographer' => l.clientMyWeddingTaskPhotographer,
    'chk-dress' => l.clientMyWeddingTaskDress,
    'chk-invitations' => l.clientMyWeddingTaskInvitations,
    'chk-cake' => l.clientMyWeddingTaskCake,
    'chk-music' => l.clientMyWeddingTaskMusic,
    'chk-flowers' => l.clientMyWeddingTaskFlowers,
    'chk-transport' => l.clientMyWeddingTaskTransport,
    _ => context.bi(item.title),
  };
}
