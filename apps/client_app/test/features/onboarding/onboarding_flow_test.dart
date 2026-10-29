// The first run through the real router and the in-process mock (ADR 0038): language, intro, sign-in, About you, then the three optional
// steps (who, date, guests and budget) and Home with the Brief filled; skip paths; the sign-in link; one Arabic run.
import 'package:client_app/app/state/state.dart';
import 'package:client_app/features/onboarding/application/onboarding_profile.dart' show obdDraftProvider;
import 'package:client_app/features/onboarding/application/onboarding_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show localeProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show DateMode, WeddingRole;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../support/flow_world.dart';

void main() {
  String top(WidgetTester t) => nav(t).currentId;

  flowTest('language: a tile mirrors the screen in place and the choice is the locale; Continue goes on', (t) async {
    await openScreen(t, 'CL-ONBD-01', locale: const Locale('ar'));
    expect(top(t), 'CL-ONBD-01');
    expect(Directionality.of(t.element(find.byType(GzScreen).first)), TextDirection.rtl);
    await tapText(t, en.clientOnboardingLanguageNativeEn, ms: 600);
    expect(container(t).read(localeProvider).languageCode, 'en');
    expect(Directionality.of(t.element(find.byType(GzScreen).first)), TextDirection.ltr);
    await tapText(t, en.commonActionContinue);
    expect(top(t), 'CL-ONBD-02');
  });

  flowTest('the whole first run: language, intro, sign-in, About you, the three optional steps, then Home with the Brief filled', (t) async {
    await openScreen(t, 'CL-ONBD-01');
    await tapText(t, en.commonActionContinue);
    // three slides: Next, Next, Get started (which goes to the sign-in, never to Home)
    expect(find.text(en.clientOnboardingIntroSlide1Title), findsOneWidget);
    await tapText(t, en.commonActionNext, ms: 600);
    expect(find.text(en.clientOnboardingIntroSlide2Title), findsWidgets);
    await tapText(t, en.commonActionNext, ms: 600);
    await tapText(t, en.clientOnboardingIntroStart);
    expect(top(t), 'CL-AUTH-01');

    // a new number: the code, then About you
    await t.enterText(find.byType(EditableText).first, '50001234');
    await t.pump();
    await tapText(t, en.clientAuthSharedSendCode, ms: 1500);
    expect(top(t), 'CL-AUTH-02');
    await t.enterText(find.byType(EditableText).first, '123456');
    await settle(t, wait: const Duration(milliseconds: 2500));
    expect(top(t), 'CL-AUTH-03');
    await t.enterText(find.byType(EditableText).first, 'Nora Al-Salem');
    await tapText(t, en.clientAuthNameSexFemale, ms: 300);
    await tapText(t, en.clientAuthNameAccept, ms: 300);
    await tapText(t, en.commonActionContinue, ms: 600);
    await settle(t, wait: const Duration(milliseconds: 2500));
    expect(top(t), 'CL-ONBD-03');

    // who is planning: the name comes from the account and the role is suggested from the sex (a chip the person can change)
    final c = container(t);
    expect(find.text('Nora Al-Salem'), findsWidgets, reason: 'the name is prefilled from the account');
    await t.enterText(find.byType(EditableText).at(1), 'Fahad Al-Shammari');
    await t.pump();
    await tapText(t, en.commonActionContinue);
    expect(top(t), 'CL-ONBD-04');
    expect(c.read(obdDraftProvider).role, WeddingRole.bride, reason: 'female suggests the bride');
    expect(c.read(obdDraftProvider).brideName, 'Nora Al-Salem');
    expect(c.read(obdDraftProvider).partnerName, 'Fahad Al-Shammari');

    // the date: a day of the visible month
    final sem = t.ensureSemantics();
    await tapDay(t, '25 November 2026');
    sem.dispose();
    await tapText(t, en.commonActionContinue);
    expect(top(t), 'CL-ONBD-05');
    expect(c.read(obdDraftProvider).dateMode, DateMode.exact);
    expect(c.read(obdDraftProvider).weddingDate?.day, 25);

    // guests and budget, the last step: a preset moves the count, Done writes the profile and opens Home
    ignoreRenderErrors = true; // Home belongs to the discover flow
    await tapText(t, '500', ms: 300);
    await tapText(t, en.commonActionDone);
    await settle(t, wait: const Duration(milliseconds: 1500));
    expect(top(t), 'CL-DISC-01');
    final brief = c.read(searchBriefProvider);
    expect(brief.guests, 500);
    expect(brief.date?.day, 25);
    expect(brief.audience?.value, 'women');
    expect(brief.governorateIds, isEmpty, reason: 'no region is asked at onboarding: the Brief sheet on Home asks for governorates');
    final profile = await t.runAsync(() => c.read(weddingRepositoryProvider).getWeddingProfile());
    expect(profile!.guests.women, 500);
    expect(profile.brideName, 'Nora Al-Salem');
  });

  flowTest('the intro: Skip goes to the sign-in screen, never to Home', (t) async {
    await openScreen(t, 'CL-ONBD-02');
    await tapText(t, en.commonActionSkip);
    expect(top(t), 'CL-AUTH-01');
    expect(container(t).read(sessionProvider).isSignedIn, isFalse);
  });

  flowTest('skip on a step goes on without writing; back returns', (t) async {
    await openScreen(t, 'CL-ONBD-04', persona: 'new_client');
    await tapText(t, en.commonActionSkip);
    expect(top(t), 'CL-ONBD-05');
    expect(container(t).read(obdDraftProvider.notifier).isEmpty, isTrue);
    await t.tap(find.byKey(const ValueKey<String>('gz:bar.back')).first, warnIfMissed: false);
    await settle(t, wait: const Duration(milliseconds: 800));
    expect(top(t), 'CL-ONBD-04');
  });

  flowTest('skipping the last step writes nothing and opens Home with an empty Brief', (t) async {
    await openScreen(t, 'CL-ONBD-05', persona: 'new_client');
    ignoreRenderErrors = true; // Home belongs to the discover flow
    await tapText(t, en.commonActionSkip);
    await settle(t, wait: const Duration(milliseconds: 1500));
    expect(top(t), 'CL-DISC-01');
    expect(container(t).read(searchBriefProvider).isEmpty, isTrue);
  });

  flowTest('the sign-in link opens the sign-in screen and Back returns to the language', (t) async {
    await openScreen(t, 'CL-ONBD-01');
    await tapText(t, en.clientOnboardingLanguageSignIn);
    expect(top(t), 'CL-AUTH-01');
    nav(t).pop();
    await settle(t, wait: const Duration(milliseconds: 800));
    expect(top(t), 'CL-ONBD-01');
  });

  flowTest('date step: undecided replaces the grid, flexible opens the month sheet', (t) async {
    await openScreen(t, 'CL-ONBD-04', persona: 'new_client');
    expect(find.byType(GzCalendar), findsOneWidget);
    await tapText(t, en.clientOnboardingDateNotDecided, ms: 500);
    expect(find.byType(GzCalendar), findsNothing);
    await tapText(t, en.clientOnboardingDatePickDate, ms: 500);
    expect(find.byType(GzCalendar), findsOneWidget);
    await tapText(t, en.clientOnboardingDateFlexible, ms: 800);
    expect(find.text(en.clientOnboardingDateFlexibleTitle), findsOneWidget);
    await tapText(t, en.commonActionDone, ms: 800);
    await tapText(t, en.commonActionContinue);
    expect(container(t).read(obdDraftProvider).dateMode, DateMode.flexibleMonth);
  });

  flowTest('guests step: Later puts a half off, Add brings it back; the split shows two steppers', (t) async {
    await openScreen(t, 'CL-ONBD-05', persona: 'new_client');
    expect(find.textContaining('350', findRichText: true), findsWidgets);
    await tapText(t, en.clientOnboardingSkipHalf, ms: 400);
    expect(find.text(en.commonActionAdd), findsOneWidget);
    await tapText(t, en.commonActionAdd, ms: 400);
    expect(find.text(en.commonActionAdd), findsNothing);
    await t.tap(find.byType(GzSwitch), warnIfMissed: false);
    await settle(t, wait: const Duration(milliseconds: 400));
    expect(find.byType(GzStepper), findsNWidgets(2));
  });

  flowTest('language step offline: the sign-in link is disabled and the screen still works', (t) async {
    await openScreen(t, 'CL-ONBD-01', overrides: [obdOfflineProvider.overrideWithValue(true)]);
    expect(find.text(en.commonStateOffline), findsOneWidget);
    await tapText(t, en.clientOnboardingLanguageSignIn, ms: 400);
    expect(top(t), 'CL-ONBD-01');
    await tapText(t, en.commonActionContinue);
    expect(top(t), 'CL-ONBD-02');
  });

  flowTest('Arabic run: the intro mirrors and its words are Arabic', (t) async {
    await openScreen(t, 'CL-ONBD-02', locale: const Locale('ar'));
    expect(find.text(ar.clientOnboardingIntroSlide1Title), findsOneWidget);
    expect(Directionality.of(t.element(find.byType(GzScreen).first)), TextDirection.rtl);
    await tapText(t, ar.commonActionNext, ms: 600);
    expect(find.text(ar.clientOnboardingIntroSlide2Title), findsWidgets);
  });
}
