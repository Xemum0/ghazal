import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'booking_layout.dart';

/// Opens the info sheet (web `InfoSheet`, ADR 0034): a title of at most three words, the paragraphs, a Done button. Nothing here is a
/// whole screen: it is where the one paragraph a step keeps lives.
Future<void> showBookingInfoSheet(BuildContext context, {required String title, required List<Widget> body, Widget? extra}) {
  return showGzSheet<void>(
    context,
    title: title,
    footer: Builder(
      builder: (c) =>
          GzButton(label: c.gzL10n.commonActionDone, variant: GzButtonVariant.secondary, fullWidth: true, onPressed: () => Navigator.of(c).pop()),
    ),
    // the sheet host supplies the gutter and the bottom inset
    builder: (c) => BookingGap(gap: GzSpace.s3, cross: CrossAxisAlignment.start, children: [...body, ?extra]),
  );
}

/// A paragraph of an info sheet (body type, ink 700).
class BookingInfoText extends StatelessWidget {
  const BookingInfoText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => GzText(text, role: GzTextRole.body, figures: true);
}

/// The info glyph (44 target) and the sheet it opens (web `InfoButton`). Place it beside the card header, the checkbox or the price it
/// explains.
class BookingInfoButton extends StatelessWidget {
  const BookingInfoButton({required this.title, required this.paragraphs, this.bleed = true, this.extra, this.label, super.key});

  /// The accessible name of the glyph (default: "More info").
  final String? label;

  final String title;
  final List<String> paragraphs;

  /// Pull the glyph's slack into the gutter (when it ends a row that sits on the gutter).
  final bool bleed;

  /// A button inside the sheet under the paragraphs (read the terms); it closes the sheet before it acts.
  final Widget Function(BuildContext sheet)? extra;

  @override
  Widget build(BuildContext context) {
    final button = GzIconButton(
      icon: GzIcons.info,
      iconSize: GzIconSize.sm,
      label: label ?? context.gzL10n.commonA11yInfo,
      onPressed: () => showBookingInfoSheet(
        context,
        title: title,
        body: [for (final p in paragraphs) BookingInfoText(p)],
        extra: extra == null ? null : Builder(builder: extra!),
      ),
    );
    return bleed ? EndBleed(child: button) : button;
  }
}

/// The one sentence a step may keep behind a quiet row: a glyph, at most one word and the info glyph (web `AsideInfo`).
class BookingAsideInfo extends StatelessWidget {
  const BookingAsideInfo({required this.icon, required this.word, required this.title, required this.paragraphs, super.key});

  final IconData icon;
  final String word;
  final String title;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: GzPressable(
        onPressed: () => showBookingInfoSheet(context, title: title, body: [for (final p in paragraphs) BookingInfoText(p)]),
        semanticLabel: '$word, $title',
        borderRadius: GzRadius.smAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.touchMin),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GzIcon(icon, size: GzIconSize.sm, color: c.textSecondary),
              const SizedBox(width: GzSpace.s2),
              GzText(word, role: GzTextRole.bodyS, color: c.textSecondary),
              const SizedBox(width: GzSpace.s2),
              GzIcon(GzIcons.info, size: GzIconSize.sm, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
