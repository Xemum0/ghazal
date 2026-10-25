// Small pieces shared by the five Visits screens and their sheets (web `visits/_components/bits.tsx`): the notice panel, the titled section
// and the sheet shell (pinned title row, scrolling middle, pinned footer). Everything numeric comes from the shared formatter.
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// A quiet panel with one icon and a short text: the consequence, the limit, the reason. Never gold. `rose` for a consequence worth reading twice.
class VisitNotice extends StatelessWidget {
  const VisitNotice({required this.icon, required this.text, this.title, this.rose = false, super.key});

  final IconData icon;
  final String text;
  final String? title;
  final bool rose;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(GzSpace.s4),
        decoration: BoxDecoration(color: rose ? c.surfaceTintSoft : c.surfaceQuiet, borderRadius: GzRadius.mdAll),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: GzSpace.s1),
              child: GzIcon(icon, size: GzIconSize.sm, color: c.iconSecondary),
            ),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[GzText(title!, role: GzTextRole.title, color: c.textStrong), const SizedBox(height: GzSpace.s1)],
                  GzUserText(text, role: GzTextRole.bodyS, color: c.textPrimary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A titled block of a detail screen: the label above, the content below, on the 20 gutter.
class VisitSection extends StatelessWidget {
  const VisitSection({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.pillMin),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: GzText(title, role: GzTextRole.label, color: c.textSecondary, header: true),
            ),
          ),
          const SizedBox(height: GzSpace.s3),
          child,
        ],
      ),
    );
  }
}

/// The anatomy of every sheet of the flow: the title row (close at inline-end) pinned above the middle, the action footer pinned below it.
class VisitSheetShell extends StatelessWidget {
  const VisitSheetShell({required this.title, required this.children, this.footer, this.gap = GzSpace.s4, super.key});

  final String title;
  final List<Widget> children;
  final Widget? footer;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final nav = GzNavigatorScope.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSheetPinnedHeader(
          child: GzSheetHeader(title: title, onClose: nav.closeSheet),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]],
            ],
          ),
        ),
        if (footer != null) GzSheetFooter(child: footer!),
      ],
    );
  }
}

/// The label of a field inside a sheet.
class VisitFieldLabel extends StatelessWidget {
  const VisitFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => GzText(text, role: GzTextRole.label, color: context.gz.colors.textSecondary);
}

/// A row of a pick list (radio of the representative sheet, static row of the member sheet): 64 high, hairline under it.
class VisitPickRow extends StatelessWidget {
  const VisitPickRow({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onPressed,
    this.selected,
    this.last = false,
    super.key,
  });

  final Widget leading;
  final Widget title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onPressed;

  /// Non-null makes it a radio row.
  final bool? selected;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final row = Container(
      constraints: const BoxConstraints(minHeight: GzSize.rowMin),
      padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: last ? c.borderHairline.withAlpha(0) : c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                title,
                if (subtitle != null) ...[const SizedBox(height: GzSpace.s1), GzText(subtitle!, role: GzTextRole.caption, color: c.textSecondary)],
              ],
            ),
          ),
          if (selected != null)
            Container(
              width: GzSize.iconMd,
              height: GzSize.iconMd,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected! ? c.actionSelectedBg : null,
                border: Border.all(color: selected! ? c.actionSelectedBg : c.borderControl, width: GzStroke.hair),
              ),
              child: selected! ? GzIcon(GzIcons.check, size: GzIconSize.sm, color: c.actionSelectedLabel) : null,
            ),
          ?trailing,
        ],
      ),
    );
    if (onPressed == null) return row;
    return GzPressable(
      onPressed: onPressed,
      selected: selected,
      semanticLabel: null,
      borderRadius: GzRadius.smAll,
      minHeight: GzSize.rowMin,
      scale: 1,
      child: row,
    );
  }
}
