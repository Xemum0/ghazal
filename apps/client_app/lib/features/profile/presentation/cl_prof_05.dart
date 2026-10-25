// CL-PROF-05 Settings. Port of CL-PROF-05.tsx. Requirements: CA-PROF-07 .. 11, CA-AUTH-08, CA-PROF-09.
// App preferences in three short lists of glyph rows, text-diet edition (ADR 0034). App: language (a two-option sheet), digits (the row
// exists only while the interface is Arabic, never inferred from the device; its value is the sample figures), biometric unlock (labelled
// by the platform) and notifications. Privacy: location, usage data (on by default, what it is behind the info glyph) and the two legal
// pages. Account: sign out (asks first) and, apart and in danger tone, delete account (CL-PROF-06). The app version closes the page.
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show ClientSession, sessionProvider;
import 'package:ghazal_core/ghazal_core.dart' show digitStyleProvider, localeProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/profile_state.dart';
import 'widgets/profile_parts.dart';
import 'widgets/profile_sheets.dart';

class ClProf05Screen extends ConsumerWidget {
  const ClProf05Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final nav = context.gzNav;
    final code = ref.watch(localeProvider).languageCode;
    final arabic = code == 'ar';
    final guest = ref.watch(sessionProvider) is! ClientSession;
    final digits = ref.watch(digitStyleProvider);
    final settings = ref.watch(deviceSettingsProvider);
    final denied = settings.osNotificationsDenied;
    void openSettings() => nav.toast(GzToastSpec(message: l.clientProfileSharedOpeningSettings, icon: GzIcons.externalLink));
    final bio = l.clientProfileSetBiometric(kBiometricMethod);

    return GzScreen(
      top: GzTopBar(title: l.commonLabelSettings),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GzIconListRow(
              icon: GzIcons.translate,
              title: l.commonLabelLanguage,
              trailing: Directionality(textDirection: arabic ? TextDirection.rtl : TextDirection.ltr, child: Text(profileNativeName(context, code), locale: Locale(code))),
              chevron: true,
              onPressed: () => nav.openLanguageSheet(context),
            ),
            if (arabic)
              GzIconListRow(
                icon: GzIcons.sliders,
                title: l.clientProfileDigitsTitle,
                trailing: Directionality(textDirection: TextDirection.ltr, child: GzText(kDigitSamples[digits]!, role: GzTextRole.figBody, color: c.textSecondary)),
                chevron: true,
                onPressed: () => nav.openDigitsSheet(context),
              ),
            if (!guest)
              ProfSwitchRow(
                icon: kBiometricMethod == 'face' ? GzIcons.faceId : GzIcons.fingerprint,
                title: bio,
                checked: settings.biometricOn,
                onChanged: (on) {
                  ref.read(deviceSettingsProvider.notifier).setBiometric(on);
                  if (!on) nav.toast(GzToastSpec(message: l.clientProfileSetBiometricOff));
                },
              ),
            GzIconListRow(
              icon: GzIcons.bell,
              title: l.clientProfileNotifTitle,
              trailing: Text(denied ? l.clientProfileSharedOff : l.clientProfileSharedOn),
              chevron: true,
              last: true,
              onPressed: () => nav.push('CL-PROF-04'),
            ),
            const SizedBox(height: GzSpace.s6),
            GzIconListRow(icon: GzIcons.pin, title: l.clientProfileSetLocation, trailing: Text(l.clientProfileSetLocationValue), chevron: true, onPressed: openSettings),
            ProfSwitchRow(
              icon: GzIcons.chartBar,
              title: l.clientProfileSetUsage,
              checked: settings.shareUsage,
              onChanged: ref.read(deviceSettingsProvider.notifier).setShareUsage,
              info: GzInfoButton(title: l.clientProfileSetUsage, paragraphs: [l.clientProfileSetUsageDetail]),
            ),
            GzIconListRow(icon: GzIcons.document, title: l.clientProfileSharedTerms, chevron: true, onPressed: () => nav.openLegalSheet(context, LegalKind.terms)),
            GzIconListRow(icon: GzIcons.shieldCheck, title: l.clientProfileSharedPrivacy, chevron: true, last: true, onPressed: () => nav.openLegalSheet(context, LegalKind.privacy)),
            if (!guest) ...[
              const SizedBox(height: GzSpace.s6),
              GzIconListRow(icon: GzIcons.signOut, title: l.clientProfileSharedSignOut, onPressed: () => confirmProfileSignOut(context, ref), chevron: false),
              GzIconListRow(icon: GzIcons.trash, tone: GzListRowTone.danger, title: l.clientProfileDelTitle, chevron: true, last: true, onPressed: () => nav.push('CL-PROF-06')),
            ],
            const SizedBox(height: GzSpace.s6),
            GzText(l.clientProfileSharedVersion(kProfileAppVersion), role: GzTextRole.figCaption, color: c.textSecondary, textAlign: TextAlign.center, figures: true),
          ],
        ),
      ),
    );
  }
}
