// The partner tab badges are part of the app and refresh when the app resumes.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:provider_app/app/state/state.dart';

import '../support/flow_world.dart';

void main() {
  flowTest('the hotel manager opens Today and the Bookings tab carries the pending count', (tester) async {
    await openScreen(tester, 'HL-TODY-01');
    final bar = tester.widget<GzTabBar>(find.byType(GzTabBar));
    expect(bar.items.firstWhere((i) => i.id == 'bookings').badge, isNotNull, reason: 'pending requests wait for an answer');
  });

  flowTest('the app coming back to the foreground refetches the badge counts', (tester) async {
    final c = await openScreen(tester, 'HL-TODY-01');
    final before = c.read(partnerDataRevisionProvider);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(c.read(partnerDataRevisionProvider), before);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(c.read(partnerDataRevisionProvider), before + 1);
    await settle(tester, flush: true);
  });
}
