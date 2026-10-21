import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show Bidi;

import '../foundation.dart';
import 'gz_preview.dart';

enum GzListRowSize { md, queue }

enum GzListRowTone { normal, danger }

/// ListRow (direction section 3): min 64 (queue row 80), a 1 dp ink-200 rule under it, title `title` role (500), caption sub-line,
/// a leading slot, a trailing slot, and a disclosure chevron that mirrors in Arabic. The row pads itself with the gutter (20) so a
/// pressed row fills edge to edge; pass [flush] inside a panel that already pads (a flush row is square, radius 0: its hairline
/// runs straight to both ends).
class GzListRow extends StatelessWidget {
  const GzListRow({
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.leading,
    this.trailing,
    this.chevron = false,
    this.size = GzListRowSize.md,
    this.onPressed,
    this.selected = false,
    this.tone = GzListRowTone.normal,
    this.autoDir = false,
    this.flush = false,
    this.last = false,
    this.previewState,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// A widget in the sub-line slot (a fact row) instead of a string.
  final Widget? subtitleWidget;

  /// Icon in a disk, avatar, thumbnail: anything up to 64 square.
  final Widget? leading;

  /// Amount, time, status pill, switch: sits at inline-end, before the chevron. Plain text inherits the `body-s` secondary style.
  final Widget? trailing;

  /// Disclosure chevron (mirrored in RTL by the icon registry).
  final bool chevron;
  final GzListRowSize size;

  /// Makes the row a button.
  final VoidCallback? onPressed;
  final bool selected;
  final GzListRowTone tone;

  /// Titles that are names (people, venues) align by their own first strong character (ADR 0014 D8).
  final bool autoDir;

  /// No own gutter: for rows inside a panel.
  final bool flush;

  /// Hide the bottom rule (last row of a group).
  final bool last;

  /// Gallery only.
  final GzPreviewState? previewState;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final interactive = onPressed != null;
    Widget titleText = GzText(title, role: GzTextRole.title, color: tone == GzListRowTone.danger ? c.textDanger : c.textStrong);
    if (autoDir) {
      titleText = Directionality(
        textDirection: Bidi.detectRtlDirectionality(title) ? TextDirection.rtl : TextDirection.ltr,
        child: titleText,
      );
    }
    Widget row(bool pressed) {
      final body = Container(
        constraints: BoxConstraints(minHeight: size == GzListRowSize.queue ? GzSize.rowQueue : GzSize.rowMin),
        padding: EdgeInsetsDirectional.only(start: flush ? 0 : GzSpace.gutter, end: flush ? 0 : GzSpace.gutter, top: GzSpace.s3, bottom: GzSpace.s3),
        decoration: BoxDecoration(
          color: pressed || selected ? c.surfaceQuiet : null,
          borderRadius: interactive && !flush ? GzRadius.smAll : null,
          border: Border(bottom: BorderSide(color: last ? c.scrimClear : c.borderHairline, width: GzStroke.hair)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: GzSpace.s4)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  titleText,
                  if (subtitleWidget != null)
                    subtitleWidget!
                  else if (subtitle != null)
                    GzText(subtitle!, role: GzTextRole.caption, color: c.textSecondary),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: GzSpace.s4),
              DefaultTextStyle(
                style: gz.text(GzTextRole.bodyS).copyWith(color: c.textSecondary, decoration: TextDecoration.none),
                child: trailing!,
              ),
            ],
            if (chevron) ...[
              const SizedBox(width: GzSpace.s4),
              GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
            ],
          ],
        ),
      );
      return gzPreview(previewState, body, radius: interactive && !flush ? GzRadius.sm : 0, scale: false);
    }

    if (!interactive) {
      return Semantics(container: true, selected: selected ? true : null, child: row(false));
    }
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: subtitle == null ? title : '$title, $subtitle',
      selected: selected ? true : null,
      borderRadius: flush ? null : GzRadius.smAll,
      scale: 1,
      minHeight: 0,
      builder: (context, st) => row(st.pressed || previewState == GzPreviewState.pressed),
    );
  }
}

/// IconListRow (ADR 0034): the list row of the diet. A leading glyph (in a quiet disk) or a small illustration, a one-line
/// title, a trailing fact or chevron. A second piece of information is a fact row under the title ([facts]). A thin layer over
/// [GzListRow] so the 64 minimum, the hairline, the pressed state and the mirrored chevron stay one implementation.
class GzIconListRow extends StatelessWidget {
  const GzIconListRow({
    required this.title,
    this.icon,
    this.illustration,
    this.trailing,
    this.facts,
    this.chevron,
    this.onPressed,
    this.selected = false,
    this.tone = GzListRowTone.normal,
    this.autoDir = false,
    this.flush = false,
    this.last = false,
    super.key,
  });

  final String title;
  final IconData? icon;

  /// A drawing instead of a glyph (state lists, partner tasks): raises the row to the illustration size.
  final GzIllustrationName? illustration;
  final Widget? trailing;

  /// Facts under the title (a fact row). The exception, not the rule.
  final Widget? facts;
  final bool? chevron;
  final VoidCallback? onPressed;
  final bool selected;
  final GzListRowTone tone;
  final bool autoDir;
  final bool flush;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final Widget? leading = illustration != null
        ? ExcludeSemantics(child: GzIllustration(illustration!, size: GzIllustrationSize.sm))
        : icon != null
            ? ExcludeSemantics(
                child: Container(
                  width: GzSize.avatarSm,
                  height: GzSize.avatarSm,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
                  child: GzIcon(icon!, size: GzIconSize.md, color: tone == GzListRowTone.danger ? c.iconDanger : c.iconPrimary),
                ),
              )
            : null;
    return GzListRow(
      title: title,
      subtitleWidget: facts,
      leading: leading,
      trailing: trailing,
      chevron: chevron ?? onPressed != null,
      onPressed: onPressed,
      selected: selected,
      tone: tone,
      autoDir: autoDir,
      flush: flush,
      last: last,
    );
  }
}
