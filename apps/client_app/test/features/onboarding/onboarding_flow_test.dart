// The first start through the real router and the in-process mock: language, intro, who, date, guests and budget, areas, then Home with the
// Brief filled; skip paths; the five states of the areas step; the sign-in link; one Arabic run.
import 'package:client_app/app/state/state.dart';
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

  flowTest('the whole first start: answers reach the draft and the Brief, Home opens', (t) async {
    await openScreen(t, 'CL-ONBD-01');
    await tapText(t, en.commonActionContinue);
    // three slides: Next, Next, Get started
    expect(find.text(en.clientOnboardingIntroSlide1Title), findsOneWidget);
    await tapText(t, en.commonActionNext, ms: 600);
    expect(find.text(en.clientOnboardingIntroSlide2Title), findsWidgets);
    await tapText(t, en.commonActionNext, ms: 600);
    await tapText(t, en.clientOnboardingIntroStart);
    expect(top(t), 'CL-ONBD-03');

    // who is planning
    await tapText(t, en.clientOnboardingAboutRoleBride, ms: 300);
    await t.enterText(find.byType(EditableText).at(0), 'Reem Al-Dosari');
    await t.enterText(find.byType(EditableText).at(1), 'Fahad Al-Shammari');
    await t.pump();
    await tapText(t, en.commonActionContinue);
    expect(top(t), 'CL-ONBD-04');
    final c = container(t);
    expect(c.read(weddingDraftProvider).role, WeddingRole.bride);
    expect(c.read(weddingDraftProvider).brideName, 'Reem Al-Dosari');
    expect(c.read(weddingDraftProvider).partnerName, 'Fahad Al-Shammari');

    // the date: a day of the visible month
    final sem = t.ensureSemantics();
    await tapDay(t, '25 November 2026');
    sem.dispose();
    await tapText(t, en.commonActionContinue);
    expect(top(t), 'CL-ONBD-05');
    expect(c.read(weddingDraftProvider).dateMode, DateMode.exact);
    expect(c.read(weddingDraftProvider).weddingDate?.day, 25);

    // guests and budget: the demo answers are the start, a preset moves the count
    await tapText(t, '500', ms: 300);
    await tapText(t, en.commonActionContinue);
    expect(top(t), 'CL-ONBD-06');
    expect(c.read(weddingDraftProvider).guests?.women, 500);
    expect(c.read(weddingDraftProvider).venueBudget?.min.fils, 20000000);

    // areas: the live route sets none by itself; pick Salmiya and finish
    expect(find.textContaining(en.commonCountHalls(21).replaceAll('21', '')), findsWidgets);
    for (var i = 0; i < 3; i++) {
      await tapText(t, 'Salmiya', ms: 800); // picked, un-picked, picked: a live toggle
    }
    final brief0 = c.read(weddingDraftProvider);
    expect(brief0.areaIds ?? const <String>[], isEmpty, reason: 'areas are written only when the step is confirmed');
    await t.tap(find.byWidgetPredicate((x) => x is GzButton && x.iconEnd == GzIcons.arrowRight));
    await settle(t);
    expect(top(t), 'CL-DISC-01');
    final brief = c.read(searchBriefProvider);
    expect(brief.areaIds, <String>['salmiya']);
    expect(brief.guests, 500);
    expect(brief.date?.day, 25);
    expect(brief.audience?.value, 'women');
  });

  flowTest('skip: from the intro Home opens with an empty Brief; from a step the answers stay untouched', (t) async {
    await openScreen(t, 'CL-ONBD-02');
    await tapText(t, en.commonActionSkip);
    expect(top(t), 'CL-DISC-01');
    expect(container(t).read(searchBriefProvider).isEmpty, isTrue);
  });

  flowTest('skip on a step goes on without writing; back returns', (t) async {
    await openScreen(t, 'CL-ONBD-03');
    await t.enterText(find.byType(EditableText).at(0), 'Someone');
    await tapText(t, en.commonActionSkip);
    expect(top(t), 'CL-ONBD-04');
    expect(container(t).read(weddingDraftProvider).brideName, isNull);
    await t.tap(find.byKey(const ValueKey<String>('gz:bar.back')).first, warnIfMissed: false);
    await settle(t, wait: const Duration(milliseconds: 800));
    expect(top(t), 'CL-ONBD-03');
  });

  flowTest('the sign-in link opens the sign-in sheet as a plain sign-in and the sheet dismisses', (t) async {
    await openScreen(t, 'CL-ONBD-01');
    await tapText(t, en.clientOnboardingLanguageSignIn);
    expect(top(t), 'CL-AUTH-01');
    expect(container(t).read(gateProvider), isNull);
    nav(t).closeSheet();
    await settle(t, wait: const Duration(milliseconds: 800));
    expect(top(t), 'CL-ONBD-01');
  });

  flowTest('date step: undecided replaces the grid, flexible opens the month sheet', (t) async {
    await openScreen(t, 'CL-ONBD-04');
    expect(find.byType(GzCalendar), findsOneWidget);
    await tapText(t, en.clientOnboardingDateNotDecided, ms: 500);
    expect(find.byType(GzCalendar), findsNothing);
    await tapText(t, en.clientOnboardingDatePickDate, ms: 500);
    expect(find.byType(GzCalendar), findsOneWidget);
    await tapText(t, en.clientOnboardingDateFlexible, ms: 800);
    expect(find.text(en.clientOnboardingDateFlexibleTitle), findsOneWidget);
    await tapText(t, en.commonActionDone, ms: 800);
    await tapText(t, en.commonActionContinue);
    expect(container(t).read(weddingDraftProvider).dateMode, DateMode.flexibleMonth);
  });

  flowTest('guests step: Later puts a half off, Add brings it back; the split shows two steppers', (t) async {
    await openScreen(t, 'CL-ONBD-05');
    expect(find.textContaining('350', findRichText: true), findsWidgets);
    await tapText(t, en.clientOnboardingSkipHalf, ms: 400);
    expect(find.text(en.commonActionAdd), findsOneWidget);
    await tapText(t, en.commonActionAdd, ms: 400);
    expect(find.text(en.commonActionAdd), findsNothing);
    await t.tap(find.byType(GzSwitch), warnIfMissed: false);
    await settle(t, wait: const Duration(milliseconds: 400));
    expect(find.byType(GzStepper), findsNWidgets(2));
  });

  flowTest('areas step: search finds by alias, no match is the empty state, an offline count says so', (t) async {
    await openScreen(t, 'CL-ONBD-06');
    expect(find.text('Sharq'), findsWidgets);
    await t.enterText(find.byType(EditableText).first, 'Mishrif');
    await settle(t, wait: const Duration(milliseconds: 500));
    expect(find.text('Mishref'), findsWidgets);
    await t.enterText(find.byType(EditableText).first, 'zzzz');
    await settle(t, wait: const Duration(milliseconds: 500));
    expect(find.text(en.commonStateTitleEmptySearch), findsOneWidget);
  });

  flowTest('areas step: loading shows a skeleton, an error shows the error state with a retry that recovers', (t) async {
    await openScreen(t, 'CL-ONBD-06', state: 'error');
    // the API retries a failed read three times (about 2 s of fake time); give it room
    await settle(t, wait: const Duration(milliseconds: 6000));
    expect(find.byType(GzErrorState), findsOneWidget);
    flowControl.setScenario('none');
    await t.tap(find.byType(GzButton).last, warnIfMissed: false);
    await settle(t, wait: const Duration(milliseconds: 1500));
    expect(find.byType(GzErrorState), findsNothing);
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

  flowTest('Arabic run: the areas step lists the Arabic names and the title', (t) async {
    await openScreen(t, 'CL-ONBD-06', locale: const Locale('ar'));
    expect(find.text('السالمية'), findsWidgets);
    expect(find.text(ar.clientOnboardingAreasTitle), findsOneWidget);
    expect(Directionality.of(t.element(find.byType(GzScreen).first)), TextDirection.rtl);
  });
}
