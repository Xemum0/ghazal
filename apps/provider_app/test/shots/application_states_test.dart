// Parity shots of the states `pnpm fshot` cannot reach (a typed form, an open sheet, a request in flight): HL-PROV-01 in all its web frame states,
// HL-ACCS-04 application-review / -rejected / -approved and HL-PROV-03 awaiting-approval. Each test drives the REAL app to the state with real
// taps and shoots it with the shot harness' own writer, at 390 x 844 and DPR 2, so `tools/parity/parity.mjs` can score it against the web frame
// `design/.shots/ref/<id>.<state>.<lang>.png` (`pnpm parity:ref -- --only HL-PROV-01 --states`).
//
//   cd apps/provider_app && node ../../tools/with-slot.mjs flutter-test -- flutter test test/shots/application_states_test.dart --dart-define=SHOT_STATES=true
//   node tools/parity/parity.mjs --app hotel --screen HL-PROV-01.filled --lang ar        (the id carries the state)
//
// Without the define the file is a no-op, so the partner suite stays lean. The data of the frames are the web's fixtures (Zahra Floral Studio,
// Taima Grand Palace): typed in, because the app owes them nothing.
import 'package:flutter/widgets.dart' show EditableText, FocusManager, Locale, Scrollable, ScrollableState;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_testing/ghazal_testing.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show OtpChannel, OtpChallenge, ServiceCategoryId;
import 'package:provider_app/app/state/state.dart' show applicationChallengeProvider, partnerDataRevisionProvider;
import 'package:provider_app/features/provider/application/application_form.dart' show ApplicationForm;
import 'package:provider_app/l10n/generated/app_localizations.dart' show AppL10n;

import '../support/flow_world.dart';

const bool _on = bool.fromEnvironment('SHOT_STATES');
const String _only = String.fromEnvironment('SHOT_STATE_ONLY'); // a comma list of "<id>.<state>" to shoot, empty = all

class _Biz {
  const _Biz({required this.nameEn, required this.nameAr, required this.gov, required this.email, required this.about, required this.cat});
  final String nameEn;
  final String nameAr;
  final Map<String, String> gov;
  final String email;
  final Map<String, String> about;
  final Map<String, String> cat;
}

const _zahra = _Biz(
  nameEn: 'Zahra Floral Studio',
  nameAr: 'استوديو زهرة للزهور',
  gov: {'en': 'Hawalli', 'ar': 'حولي'},
  email: 'zahra@zahra-floral.example',
  about: {
    'en': 'A Hawalli floral studio for kosha, entrance and table florals, designed to the hall and the colours of the family.',
    'ar': 'استوديو زهور في حولي لزهور الكوشة والمدخل والطاولات، بتصميم يناسب القاعة وألوان العائلة.',
  },
  cat: {'en': 'Floral arrangements', 'ar': 'تنسيق الزهور'},
);

const _taima = _Biz(
  nameEn: 'Taima Grand Palace',
  nameAr: 'قصر تيماء الكبير',
  gov: {'en': 'Jahra', 'ar': 'الجهراء'},
  email: 'office@taima-hall.example',
  about: {'en': 'A grand hall for large Jahra weddings', 'ar': 'قاعة كبرى لأفراح الجهراء الكبيرة'},
  cat: {},
);

const _contact = {'en': 'Zahra Al-Mutairi', 'ar': 'زهرة المطيري'};

Future<void> _type(WidgetTester tester, int field, String text) async {
  await tester.enterText(find.byType(EditableText).at(field), text);
  await tester.pump(const Duration(milliseconds: 100));
}

/// Opens the form of [kind] (a provider or a hall) from the chooser.
Future<void> _toForm(WidgetTester tester, AppL10n l, {required bool hall}) async {
  await tap(tester, find.text(hall ? l.hotelProviderTypeHallTitle : l.hotelProviderTypeProviderTitle));
  await tap(tester, find.text(l.hotelProviderContinue));
}

/// Types the fields of [b]; a provider also picks the category through the sheet. Order of the text fields: the two names (the UI language
/// first), [Other note], contact, phone, email, description, licence.
Future<void> _fill(WidgetTester tester, AppL10n l, String lang, _Biz b, {required bool hall, bool pickCategory = true, bool signedOut = false}) async {
  final first = lang == 'ar' ? b.nameAr : b.nameEn;
  final second = lang == 'ar' ? b.nameEn : b.nameAr;
  final base = signedOut ? 3 : 0; // the signed-out form starts with the account: email, password, repeat
  await _type(tester, base, first);
  await _type(tester, base + 1, second);
  var i = base + 2;
  if (!hall) {
    if (pickCategory) {
      await tap(tester, find.text(l.hotelProviderCatsChoose));
      await tapText(tester, b.cat[lang]!);
      await tap(tester, find.text(l.commonActionDone));
    }
    i++; // the Other note stays empty
  }
  await tapText(tester, b.gov[lang]!);
  await _type(tester, i++, _contact[lang]!);
  await _type(tester, i++, '50000047');
  if (!signedOut) await _type(tester, i++, b.email); // signed out, the account email is the contact email
  await _type(tester, i, b.about[lang]!);
}

