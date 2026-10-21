// Flow test of staff access (HL-ACCS-01..04): the real router and the in-process mock, real taps. The persona rule runs access as a guest.
import 'package:flutter/widgets.dart' show EditableText, Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'package:provider_app/features/access/presentation/hl_accs_01.dart';
import 'package:provider_app/features/access/presentation/hl_accs_02.dart';
import 'package:provider_app/features/access/presentation/hl_accs_03.dart';
import 'package:provider_app/features/access/presentation/hl_accs_04.dart';
import 'package:provider_app/features/today/presentation/hl_tody_01.dart';

import '../../support/flow_world.dart';

void main() {
  flowTest('Sign in: the demo account verifies the new device by email code and lands on Today with the first-run sheet', (tester) async {
    await openScreen(tester, 'HL-ACCS-01');
    expect(find.byType(HlAccs01Screen), findsOneWidget);
    expect(find.byType(GzTabBar), findsNothing); // access hides the tab bar
    await tap(tester, find.text('Sign in'));
    expect(find.byType(HlAccs02Screen), findsOneWidget);
    await tester.enterText(find.byType(EditableText).first, '123456');
    await settle(tester);
    await tester.pump(const Duration(seconds: 2)); // the success beat before Today
    await settle(tester);
    expect(find.byType(HlTody01Screen), findsOneWidget);
    expect(
      GzNavigatorScope.of(tester.element(find.byType(HlTody01Screen))).params['firstRun'],
      isTrue,
    ); // the first sign-in carries the first-run flag
    expect(find.text('Allow notifications'), findsWidgets); // first run: the notifications sheet, then the lock
  });

  flowTest('Sign in: a wrong password says so in words and keeps the form', (tester) async {
    await openScreen(tester, 'HL-ACCS-01');
    final password = find.byType(EditableText).at(1);
    await tester.enterText(password, 'not-the-password');
    await settle(tester);
    await tap(tester, find.text('Sign in'));
    expect(find.text('Incorrect details'), findsOneWidget);
    expect(find.byType(HlAccs01Screen), findsOneWidget);
  });

  flowTest('Forgot: the reset code leads to the new password screen without the invitation card', (tester) async {
    await openScreen(tester, 'HL-ACCS-01');
    await tap(tester, find.text('Forgot?'));
    expect(find.byType(HlAccs02Screen), findsOneWidget);
    await tester.enterText(find.byType(EditableText).first, '123456');
    await settle(tester);
    expect(find.byType(HlAccs03Screen), findsOneWidget);
    expect(find.text('New password'), findsOneWidget);
    expect(find.text('Aurelia Gulf Hotel'), findsNothing);
  });

  flowTest('Invitation: the sheet opens the link, the card names the venue, the role and who invited, Save signs in', (tester) async {
    await openScreen(tester, 'HL-ACCS-01');
    await tap(tester, find.text('Invitation'));
    expect(find.text('Invitation only'), findsOneWidget);
    await tap(tester, find.text('Open link'));
    expect(find.byType(HlAccs03Screen), findsOneWidget);
    expect(find.text('Aurelia Gulf Hotel'), findsWidgets);
    expect(find.text('Khalid Al-Otaibi'), findsWidgets);
    await tap(tester, find.text('Save'));
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(find.byType(HlTody01Screen), findsOneWidget);
  });

  flowTest('Account status: one calm screen, one next step, Contact support shows the contact', (tester) async {
    await openScreen(tester, 'HL-ACCS-04');
    expect(find.byType(HlAccs04Screen), findsOneWidget);
    expect(find.text('Under review'), findsOneWidget);
    expect(find.text('Aurelia Gulf Hotel'), findsOneWidget);
    await tap(tester, find.text('Contact support'));
    expect(find.text('Ghazal Support'), findsWidgets);
  });

  flowTest('Offline: Sign in says an internet connection is needed instead of failing', (tester) async {
    await openScreen(tester, 'HL-ACCS-01', state: 'offline');
    await tap(tester, find.text('Sign in'));
    expect(find.text('You’re offline'), findsOneWidget);
  });

  flowTest('Arabic run: the language chip offers English and flips the screen in place', (tester) async {
    await openScreen(tester, 'HL-ACCS-01', locale: const Locale('ar'));
    expect(find.text('تسجيل الدخول'), findsWidgets);
    await tap(tester, find.bySemanticsLabel(RegExp('English')));
    expect(find.text('Sign in'), findsWidgets);
  });
}
