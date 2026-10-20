import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

Widget _host(Locale locale) => MediaQuery(
      data: const MediaQueryData(),
      child: Localizations(
        locale: locale,
        delegates: const [GzL10n.delegate, GlobalWidgetsLocalizations.delegate],
        child: const GzStubScreen(id: 'CL-TEST-01', titleEn: 'English title', titleAr: 'عنوان عربي', kind: 'screen', purpose: 'Why.'),
      ),
    );

void main() {
  testWidgets('stub shows the id, the localised title and the not-built label (en)', (tester) async {
    await tester.pumpWidget(_host(const Locale('en')));
    await tester.pump();
    expect(find.text('CL-TEST-01'), findsOneWidget);
    expect(find.text('English title'), findsOneWidget);
    expect(find.text('Not built yet'), findsOneWidget);
  });

  testWidgets('stub is Arabic and right-to-left (ar)', (tester) async {
    await tester.pumpWidget(_host(const Locale('ar')));
    await tester.pump();
    expect(find.text('عنوان عربي'), findsOneWidget);
    expect(find.text('لم تُبنَ بعد'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('عنوان عربي'))), TextDirection.rtl);
  });

  test('font families match the bundled assets', () {
    expect(GzFonts.uiFor(const Locale('ar')), 'Almarai');
    expect(GzFonts.uiFor(const Locale('en')), 'Manrope');
    expect(GzFonts.display, 'ElMessiri');
  });
}
