import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show TextField;
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/inputs/inputs.dart';

import 'inputs_harness.dart';

TextField fieldOf(WidgetTester tester, [Finder? within]) =>
    tester.widget<TextField>(find.descendant(of: within ?? find.byType(GzTextField), matching: find.byType(TextField)));

void main() {
  group('GzTextField', () {
    testWidgets('label, hint and typing; the semantics carry the label and the hint', (tester) async {
      final handle = tester.ensureSemantics();
      final changes = <String>[];
      await pumpInputs(tester, GzTextField(label: 'Full name', helper: 'Arabic or English.', onValueChange: changes.add));
      expect(find.text('FULL NAME'), findsOneWidget); // label role is tracked caps in English
      expect(find.text('Arabic or English.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Reem');
      expect(changes, ['Reem']);
      final node = tester.getSemantics(find.byType(TextField));
      expect(node.label, contains('Full name'));
      expect(node.hint, contains('Arabic or English.'));
      expect(node.flagsCollection.isTextField, isTrue);
      handle.dispose();
    });

    testWidgets('the box is 56 high; focus turns the border ink and adds a 1 dp ring without moving anything', (tester) async {
      await pumpInputs(tester, const GzTextField(label: 'Name', forceFocus: true));
      await settle(tester);
      final box = find.descendant(of: find.byType(GzFieldShell), matching: find.byType(AnimatedContainer));
      expect(tester.getSize(box).height, GzSize.controlLg);
      final deco = tester.widget<AnimatedContainer>(box).decoration! as BoxDecoration;
      expect((deco.border! as Border).top.color, GzColors.light.borderFocus);
      expect(deco.boxShadow, hasLength(1));
      expect(deco.boxShadow!.single.spreadRadius, GzStroke.hair);
    });

    testWidgets('error: danger border, an icon and the message are shown (never colour alone)', (tester) async {
      await pumpInputs(tester, const GzTextField(label: 'Name', error: 'Required'));
      await settle(tester);
      expect(find.text('Required'), findsOneWidget);
      expect(find.byType(GzIcon), findsOneWidget);
      final box = find.descendant(of: find.byType(GzFieldShell), matching: find.byType(AnimatedContainer));
      final deco = tester.widget<AnimatedContainer>(box).decoration! as BoxDecoration;
      expect((deco.border! as Border).top.color, GzColors.light.borderError);
    });

    testWidgets('disabled: not editable and the stated reason replaces the hint', (tester) async {
      await pumpInputs(
        tester,
        const GzTextField(label: 'Date', defaultValue: 'Thu', disabled: true, disabledReason: 'Fixed once approved.', helper: 'ignored'),
      );
      expect(fieldOf(tester).enabled, isFalse);
      expect(find.text('Fixed once approved.'), findsOneWidget);
      expect(find.text('ignored'), findsNothing);
    });

    testWidgets('clearable: a clear button appears with a value and empties the field', (tester) async {
      final changes = <String>[];
      await pumpInputs(tester, GzTextField(defaultValue: 'abc', clearable: true, onValueChange: changes.add));
      expect(find.byType(GzInAction), findsOneWidget);
      await tester.tap(find.byType(GzInAction));
      await tester.pump();
      expect(changes.last, '');
      expect(find.byType(GzInAction), findsNothing);
    });

    testWidgets('an LTR island on an Arabic screen: left-to-right text that still starts at the screen start edge (right)', (tester) async {
      await pumpInputs(
        tester,
        const GzTextField(dir: GzFieldDir.ltr, defaultValue: 'reem@example.com'),
        lang: 'ar',
      );
      final f = fieldOf(tester);
      expect(f.textDirection, TextDirection.ltr);
      expect(f.textAlign, TextAlign.end);
      await pumpInputs(tester, const GzTextField(dir: GzFieldDir.ltr, defaultValue: 'reem@example.com'));
      expect(fieldOf(tester).textAlign, TextAlign.start);
    });

    testWidgets('a numeric keyboard normalises Eastern digits as they are typed', (tester) async {
      final changes = <String>[];
      await pumpInputs(tester, GzTextField(keyboardType: TextInputType.number, onValueChange: changes.add));
      await tester.enterText(find.byType(TextField), '٣٤٥');
      expect(changes.last, '345');
    });

    testWidgets('dir auto: the first strong letter decides; an empty field reads left to right', (tester) async {
      await pumpInputs(tester, const GzTextField(placeholder: 'الاسم'), lang: 'ar');
      expect(fieldOf(tester).textDirection, TextDirection.ltr);
      await tester.enterText(find.byType(TextField), 'ريم');
      await tester.pump();
      expect(fieldOf(tester).textDirection, TextDirection.rtl);
    });
  });

  group('GzPhoneField', () {
    testWidgets('masks 4 + 4, normalises Eastern digits and prefixes, caps at eight digits', (tester) async {
      final seen = <GzPhoneChange>[];
      await pumpInputs(tester, GzPhoneField(onChange: (n, info) => seen.add(info)));
      await tester.enterText(find.byType(TextField), '٥٠٠٠٠٠١٢');
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '5000 0012');
      expect(seen.last.national, '50000012');
      expect(seen.last.valid, isTrue);
      expect(seen.last.e164, '+96550000012');
      await tester.enterText(find.byType(TextField), '+965 5000 0012');
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '5000 0012');
      await tester.enterText(find.byType(TextField), '500000123456');
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '5000 0012');
      expect(find.byType(GzIcon), findsOneWidget); // the valid check
    });

    testWidgets('a malformed number shows the shared error after blur, not while typing', (tester) async {
      await pumpInputs(tester, const GzPhoneField(helper: 'We send a code.'));
      await tester.enterText(find.byType(TextField), '7000');
      await tester.pump();
      expect(find.text('We send a code.'), findsOneWidget);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(find.text('We send a code.'), findsNothing);
      expect(find.byType(GzIcon), findsOneWidget); // the warning icon of the error line
    });

    testWidgets('the compound reads left to right in both languages: chip left, value at the screen start (right in Arabic)', (
      tester,
    ) async {
      for (final lang in ['en', 'ar']) {
        await pumpInputs(tester, const GzPhoneField(defaultValue: '50000012'), lang: lang);
        final chip = tester.getTopLeft(find.text('+965'));
        final input = tester.getTopLeft(find.byType(TextField));
        expect(chip.dx, lessThan(input.dx), reason: lang);
        final f = tester.widget<TextField>(find.byType(TextField));
        expect(f.textDirection, TextDirection.ltr);
        expect(f.textAlign, lang == 'ar' ? TextAlign.end : TextAlign.start);
      }
    });
  });

  group('GzOtpInput', () {
    Finder cells() => find.byType(TextField);
    String text(WidgetTester t, int i) => t.widget<TextField>(cells().at(i)).controller!.text.replaceAll('​', '');

    testWidgets('typing fills a cell and advances; backspace on an empty cell walks back; onCompleted fires once', (tester) async {
      final changes = <String>[];
      final done = <String>[];
      await pumpInputs(tester, GzOtpInput(label: 'Code', onChanged: changes.add, onCompleted: done.add));
      expect(cells(), findsNWidgets(6));
      await tester.enterText(cells().at(0), '4');
      await tester.pump();
      expect(changes.last, '4');
      expect(FocusManager.instance.primaryFocus, tester.widget<TextField>(cells().at(1)).focusNode);
      await tester.enterText(cells().at(1), '٨'); // Eastern digit
      await tester.pump();
      expect(changes.last, '48');
      // Backspace on the empty cell 2: the sentinel is deleted, the previous digit goes, focus steps back.
      await tester.enterText(cells().at(2), '');
      await tester.pump();
      expect(changes.last, '4');
      expect(FocusManager.instance.primaryFocus, tester.widget<TextField>(cells().at(1)).focusNode);
      for (var i = 1; i < 6; i++) {
        await tester.enterText(cells().at(i), '${i + 1}');
        await tester.pump();
      }
      expect(changes.last, '423456');
      expect(done, ['423456']);
    });

    testWidgets('a pasted or autofilled code spreads over the cells', (tester) async {
      final done = <String>[];
      await pumpInputs(tester, GzOtpInput(onCompleted: done.add));
      await tester.enterText(cells().at(0), '٤٨٢٩١٥');
      await tester.pump();
      expect([for (var i = 0; i < 6; i++) text(tester, i)], ['4', '8', '2', '9', '1', '5']);
      expect(done, ['482915']);
    });

    testWidgets('digit 1 is on the left even on an Arabic screen', (tester) async {
      await pumpInputs(tester, const GzOtpInput(defaultValue: '12'), lang: 'ar');
      final first = tester.getTopLeft(cells().at(0)).dx;
      final last = tester.getTopLeft(cells().at(5)).dx;
      expect(first, lessThan(last));
    });

    testWidgets('an error shakes once; under reduced motion it does not move', (tester) async {
      await pumpInputs(tester, const GzOtpInput(defaultValue: '482915', error: 'Wrong'));
      await tester.pump(const Duration(milliseconds: 64)); // 20% of 320 ms
      final moved = tester.getTopLeft(cells().at(0)).dx;
      await tester.pump(const Duration(milliseconds: 400));
      final rest = tester.getTopLeft(cells().at(0)).dx;
      expect(moved, isNot(closeTo(rest, 0.01)));
      await pumpInputs(tester, const GzOtpInput(defaultValue: '482915', error: 'Wrong2'), reduceMotion: true);
      await tester.pump(const Duration(milliseconds: 64));
      expect(tester.getTopLeft(cells().at(0)).dx, closeTo(rest, 0.01));
    });

    testWidgets('cells are named for assistive technology', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInputs(tester, const GzOtpInput(label: 'Code'));
      expect(find.bySemanticsLabel(RegExp('Digit 3 of 6')), findsOneWidget);
      handle.dispose();
    });
  });
}
