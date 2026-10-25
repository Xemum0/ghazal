// The sheets two screens share (the Profile hub and Settings): the language choice, the digits choice (Arabic UI only), the in-app legal
// reader and the sign-out confirmation. Text diet (ADR 0034): a title, the choices, Done; no note under any of them. Port of the web
// `_components/sheets.tsx`.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show sessionProvider;
import 'package:ghazal_core/ghazal_core.dart' show DigitStyle, digitStyleProvider, localeProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import 'profile_parts.dart';

/// "العربية" and "English", each in its own script (never translated).
String profileNativeName(BuildContext context, String languageCode) => languageCode == 'ar' ? context.l10n.clientOnboardingLanguageNativeAr : context.l10n.clientOnboardingLanguageNativeEn;

Widget _done(BuildContext context) => GzSheetFooter(child: GzButton(label: context.l10n.commonActionDone, fullWidth: true, onPressed: context.gzNav.closeSheet));

/// Two options, each in its own script. Choosing applies at once: the app mirrors in place and this sheet stays open (ADR 0014 D1).
class ProfileLanguageSheet extends ConsumerWidget {
  const ProfileLanguageSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(localeProvider).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfChoiceList<String>(
          label: context.l10n.commonLabelLanguage,
          value: code,
          onChanged: (v) => ref.read(localeProvider.notifier).setLocale(Locale(v)),
          options: [
            for (final lang in const <String>['ar', 'en'])
              ProfChoice<String>(
                value: lang,
                semantic: profileNativeName(context, lang),
                title: Directionality(textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr, child: Text(profileNativeName(context, lang), locale: Locale(lang))),
              ),
          ],
        ),
        _done(context),
      ],
    );
  }
}

/// The two sets, shown together once as the person chooses (Western is the default, never inferred from the device, ADR 0010 D2).
const Map<DigitStyle, String> kDigitSamples = <DigitStyle, String>{
  DigitStyle.western: '0 1 2 3',
  DigitStyle.easternArabic: '٠‎ ‎١‎ ‎٢‎ ‎٣',
};

class ProfileDigitsSheet extends ConsumerWidget {
  const ProfileDigitsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(digitStyleProvider);
    Widget sample(DigitStyle s) => Directionality(textDirection: TextDirection.ltr, child: GzText(kDigitSamples[s]!, role: GzTextRole.figTitle));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfChoiceList<DigitStyle>(
          label: context.l10n.clientProfileDigitsTitle,
          value: style,
          onChanged: ref.read(digitStyleProvider.notifier).setStyle,
          options: [for (final s in DigitStyle.values) ProfChoice<DigitStyle>(value: s, semantic: kDigitSamples[s]!, title: sample(s))],
        ),
        _done(context),
      ],
    );
  }
}

enum LegalKind { terms, privacy }

/// The in-app reader (CA-PROF-11, CA-AUTH-11): the section headings of the Terms of Use and the Privacy Policy as icon rows, one switch
/// between the two pages. The owner's full text is served by the Super Admin CMS (`getLegalDocument`).
class ProfileLegalSheet extends StatefulWidget {
  const ProfileLegalSheet({this.kind = LegalKind.terms, super.key});

  final LegalKind kind;

  @override
  State<ProfileLegalSheet> createState() => _ProfileLegalSheetState();
}

class _ProfileLegalSheetState extends State<ProfileLegalSheet> {
  late LegalKind _kind = widget.kind;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final sections = _kind == LegalKind.terms
        ? <(IconData, String)>[
            (GzIcons.document, l.clientAuthSharedTermsSection1),
            (GzIcons.ticket, l.clientAuthSharedTermsSection2),
            (GzIcons.receipt, l.clientAuthSharedTermsSection3),
            (GzIcons.shieldCheck, l.clientAuthSharedTermsSection4),
          ]
        : <(IconData, String)>[
            (GzIcons.clipboard, l.clientAuthSharedPrivacySection1),
            (GzIcons.sliders, l.clientAuthSharedPrivacySection2),
            (GzIcons.eye, l.clientAuthSharedPrivacySection3),
            (GzIcons.settings, l.clientAuthSharedPrivacySection4),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSegmentedControl<LegalKind>(
          label: l.clientProfileLegalTitle,
          value: _kind,
          onChanged: (v) => setState(() => _kind = v),
          options: [
            GzSegmentedOption<LegalKind>(value: LegalKind.terms, label: l.clientProfileSharedTerms),
            GzSegmentedOption<LegalKind>(value: LegalKind.privacy, label: l.clientProfileSharedPrivacy),
          ],
        ),
        const SizedBox(height: GzSpace.s4),
        Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
          child: Column(
            children: [
              for (var i = 0; i < sections.length; i++) GzIconListRow(flush: true, icon: sections[i].$1, title: sections[i].$2, last: i == sections.length - 1),
            ],
          ),
        ),
        _done(context),
      ],
    );
  }
}

/// Opens the sheets from a row.
extension ProfileSheets on GzNavigator {
  void openLanguageSheet(BuildContext context) => openSheetBuilder((_) => const ProfileLanguageSheet(), options: GzSheetOptions(title: context.l10n.commonLabelLanguage));

  void openDigitsSheet(BuildContext context) => openSheetBuilder((_) => const ProfileDigitsSheet(), options: GzSheetOptions(title: context.l10n.clientProfileDigitsTitle));

  void openLegalSheet(BuildContext context, LegalKind kind) => openSheetBuilder((_) => ProfileLegalSheet(kind: kind), options: GzSheetOptions(title: context.l10n.clientProfileLegalTitle));
}

/// Sign out asks first, then clears the session and returns to the language-aware Home as a guest (CA-PROF-10).
Future<void> confirmProfileSignOut(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final nav = context.gzNav;
  final answer = await nav.openDialog(
    GzDialogSpec(
      title: l.clientProfileSharedSignOutTitle,
      icon: GzIcons.signOut,
      confirmLabel: l.clientProfileSharedSignOut,
      cancelLabel: l.clientProfileSharedSignOutStay,
      tone: GzDialogTone.destructive,
    ),
  );
  if (answer != GzDialogResult.confirm) return;
  await ref.read(sessionProvider.notifier).signOut();
  nav.reset('CL-DISC-01');
  nav.toast(GzToastSpec(message: l.clientProfileSharedSignedOut));
}
