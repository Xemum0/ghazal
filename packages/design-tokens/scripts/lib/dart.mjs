// Dart generator (ADR 0023 D5 c, ADR 0024 D9, F1a): const values plus TextStyle / Curve / Duration / EdgeInsetsDirectional helpers,
// written into packages/ghazal_ui/lib/src/tokens/generated/ (four files). References are resolved to literals. Semantic colours
// are a ThemeExtension (GzColors.light); the ref tier is separate (GzRefColors) and is not exported from the ghazal_ui barrel.
// Imports: material_ui (ThemeExtension) or widgets only, never the framework material library (ADR 0036 item 6).
import { LANGS } from './tokens.mjs'
import { NUM_CONTEXT } from './roles-css.mjs'

const cap = s => (s ? s[0].toUpperCase() + s.slice(1) : s)
/** ['text','on-gold'] -> textOnGold */
export const camel = parts => parts.flatMap(p => String(p).split('-')).map((p, i) => (i === 0 ? p : cap(p))).join('')
const num = n => (Number.isInteger(n) ? `${n}.0` : String(n))
const color = c => {
  const a = Math.round(c.alpha * 255).toString(16).padStart(2, '0')
  return `Color(0x${(a + c.hex.slice(1)).toUpperCase()})`
}
const GENERIC = new Set(['serif', 'sans-serif', 'monospace', 'system-ui', 'Georgia'])
const q = s => `'${s}'`

const byPrefix = (tokens, prefix) => [...tokens.values()].filter(t => t.path.startsWith(prefix + '.'))
const ident = (t, prefix) => {
  const n = camel(t.path.slice(prefix.length + 1).split('.'))
  return /^\d/.test(n) ? `s${n}` : n // space.4 -> s4
}
const field = (t, prefix, value, type = 'double') => `  static const ${type} ${ident(t, prefix)} = ${value};`

function colors(tokens) {
  const ref = byPrefix(tokens, 'color.ref')
  const sys = byPrefix(tokens, 'color.sys').filter(t => t.type === 'color')
  const name = t => camel(t.path.replace(/^color\.sys\./, '').split('.'))
  return `/// Reference ramps. Components never read these (ADR 0023 D7): not exported from the package barrel.
abstract final class GzRefColors {
${ref.map(t => `  static const ${camel(t.path.replace(/^color\.ref\./, '').split('.'))} = ${color(t.value)};`).join('\n')}

  /// Every step by token path (\`ink.50\`), in source order: for galleries and tests only.
  static const Map<String, Color> all = {
${ref.map(t => `    '${t.path.replace(/^color\.ref\./, '')}': ${camel(t.path.replace(/^color\.ref\./, '').split('.'))},`).join('\n')}
  };
}

/// Semantic colour roles: the only colour surface for widgets (ADR 0022 F). Light theme only for the MVP.
@immutable
class GzColors extends ThemeExtension<GzColors> {
  const GzColors({
${sys.map(t => `    required this.${name(t)},`).join('\n')}
  });

${sys.map(t => `  final Color ${name(t)};`).join('\n')}

  static const GzColors light = GzColors(
${sys.map(t => `    ${name(t)}: ${color(t.value)},`).join('\n')}
  );

  /// Every role by token path (\`text.primary\`), in source order: for galleries and tests only.
  Map<String, Color> get named => {
${sys.map(t => `        '${t.path.replace(/^color\.sys\./, '')}': ${name(t)},`).join('\n')}
      };

  @override
  GzColors copyWith({
${sys.map(t => `    Color? ${name(t)},`).join('\n')}
  }) =>
      GzColors(
${sys.map(t => `        ${name(t)}: ${name(t)} ?? this.${name(t)},`).join('\n')}
      );

  @override
  GzColors lerp(ThemeExtension<GzColors>? other, double t) {
    if (other is! GzColors) return this;
    return GzColors(
${sys.map(t => `      ${name(t)}: Color.lerp(${name(t)}, other.${name(t)}, t)!,`).join('\n')}
    );
  }
}
`
}

