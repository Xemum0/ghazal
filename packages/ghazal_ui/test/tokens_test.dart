import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// The generated Dart tokens must equal the JSON build output (dist/tokens.flat.json) for sample values.
Map<String, dynamic> _flat() {
  final file = File('../design-tokens/dist/tokens.flat.json');
  return (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>)['tokens'] as Map<String, dynamic>;
}

dynamic _v(Map<String, dynamic> t, String path) => (t[path] as Map<String, dynamic>)['value'];

Color _hex(String hex) => Color(int.parse('FF${hex.substring(1)}', radix: 16));

/// A TextStyle that names a package carries `packages/<pkg>/<family>`; the pubspec family is the last segment.
String? _family(TextStyle s) => s.fontFamily?.split('/').last;

void main() {
  final t = _flat();

  test('colours equal the sys tokens', () {
    const c = GzColors.light;
    expect(c.surfaceCanvas, _hex(_v(t, 'color.sys.surface.canvas') as String));
    expect(c.textPrimary, _hex(_v(t, 'color.sys.text.primary') as String));
    expect(c.actionPrimaryBg, _hex(_v(t, 'color.sys.action.primary.bg') as String));
    expect(c.focusRing, _hex(_v(t, 'color.sys.focus-ring') as String));
    expect(c.illusAccent, _hex(_v(t, 'color.sys.illus.accent') as String));
  });

  test('GzColors copyWith and lerp', () {
    const a = GzColors.light;
    final b = a.copyWith(textPrimary: a.borderStrong);
    expect(b.textPrimary, a.borderStrong);
    expect(b.surfaceCanvas, a.surfaceCanvas);
    expect(a.lerp(b, 0).textPrimary, a.textPrimary);
    expect(a.lerp(b, 1).textPrimary, b.textPrimary);
  });

  test('sizes, spacing, radii and strokes equal the dimension tokens', () {
    expect(GzSize.controlSm, (_v(t, 'size.control.sm') as num).toDouble());
    expect(GzSize.controlMd, 48);
    expect(GzSize.controlCta, 52);
    expect(GzSize.controlLg, 56);
    expect(GzSize.touchMin, 44);
    expect(GzSize.tabBar, 56);
    expect(GzSize.iconMd, 24);
    expect(GzSize.illustrationHero, 200);
    expect(GzSpace.gutter, 20);
    expect(GzSpace.section, 32);
    expect(GzRadius.md, (_v(t, 'radius.md') as num).toDouble());
    expect(GzStroke.focus, 2);
    expect(GzStroke.icon, 1.5);
    expect(GzLayout.aspect4x5, 4 / 5);
  });

  test('motion durations and curves equal the motion tokens', () {
    expect(GzMotion.durationFast.inMilliseconds, 120);
    expect(GzMotion.durationBase.inMilliseconds, 200);
    expect(GzMotion.durationSlow.inMilliseconds, 320);
    expect(GzMotion.durationExpressive.inMilliseconds, 480);
    expect(GzMotion.durationSuccess.inMilliseconds, 640);
    final e = (_v(t, 'motion.ease.standard') as List<dynamic>).cast<num>();
    final c = GzMotion.easeStandard as Cubic;
    expect([c.a, c.b, c.c, c.d], e.map((x) => x.toDouble()).toList());
    expect(GzMotion.scalePress, 0.985);
  });

  test('elevation and photo scrim gradients carry the token layers', () {
    expect(GzElevation.e2.length, (_v(t, 'elevation.2') as List<dynamic>).length);
    expect(GzGradient.cover.stops!.length, (_v(t, 'gradient.cover') as List<dynamic>).length);
  });

  for (final lang in ['en', 'ar']) {
    test('type roles ($lang) equal the type tokens and use the pubspec families', () {
      final locale = Locale(lang);
      for (final role in GzTextRole.values) {
        final json = _v(t, 'type.$lang.${role.id}') as Map<String, dynamic>;
        final s = GzType.style(locale, role);
        expect(s.fontSize, (json['fontSize'] as num).toDouble(), reason: role.id);
        expect(s.height! * s.fontSize!, closeTo((json['lineHeight'] as num).toDouble(), 1e-9), reason: role.id);
        expect(s.fontWeight, FontWeight.values[((json['fontWeight'] as int) ~/ 100) - 1], reason: role.id);
        expect(s.leadingDistribution, TextLeadingDistribution.even);
        expect(s.fontFamily, startsWith('packages/ghazal_ui/'));
        expect(s.fontFamilyFallback!.every((f) => f.startsWith('packages/ghazal_ui/')), isTrue, reason: role.id);
        expect(const {'ElMessiri', 'Manrope', 'Almarai'}.contains(_family(s)), isTrue, reason: '${role.id} ${s.fontFamily}');
        if (lang == 'ar') expect(s.letterSpacing, 0, reason: 'Arabic never tracks (${role.id})');
        final numeric = (json['numeric'] as String).contains('tabular');
        expect(s.fontFeatures?.contains(const FontFeature.tabularFigures()) ?? false, numeric, reason: role.id);
      }
    });
  }

  test('role sample values', () {
    expect(_family(GzType.en.body), 'Manrope');
    expect(GzType.en.body.fontSize, 16);
    expect(_family(GzType.ar.body), 'Almarai');
    expect(GzType.ar.body.fontSize, 17);
    expect(_family(GzType.ar.d3), 'ElMessiri');
    expect(GzType.en.label.letterSpacing, closeTo(1.68, 1e-9));
    expect(GzTextRole.label.uppercaseEn, isTrue);
    expect(GzTextRole.body.figureRole, GzTextRole.figBody);
  });
}
