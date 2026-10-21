import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/src/data/api_providers.dart' show gzProviderRetry;
import 'package:ghazal_app_kit/src/state_views/state_views.dart';
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

Widget host(Widget child, {Locale locale = const Locale('en'), bool reduced = false}) => MediaQuery(
      data: MediaQueryData(size: const Size(390, 844), disableAnimations: reduced),
      child: Directionality(
        textDirection: locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: GzTheme(
          locale: locale,
          child: Localizations(
            locale: locale,
            delegates: const [GzL10n.delegate, DefaultWidgetsLocalizations.delegate],
            child: SizedBox(width: 390, height: 844, child: child),
          ),
        ),
      ),
    );

const _slotProblem = ApiProblem(status: 409, code: ApiProblemCode.slotUnavailable);

void main() {
  testWidgets('loading shows the default skeleton, or the one given', (tester) async {
    await tester.pumpWidget(host(GzAsyncView<int>(value: const AsyncLoading<int>(), data: (d) => Text('$d'))));
    expect(find.byType(GzDefaultLoading), findsOneWidget);
    expect(find.byType(GzSkeleton), findsWidgets);

    await tester.pumpWidget(host(GzAsyncView<int>(value: const AsyncLoading<int>(), data: (d) => Text('$d'), loading: const Text('custom'))));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('custom'), findsOneWidget);
    expect(find.byType(GzDefaultLoading), findsNothing);
  });

  testWidgets('data builds the content; isEmpty switches to the empty state, default or given', (tester) async {
    await tester.pumpWidget(host(GzAsyncView<List<int>>(value: const AsyncData([1, 2]), data: (d) => Text('count ${d.length}'), isEmpty: (d) => d.isEmpty)));
    expect(find.text('count 2'), findsOneWidget);

    await tester.pumpWidget(host(GzAsyncView<List<int>>(value: const AsyncData(<int>[]), data: (d) => Text('count ${d.length}'), isEmpty: (d) => d.isEmpty)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(GzEmptyState), findsOneWidget);
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.textContaining('count'), findsNothing);

    await tester.pumpWidget(
      host(GzAsyncView<List<int>>(value: const AsyncData(<int>[]), data: (d) => const SizedBox(), isEmpty: (d) => d.isEmpty, empty: const Text('no venues'))),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('no venues'), findsOneWidget);
  });

  testWidgets('an ApiProblem shows the sentence of its code and a retry that calls onRetry', (tester) async {
    var retried = 0;
    await tester.pumpWidget(
      host(GzAsyncView<int>(value: AsyncError<int>(_slotProblem, StackTrace.empty), data: (d) => Text('$d'), onRetry: () => retried++)),
    );
    expect(find.byType(GzErrorState), findsOneWidget);
    // the sentence opens from the state's info glyph (GzEmptyState design), so it is on the widget, not drawn
    expect(tester.widget<GzErrorState>(find.byType(GzErrorState)).body, 'That date is no longer available. Pick another date.');
    await tester.tap(find.byType(GzButton));
    expect(retried, 1);
  });

  testWidgets('the error sentence is Arabic in Arabic', (tester) async {
    await tester.pumpWidget(
      host(GzAsyncView<int>(value: AsyncError<int>(_slotProblem, StackTrace.empty), data: (d) => Text('$d')), locale: const Locale('ar')),
    );
    expect(tester.widget<GzErrorState>(find.byType(GzErrorState)).body, 'هذا التاريخ لم يعد متاحاً. يُرجى تحديد تاريخ آخر.');
    expect(find.text('تعذّر التحميل'), findsOneWidget); // the title
  });

  testWidgets('an offline problem shows the offline state, anything else the error state', (tester) async {
    await tester.pumpWidget(host(GzAsyncView<int>(value: AsyncError<int>(const ApiProblem.offline(), StackTrace.empty), data: (d) => Text('$d'))));
    expect(find.byType(GzOfflineState), findsOneWidget);
    expect(find.byType(GzErrorState), findsOneWidget); // the offline state is the network error state

    await tester.pumpWidget(host(GzAsyncView<int>(value: AsyncError<int>(StateError('x'), StackTrace.empty), data: (d) => Text('$d'))));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(GzOfflineState), findsNothing);
    expect(find.byType(GzErrorState), findsOneWidget);
  });

  testWidgets('a retry in flight keeps the error on screen with its button busy', (tester) async {
    var calls = 0;
    final provider = FutureProvider<int>((ref) {
      if (++calls == 1) throw _slotProblem;
      return Completer<int>().future; // the second attempt is still running
    });
    final container = ProviderContainer(retry: gzProviderRetry);
    addTearDown(container.dispose);
    container.listen(provider, (_, _) {});
    await tester.runAsync(() => container.read(provider.future).then<void>((_) {}, onError: (Object _) {}));
    container.invalidate(provider);
    final retrying = container.read(provider);
    expect(retrying.isLoading && retrying.hasError, isTrue);
    await tester.pumpWidget(host(GzAsyncView<int>(value: retrying, data: (d) => Text('$d'), onRetry: () {})));
    expect(find.byType(GzDefaultLoading), findsNothing);
    expect(tester.widget<GzErrorState>(find.byType(GzErrorState)).retrying, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('states cross-fade: both are present part-way, only the new one after 200 ms', (tester) async {
    Widget view(AsyncValue<int> v) => host(GzAsyncView<int>(value: v, data: (d) => Text('value $d', key: const ValueKey('data'))));
    await tester.pumpWidget(view(const AsyncLoading<int>()));
    await tester.pumpWidget(view(const AsyncData(7)));
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(GzDefaultLoading), findsOneWidget);
    expect(find.text('value 7'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 260));
    expect(find.byType(GzDefaultLoading), findsNothing);
    expect(find.text('value 7'), findsOneWidget);
  });

  testWidgets('reduced motion shortens the cross-fade to the 120 ms fade', (tester) async {
    Widget view(AsyncValue<int> v) => host(GzAsyncView<int>(value: v, data: (d) => Text('value $d')), reduced: true);
    await tester.pumpWidget(view(const AsyncLoading<int>()));
    await tester.pumpWidget(view(const AsyncData(7)));
    await tester.pump(const Duration(milliseconds: 130));
    expect(find.byType(GzDefaultLoading), findsNothing);
  });

  testWidgets('new data of the same state rebuilds in place with no cross-fade', (tester) async {
    Widget view(int n) => host(GzAsyncView<int>(value: AsyncData(n), data: (d) => Text('value $d')));
    await tester.pumpWidget(view(1));
    await tester.pumpWidget(view(2));
    expect(find.text('value 2'), findsOneWidget);
    expect(find.text('value 1'), findsNothing);
  });

  test('gzProblemKind maps access and not-found codes to their illustrated errors', () {
    expect(gzProblemKind(const ApiProblem(status: 403, code: ApiProblemCode.forbidden)), GzErrorKind.noAccess);
    expect(gzProblemKind(const ApiProblem(status: 404, code: ApiProblemCode.notFound)), GzErrorKind.notFound);
    expect(gzProblemKind(const ApiProblem.offline()), GzErrorKind.network);
    expect(gzProblemKind(_slotProblem), GzErrorKind.load);
  });
}
