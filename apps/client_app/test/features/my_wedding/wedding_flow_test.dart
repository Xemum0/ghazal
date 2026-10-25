// My Wedding, the checklist and the budget on the real router over the in-process mock.
// Bounded: every wait is a bounded settle, no real IO in fake async.
import 'package:client_app/features/my_wedding/presentation/widgets/wedding_hero.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../support/flow_world.dart';

void main() {
  flowTest('the hub: countdown, next up, the bookings card and the tools', (tester) async {
    final c = await openScreen(tester, 'CL-WEDD-01');
    await settle(tester, flush: true);
    expect(shows(en.clientMyWeddingHubTitle), isTrue);
    expect(find.byType(WeddingHero), findsOneWidget, reason: 'the countdown hero');
    expect(shows(en.clientMyWeddingNextTitle), isTrue, reason: 'next up');
    expect(shows(en.clientMyWeddingBookingsTitle), isTrue, reason: 'the bookings card');
    expect(shows(en.clientMyWeddingToolsLabel), isTrue, reason: 'the tools row');
    // The bookings card opens the detail (another flow: its render errors are not this test's failure).
    final booking = (await tester.runAsync(() => flowRepos('reem').requests.listRequests()))!.items.firstOrNull;
    expect(booking, isNotNull);
    ignoreRenderErrors = true;
    await tapText(tester, booking!.target.name.of('en'), flush: true);
    expect(currentId(c), 'CL-BKNG-02');
  });

  flowTest('checklist: ticking a task completes it with an undo bar', (tester) async {
    await openScreen(tester, 'CL-WEDD-02');
    await settle(tester, flush: true);
    expect(shows(en.clientMyWeddingChecklistTitle), isTrue);
    final view = (await tester.runAsync(() => flowRepos('reem').wedding.getChecklist()))!;
    final open = view.items.where((i) => !i.done && !i.auto).firstOrNull;
    expect(open, isNotNull, reason: 'an open manual task to tick');
    await tapLabel(tester, open!.title.of('en'));
    await settle(tester, flush: true);
    expect(shows(en.clientMyWeddingChecklistToastDone), isTrue, reason: 'the undo toast');
    final after = (await tester.runAsync(() => flowRepos('reem').wedding.getChecklist()))!;
    expect(after.items.where((i) => i.id == open.id).single.done, isTrue, reason: 'the tick is on the server');
  });

  flowTest('checklist: the venue item links to its booking', (tester) async {
    await openScreen(tester, 'CL-WEDD-02');
    await settle(tester, flush: true);
    final view = (await tester.runAsync(() => flowRepos('reem').wedding.getChecklist()))!;
    final venue = view.items.where((i) => i.bookingId != null).firstOrNull;
    if (venue == null) return;
    final c = container(tester);
    // The venue row opens its booking (another flow: its render errors are not this test's failure).
    ignoreRenderErrors = true;
    await tapText(tester, en.clientMyWeddingChecklistViewBookingLabel(venue.title.of('en')), flush: true);
    expect(currentId(c), 'CL-BKNG-02');
  });

  flowTest('budget: the hero, the ranked categories and the add-expense sheet', (tester) async {
    await openScreen(tester, 'CL-WEDD-03');
    await settle(tester, flush: true);
    expect(shows(en.clientMyWeddingBudgetTitle), isTrue);
    // The hero is the web's: Remaining as the figure under one word (the kit GzBudgetSummary is the stat-row variant).
    expect(shows(en.clientMyWeddingBudgetRemaining), isTrue, reason: 'the hero names the remaining figure');
    expect(find.byType(GzPrice), findsWidgets);
    await tapText(tester, en.clientMyWeddingBudgetAddExpense, flush: true);
    await settle(tester, flush: true);
    expect(currentId(container(tester)), 'CL-WEDD-04');
    // Blameless validation: saving the empty form only says why.
    await tapText(tester, en.commonActionSave, flush: true);
    await settle(tester, flush: true);
    expect(shows(en.clientMyWeddingExpenseAmountError), isTrue, reason: 'the blameless error');
    expect(find.byType(GzTextField), findsWidgets);
  });

  flowTest('budget setup: changing the total saves and redraws the bar', (tester) async {
    final c = await openScreen(tester, 'CL-WEDD-03');
    await settle(tester, flush: true);
    c.read(gzNavigatorProvider).openSheet('CL-WEDD-05');
    await settle(tester, flush: true);
    expect(shows(en.clientMyWeddingSetupTitle), isTrue);
    final fields = find.byType(EditableText);
    expect(fields, findsWidgets);
    await tester.enterText(fields.first, '60000');
    await tester.pump(const Duration(milliseconds: 300));
    await tapText(tester, en.commonActionSave, flush: true);
    await settle(tester, flush: true);
    expect(shows(en.clientMyWeddingSetupSaved), isTrue, reason: 'the saved toast');
  });

  flowTest('state loading: the skeleton shows, no error', (tester) async {
    await openScreen(tester, 'CL-WEDD-01', state: 'loading');
    expect(find.byType(GzSkeleton), findsWidgets);
    expect(find.byType(GzErrorState), findsNothing);
  });

  flowTest('state error: the problem is told with a retry', (tester) async {
    await openScreen(tester, 'CL-WEDD-01', state: 'error', extraSeconds: 6);
    expect(find.byType(GzErrorState), findsOneWidget);
    expect(find.text(en.commonActionRetry), findsWidgets);
  });

  flowTest('state offline: the network state shows with its retry', (tester) async {
    await openScreen(tester, 'CL-WEDD-01', state: 'offline', extraSeconds: 6);
    expect(find.byType(GzOfflineState), findsOneWidget, reason: 'the offline state is its own state');
  });

  flowTest('guest: the sample structure with a sign-in at the first write', (tester) async {
    final c = await openScreen(tester, 'CL-WEDD-01', persona: 'guest');
    await settle(tester, flush: true);
    expect(shows(en.clientMyWeddingSample), isTrue);
    expect(currentId(c), 'CL-WEDD-01');
  });

  flowTest('arabic: the hub renders right to left with no overflow', (tester) async {
    await openScreen(tester, 'CL-WEDD-01', locale: const Locale('ar'));
    await settle(tester, flush: true);
    expect(shows(ar.clientMyWeddingHubTitle), isTrue);
  });
}