function dims(tokens, cls, prefix, doc, extra = '') {
  const items = byPrefix(tokens, prefix).filter(t => t.type === 'dimension' || t.type === 'number')
  const ratios = byPrefix(tokens, prefix).filter(t => t.type === 'aspect')
  return `/// ${doc}
abstract final class ${cls} {
${items.map(t => field(t, prefix, num(t.type === 'dimension' ? t.value.value : t.value))).join('\n')}
${ratios.map(t => field(t, prefix, `${t.value[0]} / ${t.value[1]}`)).join('\n')}
${extra}}
`
}

function space(tokens) {
  return dims(tokens, 'GzSpace', 'space', 'Spacing: 4-pt scale (s4 = 16 dp) and structural aliases.', `
  /// The one screen gutter, as directional insets.
  static const EdgeInsetsDirectional screen = EdgeInsetsDirectional.symmetric(horizontal: gutter);

  /// Card and panel padding.
  static const EdgeInsetsDirectional panel = EdgeInsetsDirectional.all(panelPad);

  /// start / top / end / bottom, always directional (never left / right, ADR 0014).
  static EdgeInsetsDirectional only({double start = 0, double top = 0, double end = 0, double bottom = 0}) =>
      EdgeInsetsDirectional.fromSTEB(start, top, end, bottom);
`)
}

function radius(tokens) {
  const r = byPrefix(tokens, 'radius')
  return `/// Radius scale: 4 status pill, 8 button/input/chip, 12 card/panel, 20 sheet top, pill = full.
abstract final class GzRadius {
${r.map(t => field(t, 'radius', num(t.value.value))).join('\n')}

${r.map(t => `  static const BorderRadius ${camel([t.path.split('.').at(-1), 'all'])} = BorderRadius.all(Radius.circular(${camel([t.path.split('.').at(-1)])}));`).join('\n')}

  /// Sheet: top corners only, directional-safe (both top corners are equal).
  static const BorderRadius sheetTop = BorderRadius.vertical(top: Radius.circular(lg));
}
`
}

function elevation(tokens) {
  const e = byPrefix(tokens, 'elevation')
  const layer = l => `BoxShadow(color: ${color(l.color)}, offset: Offset(${num(l.offsetX.value)}, ${num(l.offsetY.value)}), blurRadius: ${num(l.blur.value)}, spreadRadius: ${num(l.spread.value)})`
  return `/// Elevation: hairline first (e1 is a 1 dp ring), one warm shadow family for floating things (e2) and sheets (e3).
abstract final class GzElevation {
${e.map(t => `  static const List<BoxShadow> e${t.path.split('.').at(-1)} = [${t.value.map(layer).join(', ')}];`).join('\n')}
}
`
}

function gradients(tokens) {
  const g = byPrefix(tokens, 'gradient')
  return `/// Photo scrims (top to bottom). The only gradients in the product.
abstract final class GzGradient {
${g.map(t => `  static const LinearGradient ${camel([t.path.split('.').at(-1)])} = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [${t.value.map(s => color(s.color)).join(', ')}],
    stops: [${t.value.map(s => num(s.position)).join(', ')}],
  );`).join('\n\n')}
}
`
}

function motion(tokens) {
  const d = byPrefix(tokens, 'motion.duration')
  const e = byPrefix(tokens, 'motion.ease')
  const sc = byPrefix(tokens, 'motion.scale')
  const di = byPrefix(tokens, 'motion.distance')
  const sp = ['mass', 'stiffness', 'damping'].map(k => tokens.get(`motion.spring.settle.${k}`).value)
  return `/// Motion (ADR 0017): durations, exact cubic curves, the settle spring as numbers, scale and distance constants.
/// With MediaQuery.disableAnimationsOf: use durationInstant for transform/draw/pop, keep durationFast for fades.
abstract final class GzMotion {
${d.map(t => `  static const Duration ${camel(['duration', t.path.split('.').at(-1)])} = Duration(milliseconds: ${t.value.value});`).join('\n')}

${e.map(t => `  static const Curve ${camel(['ease', t.path.split('.').at(-1)])} = Cubic(${t.value.map(num).join(', ')});`).join('\n')}

  static const SpringDescription springSettle = SpringDescription(mass: ${num(sp[0])}, stiffness: ${num(sp[1])}, damping: ${num(sp[2])});

${sc.map(t => `  static const double ${camel(['scale', t.path.split('.').at(-1)])} = ${num(t.value)};`).join('\n')}
${di.map(t => `  static const double ${camel(['distance', t.path.split('.').at(-1)])} = ${num(t.value.value)};`).join('\n')}
}
`
}

