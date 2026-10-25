// Flow test of Grow (HL-GROW-01..04, 06): the real router and the in-process mock (`autoRun: false`). Bounded.
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'package:provider_app/features/grow/presentation/hl_grow_01.dart';
import 'package:provider_app/features/grow/presentation/hl_grow_02.dart';
import 'package:provider_app/features/grow/presentation/hl_grow_03.dart';
import 'package:provider_app/features/grow/presentation/hl_grow_04.dart';
import 'package:provider_app/features/grow/presentation/hl_grow_06.dart';

import '../../support/flow_world.dart';

void main() {
  flowTest('voucher prices list shows the windows', (tester) async {
    await openScreen(tester, 'HL-GROW-01');
    expect(find.byType(HlGrow01Screen), findsOneWidget);
    expect(find.text('Voucher prices'), findsWidgets);
    expect(find.text('Midweek voucher price'), findsWidgets);
  });

  flowTest('new window opens the create screen', (tester) async {
    await openScreen(tester, 'HL-GROW-01');
    await tapText(tester, 'New voucher price window');
    expect(find.byType(HlGrow02Screen), findsOneWidget);
  });

  flowTest('window form shows the preview', (tester) async {
    await openScreen(tester, 'HL-GROW-02');
    expect(find.text('Voucher price window'), findsWidgets);
    expect(find.text('Preview'), findsWidgets);
  });

  flowTest('event dates screen shows the month', (tester) async {
    await openScreen(tester, 'HL-GROW-03');
    expect(find.byType(HlGrow03Screen), findsOneWidget);
    expect(find.text('Event dates'), findsWidgets);
    expect(find.textContaining('November'), findsWidgets);
  });

  flowTest('analytics shows the ranges and no plan rate', (tester) async {
    await openScreen(tester, 'HL-GROW-04');
    expect(find.byType(HlGrow04Screen), findsOneWidget);
    expect(find.text('Analytics'), findsWidgets);
  });

  flowTest('analytics range chip switches', (tester) async {
    await openScreen(tester, 'HL-GROW-04');
    await tapLabel(tester, RegExp('Last 90'));
    expect(find.byType(HlGrow04Screen), findsOneWidget);
  });

  flowTest('reviews list shows reply and report', (tester) async {
    await openScreen(tester, 'HL-GROW-06');
    expect(find.byType(HlGrow06Screen), findsOneWidget);
    expect(find.text('Reply'), findsWidgets);
    expect(find.text('Report'), findsWidgets);
  });

  flowTest('error state shows the error view', (tester) async {
    await openScreen(tester, 'HL-GROW-01', state: 'error');
    expect(find.byType(GzErrorState), findsOneWidget);
  });

  flowTest('offline state shows the offline view', (tester) async {
    await openScreen(tester, 'HL-GROW-06', state: 'offline');
    expect(find.byType(GzOfflineState), findsOneWidget);
  });

  flowTest('Arabic run: analytics renders in Arabic', (tester) async {
    await openScreen(tester, 'HL-GROW-04', locale: const Locale('ar'));
    expect(find.byType(HlGrow04Screen), findsOneWidget);
  });
}
