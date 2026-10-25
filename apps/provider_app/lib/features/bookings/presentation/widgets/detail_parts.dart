// The small anatomy of Booking detail (web `DetailParts.tsx`, ADR 0034): a quiet panel, a ruled list of glyph lines (a glyph or a drawing at
// inline-start, the value, an optional trailing figure), a notice line, the copy-on-long-press value and the quiet money of the detail.
// Hairlines and tone before shadows; gold only where a state is waiting.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show MoneyMode, MoneyOptions;
import 'package:ghazal_ui/ghazal_ui.dart';

enum PanelTone { paper, quiet, tint }

class BkPanel extends StatelessWidget {
  const BkPanel({required this.child, this.tone = PanelTone.paper, super.key});

  final Widget child;
  final PanelTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final (Color bg, Color border) = switch (tone) {
      PanelTone.paper => (c.surfaceRaised, c.borderStrong),
      PanelTone.quiet => (c.surfaceQuiet, c.borderHairline),
      PanelTone.tint => (c.surfaceTint, c.surfaceTint),
    };
    return Container(
      padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
      decoration: BoxDecoration(color: bg, borderRadius: GzRadius.mdAll, border: Border.all(color: border, width: GzStroke.hair)),
      child: child,
    );
  }
}

/// One line of a [BkLines]: a glyph in a quiet disk (or a [lead] drawing), the value in the title weight, facts under it, a figure at the end.
class BkLine {
  const BkLine({required this.child, this.icon, this.lead, this.label, this.tone = GzIconTone.secondary, this.trailing, this.facts});

  final Widget child;
  final IconData? icon;
  final Widget? lead;
  final String? label;
  final GzIconTone tone;
  final Widget? trailing;
  final Widget? facts;
}

/// A ruled list of glyph lines: a hairline between, none after the last; the first has no top pad and the last no bottom pad.
class BkLines extends StatelessWidget {
  const BkLines({required this.lines, this.label, super.key});

  final List<BkLine> lines;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < lines.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(border: i == lines.length - 1 ? null : Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: GzSize.rowMin),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(top: i == 0 ? 0 : GzSpace.s3, bottom: i == lines.length - 1 ? 0 : GzSpace.s3),
                  child: _line(context, lines[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, BkLine l) {
    final c = context.gz.colors;
    final lead = l.lead ??
        (l.icon == null
            ? null
            : ExcludeSemantics(
                child: Container(
                  width: GzSize.avatarSm,
                  height: GzSize.avatarSm,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.surfaceQuiet, shape: BoxShape.circle),
                  child: GzIcon(l.icon!, size: GzIconSize.sm, tone: l.tone),
                ),
              ));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (lead != null) ...[lead, const SizedBox(width: GzSpace.s3)],
        Expanded(
          child: Semantics(
            container: true,
            label: l.label,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [l.child, if (l.facts != null) ...[const SizedBox(height: GzSpace.s1), l.facts!]],
            ),
          ),
        ),
        if (l.trailing != null) ...[const SizedBox(width: GzSpace.s3), l.trailing!],
      ],
    );
  }
}

/// A glyph and a few words: the notice of the detail (offline, held, view only).
class BkNote extends StatelessWidget {
  const BkNote({required this.icon, required this.child, this.tone = GzIconTone.secondary, this.action, super.key});

  final IconData icon;
  final Widget child;
  final GzIconTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    container: true,
    child: Row(
      children: [
        GzIcon(icon, size: GzIconSize.sm, tone: tone),
        const SizedBox(width: GzSpace.s2),
        Expanded(child: child),
        ?action,
      ],
    ),
  );
}

/// A value that copies on a long press (500 ms) and says so with the shared "Copied" toast.
class BkCopyable extends StatelessWidget {
  const BkCopyable({required this.value, required this.child, super.key});

  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onLongPress: () {
      Clipboard.setData(ClipboardData(text: value));
      context.gzNav.toast(GzToastSpec(message: context.gzL10n.commonStateCopied, icon: GzIcons.copy));
    },
    child: child,
  );
}

/// A small amount in the figures voice (a saving, a line of the quote): currency and figure in one LTR island (web `QuietMoney`).
class BkQuietMoney extends StatelessWidget {
  const BkQuietMoney({required this.fils, this.label, this.color, super.key});

  final int fils;
  final String? label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final parts = context.gzFormat.moneyParts(fils, const MoneyOptions(mode: MoneyMode.exact));
    final style = gz.text(GzTextRole.figBodyS).copyWith(color: color ?? gz.colors.textSecondary, decoration: TextDecoration.none);
    return Semantics(
      label: label == null ? GzBidi.strip(parts.text) : '$label ${GzBidi.strip(parts.text)}',
      excludeSemantics: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: gz.isAr ? 26 : GzSize.iconMd),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              gzSnappedText(parts.currency, style: style, softWrap: false),
              gzSnappedText(' ', style: style),
              gzSnappedText('${parts.integer}${parts.fraction}', style: style, softWrap: false),
            ],
          ),
        ),
      ),
    );
  }
}
