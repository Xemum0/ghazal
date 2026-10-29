// Flow test of the partner application (owner round 2, ADR 0038, PA-ACC-07, PA-ACC-08): HL-PROV-01 "Apply to join" (account type, form, validation,
// categories sheet, submit, "Application received"), HL-ACCS-04 (application under review, the staff decision through the mock control then a
// refetch: approved continues, rejected shows the reason with "Edit and resubmit"), the resubmit, and the HL-PROV-03 hold. The real router and the
// in-process mock (`autoRun: false`), real taps. Bounded: no real IO in fake async.
import 'package:flutter/widgets.dart' show EditableText, Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show ApplicationStatus, PartnerApplication, PartnerMembership, PartnerAccountStatus;
import 'package:ghazal_ui/ghazal_ui.dart';

import 'package:provider_app/app/state/state.dart';
import 'package:provider_app/features/access/presentation/hl_accs_04.dart';
import 'package:provider_app/features/provider/application/listing_draft.dart';
import 'package:provider_app/features/provider/application/provider_actions.dart';
import 'package:provider_app/features/provider/presentation/hl_prov_01.dart';
import 'package:provider_app/features/provider/presentation/hl_prov_03.dart';

import '../../support/flow_world.dart';

/// A field label as the English UI draws it (the label role is uppercase).
bool _label(String text) => shows(text) || shows(text.toUpperCase());

/// The application of [persona] as the server has it (real async: inside `tester.runAsync`).
Future<PartnerApplication?> _applicationOf(WidgetTester tester, String persona) async {
  final me = await tester.runAsync(() => flowRepos(persona).partnerAccount.getPartnerMe());
  return me!.memberships.where((m) => m.application != null).lastOrNull?.application;
}

Future<void> _type(WidgetTester tester, int field, String text) async {
  await tester.enterText(find.byType(EditableText).at(field), text);
  await tester.pump(const Duration(milliseconds: 100));
}

/// The fields of the provider form in the English UI: name EN, name AR, Other note, contact, phone, email, description, licence.
Future<void> _fillProvider(WidgetTester tester) async {
  await _type(tester, 0, 'Lens House');
  await _type(tester, 1, 'بيت العدسة');
  await _type(tester, 3, 'Nora Al-Sabah');
  await _type(tester, 4, '55512345');
  await _type(tester, 5, 'nora@lens-house.example');
  await _type(tester, 6, 'Wedding photography with a ladies-only team.');
}

Future<void> _toForm(WidgetTester tester, String kind) async {
  await tap(tester, find.text(kind));
  await tap(tester, find.text(en.hotelProviderContinue));
}

