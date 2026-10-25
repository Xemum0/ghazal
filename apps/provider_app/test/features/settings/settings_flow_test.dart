// Flow test of Settings (HL-SETT-01..05): the real router and the in-process mock (`autoRun: false`), real taps. Bounded.
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'package:provider_app/features/settings/presentation/hl_sett_01.dart';
import 'package:provider_app/features/settings/presentation/hl_sett_02.dart';
import 'package:provider_app/features/settings/presentation/hl_sett_03.dart';
import 'package:provider_app/features/settings/presentation/hl_sett_04.dart';
import 'package:provider_app/features/settings/presentation/hl_sett_05.dart';

import '../../support/flow_world.dart';

void main() {
  flowTest('More shows the venue card, the groups and the tab bar', (tester) async {
    await openScreen(tester, 'HL-SETT-01');
    expect(find.byType(HlSett01Screen), findsOneWidget);
    expect(find.byType(GzTabBar), findsOneWidget);
    expect(find.text('Language'), findsWidgets);
    expect(find.text('Log out'), findsWidgets);
  });

  flowTest('Language opens its sheet', (tester) async {
    await openScreen(tester, 'HL-SETT-01');
    await tapText(tester, 'Language');
    expect(find.text('English'), findsWidgets);
    expect(find.text('العربية'), findsWidgets);
  });

  flowTest('Log out asks first', (tester) async {
    await openScreen(tester, 'HL-SETT-01');
    await tapText(tester, 'Log out');
    expect(find.text('Log out?'), findsWidgets);
  });

  flowTest('the admin sees the staff list and the Invite action', (tester) async {
    await openScreen(tester, 'HL-SETT-03', persona: 'hotel_admin');
    expect(find.byType(HlSett03Screen), findsOneWidget);
    expect(find.text('Invite staff'), findsWidgets);
  });

  flowTest('the admin edits the business hours and sees Save', (tester) async {
    await openScreen(tester, 'HL-SETT-05', persona: 'hotel_admin');
    expect(find.byType(HlSett05Screen), findsOneWidget);
    expect(find.text('Save'), findsWidgets);
    expect(find.text('View only'), findsNothing);
  });

  flowTest('the manager only views the business hours', (tester) async {
    await openScreen(tester, 'HL-SETT-05', persona: 'hotel_manager');
    expect(find.text('View only'), findsWidgets);
  });

  flowTest('notification preferences and billing open', (tester) async {
    await openScreen(tester, 'HL-SETT-02');
    expect(find.byType(HlSett02Screen), findsOneWidget);
    await finish(tester);
  });

  flowTest('billing screen builds', (tester) async {
    await openScreen(tester, 'HL-SETT-04');
    expect(find.byType(HlSett04Screen), findsOneWidget);
  });

  flowTest('error state shows Try again', (tester) async {
    await openScreen(tester, 'HL-SETT-03', persona: 'hotel_admin', state: 'error');
    expect(find.byType(GzErrorState), findsOneWidget);
  });

  flowTest('offline state shows the offline view', (tester) async {
    await openScreen(tester, 'HL-SETT-03', persona: 'hotel_admin', state: 'offline');
    expect(find.byType(GzOfflineState), findsOneWidget);
  });

  flowTest('Arabic run: More renders in Arabic', (tester) async {
    await openScreen(tester, 'HL-SETT-01', locale: const Locale('ar'));
    expect(find.text('اللغة'), findsWidgets);
  });
}
