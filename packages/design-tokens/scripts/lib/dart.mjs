// Dart generator (ADR 0023 D5 c, ADR 0024 D9): const values plus TextStyle / Curve / Duration / EdgeInsetsDirectional helpers.
// References are resolved to literals. Semantic colours are a ThemeExtension (GzColors.light); the ref tier is separate
// (GzRefColors) and must not be exported from the ghazal_ui barrel.
import { LANGS } from './tokens.mjs'

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

function fonts(tokens) {
  const fam = (path, lang) => {
    const [first, ...rest] = tokens.get(path).value
    return { first, fallback: rest.filter(f => !GENERIC.has(f)) }
  }
  const f = {
    en: { ui: fam('font.en.ui'), display: fam('font.en.display') },
    ar: { ui: fam('font.ar.ui'), display: fam('font.ar.display') },
    fig: fam('font.fig'),
  }
  const list = fb => `[${fb.map(q).join(', ')}]`
  return { f, text: `/// Font families (static files from design/public/fonts/ttf, declared in pubspec as Poppins, Cairo, Newsreader, Amiri).
abstract final class GzFont {
  static const String uiEn = ${q(f.en.ui.first)};
  static const List<String> uiEnFallback = ${list(f.en.ui.fallback)};
  static const String displayEn = ${q(f.en.display.first)};
  static const List<String> displayEnFallback = ${list(f.en.display.fallback)};
  static const String uiAr = ${q(f.ar.ui.first)};
  static const List<String> uiArFallback = ${list(f.ar.ui.fallback)};
  static const String displayAr = ${q(f.ar.display.first)};
  static const List<String> displayArFallback = ${list(f.ar.display.fallback)};
  static const String fig = ${q(f.fig.first)};
  static const List<String> figFallback = ${list(f.fig.fallback)};
}
` }
}

const WEIGHT = { 300: 'w300', 400: 'w400', 500: 'w500', 600: 'w600', 700: 'w700' }
const FEATURE = { 'lining-nums': "FontFeature.liningFigures()", 'proportional-nums': 'FontFeature.proportionalFigures()', 'tabular-nums': 'FontFeature.tabularFigures()' }

function types(tokens, flat) {
  const roles = byPrefix(tokens, 'type.en').map(t => t.path.slice(8))
  const style = (lang, role) => {
    const v = tokens.get(`type.${lang}.${role}`).value
    const first = v.fontFamily[0]
    const fallback = v.fontFamily.slice(1).filter(x => !GENERIC.has(x))
    const feats = v.numeric === 'normal' ? [] : v.numeric.split(' ').map(n => FEATURE[n])
    const parts = [
      `fontFamily: ${q(first)}`,
      `fontFamilyFallback: [${fallback.map(q).join(', ')}]`,
      `fontSize: ${num(v.fontSize)}`,
      `height: ${v.lineHeight} / ${v.fontSize}`,
      `fontWeight: FontWeight.${WEIGHT[v.fontWeight]}`,
      `letterSpacing: ${num(v.letterSpacing)}`,
      `wordSpacing: ${num(v.wordSpacing)}`,
      'leadingDistribution: TextLeadingDistribution.even',
    ]
    if (feats.length) parts.push(`fontFeatures: [${feats.join(', ')}]`)
    return `TextStyle(${parts.join(', ')})`
  }
  const nm = r => camel([r])
  const upper = roles.filter(r => tokens.get(`type.en.${r}`).value.textTransform === 'uppercase').map(q)
  return `/// A full set of text styles for one script. Colour is never in a style: widgets take it from GzColors.
/// Line heights are explicit (height = line / size) with even leading distribution.
@immutable
class GzTypeSet {
  const GzTypeSet({
${roles.map(r => `    required this.${nm(r)},`).join('\n')}
  });

${roles.map(r => `  final TextStyle ${nm(r)};`).join('\n')}
}

/// Type roles per script (docs/design/01-direction.md 2.4). Use GzType.forLocale(locale).body.
abstract final class GzType {
${LANGS.map(lang => `  static const GzTypeSet ${lang} = GzTypeSet(\n${roles.map(r => `    ${nm(r)}: ${style(lang, r)},`).join('\n')}\n  );\n`).join('\n')}
  static GzTypeSet forLocale(Locale locale) => locale.languageCode == 'ar' ? ar : en;

  /// English roles authored in sentence case and uppercased by the shared label component (no textTransform in Flutter).
  static const Set<String> uppercaseRolesEn = {${upper.join(', ')}};
}
`
}

export function buildDart({ tokens, flat }, header) {
  const f = fonts(tokens)
  return `${header.split('\n').map(l => '// ' + l).join('\n')}
// ignore_for_file: lines_longer_than_80_chars, prefer_int_literals, unnecessary_const
// Units: every double is dp (1 px on the web = 1 dp). Hex values live only in GzRefColors.

import 'package:flutter/animation.dart' show Cubic, Curve;
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/material.dart' show ThemeExtension;
import 'package:flutter/painting.dart';
import 'package:flutter/physics.dart' show SpringDescription;

${colors(tokens)}
${space(tokens)}
${radius(tokens)}
${dims(tokens, 'GzSize', 'size', 'Sizes: control heights 44 / 48 / 52 / 56, touch minimum 44, icons, rows, knots.')}
${dims(tokens, 'GzStroke', 'stroke', 'Stroke widths (icon 1.5 on the 24 grid, thread 2, hairline 1).')}
${dims(tokens, 'GzZ', 'z', 'Layer order (web z-index; in Flutter the widget tree order follows it).')}
${dims(tokens, 'GzLayout', 'layout', 'Device frame (390 x 844), safe areas (use real MediaQuery insets on device), breakpoints, aspect ratios (width / height).', '')}
${elevation(tokens)}
${gradients(tokens)}
/// Arch crown (Home and onboarding hero only): a path in a 100 x 100 box, rise in dp.
abstract final class GzShape {
  static const String archPath = '${tokens.get('shape.arch.path').value}';
  static const double archRise = ${num(tokens.get('shape.arch.rise').value.value)};
}

${motion(tokens)}
${f.text}
${types(tokens, flat)}`
}
