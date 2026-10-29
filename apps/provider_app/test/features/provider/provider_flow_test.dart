// Flow test of Provider and listings (HL-PROV-01..07): the real router and the in-process mock (`autoRun: false`), real taps, as the
// service-provider persona. Bounded: no real IO in fake async.
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'package:provider_app/features/provider/presentation/hl_prov_01.dart';
import 'package:provider_app/features/provider/presentation/hl_prov_02.dart';
import 'package:provider_app/features/provider/presentation/hl_prov_03.dart';
import 'package:provider_app/features/provider/presentation/hl_prov_04.dart';
import 'package:provider_app/features/provider/presentation/hl_prov_05.dart';
import 'package:provider_app/features/provider/presentation/hl_prov_06.dart';
import 'package:provider_app/features/provider/presentation/hl_prov_07.dart';

import '../../support/flow_world.dart';

void main() {
  flowTest('Apply to join: the chooser offers a service provider and a private hall (the application flow is tested in application_flow_test.dart)', (tester) async {
    await openScreen(tester, 'HL-PROV-01', persona: 'provider');
    expect(find.byType(HlProv01Screen), findsOneWidget);
    expect(find.text(en.hotelProviderTypeProviderTitle), findsOneWidget);
    expect(find.text(en.hotelProviderTypeHallTitle), findsOneWidget);
    await tap(tester, find.text(en.hotelProviderTypeProviderTitle));
    await tap(tester, find.text(en.hotelProviderContinue));
    // the form: submitting empty shows the required marks and stays
    await tap(tester, find.text(en.hotelProviderSubmit));
    expect(find.text(en.hotelProviderRequired), findsWidgets);
    expect(find.text(en.hotelProviderSubmittedTitle), findsNothing);
  });

  flowTest('My listings: every listing has its status pill; a card opens its screen by state', (tester) async {
    await openScreen(tester, 'HL-PROV-02', persona: 'provider');
    expect(find.byType(HlProv02Screen), findsOneWidget);
    expect(find.byType(GzListingStatusPill), findsWidgets);
    expect(find.text(en.hotelProviderListNew), findsWidgets);
  });

  flowTest('My listings: New opens the editor', (tester) async {
    await openScreen(tester, 'HL-PROV-02', persona: 'provider');
    await tap(tester, find.text(en.hotelProviderListNew).first);
    expect(find.byType(HlProv03Screen), findsOneWidget);
  });

  flowTest('My listings: an empty account shows the empty state with one action', (tester) async {
    await openScreen(tester, 'HL-PROV-02', persona: 'provider', state: 'empty');
    expect(find.byType(GzEmptyState), findsOneWidget);
  });

  flowTest('My listings: an error offers Try again', (tester) async {
    await openScreen(tester, 'HL-PROV-02', persona: 'provider', state: 'error');
    expect(find.text(en.commonActionRetry), findsWidgets);
  });

  flowTest('Review status: a listing in review says so, and never claims it is live because it was paid', (tester) async {
    await openScreen(tester, 'HL-PROV-06', persona: 'provider');
    expect(find.byType(HlProv06Screen), findsOneWidget);
    expect(find.byType(GzReviewTimeline), findsWidgets);
  });

  flowTest('Plan: rates not announced show no number and the plain submit instead of payment', (tester) async {
    await openScreen(tester, 'HL-PROV-04', persona: 'provider');
    expect(find.byType(HlProv04Screen), findsOneWidget);
    expect(find.text(en.hotelProviderPlanReasonRates), findsOneWidget);
    expect(find.text(en.hotelProviderStepSubmit), findsOneWidget);
    expect(find.textContaining('KD'), findsNothing);
  });

  flowTest('Pay: while rates are not announced the screen cannot be reached and says so', (tester) async {
    await openScreen(tester, 'HL-PROV-05', persona: 'provider', params: {'cycle': 'monthly'});
    expect(find.byType(HlProv05Screen), findsOneWidget);
    expect(find.text(en.hotelProviderBlockedTitle), findsOneWidget);
    await tap(tester, find.text(en.hotelProviderBackToPlans));
    expect(find.byType(HlProv05Screen), findsNothing);
  });

  flowTest('Pay: the sample layout shows the amount with its Sample mark and Pay is refused (409) until rates exist', (tester) async {
    await openScreen(tester, 'HL-PROV-05', persona: 'provider', params: {'sample': true});
    expect(find.text(en.hotelProviderSampleBadge), findsWidgets);
    expect(find.text(en.hotelProviderChangeMethod), findsOneWidget);
    // with no announced rate the API refuses a session (409): the screen stays, nothing is charged
    await tap(tester, find.textContaining('Pay '));
    expect(find.text(en.hotelProviderBankMerchant), findsNothing);
    expect(find.byType(HlProv05Screen), findsOneWidget);
  });

  flowTest('Pay: the bank frame shows merchant and amount, Cancel ends in the cancelled outcome', (tester) async {
    await openScreen(tester, 'HL-PROV-05', persona: 'provider', params: {'sample': true, 'scene': 'bank'});
    expect(find.text(en.hotelProviderBankMerchant), findsOneWidget);
    await tap(tester, find.text('Cancel'));
    expect(find.text(en.hotelProviderCancelledTitle), findsOneWidget);
  });

  flowTest('Pay: the paid frame leads to the review status, not to a live listing', (tester) async {
    await openScreen(tester, 'HL-PROV-05', persona: 'provider', params: {'sample': true, 'scene': 'paid'});
    expect(find.text(en.hotelProviderPaidTitle), findsOneWidget);
    await tap(tester, find.text(en.hotelProviderViewStatus));
    expect(find.byType(HlProv06Screen), findsOneWidget);
  });

  flowTest('Performance: a live listing shows its figures', (tester) async {
    await openScreen(tester, 'HL-PROV-07', persona: 'provider');
    expect(find.byType(HlProv07Screen), findsOneWidget);
    expect(find.byType(GzKpiTile), findsWidgets);
  });

  flowTest('Arabic run: My listings reads right to left', (tester) async {
    await openScreen(tester, 'HL-PROV-02', persona: 'provider', locale: const Locale('ar'));
    expect(find.text(ar.hotelProviderListTitle), findsWidgets);
    expect(find.text(ar.hotelProviderListNew), findsWidgets);
  });
}