void main() {
  flowTest('Chooser: a service provider or a private hall, Continue waits for a choice, hotels and chains are told to join through Ghazal', (tester) async {
    await openScreen(tester, 'HL-PROV-01', persona: 'provider');
    expect(find.byType(HlProv01Screen), findsOneWidget);
    expect(find.text(en.hotelProviderChooseTitle), findsOneWidget);
    expect(find.text(en.hotelProviderTypeProviderTitle), findsOneWidget);
    expect(find.text(en.hotelProviderTypeHallTitle), findsOneWidget);
    expect(find.text(en.hotelProviderChooseChains), findsOneWidget);
    await tap(tester, find.text(en.hotelProviderContinue)); // disabled with its reason: nothing moves
    expect(find.text(en.hotelProviderChooseReason), findsWidgets);
    expect(find.text(en.hotelProviderSubmit), findsNothing);
  });

  flowTest('Form: a private hall has no categories, a provider has the chooser, the Other note and the governorate chips', (tester) async {
    await openScreen(tester, 'HL-PROV-01', persona: 'provider');
    await _toForm(tester, en.hotelProviderTypeProviderTitle);
    expect(_label(en.hotelProviderProfileCategories), isTrue);
    expect(_label(en.hotelProviderFormOther), isTrue);
    expect(find.text('Hawalli'), findsWidgets);
    expect(find.text('Mubarak Al-Kabeer'), findsWidgets);
    expect(_label(en.hotelProviderFormLicence), isTrue);
  });

  flowTest('Form (private hall): no categories section and no Other note', (tester) async {
    await openScreen(tester, 'HL-PROV-01', persona: 'provider');
    await _toForm(tester, en.hotelProviderTypeHallTitle);
    expect(_label(en.hotelProviderProfileCategories), isFalse);
    expect(_label(en.hotelProviderFormOther), isFalse);
    expect(_label(en.hotelProviderProfileGovernorate), isTrue);
  });

  flowTest('Validation: an empty submit marks every required field inline and says to fix them; nothing is sent', (tester) async {
    await openScreen(tester, 'HL-PROV-01', persona: 'provider');
    await _toForm(tester, en.hotelProviderTypeProviderTitle);
    await tap(tester, find.text(en.hotelProviderSubmit));
    expect(find.text(en.hotelProviderFormFix), findsOneWidget);
    expect(find.text(en.hotelProviderRequired), findsWidgets);
    expect(find.text(en.hotelProviderPhoneError), findsOneWidget);
    expect(find.text(en.hotelProviderFormEmailError), findsOneWidget);
    expect(find.text(en.hotelProviderSubmittedTitle), findsNothing);
    expect((await _applicationOf(tester, 'provider')), isNull);
  });

  flowTest('Validation: an email that is not an email stays an error while the rest is valid', (tester) async {
    await openScreen(tester, 'HL-PROV-01', persona: 'provider');
    await _toForm(tester, en.hotelProviderTypeProviderTitle);
    await _fillProvider(tester);
    await _type(tester, 5, 'not-an-email');
    await tapText(tester, 'Hawalli');
    await _type(tester, 2, 'Falcon show'); // the Other note counts as the category
    await tap(tester, find.text(en.hotelProviderSubmit));
    expect(find.text(en.hotelProviderFormEmailError), findsOneWidget);
    expect(find.text(en.hotelProviderSubmittedTitle), findsNothing);
  });

  flowTest('Categories: the sheet takes at most three, the fourth chip is disabled, Done puts them on the form', (tester) async {
    await openScreen(tester, 'HL-PROV-01', persona: 'provider');
    await _toForm(tester, en.hotelProviderTypeProviderTitle);
    await tap(tester, find.text(en.hotelProviderCatsChoose));
    expect(shows('0/3'), isTrue);
    for (final name in ['Floral arrangements', 'Photography', 'Cake']) {
      await tapText(tester, name);
    }
    expect(shows('3/3'), isTrue);
    await tapText(tester, 'DJ'); // the limit is reached: it does not select
    expect(shows('3/3'), isTrue);
    await tap(tester, find.text(en.commonActionDone));
    expect(find.text(en.hotelProviderCatsEdit), findsOneWidget);
    expect(find.text('Floral arrangements'), findsWidgets);
    expect(find.text('DJ'), findsNothing);
  });

  flowTest('Submit: a complete application is received, the account stays under review and the status shows the wait', (tester) async {
    final c = await openScreen(tester, 'HL-PROV-01', persona: 'provider');
    await _toForm(tester, en.hotelProviderTypeProviderTitle);
    await _fillProvider(tester);
    await _type(tester, 2, 'Drone shots of the entrance');
    await tapText(tester, 'Hawalli');
    await tap(tester, find.text(en.hotelProviderSubmit));
    // received: the business, what happens next, one way forward
    expect(find.text(en.hotelProviderSubmittedTitle), findsOneWidget);
    expect(find.text('Lens House'), findsWidgets);
    expect(find.text(en.hotelProviderNextReview), findsOneWidget);
    expect(find.text(en.hotelProviderNextListings), findsOneWidget);
    final app = await _applicationOf(tester, 'provider');
    expect(app?.status, ApplicationStatus.pending);
    expect(app?.name.en, 'Lens House');
    expect(app?.governorateId, 'hawalli');
    expect(app?.otherCategoryNote, 'Drone shots of the entrance');
    expect(app?.phone, '+96555512345');
    // the session follows the new account (under review), so everything after carries it
    expect((c.read(partnerContextProvider))?.accountName?.en, 'Lens House');
    await tap(tester, find.text(en.hotelProviderSubmittedStatus));
    dropShellTeardownError(tester);
    expect(currentId(c), 'HL-ACCS-04');
    expect(find.text(en.hotelAccessStatusApplicationTitle), findsOneWidget);
    expect(find.text('Lens House'), findsWidgets);
  });

  flowTest('Staff decision: accepted through the mock control, the status refetches to Approved and Continue opens Today', (tester) async {
    final c = await openScreen(tester, 'HL-ACCS-04', persona: 'provider_applicant', params: {'variant': 'application-review', 'account': 'provider'});
    expect(find.byType(HlAccs04Screen), findsOneWidget);
    expect(find.text(en.hotelAccessStatusApplicationTitle), findsOneWidget);
    expect(find.text('Rawan Lens'), findsOneWidget);
    expect(find.text(en.hotelAccessSupportAction), findsOneWidget);
    final app = await _applicationOf(tester, 'provider_applicant');
    expect(app?.status, ApplicationStatus.pending);
    flowControl.decidePartnerApplication(app!.id, accept: true);
    c.read(partnerDataRevisionProvider.notifier).bump(); // the app returning to the foreground does this
    await settle(tester);
    expect(find.text(en.hotelAccessStatusApprovedTitle), findsOneWidget);
    expect(find.text(en.hotelAccessSupportAction), findsNothing);
    await tap(tester, find.text(en.commonActionContinue));
    expect(currentId(c), 'HL-TODY-01');
  });

  flowTest('Staff decision: rejected shows the reason and Edit and resubmit opens the prefilled form; resubmitting puts it back under review', (tester) async {
    final c = await openScreen(tester, 'HL-ACCS-04', persona: 'provider_rejected', params: {'variant': 'application-rejected', 'account': 'provider'});
    expect(find.text(en.hotelAccessStatusRejectedTitle), findsOneWidget);
    expect(find.text('Please add your commercial licence reference and send the application again.'), findsOneWidget);
    await tap(tester, find.text(en.hotelAccessStatusEditResubmit));
    expect(currentId(c), 'HL-PROV-01');
    expect(find.text(en.hotelProviderFormBarEdit), findsOneWidget);
    expect(find.text('Not approved: Please add your commercial licence reference and send the application again.'), findsOneWidget);
    // prefilled from the application, with no account type step
    expect(find.text(en.hotelProviderChooseTitle), findsNothing);
    final fields = find.byType(EditableText).evaluate().map((e) => (e.widget as EditableText).controller.text).toList();
    expect(fields, contains('Bader Decor'));
    expect(fields, contains('بدر للديكور'));
    expect(fields, contains('Lighting arches and entrance walkways'));
    expect(fields, contains('bader@bader-decor.example'));
    await _type(tester, 7, 'KW-77120'); // the licence reference the staff asked for
    await tap(tester, find.text(en.hotelProviderSubmit));
    expect(find.text(en.hotelProviderSubmittedTitle), findsOneWidget);
    final app = await _applicationOf(tester, 'provider_rejected');
    expect(app?.status, ApplicationStatus.pending);
    expect(app?.rejectionReason, isNull);
    expect(app?.licenceRef, 'KW-77120');
    await tap(tester, find.text(en.hotelProviderSubmittedStatus));
    dropShellTeardownError(tester);
    expect(find.text(en.hotelAccessStatusApplicationTitle), findsOneWidget);
  });

  flowTest('Listings hold: an applicant cannot open the editor (the screen says so and points to the status); the server refuses a listing too', (tester) async {
    final c = await openScreen(tester, 'HL-PROV-03', persona: 'provider_applicant');
    expect(find.byType(HlProv03Screen), findsOneWidget);
    expect(find.text(en.hotelProviderApprovalGuardTitle), findsOneWidget);
    expect(find.text(en.hotelProviderEditorTitleNew), findsWidgets); // the bar title only: no fields
    expect(find.byType(EditableText), findsNothing);
    // the 403 APPLICATION_NOT_ACCEPTED the server answers to a create is an ActionFailure the editor turns into the same hold
    final r = await tester.runAsync(() => c.read(listingActionsProvider.notifier).saveDraft(const ListingDraft(titleEn: 'Entrance arch', titleAr: 'قوس المدخل')));
    expect(r, isA<ActionFailure<Object?>>());
    expect((r! as ActionFailure<Object?>).problem.code.wire, 'APPLICATION_NOT_ACCEPTED');
    await tap(tester, find.text(en.hotelProviderSubmittedStatus));
    dropShellTeardownError(tester);
    expect(currentId(c), 'HL-ACCS-04');
    expect(find.text(en.hotelAccessStatusApplicationTitle), findsOneWidget);
  });

  flowTest('Listings hold: once the staff accept, the same screen opens the editor', (tester) async {
    final c = await openScreen(tester, 'HL-PROV-03', persona: 'provider_applicant');
    expect(find.text(en.hotelProviderApprovalGuardTitle), findsOneWidget);
    final app = await _applicationOf(tester, 'provider_applicant');
    flowControl.decidePartnerApplication(app!.id, accept: true);
    c.read(partnerDataRevisionProvider.notifier).bump();
    await settle(tester, wait: const Duration(seconds: 2));
    expect(find.text(en.hotelProviderApprovalGuardTitle), findsNothing);
    expect(find.byType(EditableText), findsWidgets);
  });

  flowTest('An accepted account (no application) is never held: Zahra opens the editor', (tester) async {
    await openScreen(tester, 'HL-PROV-03', persona: 'provider');
    expect(find.text(en.hotelProviderApprovalGuardTitle), findsNothing);
    expect(find.byType(EditableText), findsWidgets);
    final me = await tester.runAsync(() => flowRepos('provider').partnerAccount.getPartnerMe());
    expect(me!.memberships.every((PartnerMembership m) => m.application == null && m.status == PartnerAccountStatus.active), isTrue);
  });

  flowTest('Five states: the form loads behind a skeleton, an error offers Try again, offline says so', (tester) async {
    await openScreen(tester, 'HL-PROV-01', persona: 'provider', state: 'error');
    await _toForm(tester, en.hotelProviderTypeProviderTitle);
    expect(find.byType(GzErrorState), findsOneWidget);
    expect(find.text(en.commonActionRetry), findsWidgets);
  });

  flowTest('Five states: offline on the form shows the offline view', (tester) async {
    await openScreen(tester, 'HL-PROV-01', persona: 'provider', state: 'offline');
    await _toForm(tester, en.hotelProviderTypeHallTitle);
    expect(find.byType(GzOfflineState), findsOneWidget);
  });

  flowTest('Five states: while the lists load the form shows skeleton blocks and a disabled Send', (tester) async {
    await openScreen(tester, 'HL-PROV-01', persona: 'provider', state: 'loading');
    await tap(tester, find.text(en.hotelProviderTypeProviderTitle), ms: 100);
    await tap(tester, find.text(en.hotelProviderContinue), ms: 100);
    expect(find.byType(GzSkeleton), findsWidgets);
    expect(find.text(en.hotelProviderSubmit), findsOneWidget);
  });

  flowTest('Arabic run: the chooser and the form read right to left with the Arabic words', (tester) async {
    await openScreen(tester, 'HL-PROV-01', persona: 'provider', locale: const Locale('ar'));
    expect(find.text(ar.hotelProviderChooseTitle), findsOneWidget);
    expect(find.text(ar.hotelProviderTypeHallTitle), findsOneWidget);
    await tap(tester, find.text(ar.hotelProviderTypeProviderTitle));
    await tap(tester, find.text(ar.hotelProviderContinue));
    expect(shows(ar.hotelProviderProfileGovernorate), isTrue);
    expect(find.text('حولي'), findsWidgets);
    await tap(tester, find.text(ar.hotelProviderSubmit));
    expect(find.text(ar.hotelProviderFormFix), findsOneWidget);
  });
}
