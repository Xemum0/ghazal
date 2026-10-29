/// ProviderNote (CA-SVC-20, ADR 0038, round 2b / OQ-R2-13): the note that tells a service provider where to apply, made impossible to
/// miss. Port of design/src/system/domain-client/ProviderNote.tsx.
///
/// Visible text, not an info glyph: a glyph at the start, the whole sentence ("Service provider? Apply in the Partner app") and a call to
/// action at the end, a short "Apply" label in the accent ink with a chevron (mirrored in Arabic). One full-width row or card, at least
/// 44 dp high (the card 64), and the sentence wraps (two lines on the narrowest phone, more at a large text scale) instead of being cut.
/// The sentence is plain `body` text (not the list's `title` weight) and the gaps are 12, so it keeps two lines beside the action.
/// Two forms of the same note, both at the TOP of their screen (R3: inside the first screen, never under the fold):
/// [GzProviderNoteVariant.banner] is a rose card inside the screen's gutter, right under the Venues | Services switch of the Services hub
/// (CL-SERV-01; [GzProviderNoteVariant.footer] is its earlier name, kept as an alias) and [GzProviderNoteVariant.row] is one row at the top
/// of the Profile hub (CL-PROF-01: the list's own icon row, no hairline under it; with [band] it sits on a full-width rose band). The target
/// is the Partner app's store page, a URL kept in configuration (OQ-R2-04): the widget never knows the address, the app passes [onOpen]
/// and opens it. The whole note is one tap target (at least 44 dp), announced as a link with the sentence as its name; with no [onOpen]
/// it is drawn but inert (a gallery specimen, or the address is not known yet).
library;

import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';

/// `banner`: a rose card (top of the Services hub). `footer`: the earlier name of `banner`, the same card. `row`: a list row (top of the
/// Profile hub).
enum GzProviderNoteVariant { banner, footer, row }

class GzProviderNote extends StatelessWidget {
  const GzProviderNote({this.variant = GzProviderNoteVariant.row, this.onOpen, this.band = false, super.key});

  final GzProviderNoteVariant variant;

  /// `row` only: draw the row on a full-width rose band (surface tint, no corners, the glyph disk on the raised surface so it reads on the
  /// tint), as CL-PROF-01 shows it edge to edge under the identity header. The band is as wide as the parent: give it the full screen width.
  final bool band;

  /// The app opens the Partner app's store page (the address comes from configuration). Null = an inert note.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final text = l.uiClientProviderNoteText;
    // The call to action is accent text (the tertiary label ink, AA on white and on the rose card); the sentence stays the accessible name.
    final cta = GzText(l.uiClientProviderNoteCta, role: GzTextRole.button, color: c.actionTertiaryLabel);
    if (variant == GzProviderNoteVariant.row) {
      final row = GzIconListRow(
        icon: GzIcons.userPlus,
        title: text,
        trailing: ExcludeSemantics(child: cta),
        titleRole: GzTextRole.body,
        gap: GzSpace.s3,
        iconDiskColor: band ? c.surfaceRaised : null,
        chevron: true,
        last: true,
        onPressed: onOpen,
        link: onOpen != null,
      );
      return band ? ColoredBox(color: c.surfaceTint, child: row) : row;
    }
    final card = Container(
      constraints: const BoxConstraints(minHeight: GzSize.rowMin),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3, vertical: GzSpace.s3),
      decoration: BoxDecoration(color: c.surfaceTint, borderRadius: GzRadius.mdAll),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GzIcon(GzIcons.userPlus, size: GzIconSize.md, color: c.iconPrimary),
          const SizedBox(width: GzSpace.s3),
          Expanded(child: GzText(text, role: GzTextRole.body, color: c.textStrong)),
          const SizedBox(width: GzSpace.s3),
          cta,
          const SizedBox(width: GzSpace.s1),
          GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.actionTertiaryLabel),
        ],
      ),
    );
    if (onOpen == null) return Semantics(container: true, label: text, child: ExcludeSemantics(child: card));
    return GzPressable(
      onPressed: onOpen,
      link: true,
      semanticLabel: text,
      borderRadius: GzRadius.mdAll,
      minHeight: GzSize.touchMin,
      child: card,
    );
  }
}
