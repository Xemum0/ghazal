// The tab badges are part of the app (a shot and a test show them, not only the running build) and refresh when the app resumes.
import 'package:client_app/app/state/state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../support/flow_world.dart';

void main() {
  flowTest('Reem opens Discover and the Messages tab already carries its unread count; the Brief is hers without a screen asking', (tester) async {
    final c = await openScreen(tester, 'CL-DISC-01');
    final bar = tester.widget<GzTabBar>(find.byType(GzTabBar));
    final messages = bar.items.firstWhere((i) => i.id == 'messages');
    expect(messages.badge, isNotNull, reason: 'the badge is loaded by the time the shot settles');
    expect(messages.badge!.count, 3);
    expect(find.byKey(const ValueKey<String>('gz:tab.badge')), findsWidgets);
    expect(c.read(searchBriefProvider).guests, 350, reason: 'the wedding profile seeded the Brief at sign-in');
  });

  flowTest('the app coming back to the foreground refetches the badge counts', (tester) async {
    final c = await openScreen(tester, 'CL-DISC-01');
    final before = c.read(clientDataRevisionProvider);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(c.read(clientDataRevisionProvider), before, reason: 'leaving the app refreshes nothing');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(c.read(clientDataRevisionProvider), before + 1);
    await settle(tester, flush: true);
  });
}
