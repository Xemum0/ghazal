import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/src/nav/nav_providers.dart' show gzNavigatorProvider;
import 'package:ghazal_app_kit/src/session/session.dart';
import 'package:ghazal_ui/ghazal_ui.dart' show GzDialogResult, GzDialogSpec, GzNavigator, GzParams, GzSheetOptions, GzToastSpec;

import '../data/kit_world.dart';

/// A navigator that keeps a plain stack, enough to see what the gate opened, closed and pushed.
class FakeNavigator implements GzNavigator {
  FakeNavigator(String root) : stack = [(root, const <String, Object?>{})];

  final List<(String, GzParams)> stack;
  final List<GzSheetOptions> sheetOptions = [];

  @override
  String get currentId => stack.last.$1;
  @override
  GzParams get params => stack.last.$2;
  @override
  bool get canGoBack => stack.length > 1;
  @override
  String? get activeTab => null;
  @override
  void push(String id, {GzParams params = const {}}) => stack.add((id, params));
  @override
  void pop({int count = 1}) {
    for (var i = 0; i < count && stack.length > 1; i++) {
      stack.removeLast();
    }
  }

  @override
  void replace(String id, {GzParams params = const {}}) => stack.last = (id, params);
  @override
  void reset(String id, {GzParams params = const {}}) => stack
    ..clear()
    ..add((id, params));
  @override
  void switchTab(String tabId) {}
  @override
  String openSheet(String screenId, {GzSheetOptions options = const GzSheetOptions()}) {
    sheetOptions.add(options);
    stack.add((screenId, options.params));
    return screenId;
  }

  @override
  String openSheetBuilder(WidgetBuilder builder, {GzSheetOptions options = const GzSheetOptions()}) => '';
  @override
  void closeSheet([String? key]) => pop();
  @override
  Future<GzDialogResult> openDialog(GzDialogSpec spec) async => GzDialogResult.cancel;
  @override
  String toast(GzToastSpec spec) => '';
  @override
  void dismissToast([String? key]) {}
}

final _gate = Provider<bool Function(GateReason, GateResume?)>((ref) => (reason, resume) => ref.requireSignIn(reason, resume: resume));

void main() {
  late KitWorld world;
  setUpAll(() async => world = await KitWorld.load());
  setUp(() async => world.fresh());
  tearDown(KitWorld.disposeAll);

  test('a guest at a commit moment opens the gate sheet with the reason and the resume route', () {
    final nav = FakeNavigator('CL-BOOK-05');
    final c = world.container(overrides: [gzNavigatorProvider.overrideWithValue(nav)]);

    final ok = c.read(_gate)(GateReason.sendRequest, const GateResume('CL-BOOK-05', {'venueId': 'V01'}));

    expect(ok, isFalse);
    expect(nav.currentId, 'CL-AUTH-01');
    expect(nav.params['reason'], 'send-request');
    expect(nav.params['resume'], 'CL-BOOK-05');
    final request = c.read(gateProvider)!;
    expect(request.reason, GateReason.sendRequest);
    expect(request.resume!.params['venueId'], 'V01');
  });

  test('a signed-in client passes the gate untouched', () async {
    final nav = FakeNavigator('CL-BOOK-05');
    final c = world.container(overrides: [gzNavigatorProvider.overrideWithValue(nav)]);
    await c.read(sessionProvider.notifier).loadPersona('reem');

    expect(c.read(_gate)(GateReason.voucher, null), isTrue);
    expect(nav.stack, hasLength(1));
    expect(c.read(gateProvider), isNull);
  });

  test('after the sign-in the sheet and the sign-in screens close and the app continues at the resume route with its params', () async {
    final nav = FakeNavigator('CL-VENU-01');
    final c = world.container(overrides: [gzNavigatorProvider.overrideWithValue(nav)]);
    c.read(_gate)(GateReason.voucher, const GateResume('CL-VCHR-01', {'venueId': 'V01', 'date': '2027-01-14'}));
    nav.push('CL-AUTH-02'); // the code screen of the sign-in flow, pushed over the sheet

    final notifier = c.read(sessionProvider.notifier);
    await notifier.requestOtp('50000012');
    await notifier.verifyOtp('123456');

    expect(c.read(sessionProvider), isA<ClientSession>());
    expect(c.read(gateProvider), isNull);
    expect(nav.stack.map((e) => e.$1), ['CL-VENU-01', 'CL-VCHR-01']);
    expect(nav.params, {'venueId': 'V01', 'date': '2027-01-14'});
  });

  test('when the resume screen is the one underneath, nothing is pushed twice', () async {
    final nav = FakeNavigator('CL-BOOK-05');
    final c = world.container(overrides: [gzNavigatorProvider.overrideWithValue(nav)]);
    c.read(_gate)(GateReason.sendRequest, const GateResume('CL-BOOK-05'));

    final notifier = c.read(sessionProvider.notifier);
    await notifier.requestOtp('50000012');
    await notifier.verifyOtp('123456');

    expect(nav.stack.map((e) => e.$1), ['CL-BOOK-05']);
  });

  test('closing the sheet without signing in clears the request', () {
    final nav = FakeNavigator('CL-DISC-01');
    final c = world.container(overrides: [gzNavigatorProvider.overrideWithValue(nav)]);
    c.read(_gate)(GateReason.save, null);
    expect(c.read(gateProvider), isNotNull);

    nav.sheetOptions.single.onClose!();

    expect(c.read(gateProvider), isNull);
    expect(c.read(sessionProvider), isA<GuestSession>());
  });

  test('GateReason spellings are the web ones', () {
    expect(GateReason.sendRequest.wire, 'send-request');
    expect(GateReason.parse('send-request'), GateReason.sendRequest);
    expect(GateReason.parse('chat'), GateReason.chat);
    expect(GateReason.values, hasLength(8));
  });
}
