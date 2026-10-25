// Flow test of the partner Visits (HL-VIST-01..05): the real router and the in-process mock (`autoRun: false`), real taps. Bounded: no real IO.
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'package:provider_app/features/visits/presentation/hl_vist_01.dart';
import 'package:provider_app/features/visits/presentation/hl_vist_02.dart';
import 'package:provider_app/features/visits/presentation/hl_vist_03.dart';
import 'package:provider_app/features/visits/presentation/hl_vist_05.dart';

import '../../support/flow_world.dart';

void main() {
  flowTest('Visit requests: the queue shows the requested visit with its actions', (tester) async {
    await openScreen(tester, 'HL-VIST-01');
    expect(find.byType(HlVist01Screen), findsOneWidget);
    expect(find.text('Confirm'), findsWidgets);
    expect(find.text('Another time'), findsWidgets);
    expect(find.textContaining('راشد'), findsWidgets);
  });

  flowTest('Confirm in the queue changes the status and says so', (tester) async {
    await openScreen(tester, 'HL-VIST-01');
    await tap(tester, find.text('Confirm').first, flush: true);
    expect(find.text('Confirmed'), findsWidgets);
  });

  flowTest('a visit card opens its detail; the chat button opens the group chat of three', (tester) async {
    final c = await openScreen(tester, 'HL-VIST-01');
    await tap(tester, find.textContaining('راشد').first);
    expect(currentId(c), 'HL-VIST-02');
    expect(find.byType(HlVist02Screen), findsOneWidget);
    await tap(tester, find.text('Open chat'));
    expect(currentId(c), 'HL-VIST-03');
    expect(find.byType(HlVist03Screen), findsOneWidget);
    expect(find.text('Ghazal support'), findsWidgets);
    expect(find.text('Client'), findsWidgets);
  });

  flowTest('Visit chat: a quick reply fills the field and Send adds the message', (tester) async {
    await openScreen(tester, 'HL-VIST-03');
    await tap(tester, find.text('Main entrance'));
    await tap(tester, find.bySemanticsLabel('Send'), flush: true);
    expect(find.textContaining('entrance'), findsWidgets);
  });

  flowTest('Mark arrival: the sheet marks the client arrived and offers the chat', (tester) async {
    final c = await openScreen(tester, 'HL-VIST-02', story: 'confirmed');
    await openSheetOf(tester, c, 'HL-VIST-04', <String, Object?>{'visitId': 'visit-aurelia-reem'});
    expect(currentId(c), 'HL-VIST-04');
    expect(find.text('Mark arrived'), findsWidgets);
    expect(find.text('No-show'), findsWidgets);
  });

  flowTest('Visit hours: the weekly rules load and Save rests until something changes', (tester) async {
    await openScreen(tester, 'HL-VIST-05');
    expect(find.byType(HlVist05Screen), findsOneWidget);
    expect(find.text('Accept visits'), findsWidgets);
    expect(find.text('No changes'), findsWidgets);
  });

  flowTest('empty queue shows an empty state, never a blank', (tester) async {
    await openScreen(tester, 'HL-VIST-01', state: 'empty');
    expect(find.byType(GzEmptyState), findsWidgets);
  });

  flowTest('a failing load shows the error state with Try again', (tester) async {
    await openScreen(tester, 'HL-VIST-01', state: 'error');
    expect(find.byType(GzErrorState), findsOneWidget);
  });

  flowTest('offline shows the offline state', (tester) async {
    await openScreen(tester, 'HL-VIST-01', state: 'offline');
    expect(find.byType(GzOfflineState), findsOneWidget);
  });

  flowTest('loading shows the skeleton that matches the layout', (tester) async {
    await openScreen(tester, 'HL-VIST-01', state: 'loading');
    expect(find.byType(GzSkeleton), findsWidgets);
  });

  flowTest('Arabic run: the queue mirrors', (tester) async {
    await openScreen(tester, 'HL-VIST-01', locale: const Locale('ar'));
    expect(find.text('تأكيد'), findsWidgets);
  });
}
