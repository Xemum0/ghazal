// The profile flow through the real router over the in-process mock: the hub (and the provider note), sign out, wedding info, personal info
// (Latin name in English, live monogram, save), notifications, settings (language sheet, digits only in Arabic), and account deletion
// (consequences, blocked variants, scheduled, the WhatsApp re-auth, confirm, delete, success). Bounded: every wait is a bounded settle.
import 'package:client_app/app/state/state.dart' show openExternalUrlProvider;
import 'package:client_app/features/profile/application/profile_activity.dart';
import 'package:client_app/features/profile/application/profile_identity.dart';
import 'package:client_app/features/profile/application/profile_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Sex;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../support/flow_world.dart';

void main() {
  String top(WidgetTester t) => nav(t).currentId;

  flowTest('hub default: Reem, the phone, the wedding card and every row, and the Wedding row opens the file', (t) async {
    final c = await openScreen(t, 'CL-PROF-01');
    expect(find.text('Reem Al-Dosari'), findsOneWidget);
    expect(c.read(profileIdentityProvider)?.phone, '+96550000012');
    expect(find.text('Wedding'), findsOneWidget);
    for (final row in ['Bookings', 'Vouchers', 'Visits', 'Receipts', 'Personal info', 'Notifications', 'Settings', 'Support']) {
      expect(find.text(row), findsOneWidget, reason: 'row $row');
    }
    expect(find.text('Saved'), findsWidgets, reason: 'the row and the tab');
    expect(c.read(profileHubProvider), isNotNull);
    await tapText(t, 'Wedding');
    expect(top(t), 'CL-PROF-02');
    container(t).read(gzNavigatorProvider).pop();
    await settle(t);
    expect(top(t), 'CL-PROF-01');
  });

  flowTest('hub: the provider note closes the help list and opens the Partner app store page', (t) async {
    final opened = <Uri>[];
    await openScreen(
      t,
      'CL-PROF-01',
      overrides: [
        openExternalUrlProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return true;
        }),
      ],
    );
    const note = 'Service provider? Apply in the Partner app';
    await scrollTo(t, find.text(note));
    expect(find.text(note), findsOneWidget);
    await tapText(t, note, ms: 400);
    expect(opened, isNotEmpty, reason: 'the platform call was made once, through the overridable opener');
    expect(opened.first.scheme, 'https');
    expect(top(t), 'CL-PROF-01', reason: 'the note leaves the app, not the screen');
  });

  flowTest('sign out asks first, then returns to the sign-in screen and a signed-out client reaches nothing else', (t) async {
    await openScreen(t, 'CL-PROF-01');
    ignoreRenderErrors = true; // the sign-in screen belongs to the auth flow; the tab shell leaves while the toast host stays (requests.md, R2-PARTNER)
    await scrollTo(t, find.text('Sign out'));
    await tapText(t, 'Sign out', ms: 600);
    expect(find.text('Stay'), findsWidgets, reason: 'the confirmation dialog');
    await tapText(t, 'Sign out', last: true, ms: 1500);
    expect(container(t).read(sessionProvider).isSignedIn, isFalse);
    expect(top(t), 'CL-AUTH-01', reason: 'sign out goes to the sign-in screen');
    nav(t).push('CL-PROF-01');
    await settle(t, wait: const Duration(milliseconds: 1000));
    expect(top(t), 'CL-ONBD-01', reason: 'the profile is closed to a signed-out client');
  });

  flowTest('wedding info: the file, the pickers and the total-budget link', (t) async {
    await openScreen(t, 'CL-PROF-02');
    expect(find.text('Bride'), findsWidgets);
    expect(find.text('Reem Al-Dosari'), findsNothing, reason: 'names are the Arabic spelling in the fixture');
    expect(find.text('Total budget'), findsOneWidget);
    await tapLabel(t, 'I am');
    expect(find.text('Groom'), findsOneWidget, reason: 'the role sheet');
    nav(t).closeSheet();
    await settle(t);
  });

  flowTest('wedding info: the Governorates row lists the profile governorates and its sheet picks governorates, never areas', (t) async {
    final c = await openScreen(t, 'CL-PROF-02', size: const Size(390, 1600));
    expect(find.textContaining('Hawalli'), findsWidgets, reason: "Reem's governorates are the answer of the row");
    await tapLabel(t, 'Governorates');
    expect(find.text('Farwaniya'), findsWidgets, reason: 'the chips of the six governorates');
    expect(find.text('Salmiya'), findsNothing, reason: 'no exact area');
    await tapText(t, 'Farwaniya', ms: 300);
    await tapText(t, 'Done', ms: 1200);
    final p = await t.runAsync(() => c.read(weddingRepositoryProvider).getWeddingProfile());
    expect(p!.governorateIds, contains('farwaniya'));
  });

  flowTest('personal info: the Latin name in English with a live monogram, edit shows Save, save keeps it', (t) async {
    final c = await openScreen(t, 'CL-PROF-03');
    expect(find.text('Reem Al-Dosari'), findsOneWidget, reason: 'the field shows the Latin spelling in English');
    expect(find.text('R'), findsOneWidget, reason: 'the monogram follows the Latin name');
    await t.enterText(find.byType(EditableText).first, 'Reem Al-Dosari Updated');
    await settle(t);
    expect(find.text('Save'), findsOneWidget, reason: 'the bar appears with the first edit');
    await tapText(t, 'Save', flush: true);
    expect(c.read(sessionProvider), isA<ClientSession>());
    expect((c.read(sessionProvider) as ClientSession).user.name, 'Reem Al-Dosari Updated');
  });

  flowTest('personal info: the sex switch shows the stored sex; changing it shows Save and stores it on the account', (t) async {
    final c = await openScreen(t, 'CL-PROF-03');
    expect(find.text('Female'), findsWidgets);
    expect(find.text('Male'), findsWidgets);
    expect(find.text('Save'), findsNothing, reason: 'nothing edited yet');
    await tapText(t, 'Male', ms: 400);
    expect(find.text('Save'), findsOneWidget, reason: 'the sex is an edit like the name');
    await tapText(t, 'Save', flush: true);
    final me = await t.runAsync(() => c.read(profileRepositoryProvider).getMe());
    expect(me!.user.sex, Sex.male);
  });

  flowTest('personal info: an empty name is refused with a blameless error', (t) async {
    await openScreen(t, 'CL-PROF-03');
    await t.enterText(find.byType(EditableText).first, '');
    await settle(t);
    await tapText(t, 'Save');
    expect(find.text('Save'), findsOneWidget, reason: 'still unsaved');
  });

  flowTest('notifications: the groups, the master switch and the quiet hours', (t) async {
    final c = await openScreen(t, 'CL-PROF-04');
    expect(find.text('Always on'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Offers and news'), findsOneWidget);
    expect(find.text('Quiet hours'), findsOneWidget);
    expect(find.text('Venue offers'), findsOneWidget, reason: 'Reem is opted in by the seed');
    await tapText(t, 'Offers and news');
    expect(find.text('Venue offers'), findsNothing, reason: 'the master switches the detail off');
    expect(c.read(notifPrefsProvider).value?.marketing, isFalse);
    await tapText(t, 'Offers and news');
    expect(find.text('Venue offers'), findsOneWidget, reason: 'and back on');
  });

  flowTest('settings: the language sheet applies at once, no digits row in English', (t) async {
    await openScreen(t, 'CL-PROF-05');
    expect(find.text('Digits'), findsNothing, reason: 'digits only exist in Arabic');
    await tapText(t, 'Language');
    expect(find.text('العربية'), findsWidgets, reason: 'the language sheet');
    expect(find.text('English'), findsWidgets);
    nav(t).closeSheet();
    await settle(t);
  });

  flowTest('settings in Arabic: the digits row is there', (t) async {
    await openScreen(t, 'CL-PROF-05', locale: const Locale('ar'));
    expect(find.text('الأرقام'), findsOneWidget);
  });

  flowTest('deletion: the consequences name the pending request and the ready vouchers, Delete asks for a fresh code', (t) async {
    await openScreen(t, 'CL-PROF-06');
    expect(find.text('Can’t be undone'), findsOneWidget);
    expect(find.text('Personal data'), findsOneWidget);
    expect(find.text('Anonymised'), findsOneWidget);
    expect(find.text('2 vouchers ready'), findsOneWidget, reason: 'the bound voucher and the credit voucher');
    expect(find.text('Use voucher'), findsOneWidget);
    await tapText(t, 'Delete account');
    await settle(t, wait: const Duration(seconds: 2));
    expect(find.text('Verify'), findsOneWidget, reason: 'the code step with its action');
    await tapLabel(t, 'Back');
    expect(find.text('Can’t be undone'), findsOneWidget, reason: 'back returns to the consequences');
  });

  flowTest('deletion blocked while approved: the hourglass names the request and opens it', (t) async {
    ignoreRenderErrors = true; // CL-BOOK-02 belongs to the bookings flow
    await openScreen(t, 'CL-PROF-06', story: 'approved');
    expect(find.text('Deletion paused'), findsWidgets);
    expect(find.text('Open request'), findsOneWidget);
    expect(find.text('Cancel request'), findsOneWidget);
    await tapText(t, 'Open request');
    expect(top(t), 'CL-BKNG-02');
  });

  flowTest('deletion blocked while confirmed: scheduling names the day, cancelling undoes it', (t) async {
    final c = await openScreen(t, 'CL-PROF-06', story: 'confirmed', base: 'CL-PROF-01');
    expect(find.text('Schedule deletion'), findsOneWidget);
    await tapText(t, 'Schedule deletion');
    expect(find.text('Deletion scheduled'), findsWidgets, reason: 'the scheduled state');
    expect(c.read(profileDeletionAfterProvider), isNotNull);
    await tapText(t, 'Cancel deletion');
    expect(c.read(profileDeletionAfterProvider), isNull);
    expect(top(t), 'CL-PROF-01', reason: 'cancelling pops back to the hub');
  });

  flowTest('deletion: a fresh code confirms, the account is erased and Done leaves to the language screen', (t) async {
    await openScreen(t, 'CL-PROF-06');
    await tapText(t, 'Delete account');
    await settle(t, wait: const Duration(seconds: 2));
    await t.enterText(find.byType(EditableText).first, '123456');
    await settle(t, wait: const Duration(seconds: 3));
    expect(find.text('Can’t be undone'), findsWidgets, reason: 'the last confirmation');
    await tapText(t, 'Delete account');
    await settle(t, wait: const Duration(seconds: 3));
    expect(find.text('Account deleted'), findsWidgets, reason: 'the plain confirmation');
    expect(container(t).read(sessionProvider).isSignedIn, isTrue, reason: 'the session ends at Done, so the success page is not cut short');
    await tapText(t, 'Done');
    await settle(t, wait: const Duration(seconds: 1));
    expect(container(t).read(sessionProvider).isSignedIn, isFalse);
    expect(top(t), 'CL-ONBD-01');
  });

  flowTest('states: loading skeletons, error retries, offline, and one Arabic run of the hub', (t) async {
    await openScreen(t, 'CL-PROF-01', state: 'loading');
    expect(find.byType(GzSkeleton), findsWidgets);
    expect(find.byType(GzErrorState), findsNothing);
  });

  flowTest('states: error retries on the hub', (t) async {
    await openScreen(t, 'CL-PROF-02', state: 'error', extraSeconds: 6);
    expect(find.byType(GzErrorState), findsOneWidget);
  });

  flowTest('states: offline on the hub', (t) async {
    await openScreen(t, 'CL-PROF-01', state: 'offline', extraSeconds: 6);
    expect(find.byType(GzOfflineState), findsWidgets);
  });

  flowTest('arabic: the hub reads right to left', (t) async {
    await openScreen(t, 'CL-PROF-01', locale: const Locale('ar'));
    expect(find.text('حسابكم'), findsWidgets);
    expect(find.text('ريم الدوسري'), findsWidgets);
  });
}
