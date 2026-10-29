// The small pieces every screen of the staff access flow shares (web `design/src/screens/hotel/access/_components`): the heading block,
// the state note, the language chip, the info glyph, the masked email row, the password field and the attempts pips.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show localeProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

/// One drawing at the start edge, then the title; [end] puts one control (the language chip) on the title line.
class AccessHead extends StatelessWidget {
  const AccessHead({required this.title, this.art, this.end, super.key});

  final String title;
  final GzIllustrationName? art;
  final Widget? end;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final heading = GzText(title, role: GzTextRole.uiXl, color: c.textStrong, header: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (art != null)
          Transform.translate(
            offset: Offset(context.gz.isRtl ? 12 : -12, 0),
            child: GzIllustration(art!, size: GzIllustrationSize.lg),
          ),
        if (art != null) const SizedBox(height: GzSpace.s2),
        if (end != null)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.controlLg),
            child: Row(
              children: [
                Expanded(child: heading),
                const SizedBox(width: GzSpace.s3),
                end!,
              ],
            ),
          )
        else
          heading,
      ],
    );
  }
}

enum AccessNoteTone { danger, success, offline }

/// The state line inside a form: a glyph, a title of at most three words, optional facts, the sentence behind an info glyph.
class AccessStateNote extends StatelessWidget {
  const AccessStateNote({required this.tone, required this.text, this.icon, this.facts, this.detail, this.detailTitle, super.key});

  final AccessNoteTone tone;
  final String text;
  final IconData? icon;
  final Widget? facts;
  final String? detail;
  final String? detailTitle;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final bg = switch (tone) {
      AccessNoteTone.danger => c.statusDangerBg,
      AccessNoteTone.success => c.statusSuccessBg,
      AccessNoteTone.offline => c.surfaceQuiet,
    };
    final fg = switch (tone) {
      AccessNoteTone.danger => c.statusDangerText,
      AccessNoteTone.success => c.statusSuccessText,
      AccessNoteTone.offline => c.textPrimary,
    };
    final glyph = switch (tone) {
      AccessNoteTone.danger => c.iconDanger,
      AccessNoteTone.success => c.iconSuccess,
      AccessNoteTone.offline => c.iconSecondary,
    };
    final ic =
        icon ??
        switch (tone) {
          AccessNoteTone.danger => GzIcons.warningCircle,
          AccessNoteTone.success => GzIcons.checkCircle,
          AccessNoteTone.offline => GzIcons.offline,
        };
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: GzSize.controlLg),
        padding: EdgeInsetsDirectional.only(top: GzSpace.s1, bottom: GzSpace.s1, start: GzSpace.s4, end: detail != null ? GzSpace.s2 : GzSpace.s4),
        decoration: BoxDecoration(color: bg, borderRadius: GzRadius.smAll),
        child: Row(
          children: [
            GzIcon(ic, size: GzIconSize.sm, color: glyph),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: GzText(text, role: GzTextRole.bodyS, color: fg),
            ),
            ?facts,
            if (detail != null) GzInfoButton(title: detailTitle ?? text, paragraphs: [detail!]),
          ],
        ),
      ),
    );
  }
}

/// Shows the OTHER language in its own script and flips the whole screen in place.
class AccessLangChip extends ConsumerWidget {
  const AccessLangChip({this.disabled = false, super.key});

  final bool disabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.gz.colors;
    final isAr = context.gz.isAr;
    final name = isAr ? 'English' : 'العربية';
    return GzPressable(
      semanticLabel: '${context.l10n.hotelAccessLanguageSwitch}: $name',
      onPressed: disabled ? null : () => ref.read(localeProvider.notifier).setLocale(Locale(isAr ? 'en' : 'ar')),
      borderRadius: GzRadius.smAll,
      child: Container(
        constraints: const BoxConstraints(minHeight: GzSize.touchMin),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3),
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: GzRadius.smAll,
          border: Border.all(color: c.controlChipBorder, width: GzStroke.hair),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GzIcon(GzIcons.translate, size: GzIconSize.sm, color: disabled ? c.iconDisabled : c.textStrong),
            const SizedBox(width: GzSpace.s2),
            GzText(name, role: GzTextRole.bodyS, color: disabled ? c.textDisabled : c.textStrong),
          ],
        ),
      ),
    );
  }
}

/// The email a code went to: the envelope on a quiet disk and the masked address in an LTR island.
class AccessNumberRow extends StatelessWidget {
  const AccessNumberRow({required this.masked, super.key});

  final String masked;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      container: true,
      label: context.l10n.hotelAccessVerifySentTo(masked),
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.touchMin),
          child: Row(
            children: [
              Container(
                width: GzSize.disk,
                height: GzSize.disk,
                decoration: BoxDecoration(color: c.surfaceTint, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: GzIcon(GzIcons.mail, size: GzIconSize.sm, color: c.iconSecondary),
              ),
              const SizedBox(width: GzSpace.s3),
              GzLtr(child: GzText(masked, role: GzTextRole.title)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Attempts left as quiet pips (filled = still available); the number is the accessible name.
class AccessAttemptPips extends StatelessWidget {
  const AccessAttemptPips({required this.left, required this.total, super.key});

  final int left;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      label: context.l10n.hotelAccessVerifyAttemptsLeft(left),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: GzSpace.s1),
              Container(
                width: GzSize.dotOn,
                height: GzSize.dotOn,
                decoration: BoxDecoration(shape: BoxShape.circle, color: i < left ? c.markState : c.markTrack),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The way in for a new partner (PA-ACC-07), pinned in the bar under Sign in: one short line and a full-width outlined "Apply to join" (web
/// `hxa01__apply`). A real button, never a link inside a sentence.
class ApplyNote extends StatelessWidget {
  const ApplyNote({required this.onApply, super.key});

  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GzText(l.hotelAccessSigninApplyLine, role: GzTextRole.bodyS, color: context.gz.colors.textSecondary, textAlign: TextAlign.center),
          const SizedBox(height: GzSpace.s2),
          GzButton(label: l.hotelAccessSigninApply, variant: GzButtonVariant.secondary, size: GzButtonSize.sm, fullWidth: true, iconStart: GzIcons.userPlus, onPressed: onApply),
        ],
      ),
    );
  }
}
