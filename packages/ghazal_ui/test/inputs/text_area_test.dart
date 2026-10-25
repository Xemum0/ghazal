import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/inputs/gz_field_input.dart';
import 'package:ghazal_ui/src/inputs/gz_text_area.dart';

import '../shared/shared_harness.dart';
import 'inputs_harness.dart';

void main() {
  setUpAll(loadUiFonts);

  // Web HL-VENU-05 (ar): the English terms box is `lang="en"`: Manrope 16/24 inside the Arabic UI, a 4-line box is 96 + padding + hairlines.
  testWidgets('English value inside the Arabic UI keeps the English line height', (tester) async {
    const text =
        'Payment, schedule and any changes are agreed with the hotel directly, off the app, and the voucher is only used to request the lower price.';
    Future<double> height(String lang, String? valueLang) async {
      await pumpInputs(
        tester,
        GzTextArea(key: UniqueKey(), defaultValue: text, rows: 1, lang: valueLang),
        lang: lang,
      );
      return tester.getSize(find.byType(GzTextArea)).height;
    }

    final en = await height('en', null);
    expect(await height('ar', 'en'), en);
    expect(await height('ar', null), greaterThan(en));
  });

  // Web HL-VENU-05: a line that exactly fills the 316 content box stays on one line; Flutter used to keep caret room (2.5) at line end.
  testWidgets('a multi-line value may fill the whole content width (no caret room)', (tester) async {
    const text = 'مباشرة بينكم وبين القاعة. أظهروا رمز الكوبون';
    final style = GzType.ar.body;
    final painter = TextPainter(text: const TextSpan(text: text), textDirection: TextDirection.rtl)
      ..text = TextSpan(text: text, style: style)
      ..layout();
    final w = painter.width.ceilToDouble();
    final controller = TextEditingController(text: text);
    addTearDown(controller.dispose);
    await pumpInputs(
      tester,
      Align(
        alignment: AlignmentDirectional.topStart,
        child: SizedBox(width: w, child: GzFieldInput(controller: controller, maxLines: 4, minLines: 1, lang: 'ar')),
      ),
      lang: 'en',
    );
    expect(tester.getSize(find.byType(GzFieldInput)).height, 28);
  });
}
