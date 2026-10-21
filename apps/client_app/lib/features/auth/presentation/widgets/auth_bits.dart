import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/auth_flow.dart';

/// The heading block every pushed auth screen opens with (text diet): one drawing at the start edge, then the serif title, nothing else.
/// [trailing] sits at the title row's end edge (the live monogram of the name step).
class AuthHead extends StatelessWidget {
  const AuthHead({required this.title, this.art, this.trailing, super.key});

  final String title;
  final GzIllustrationName? art;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (art != null) ...[GzIllustration(art!, size: GzIllustrationSize.lg), const SizedBox(height: GzSpace.s2)],
          Row(
            children: [
              Expanded(child: GzText(title, role: GzTextRole.d2, color: context.gz.colors.textStrong, header: true)),
              if (trailing != null) ...[const SizedBox(width: GzSpace.s4), trailing!],
            ],
          ),
        ],
      );
}

/// The padded body of a pushed auth screen (web `.gza-body`): 20 gutter, 8 under the bar, 32 above the bottom bar, [spacing] between blocks.
class AuthBody extends StatelessWidget {
  const AuthBody({required this.children, this.spacing = GzSpace.section, super.key});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: spacing), children[i]],
          ],
        ),
      );
}

/// The number a code was sent to, as a value and not a sentence: the WhatsApp mark on a quiet disk, the figure in an LTR island, and one
/// word at the end edge to change it (web `NumberRow`).
class AuthNumberRow extends StatelessWidget {
  const AuthNumberRow({required this.phone, required this.format, required this.onChange, super.key});

  final String phone;
  final GzFormat format;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l10n = context.l10n;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSize.touchMin),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
            child: SizedBox(width: GzSize.disk, height: GzSize.disk, child: Center(child: GzIcon(GzIcons.whatsapp, size: GzIconSize.sm, color: c.iconSecondary))),
          ),
          const SizedBox(width: GzSpace.s3),
          GzNum(format.phone(phone), role: GzTextRole.figTitle, color: c.textPrimary),
          const Spacer(),
          Semantics(
            label: l10n.clientAuthOtpChangeNumber,
            excludeSemantics: true,
            onTap: onChange,
            button: true,
            child: GzButton(label: l10n.clientAuthOtpChange, variant: GzButtonVariant.tertiary, onPressed: onChange),
          ),
        ],
      ),
    );
  }
}

enum AuthNoteTone { danger, success, info, offline }

/// A state line inside a sheet or a form (web `InlineNote`): a glyph, a title of at most three words, optional facts, the long sentence
/// behind an info glyph and one optional one-word action. Never colour alone: glyph + word + tone.
class AuthInlineNote extends StatelessWidget {
  const AuthInlineNote({required this.tone, required this.message, this.icon, this.facts, this.detail, this.detailTitle, this.actionLabel, this.onAction, super.key});

  final AuthNoteTone tone;
  final String message;
  final IconData? icon;
  final Widget? facts;
  final String? detail;
  final String? detailTitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l10n = context.l10n;
    final (Color bg, Color fg, Color glyph, IconData defaultIcon) = switch (tone) {
      AuthNoteTone.danger => (c.statusDangerBg, c.statusDangerText, c.iconDanger, GzIcons.warningCircle),
      AuthNoteTone.success => (c.statusSuccessBg, c.statusSuccessText, c.iconSuccess, GzIcons.checkCircle),
      AuthNoteTone.info => (c.surfaceQuiet, c.textPrimary, c.iconSecondary, GzIcons.info),
      AuthNoteTone.offline => (c.surfaceQuiet, c.textPrimary, c.iconSecondary, GzIcons.offline),
    };
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: bg, borderRadius: GzRadius.smAll),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.controlLg),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.s4, end: GzSpace.s2, top: GzSpace.s1, bottom: GzSpace.s1),
            child: Row(
              children: [
                GzIcon(icon ?? defaultIcon, size: GzIconSize.sm, color: glyph),
                const SizedBox(width: GzSpace.s3),
                Expanded(child: GzText(message, role: GzTextRole.bodyS, color: fg)),
                if (facts != null) ...[const SizedBox(width: GzSpace.s3), facts!],
                if (detail != null) GzInfoButton(title: detailTitle ?? l10n.commonLabelDetails, paragraphs: [detail!]),
                if (actionLabel != null) GzButton(label: actionLabel!, variant: GzButtonVariant.tertiary, onPressed: onAction),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The two provider buttons, side by side and equal (secondary 48). Apple is shown because the prototype is an iPhone; the native sign-in
/// SDKs are not in the build yet (requests.md).
class AuthProviderButtons extends StatelessWidget {
  const AuthProviderButtons({this.onApple, this.onGoogle, super.key});

  final VoidCallback? onApple;
  final VoidCallback? onGoogle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(child: GzButton(label: l10n.clientAuthSharedApple, variant: GzButtonVariant.secondary, iconStart: GzIcons.apple, fullWidth: true, onPressed: onApple)),
        const SizedBox(width: GzSpace.s3),
        Expanded(child: GzButton(label: l10n.clientAuthSharedGoogle, variant: GzButtonVariant.secondary, iconStart: GzIcons.google, fullWidth: true, onPressed: onGoogle)),
      ],
    );
  }
}

/// The "or" divider.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    Widget rule() => Expanded(child: SizedBox(height: GzStroke.hair, child: ColoredBox(color: c.borderHairline)));
    return Semantics(
      label: context.l10n.commonLabelOr,
      excludeSemantics: true,
      child: Row(children: [rule(), const SizedBox(width: GzSpace.s3), GzText(context.l10n.commonLabelOr, role: GzTextRole.caption, color: c.textSecondary), const SizedBox(width: GzSpace.s3), rule()]),
    );
  }
}

/// Attempts left as five quiet pips (filled = still available), after a wrong code. The number is the accessible name.
class AuthAttemptPips extends StatelessWidget {
  const AuthAttemptPips({required this.left, super.key});

  final int left;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      label: context.l10n.clientAuthOtpAttemptsLeft(left),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < AuthConfig.maxAttempts; i++) ...[
            if (i > 0) const SizedBox(width: GzSpace.s2),
            DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: i < left ? c.iconPrimary : c.markTrack),
              child: const SizedBox(width: GzSize.dotOff, height: GzSize.dotOff),
            ),
          ],
        ],
      ),
    );
  }
}

/// Hands a 44 target's slack back to the 20 gutter: the glyph meets the gutter edge (web `inset-inline-end: -10px`).
class AuthEndShift extends StatelessWidget {
  const AuthEndShift({required this.child, this.toStart = false, super.key});

  final Widget child;

  /// Shift toward the start edge instead of the end edge.
  final bool toStart;

  static const double _slack = (GzSize.touchMin - GzSize.iconMd) / 2;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final dx = (toStart ? -_slack : _slack) * (rtl ? -1 : 1);
    return Transform.translate(offset: Offset(dx, 0), child: child);
  }
}
