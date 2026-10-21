import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';

import 'nav_fixture.dart';

void main() {
  testWidgets('GzAppRoot onResume: each callback runs, in order, when the app comes back to the foreground, and not for other changes', (
    tester,
  ) async {
    final calls = <String>[];
    await pumpNav(tester, onResume: <void Function(WidgetRef ref)>[(ref) => calls.add('badges'), (ref) => calls.add('second')]);
    expect(calls, isEmpty);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(calls, isEmpty, reason: 'going away refreshes nothing');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(calls, <String>['badges', 'second']);
  });

  testWidgets('GzAppRoot warmUp: the listed providers start loading with the app, before any screen asks', (tester) async {
    var built = 0;
    final warm = Provider<int>((ref) => ++built);
    await pumpNav(tester, warmUp: <ProviderListenable<Object?>>[warm]);
    expect(built, 1);
  });

  testWidgets('GzAppRoot removes its lifecycle observer when it leaves the tree', (tester) async {
    final calls = <String>[];
    await pumpNav(tester, onResume: <void Function(WidgetRef ref)>[(ref) => calls.add('x')]);
    await tester.pumpWidget(const SizedBox.shrink());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(calls, isEmpty);
  });
}