/** Web family name -> the family name declared in packages/ghazal_ui/pubspec.yaml. */
const FAMILY = { 'El Messiri': 'ElMessiri', Manrope: 'Manrope', Almarai: 'Almarai' }
const family = name => {
  if (!(name in FAMILY)) throw new Error(`dart generator: no pubspec family for font "${name}"`)
  return FAMILY[name]
}
const chain = list => list.filter(f => !GENERIC.has(f)).map(family)
const PKG = "package: 'ghazal_ui'"

function fonts(tokens) {
  const fam = path => {
    const [first, ...rest] = chain(tokens.get(path).value)
    return { first, fallback: rest }
  }
  const f = { uiEn: fam('font.en.ui'), displayEn: fam('font.en.display'), uiAr: fam('font.ar.ui'), displayAr: fam('font.ar.display'), fig: fam('font.fig') }
  const list = fb => `[${fb.map(q).join(', ')}]`
  return `/// Font families as declared in the pubspec of ghazal_ui (static TTFs in assets/fonts). Web "El Messiri" is ElMessiri.
/// Every TextStyle that names one also passes package: 'ghazal_ui' (GzFont.package).
abstract final class GzFont {
  static const String package = 'ghazal_ui';
${Object.entries(f).map(([k, v]) => `  static const String ${k} = ${q(v.first)};\n  static const List<String> ${k}Fallback = ${list(v.fallback)};`).join('\n')}
}
`
}

const WEIGHT = { 300: 'w300', 400: 'w400', 500: 'w500', 600: 'w600', 700: 'w700', 800: 'w800' }
const FEATURE = { 'lining-nums': 'FontFeature.liningFigures()', 'proportional-nums': 'FontFeature.proportionalFigures()', 'tabular-nums': 'FontFeature.tabularFigures()' }

function types(tokens) {
  const roles = byPrefix(tokens, 'type.en').map(t => t.path.slice(8))
  const nm = r => camel([r])
  const style = (lang, role) => {
    const v = tokens.get(`type.${lang}.${role}`).value
    if (lang === 'ar' && v.letterSpacing !== 0) throw new Error(`type.ar.${role}: Arabic letterSpacing must be 0`)
    const [first, ...fallback] = chain(v.fontFamily)
    const feats = v.numeric === 'normal' ? [] : v.numeric.split(' ').map(n => FEATURE[n])
    const lh = v.lineHeight % v.fontSize === 0 ? `${v.lineHeight / v.fontSize}` : `${v.lineHeight} / ${v.fontSize}`
    const parts = [
      `fontFamily: ${q(first)}`, PKG,
      `fontFamilyFallback: [${fallback.map(q).join(', ')}]`,
      `fontSize: ${num(v.fontSize)}`,
      `height: ${lh}`,
      `fontWeight: FontWeight.${WEIGHT[v.fontWeight]}`,
      `letterSpacing: ${num(v.letterSpacing)}`,
      `wordSpacing: ${num(v.wordSpacing)}`,
      'leadingDistribution: TextLeadingDistribution.even',
    ]
    if (feats.length) parts.push(`fontFeatures: [${feats.join(', ')}]`)
    return `TextStyle(\n${parts.map(p => `      ${p},`).join('\n')}\n    )`
  }
  const upper = roles.filter(r => tokens.get(`type.en.${r}`).value.textTransform === 'uppercase')
  const numeric = roles.filter(r => tokens.get(`type.en.${r}`).value.numeric.includes('tabular'))
  return `/// Every type role (docs/design/01-direction.md 2.4). The same names exist in both scripts; the size, line height and
/// weight differ per locale (the Arabic scale is already applied in the token). Read one with GzType.style(locale, role)
/// or, in a widget, context.gz.text(role).
enum GzTextRole {
${roles.map(r => `  ${nm(r)}('${r}'),`).join('\n')}
  ;

  const GzTextRole(this.id);

  /// The token / CSS name (\`.gz-t-<id>\`).
  final String id;

  /// English roles authored in sentence case and uppercased by GzText (no textTransform in Flutter): tracked eyebrows.
  bool get uppercaseEn => const {${upper.map(r => `GzTextRole.${nm(r)}`).join(', ')}}.contains(this);

  /// Roles that use tabular lining figures (prices, KPIs, calendar numbers).
  bool get isNumeric => const {${numeric.map(r => `GzTextRole.${nm(r)}`).join(', ')}}.contains(this);

  /// The figure role whose size inline numbers take inside this role (the web --gz-num-size), or null to keep the size.
  GzTextRole? get figureRole => switch (this) {
${Object.entries(NUM_CONTEXT).map(([r, f]) => `        GzTextRole.${nm(r)} => GzTextRole.${nm(f)},`).join('\n')}
        _ => null,
      };
}

/// A full set of text styles for one script. Colour is never in a style: widgets take it from GzColors.
/// Line heights are explicit (height = line / size) with even leading distribution (the CSS half-leading).
@immutable
class GzTypeSet {
  const GzTypeSet({
${roles.map(r => `    required this.${nm(r)},`).join('\n')}
  });

${roles.map(r => `  final TextStyle ${nm(r)};`).join('\n')}

  /// The style of one role by name.
  TextStyle of(GzTextRole role) => switch (role) {
${roles.map(r => `        GzTextRole.${nm(r)} => ${nm(r)},`).join('\n')}
      };
}

/// Type roles per script. Use GzType.style(locale, role) or GzType.forLocale(locale).body.
abstract final class GzType {
${LANGS.map(lang => `  static const GzTypeSet ${lang} = GzTypeSet(\n${roles.map(r => `    ${nm(r)}: ${style(lang, r)},`).join('\n')}\n  );\n`).join('\n')}
  static GzTypeSet forLocale(Locale locale) => locale.languageCode == 'ar' ? ar : en;

  static TextStyle style(Locale locale, GzTextRole role) => forLocale(locale).of(role);
}
`
}