Future<void> _shoot(WidgetTester tester, String id, String state, String lang) async {
  // typing scrolled the field into view and left it focused: the web frame is at the top and nothing has focus
  FocusManager.instance.primaryFocus?.unfocus();
  final scrollables = find.byType(Scrollable);
  if (scrollables.evaluate().isNotEmpty) tester.state<ScrollableState>(scrollables.first).position.jumpTo(0);
  await settle(tester, wait: const Duration(milliseconds: 600));
  final file = await GzHarness.shoot(tester, 'build/shots/$id.$state.$lang.390.png');
  // ignore: avoid_print
  print('SHOT ${file.path}');
}

void _shot(String id, String state, String lang, Future<void> Function(WidgetTester tester, AppL10n l) body) {
  final key = '$id.$state';
  if (_only.isNotEmpty && !_only.split(',').contains(key)) return;
  flowTest('shot $key $lang', (tester) async {
    await body(tester, lang == 'ar' ? ar : en);
  });
}

void main() {
  if (!_on) {
    test('application state shots: pass --dart-define=SHOT_STATES=true to shoot', () {});
    return;
  }
  for (final lang in ['ar', 'en']) {
    final locale = Locale(lang);
    const id = 'HL-PROV-01';

    _shot(id, 'empty', lang, (tester, l) async {
      await openScreen(tester, id, persona: 'provider', locale: locale);
      await _toForm(tester, l, hall: false);
      await _shoot(tester, id, 'empty', lang);
    });
    _shot(id, 'hall', lang, (tester, l) async {
      await openScreen(tester, id, persona: 'provider', locale: locale);
      await _toForm(tester, l, hall: true);
      await _fill(tester, l, lang, _taima, hall: true);
      await _shoot(tester, id, 'hall', lang);
    });
    _shot(id, 'filled', lang, (tester, l) async {
      await openScreen(tester, id, persona: 'provider', locale: locale);
      await _toForm(tester, l, hall: false);
      await _fill(tester, l, lang, _zahra, hall: false);
      await _shoot(tester, id, 'filled', lang);
    });
    _shot(id, 'categories', lang, (tester, l) async {
      await openScreen(tester, id, persona: 'provider', locale: locale);
      await _toForm(tester, l, hall: false);
      await tap(tester, find.text(l.hotelProviderCatsChoose));
      await tapText(tester, _zahra.cat[lang]!);
      await _shoot(tester, id, 'categories', lang);
    });
    _shot(id, 'validation', lang, (tester, l) async {
      await openScreen(tester, id, persona: 'provider', locale: locale);
      await _toForm(tester, l, hall: false);
      await tap(tester, find.text(l.hotelProviderSubmit));
      await _shoot(tester, id, 'validation', lang);
    });
    _shot(id, 'submitting', lang, (tester, l) async {
      await openScreen(tester, id, persona: 'provider', locale: locale);
      await _toForm(tester, l, hall: false);
      await _fill(tester, l, lang, _zahra, hall: false);
      flowControl.setLatency(const Duration(seconds: 30));
      await tester.tap(find.text(l.hotelProviderSubmit));
      await tester.pump(const Duration(milliseconds: 300));
      await _shoot(tester, id, 'submitting', lang);
      flowControl.setLatency(Duration.zero);
      await tester.pump(const Duration(seconds: 31));
    });
    _shot(id, 'submitted', lang, (tester, l) async {
      await openScreen(tester, id, persona: 'provider', locale: locale);
      await _toForm(tester, l, hall: false);
      await _fill(tester, l, lang, _zahra, hall: false);
      await tap(tester, find.text(l.hotelProviderSubmit));
      await _shoot(tester, id, 'submitted', lang);
    });
    _shot(id, 'resubmit', lang, (tester, l) async {
      // the web frame: Zahra's application, refused for the demo reason, opened from More (the tab bar shows). The seeded rejected applicant
      // gets Zahra's data through the API and the staff refuse it again with the demo words, so the frame compares like with like.
      final c = await openScreen(tester, id, persona: 'provider_rejected', locale: locale, params: {'resubmit': true}, base: 'HL-SETT-01');
      final repos = flowRepos('provider_rejected');
      final me = await tester.runAsync(() => repos.partnerAccount.getPartnerMe());
      final app = me!.memberships.firstWhere((m) => m.application != null).application!;
      final form = ApplicationForm(
        nameAr: _zahra.nameAr,
        nameEn: _zahra.nameEn,
        cats: const [ServiceCategoryId.flowers],
        gov: 'hawalli',
        contact: _contact[lang]!,
        phone: '50000047',
        email: _zahra.email,
        about: _zahra.about[lang]!,
      );
      await tester.runAsync(() => repos.partnerAccount.resubmitPartnerApplication(body: form.toResubmitInput()));
      flowControl.decidePartnerApplication(app.id, accept: false, reason: lang == 'ar' ? 'أضيفوا رقم الترخيص ووصفًا أوضح للنشاط.' : 'Add your licence number and a clearer description.');
      c.read(partnerDataRevisionProvider.notifier).bump();
      await settle(tester, wait: const Duration(seconds: 2));
      await _shoot(tester, id, 'resubmit', lang);
    });
    _shot(id, 'error', lang, (tester, l) async {
      await openScreen(tester, id, persona: 'provider', locale: locale);
      await _toForm(tester, l, hall: false);
      await _fill(tester, l, lang, _zahra, hall: false);
      flowControl.setScenario('error');
      await tap(tester, find.text(l.hotelProviderSubmit));
      await _shoot(tester, id, 'error', lang);
    });
    _shot(id, 'offline', lang, (tester, l) async {
      await openScreen(tester, id, persona: 'provider', locale: locale);
      await _toForm(tester, l, hall: false);
      await _fill(tester, l, lang, _zahra, hall: false);
      flowControl.setScenario('offline');
      await tap(tester, find.text(l.hotelProviderSubmit));
      await _shoot(tester, id, 'offline', lang);
    });

    // Round 2b: the signed-out entry (HL-ACCS-01 "Apply to join" -> HL-PROV-01 signed out -> HL-ACCS-02 mode application), all from the real sign-in screen
    Future<void> toSignedOutForm(WidgetTester tester, AppL10n l) async {
      await openScreen(tester, 'HL-ACCS-01', locale: locale);
      await tap(tester, find.text(l.hotelAccessSigninApply));
      await _toForm(tester, l, hall: false);
    }
    _shot(id, 'signed-out', lang, (tester, l) async {
      await toSignedOutForm(tester, l);
      await _shoot(tester, id, 'signed-out', lang);
    });
    _shot(id, 'account-errors', lang, (tester, l) async {
      await toSignedOutForm(tester, l);
      await _fill(tester, l, lang, _zahra, hall: false, signedOut: true);
      // the server knows this email (Zahra's): the first send says so; then a weak password and a repeat that differs, tried again
      await _type(tester, 0, _zahra.email);
      await _type(tester, 1, 'Ghazal#2026x');
      await _type(tester, 2, 'Ghazal#2026x');
      await tap(tester, find.text(l.hotelProviderSubmit));
      await _type(tester, 1, '123456');
      await _type(tester, 2, '123457');
      await tap(tester, find.text(l.hotelProviderSubmit));
      await _shoot(tester, id, 'account-errors', lang);
    });
    _shot('HL-ACCS-02', 'application', lang, (tester, l) async {
      final c = await openScreen(tester, 'HL-ACCS-02', persona: 'guest', locale: locale, params: {'mode': 'application'}, base: 'HL-ACCS-01');
      c.read(applicationChallengeProvider.notifier).open(
        _zahra.email,
        const OtpChallenge(challengeId: 'shot', channel: OtpChannel.email, destinationHint: 'z***@zahra-floral.example', expiresInSeconds: 300, resendAfterSeconds: 60, codeLength: 6),
      );
      await settle(tester, wait: const Duration(milliseconds: 400));
      await _shoot(tester, 'HL-ACCS-02', 'application', lang);
    });

    // HL-ACCS-04, the three application variants (the signed-in applicant, her account status)
    _shot('HL-ACCS-04', 'application-review', lang, (tester, l) async {
      await openScreen(tester, 'HL-ACCS-04', persona: 'provider_applicant', locale: locale, params: {'variant': 'application-review', 'account': 'provider'});
      await _shoot(tester, 'HL-ACCS-04', 'application-review', lang);
    });
    _shot('HL-ACCS-04', 'application-rejected', lang, (tester, l) async {
      await openScreen(tester, 'HL-ACCS-04', persona: 'provider_rejected', locale: locale, params: {'variant': 'application-rejected', 'account': 'provider'});
      await _shoot(tester, 'HL-ACCS-04', 'application-rejected', lang);
    });
    _shot('HL-ACCS-04', 'application-approved', lang, (tester, l) async {
      final c = await openScreen(tester, 'HL-ACCS-04', persona: 'provider_applicant', locale: locale, params: {'variant': 'application-review', 'account': 'provider'});
      final me = await tester.runAsync(() => flowRepos('provider_applicant').partnerAccount.getPartnerMe());
      flowControl.decidePartnerApplication(me!.memberships.firstWhere((m) => m.application != null).application!.id, accept: true);
      c.read(partnerDataRevisionProvider.notifier).bump();
      await settle(tester);
      await _shoot(tester, 'HL-ACCS-04', 'application-approved', lang);
    });
    // HL-PROV-03: the editor held back for an account the staff have not accepted yet
    _shot('HL-PROV-03', 'awaiting-approval', lang, (tester, l) async {
      await openScreen(tester, 'HL-PROV-03', persona: 'provider_applicant', locale: locale);
      await _shoot(tester, 'HL-PROV-03', 'awaiting-approval', lang);
    });
  }
}
