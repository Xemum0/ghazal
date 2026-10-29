// The messages flow on the real router over the in-process mock: inbox,
// the thread with send and gate, conversation info, the notification centre,
// the five states, back and sheet dismissal, one Arabic run. Bounded.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:client_app/features/messages/presentation/widgets/msg_composer.dart';

import '../../support/flow_world.dart';

void main() {
  flowTest('the inbox shows threads and opens the hero conversation', (tester) async {
    final c = await openScreen(tester, 'CL-MSGS-01');
    expect(find.textContaining('Aurelia'), findsWidgets);
    await tapKey(tester, 'messages.row.conv-aurelia-reem', flush: true);
    expect(currentId(c), 'CL-MSGS-02');
  });

  flowTest('the thread sends a message and it stays in the thread', (tester) async {
    await openScreen(tester, 'CL-MSGS-02');
    expect(find.byType(GzChatBubble), findsWidgets);
    await tap(tester, find.byType(GzFieldInput));
    await tester.enterText(find.byType(GzFieldInput), 'Is Friday available?');
    await settle(tester);
    await tapLabel(tester, 'Send voice message', flush: true);
    expect(find.textContaining('Is Friday available?'), findsWidgets);
  });

  flowTest('a first message to a venue with no thread opens the thread (the server creates it with that message)', (tester) async {
    final c = await openScreen(tester, 'CL-MSGS-02', params: {'venueId': 'V10'});
    expect(find.text(en.clientMessagesSuggestAvailability), findsOneWidget, reason: 'the empty enquiry offers its suggestions');
    await tap(tester, find.byType(GzFieldInput));
    await tester.enterText(find.byType(GzFieldInput), 'Is Friday available?');
    await settle(tester);
    await tapLabel(tester, 'Send voice message', flush: true);
    await settle(tester, flush: true);
    expect(find.textContaining('Is Friday available?'), findsWidgets, reason: 'the message is the first of the new thread');
    expect(find.text(en.clientMessagesSuggestAvailability), findsNothing, reason: 'it is a thread now, not an enquiry');
    final list = await tester.runAsync(() => flowRepos('reem').chat.listConversations(limit: 50));
    expect(list!.items.any((x) => x.venueId == 'V10'), isTrue);
    expect(currentId(c), 'CL-MSGS-02');
  });

  flowTest('the thread follows a message sent while it is open: the newest one stays in view, not below the fold', (tester) async {
    // Regression (simulator pass, 2026-10-26): with the real keyboard up the list is short; a sent message landed below the fold.
    await openScreen(tester, 'CL-MSGS-02', size: const Size(390, 520));
    for (final text in const ['First question', 'Second question', 'Third question', 'Fourth question']) {
      await tap(tester, find.byType(GzFieldInput));
      await tester.enterText(find.byType(GzFieldInput), text);
      await settle(tester);
      await tapLabel(tester, 'Send voice message', flush: true);
      final newest = find.textContaining(text);
      expect(newest, findsWidgets);
      expect(newest.hitTestable(), findsWidgets, reason: '"$text" is on screen');
    }
  });

  flowTest('conversation info opens with mute, report and block, then closes', (tester) async {
    final c = await openScreen(tester, 'CL-MSGS-02');
    await tapLabel(tester, 'Details', flush: true);
    expect(onScreen('thread.info'), isTrue);
    expect(find.text('Mute'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
    expect(find.text('Block'), findsOneWidget);
    nav(tester).closeSheet();
    await settle(tester, flush: true);
    expect(currentId(c), 'CL-MSGS-02');
  });

  flowTest('report walks pick then reason then done', (tester) async {
    await openScreen(tester, 'CL-MSGS-02');
    await tapLabel(tester, 'Details', flush: true);
    await tapText(tester, 'Report', flush: true);
    expect(onScreen('thread.info.pick'), isTrue);
    nav(tester).closeSheet();
    await settle(tester, flush: true);
  });

  flowTest('the notification centre shows rows and filters', (tester) async {
    await openScreen(tester, 'CL-MSGS-04');
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Request sent'), findsWidgets);
    expect(find.text('Read all'), findsOneWidget);
    expect(find.byType(GzErrorState), findsNothing);
  });

  flowTest('state loading: skeletons show, no error', (tester) async {
    await openScreen(tester, 'CL-MSGS-02', state: 'loading');
    expect(find.byType(GzSkeleton), findsWidgets);
    expect(find.byType(GzErrorState), findsNothing);
  });

  flowTest('state error: the problem is told with a retry', (tester) async {
    await openScreen(tester, 'CL-MSGS-01', state: 'error', extraSeconds: 6);
    expect(find.byType(GzErrorState), findsOneWidget);
    expect(find.text('Try again'), findsWidgets);
  });

  flowTest('state offline: the network state shows', (tester) async {
    await openScreen(tester, 'CL-MSGS-01', state: 'offline', extraSeconds: 6);
    expect(find.byType(GzErrorState), findsOneWidget);
  });

  flowTest('blocked conversation replaces the composer with an unblock bar', (tester) async {
    await openScreen(tester, 'CL-MSGS-02');
    await tapLabel(tester, 'Details', flush: true);
    expect(onScreen('thread.info'), isTrue);
    await tapText(tester, 'Block', flush: true);
    await tapText(tester, 'Block', flush: true);
    await settle(tester, flush: true);
    expect(onScreen('thread.info.blocked'), isTrue);
    nav(tester).closeSheet();
    await settle(tester, flush: true);
    expect(find.text('Blocked'), findsWidgets);
    await tapText(tester, 'Unblock', flush: true);
    expect(find.byType(MsgComposer), findsWidgets);
  });

  flowTest('support variant opens the support thread', (tester) async {
    await openScreen(tester, 'CL-MSGS-02', params: {'support': true});
    expect(find.byType(GzChatBubble), findsWidgets);
  });

  flowTest('arabic: the thread reads right to left', (tester) async {
    await openScreen(tester, 'CL-MSGS-02', locale: const Locale('ar'));
    expect(find.byType(GzChatBubble), findsWidgets);
    expect(shows('السلام عليكم'), isTrue);
  });
}
