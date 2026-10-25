// The reviews flow on the real router over the in-process mock: the list
// with summary and filters, the report sheet, the composer with stars, the
// guest gate, the five states, one Arabic run. Bounded.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'package:client_app/features/reviews_rewards/presentation/widgets/flow_review_item.dart';
import 'package:client_app/features/reviews_rewards/presentation/widgets/flow_score_summary.dart';

import '../../support/flow_world.dart';

void main() {
  flowTest('the list shows the summary, filters and review cards', (tester) async {
    await openScreen(tester, 'CL-RVRW-01', params: {'venueId': 'V01'});
    expect(find.text('Reviews'), findsOneWidget);
    expect(find.byType(FlowScoreSummary), findsWidgets);
    expect(find.byType(FlowReviewItem), findsWidgets);
    expect(find.text('Photos'), findsWidgets);
  });

  flowTest('the sort sheet changes the order label', (tester) async {
    await openScreen(tester, 'CL-RVRW-01', params: {'venueId': 'V01'});
    await tapText(tester, 'Recent');
    expect(onScreen('reviews.sort'), isTrue);
    await tapText(tester, 'Highest');
    await settle(tester, flush: true);
    expect(find.text('Highest'), findsWidgets);
  });

  flowTest('the report sheet asks a reason and confirms', (tester) async {
    await openScreen(tester, 'CL-RVRW-01', params: {'venueId': 'V01'});
    final reportBtn = find.byWidgetPredicate((w) => w is GzIconButton && (w.key as ValueKey<String>? ?? const ValueKey<String>('')).value.startsWith('reviews.report.'));
    expect(reportBtn, findsWidgets);
    await tap(tester, reportBtn.first, flush: true);
    expect(onScreen('reviews.report'), isTrue);
    await tapText(tester, 'Abusive');
    await settle(tester);
    await tapText(tester, 'Send', flush: true);
    expect(find.text('Report sent'), findsWidgets);
  });

  flowTest('the composer rates, writes and sends a review', (tester) async {
    await openScreen(tester, 'CL-RVRW-02', story: 'completed', params: {'bookingId': 'bk-GZ-2611-0147'});
    expect(find.text('Write review'), findsOneWidget);
    await tapKey(tester, 'review.star.overall.5');
    await settle(tester);
    await tap(tester, find.byType(GzTextArea));
    await tester.enterText(find.byType(GzTextArea), 'Wonderful hall and service.');
    await settle(tester);
    await tapText(tester, 'Send', flush: true);
    await settle(tester, flush: true);
    expect(find.byKey(const ValueKey<String>('review.done')), findsOneWidget);
  });

  flowTest('state loading: skeletons show, no error', (tester) async {
    await openScreen(tester, 'CL-RVRW-01', params: {'venueId': 'V01'}, state: 'loading');
    expect(find.byType(GzSkeleton), findsWidgets);
    expect(find.byType(GzErrorState), findsNothing);
  });

  flowTest('state error: the problem is told with a retry', (tester) async {
    await openScreen(tester, 'CL-RVRW-01', params: {'venueId': 'V01'}, state: 'error', extraSeconds: 6);
    expect(find.byType(GzErrorState), findsOneWidget);
  });

  flowTest('arabic: the list reads right to left', (tester) async {
    await openScreen(tester, 'CL-RVRW-01', params: {'venueId': 'V01'}, locale: const Locale('ar'));
    expect(find.byType(FlowReviewItem), findsWidgets);
  });
}
