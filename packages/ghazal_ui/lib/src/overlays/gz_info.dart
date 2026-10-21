import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';
import 'gz_sheet.dart';

/// The button a sheet may carry under its paragraphs (read the terms): it closes the sheet first, then acts (web `AsideInfo.action`).
@immutable
class GzInfoAction {
  const GzInfoAction({required this.label, required this.onPressed, this.iconEnd});

  final String label;
  final VoidCallback onPressed;
  final IconData? iconEnd;
}

/// InfoSheet (web `InfoSheet`, ADR 0034, text diet section 6): the sheet where the paragraphs that survive the diet live: a [title] of at
/// most three words, the paragraphs (one idea each, body type, ink 700) and a Done button. The sheet supplies the 20 gutter and the bottom
/// padding: [paragraphs] and [children] are bare. [action] adds a tertiary button under them that closes the sheet before it acts.
Future<void> showGzInfoSheet(
  BuildContext context, {
  required String title,
  List<String> paragraphs = const [],
  List<Widget> children = const [],
  GzInfoAction? action,
}) {
  return showGzSheet<void>(
    context,
    title: title,
    footer: Builder(
      builder: (c) => GzButton(label: c.gzL10n.commonActionDone, variant: GzButtonVariant.secondary, fullWidth: true, onPressed: () => Navigator.of(c).pop()),
    ),
    builder: (sheet) => GzInfoBody(
      children: [
        for (final p in paragraphs) GzText(p, role: GzTextRole.body, color: sheet.gz.colors.textPrimary, figures: true),
        ...children,
        if (action != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: GzButton(
              label: action.label,
              variant: GzButtonVariant.tertiary,
              iconEnd: action.iconEnd,
              onPressed: () {
                Navigator.of(sheet).pop();
                action.onPressed();
              },
            ),
          ),
      ],
    ),
  );
}

/// The body of an info sheet: a column with 12 between the paragraphs (web `.gz-info__body`).
class GzInfoBody extends StatelessWidget {
  const GzInfoBody({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s3), children[i]],
      ],
    );
  }
}

/// InfoButton (web `InfoButton`): the info glyph (a 44 dp target) and the sheet it opens. Place it beside the checkbox, the card header or
/// the error it explains. [label] is its accessible name (default the shared "More info"); [paragraphs] and [children] fill the sheet
/// (see [showGzInfoSheet]; the sheet adds the gutter); [action] is the optional button under them. Reports `expanded` while the sheet is up.
/// [bleed] pulls the glyph's 10 dp of slack into the gutter when it ends a row that sits on the gutter.
class GzInfoButton extends StatefulWidget {
  const GzInfoButton({
    required this.title,
    this.paragraphs = const [],
    this.children = const [],
    this.action,
    this.label,
    this.icon = GzIcons.info,
    this.bleed = false,
    super.key,
  });

  /// The sheet title (at most three words).
  final String title;
  final List<String> paragraphs;
  final List<Widget> children;
  final GzInfoAction? action;
  final String? label;
  final IconData icon;
  final bool bleed;

  /// The slack between the 24 dp glyph and the 44 dp target, per side.
  static const double slack = (GzSize.touchMin - GzSize.iconMd) / 2;

  @override
  State<GzInfoButton> createState() => _GzInfoButtonState();
}

class _GzInfoButtonState extends State<GzInfoButton> {
  bool _open = false;

  Future<void> _show() async {
    setState(() => _open = true);
    await showGzInfoSheet(context, title: widget.title, paragraphs: widget.paragraphs, children: widget.children, action: widget.action);
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final button = GzIconButton(icon: widget.icon, iconSize: GzIconSize.sm, label: widget.label ?? context.gzL10n.commonA11yInfo, expanded: _open, onPressed: _show);
    if (!widget.bleed) return button;
    return Transform.translate(offset: Offset(context.gz.isRtl ? -GzInfoButton.slack : GzInfoButton.slack, 0), child: button);
  }
}

/// AsideInfo (web `AsideInfo`): the one sentence a step may keep, behind a quiet row: a glyph, at most one word and the info glyph.
/// Tapping anywhere on the row opens the info sheet ([title] of at most three words, the paragraphs, Done, the optional [action]).
class GzAsideInfo extends StatefulWidget {
  const GzAsideInfo({required this.icon, required this.word, required this.title, this.paragraphs = const [], this.children = const [], this.action, super.key});

  final IconData icon;

  /// The one word on the row.
  final String word;
  final String title;
  final List<String> paragraphs;
  final List<Widget> children;
  final GzInfoAction? action;

  @override
  State<GzAsideInfo> createState() => _GzAsideInfoState();
}

class _GzAsideInfoState extends State<GzAsideInfo> {
  bool _open = false;

  Future<void> _show() async {
    setState(() => _open = true);
    await showGzInfoSheet(context, title: widget.title, paragraphs: widget.paragraphs, children: widget.children, action: widget.action);
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: GzPressable(
        onPressed: _show,
        semanticLabel: '${widget.word}, ${widget.title}',
        expanded: _open,
        borderRadius: GzRadius.smAll,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GzIcon(widget.icon, size: GzIconSize.sm, color: c.textSecondary),
            const SizedBox(width: GzSpace.s2),
            GzText(widget.word, role: GzTextRole.bodyS, color: c.textSecondary),
            const SizedBox(width: GzSpace.s2),
            GzIcon(GzIcons.info, size: GzIconSize.sm, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}
