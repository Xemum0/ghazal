import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

Widget _host(Widget child, {Locale locale = const Locale('en'), bool reduced = false}) => Directionality(
      textDirection: locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: GzTheme(locale: locale, child: child),
      ),
    );

void main() {
  test('buildGhazalTheme is explicit from the tokens (no seed)', () {
    final theme = buildGhazalTheme(const Locale('ar'));
    expect(theme.colorScheme.primary, GzColors.light.actionPrimaryBg);
    expect(theme.colorScheme.surface, GzColors.light.surfaceCanvas);
    expect(theme.scaffoldBackgroundColor, GzColors.light.surfaceCanvas);
    expect(theme.extension<GzColors>(), GzColors.light);
    expect(theme.textTheme.bodyLarge?.fontFamily, endsWith('/Almarai'));
    expect(theme.textTheme.bodyLarge?.fontSize, 17);
    expect(buildGhazalTheme(const Locale('en')).textTheme.bodyLarge?.fontFamily, endsWith('/Manrope'));
  });

  testWidgets('context.gz gives colours, role styles, locale and direction', (tester) async {
    late GzThemeData ar;
    await tester.pumpWidget(_host(Builder(builder: (c) {
      ar = c.gz;
      return const SizedBox();
    }), locale: const Locale('ar')));
    expect(ar.isRtl, isTrue);
    expect(ar.text(GzTextRole.body).fontFamily, endsWith('/Almarai'));
    expect(ar.colors.textPrimary, GzColors.light.textPrimary);
  });

  testWidgets('context.gz falls back without a GzTheme', (tester) async {
    late GzThemeData d;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(builder: (c) {
        d = c.gz;
        return const SizedBox();
      }),
    ));
    expect(d.colors, GzColors.light);
    expect(d.isAr, isTrue);
  });

  testWidgets('GzText applies the role, default colour and uppercases tracked English labels only', (tester) async {
    await tester.pumpWidget(_host(const GzText('Hello', role: GzTextRole.label)));
    expect(find.text('HELLO'), findsOneWidget);
    final t = tester.widget<Text>(find.text('HELLO'));
    expect(t.style?.fontSize, 12);
    expect(t.style?.color, GzColors.light.textPrimary);
    await tester.pumpWidget(_host(const GzText('Hello', role: GzTextRole.label), locale: const Locale('ar')));
    expect(find.text('Hello'), findsOneWidget);
    expect(tester.widget<Text>(find.text('Hello')).style?.letterSpacing, 0);
  });

  testWidgets('GzNum is an LTR isolate in the figures face; figures wraps digit runs', (tester) async {
    await tester.pumpWidget(_host(const GzNum('1,500', role: GzTextRole.body), locale: const Locale('ar')));
    final t = tester.widget<Text>(find.byType(Text));
    expect(t.data, '\u20661,500\u2069');
    expect(t.style?.fontFamily, endsWith('/Manrope'));
    expect(t.style?.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(t.style?.fontSize, 17); // figure size of the body role (fig-body)
    expect(GzBidi.strip('\u20661\u2069'), '1');
    expect(GzFigures.run.allMatches('Tue 9:00, KD 35,000+ and \u221215%').map((m) => m.group(0)), ['9:00', '35,000+', '\u221215%']);
  });
}
