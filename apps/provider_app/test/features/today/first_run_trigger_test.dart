// Regression (simulator pass, 2026-10-26): Today is built twice right after sign-in and each build opened its own "Allow notifications"
// sheet, so two sheets stacked and the first one stayed over the tab bar after both were answered. The sheets open once per run of the app.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart' show GzDialogResult, GzDialogSpec, GzNavigator, GzNavigatorScope, GzParams, GzSheetOptions, GzToastSpec;
import 'package:provider_app/features/today/presentation/widgets/today_overlays.dart';
import 'package:provider_app/l10n/l10n.dart';

/// Counts the sheets that were opened; everything else does nothing.
class _CountingNavigator implements GzNavigator {
  _CountingNavigator(this.params);

  @override
  final GzParams params;
  int sheets = 0;

  @override
  String openSheetBuilder(WidgetBuilder builder, {GzSheetOptions options = const GzSheetOptions()}) {
    sheets++;
    return 's$sheets';
  }

  @override
  bool get canGoBack => false;
  @override
  String get currentId => 'HL-TODY-01';
  @override
  String? get activeTab => 'today';
  @override
  void push(String id, {GzParams params = const {}}) {}
  @override
  void pop({int count = 1}) {}
  @override
  void replace(String id, {GzParams params = const {}}) {}
  @override
  void reset(String id, {GzParams params = const {}}) {}
  @override
  void switchTab(String tabId) {}
  @override
  String openSheet(String screenId, {GzSheetOptions options = const GzSheetOptions()}) => '';
  @override
  void closeSheet([String? key]) {}
  @override
  Future<GzDialogResult> openDialog(GzDialogSpec spec) async => GzDialogResult.cancel;
  @override
  String toast(GzToastSpec spec) => '';
  @override
  void dismissToast([String? key]) {}
}

Widget _host(GzNavigator nav, List<Widget> children) => ProviderScope(
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Localizations(
      locale: const Locale('en'),
      delegates: const [AppL10n.delegate, DefaultWidgetsLocalizations.delegate],
      child: GzNavigatorScope(navigator: nav, child: Column(children: children)),
    ),
  ),
);

void main() {
  testWidgets('two builds of Today at once open the first-run notifications sheet once', (tester) async {
    final nav = _CountingNavigator(const <String, Object?>{'firstRun': true});
    // two triggers in the same frame: the incoming Today and the outgoing one that is still mounted
    await tester.pumpWidget(_host(nav, const [FirstRunTrigger(key: ValueKey<String>('a')), FirstRunTrigger(key: ValueKey<String>('b'))]));
    await tester.pump();
    expect(nav.sheets, 1, reason: 'one first-run sheet, not one per build of Today');
  });

  testWidgets('a rebuilt Today (a new state, a frame later) does not open it again', (tester) async {
    final nav = _CountingNavigator(const <String, Object?>{'firstRun': true});
    await tester.pumpWidget(_host(nav, const [FirstRunTrigger(key: ValueKey<String>('a'))]));
    await tester.pump();
    expect(nav.sheets, 1);
    await tester.pumpWidget(_host(nav, const [FirstRunTrigger(key: ValueKey<String>('b'))]));
    await tester.pump();
    expect(nav.sheets, 1, reason: 'the sheets open once per run of the app');
  });

  testWidgets('without the firstRun param Today opens nothing', (tester) async {
    final nav = _CountingNavigator(const <String, Object?>{});
    await tester.pumpWidget(_host(nav, const [FirstRunTrigger()]));
    await tester.pump();
    expect(nav.sheets, 0);
  });
}