const FILE_IMPORTS = {
  colors: `import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';
import 'package:material_ui/material_ui.dart' show ThemeExtension;`,
  dimensions: `import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';`,
  motion: `import 'package:flutter/animation.dart' show Cubic, Curve;
import 'package:flutter/physics.dart' show SpringDescription;`,
  type: `import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';`,
}

const wrap = (header, kind, body) => `${header.split('\n').map(l => '// ' + l).join('\n')}
// ignore_for_file: lines_longer_than_80_chars, prefer_int_literals, unnecessary_const, require_trailing_commas
// Units: every double is dp (1 px on the web = 1 dp). Hex values live only in this folder (tools/check-dart-rules.sh).

${FILE_IMPORTS[kind]}

${body}`

/** The generated Dart files, keyed by path relative to packages/design-tokens (they land in packages/ghazal_ui). */
export function buildDartFiles({ tokens }, header) {
  const dir = '../ghazal_ui/lib/src/tokens/generated/'
  return {
    [`${dir}gz_colors.g.dart`]: wrap(header, 'colors', colors(tokens)),
    [`${dir}gz_dimensions.g.dart`]: wrap(header, 'dimensions', `${space(tokens)}
${radius(tokens)}
${dims(tokens, 'GzSize', 'size', 'Sizes: control heights 44 / 48 / 52 / 56, touch minimum 44, icons, rows, knots.')}
${dims(tokens, 'GzStroke', 'stroke', 'Stroke widths (icon 1.5 on the 24 grid, thread 2, hairline 1, focus ring 2).')}
${dims(tokens, 'GzZ', 'z', 'Layer order (web z-index; in Flutter the widget tree order follows it).')}
${dims(tokens, 'GzLayout', 'layout', 'Device frame (390 x 844), safe areas (use real MediaQuery insets on device), breakpoints, aspect ratios (width / height).', '')}
${elevation(tokens)}
${gradients(tokens)}
/// Arch crown (Home and onboarding hero only): a path in a 100 x 100 box, rise in dp.
abstract final class GzShape {
  static const String archPath = '${tokens.get('shape.arch.path').value}';
  static const double archRise = ${num(tokens.get('shape.arch.rise').value.value)};
}
`),
    [`${dir}gz_motion.g.dart`]: wrap(header, 'motion', motion(tokens)),
    [`${dir}gz_type.g.dart`]: wrap(header, 'type', `${fonts(tokens)}\n${types(tokens)}`),
  }
}
