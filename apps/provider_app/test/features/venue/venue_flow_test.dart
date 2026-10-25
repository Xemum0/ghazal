// Flow test of Venue (HL-VENU-01..06): the real router and the in-process mock (`autoRun: false`). Bounded.
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'package:provider_app/features/venue/presentation/hl_venu_01.dart';
import 'package:provider_app/features/venue/presentation/hl_venu_02.dart';
import 'package:provider_app/features/venue/presentation/hl_venu_03.dart';
import 'package:provider_app/features/venue/presentation/hl_venu_04.dart';
import 'package:provider_app/features/venue/presentation/hl_venu_05.dart';
import 'package:provider_app/features/venue/presentation/hl_venu_06.dart';

import '../../support/flow_world.dart';

void main() {
  flowTest('media manager lists the photos and the zone filters', (tester) async {
    await openScreen(tester, 'HL-VENU-01');
    expect(find.byType(HlVenu01Screen), findsOneWidget);
    expect(find.text('Photos and videos'), findsWidgets);
    expect(find.text('Reorder'), findsWidgets);
  });

  flowTest('media manager Videos tab switches', (tester) async {
    await openScreen(tester, 'HL-VENU-01');
    await tapText(tester, 'Videos 2');
    expect(find.text('Photos 24'), findsWidgets);
  });

  flowTest('packages list shows packages and the extras tab', (tester) async {
    await openScreen(tester, 'HL-VENU-02');
    expect(find.byType(HlVenu02Screen), findsOneWidget);
    expect(find.text('Ladies’ Reception, Weekday'), findsWidgets);
    await tapText(tester, 'Extras (12)');
    expect(find.text('Packages (6)'), findsWidgets);
  });

  flowTest('package editor builds with its fields', (tester) async {
    await openScreen(tester, 'HL-VENU-03');
    expect(find.byType(HlVenu03Screen), findsOneWidget);
    expect(find.text('Edit package'), findsWidgets);
    expect(find.text('Audience'), findsWidgets);
  });

  flowTest('halls and amenities shows the halls', (tester) async {
    await openScreen(tester, 'HL-VENU-04');
    expect(find.byType(HlVenu04Screen), findsOneWidget);
    expect(find.text('Danah Ballroom'), findsWidgets);
  });

  flowTest('policies shows the voucher terms', (tester) async {
    await openScreen(tester, 'HL-VENU-05');
    expect(find.byType(HlVenu05Screen), findsOneWidget);
    expect(find.text('Voucher terms'), findsWidgets);
    expect(find.text('Save changes'), findsWidgets);
  });

  flowTest('booking rules shows the mode and the preview', (tester) async {
    await openScreen(tester, 'HL-VENU-06');
    expect(find.byType(HlVenu06Screen), findsOneWidget);
    expect(find.text('Request to book'), findsWidgets);
  });

  flowTest('error state shows the error view', (tester) async {
    await openScreen(tester, 'HL-VENU-02', state: 'error');
    expect(find.byType(GzErrorState), findsOneWidget);
  });

  flowTest('offline state shows the offline view', (tester) async {
    await openScreen(tester, 'HL-VENU-04', state: 'offline');
    expect(find.byType(GzOfflineState), findsOneWidget);
  });

  flowTest('Arabic run: media manager renders in Arabic', (tester) async {
    await openScreen(tester, 'HL-VENU-01', locale: const Locale('ar'));
    expect(find.text('الصور والفيديو'), findsWidgets);
  });
}
