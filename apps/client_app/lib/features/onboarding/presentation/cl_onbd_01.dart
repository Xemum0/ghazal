// CL-ONBD-01 Language: first-ever screen (CA-ONB-02). Port of design/src/screens/client/onboarding/CL-ONBD-01.tsx.
// Text diet: no title, no hint. The photograph and two language tiles say it; tapping a tile mirrors the whole screen in place (the locale
// provider is the source of truth and persists), Continue goes to the intro, a quiet Sign in link opens the sign-in sheet.
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show localeProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/onboarding_state.dart';
import 'widgets/arch_hero.dart';

const String _photo = 'asset://ghazal_mock_api/images/ballrooms-17-floral-arch-stage-draped-ceiling';
const double _heroHeight = 372;
// Offline adds a banner: a shorter photograph keeps both language tiles above the bar.
const double _heroHeightOffline = 280;
// Arabic first in both languages: the app is Kuwait-first and the order is stable while the layout mirrors.
const List<String> _langs = <String>['ar', 'en'];
// The mark of each script: a typographic specimen, decorative.
const Map<String, String> _marks = <String, String>{'ar': 'ع', 'en': 'Aa'};

class ClOnbd01Screen extends ConsumerWidget {
  const ClOnbd01Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = ref.watch(localeProvider).languageCode;
    final offline = ref.watch(obdOfflineProvider);
    final nav = context.gzNav;

    final names = <String, String>{'ar': l10n.clientOnboardingLanguageNativeAr, 'en': l10n.clientOnboardingLanguageNativeEn};
    final account = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GzButton(
          label: l10n.clientOnboardingLanguageSignIn,
          variant: GzButtonVariant.tertiary,
          iconStart: GzIcons.signIn,
          onPressed: offline ? null : () => nav.push('CL-AUTH-01'),
        ),
        if (offline) Semantics(label: l10n.clientOnboardingLanguageSignInOffline, child: const SizedBox.shrink()),
      ],
    );

    return GzScreen(
      bottom: GzActionBar(
        action: GzActionBarAction(label: l10n.commonActionContinue, onPressed: () => nav.push('CL-ONBD-02')),
        noteWidget: Center(child: account),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(top: MediaQuery.paddingOf(context).top),
            child: SizedBox(
              height: GzSpace.s16,
              child: Center(
                child: GzWordmark(size: GzWordmarkSize.lg, script: lang == 'ar' ? GzWordmarkScript.arabic : GzWordmarkScript.latin, draw: true),
              ),
            ),
          ),
          ObdArchHero(src: _photo, alt: l10n.clientOnboardingAltLanguage, height: offline ? _heroHeightOffline : _heroHeight),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(header: true, label: l10n.clientOnboardingLanguageTitle, child: const SizedBox.shrink()),
                if (offline) ...[
                  GzBanner(message: l10n.commonStateOffline, tone: GzBannerTone.offline, shape: GzBannerShape.card),
                  const SizedBox(height: GzSpace.s4),
                ],
                Semantics(
                  container: true,
                  label: l10n.clientOnboardingLanguageGroup,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < _langs.length; i++) ...[
                        if (i > 0) const SizedBox(width: GzSpace.s3),
                        Expanded(
                          child: _LanguageCard(
                            code: _langs[i],
                            name: names[_langs[i]]!,
                            selected: _langs[i] == lang,
                            onPressed: () {
                              if (_langs[i] != lang) ref.read(localeProvider.notifier).setLocale(Locale(_langs[i]));
                            },
                          ),
                        ),
                      ],
                    ],
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

/// One language tile: the script's mark and the selection ring on one line, the language written in itself under them.
class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.code, required this.name, required this.selected, required this.onPressed});

  final String code;
  final String name;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    // The tile is written in its own language: its text takes that script's faces (the web `lang` attribute).
    return GzTheme(
      locale: Locale(code),
      colors: c,
      child: Builder(
        builder: (context) => Semantics(
          inMutuallyExclusiveGroup: true,
          checked: selected,
          label: name,
          onTap: onPressed,
          excludeSemantics: true,
          child: GzPressable(
            onPressed: onPressed,
            minHeight: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.controlBg,
                borderRadius: GzRadius.mdAll,
                border: Border.all(color: selected ? c.controlChipBorderSelected : c.borderStrong, width: GzStroke.hair),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: GzSpace.s4, end: GzSpace.s4, top: GzSpace.s3, bottom: GzSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GzText(_marks[code]!, role: GzTextRole.d3, color: selected ? c.textStrong : c.textSecondary, excludeSemantics: true),
                        ),
                        const SizedBox(width: GzSpace.s2),
                        _Check(selected: selected),
                      ],
                    ),
                    const SizedBox(height: GzSpace.s1),
                    GzText(name, role: GzTextRole.uiTitle, color: c.textStrong),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selected is an ink check on its own disk: never gold alone, never colour alone.
class _Check extends StatelessWidget {
  const _Check({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.surfaceDark : null,
        border: Border.all(color: selected ? c.surfaceDark : c.borderStrong, width: GzStroke.hair),
      ),
      child: SizedBox(
        width: GzSize.iconMd,
        height: GzSize.iconMd,
        child: selected
            ? Center(
                child: GzIcon(GzIcons.check, size: GzIconSize.xs, color: c.textOnDark),
              )
            : null,
      ),
    );
  }
}
