import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:ghazal_ui/ghazal_ui_dev.dart' show GzRefColors;

/// The parts of [GzFoundationGallery] (each can be rendered alone to keep a PNG small).
enum GzFoundationSection { colour, roles, type, metrics, motion, icons, illustrations }

/// The Flutter twin of the web `#/gallery/tokens` and `#/gallery/illustration` pages: colour ramps with measured contrast, the
/// semantic roles, every type role in the current script, space / radius / elevation / stroke samples, the icon sheet (name under
/// each glyph) and the illustration contact sheet (not scrollable: the host sizes it, see the foundation gallery test) at the real sizes. Render it with [GzHarness] under both locales and compare
/// with `pnpm shots --route gallery:tokens` (the eyebrow, title, lede and colour note are the web strings verbatim) (tools/parity). Specimen strings are hand-written on purpose (design-tool text, like the
/// web gallery), so this lives in ghazal_testing where string literals are allowed.
class GzFoundationGallery extends StatelessWidget {
  const GzFoundationGallery({
    this.sections = GzFoundationSection.values,
    this.header = true,
    this.icons,
    this.illustrations,
    super.key,
  });

  final List<GzFoundationSection> sections;

  /// The eyebrow, title and lede above the first section.
  final bool header;

  /// A subset of icon names (registry names) for the icon sheet; null = all.
  final List<String>? icons;

  /// A subset of illustrations for the contact sheet; null = all.
  final List<GzIllustrationName>? illustrations;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final ar = gz.isAr;
    String t(String en, String arText) => ar ? arText : en;
    final children = <Widget>[
      if (header)
        Padding(
          padding: const EdgeInsetsDirectional.only(top: GzSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GzText(t('Design system', 'نظام التصميم'), role: GzTextRole.label, color: gz.colors.textSecondary),
              const SizedBox(height: GzSpace.s3),
              GzText(t('Tokens', 'رموز التصميم'), role: GzTextRole.d3, color: gz.colors.textStrong),
              const SizedBox(height: GzSpace.s3),
              GzText(
                t(
                  'Every colour, space, radius, type size and motion value in the product. Components read them through var(--gz-...) and nothing else; the generator checks contrast, grids and Arabic parity on every build.',
                  'كل لون ومسافة وزاوية وحجم خط وحركة في المنتج. تقرأ المكوّنات هذه القيم عبر var(--gz-...) ولا شيء غيرها، ويتحقق المولّد عند كل بناء من التباين والشبكة وتطابق العربية.',
                ),
                role: GzTextRole.body,
                color: gz.colors.textSecondary,
              ),
            ],
          ),
        ),
      for (final s in sections)
        switch (s) {
          GzFoundationSection.colour => const _Colour(),
          GzFoundationSection.roles => const _Roles(),
          GzFoundationSection.type => const _TypeSection(),
          GzFoundationSection.metrics => const _Metrics(),
          GzFoundationSection.motion => const _Motion(),
          GzFoundationSection.icons => _Icons(names: icons),
          GzFoundationSection.illustrations => _Illustrations(names: illustrations),
        },
    ];
    return ColoredBox(
      color: gz.colors.surfaceCanvas,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.section),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: GzSpace.section),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.note});

  final String title;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: GzSize.khaytWidth, height: GzStroke.khayt, color: c.markKhayt),
        const SizedBox(height: GzSpace.s3),
        GzText(title, role: GzTextRole.d2, color: c.textStrong),
        if (note != null) ...[
          const SizedBox(height: GzSpace.s3),
          GzText(note!, role: GzTextRole.bodyS, color: c.textSecondary),
        ],
        const SizedBox(height: GzSpace.s4),
        child,
      ],
    );
  }
}

// ---------------------------------------------------------------------------------------------------------------- colour

double _lin(int c) {
  final v = c / 255;
  return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
}

double _lum(Color c) =>
    0.2126 * _lin((c.r * 255).round()) + 0.7152 * _lin((c.g * 255).round()) + 0.0722 * _lin((c.b * 255).round());

double _ratio(Color a, Color b) {
  final x = _lum(a);
  final y = _lum(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

const _notes = <String, (String, String)>{
  'ink.900': ('headings, label on gold', 'العناوين وتسمية الذهبي'),
  'ink.800': ('dark panel raised', 'سطح داكن مرتفع'),
  'ink.700': ('body, PRD ink', 'النص الأساسي'),
  'ink.600': ('muted text', 'نص خافت'),
  'ink.500': ('control border', 'حدّ العناصر'),
  'ink.300': ('strong line', 'خط قوي'),
  'ink.200': ('hairline', 'خط دقيق'),
  'ink.100': ('placeholder, track', 'مكان الصورة'),
  'ink.50': ('quiet surface', 'سطح هادئ'),
  'gold.700': ('the gold for text', 'ذهبي النص'),
  'gold.650': ('state stroke', 'خط الحالة'),
  'gold.600': ('decor hairline', 'خط زخرفي'),
  'gold.550': ('pressed fill', 'تعبئة الضغط'),
  'gold.500': ('fill, never text', 'تعبئة، ليس نصاً'),
  'gold.100': ('pending pill', 'شارة الانتظار'),
  'rose.100': ('quiet panel', 'لوحة هادئة'),
  'neutral.canvas': ('surface', 'السطح'),
  'neutral.paper': ('raised, inputs', 'مرتفع، حقول'),
};

class _Colour extends StatelessWidget {
  const _Colour();

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    String t(String en, String ar) => gz.isAr ? ar : en;
    List<MapEntry<String, Color>> ramp(String prefix) {
      final list = GzRefColors.all.entries.where((e) => e.key.startsWith('$prefix.')).toList();
      double step(String k) => double.tryParse(k.split('.').last) ?? -1;
      list.sort((a, b) => step(b.key).compareTo(step(a.key)));
      return list;
    }

    final groups = <(String, List<MapEntry<String, Color>>)>[
      (t('Ink', 'الحبر'), ramp('ink')),
      (t('Gold', 'الذهبي'), ramp('gold')),
      (t('Rose', 'الوردي'), ramp('rose')),
      (
        t('Neutrals', 'المحايدات'),
        GzRefColors.all.entries.where((e) => e.key.startsWith('neutral.')).toList(),
      ),
      (
        t('Functional (status only)', 'وظيفية (للحالة فقط)'),
        [
          for (final k in ['success.700', 'success.100', 'danger.700', 'danger.100']) MapEntry(k, GzRefColors.all[k]!),
        ],
      ),
    ];
    return _Section(
      title: t('Colour ramps', 'تدرّجات الألوان'),
      note: t(
        'Hex lives only in these reference ramps. Gold-500 is fill, hairline and knot, never text; gold-700 is the only gold for text and icons.',
        'القيم السداسية لا تُكتب إلا في هذه التدرّجات المرجعية. الذهبي 500 للتعبئة والخطوط الدقيقة والعُقد، وليس للنص أبداً؛ والذهبي 700 هو الوحيد للنصوص والأيقونات.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (name, entries) in groups) ...[
            GzText(name, role: GzTextRole.uiTitle, color: gz.colors.textPrimary),
            const SizedBox(height: GzSpace.s3),
            _Ramp(entries: entries),
            const SizedBox(height: GzSpace.s4),
          ],
        ],
      ),
    );
  }
}

class _Ramp extends StatelessWidget {
  const _Ramp({required this.entries});

  final List<MapEntry<String, Color>> entries;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      // The web ramp is flex-wrap with a 88 dp basis and 12 dp gap; ghosts keep the last row at the same column width.
      final cols = ((box.maxWidth + GzSpace.s3) / (GzSize.weekStrip + GzSpace.s3)).floor();
      final w = (box.maxWidth - (cols - 1) * GzSpace.s3) / cols;
      // The web ramp ends with four zero-height ghost items (to keep the last row at the column width). The ones that do not fit in
      // the last row wrap onto empty rows of their own, each adding one 12 dp gap: reproduced here so the two pages line up.
      final free = (cols - entries.length % cols) % cols;
      final ghostRows = ((4 - free).clamp(0, 4) / cols).ceil();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: GzSpace.s3,
            runSpacing: GzSpace.s3,
            children: [for (final e in entries) SizedBox(width: w, child: _Swatch(path: e.key, color: e.value))],
          ),
          SizedBox(height: GzSpace.s3 * ghostRows),
        ],
      );
    });
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.path, required this.color});

  final String path;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final canvas = GzRefColors.all['neutral.canvas']!;
    final ink = GzRefColors.all['ink.900']!;
    final onC = _ratio(color, canvas);
    final onI = _ratio(color, ink);
    final onChip = onC >= onI ? canvas : ink;
    final note = _notes[path];
    final c = gz.colors;
    Widget line(String label, double v) => GzText.rich(
          TextSpan(children: [TextSpan(text: '$label '), GzFigures.span(context, v.toStringAsFixed(2), role: GzTextRole.caption)]),
          role: GzTextRole.caption,
          color: c.textSecondary,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: GzSize.avatarMd,
          padding: const EdgeInsetsDirectional.all(GzSpace.s2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: GzRadius.smAll,
            border: Border.all(color: c.borderHairline, width: GzStroke.hair),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GzText('Aa', role: GzTextRole.badge, color: onChip),
              GzText.rich(GzFigures.span(context, math.max(onC, onI).toStringAsFixed(1), role: GzTextRole.badge), role: GzTextRole.badge, color: onChip),
            ],
          ),
        ),
        const SizedBox(height: GzSpace.s2),
        GzLtr(child: GzText(path.split('.').last, role: GzTextRole.title, color: c.textStrong)),
        GzLtr(child: GzText(_hex(color), role: GzTextRole.caption, color: c.textSecondary)),
        line(gz.isAr ? 'الخلفية' : 'canvas', onC),
        line(gz.isAr ? 'الحبر' : 'ink', onI),
        if (note != null) GzText(gz.isAr ? note.$2 : note.$1, role: GzTextRole.caption, color: c.textGoldInk),
      ],
    );
  }
}

class _Roles extends StatelessWidget {
  const _Roles();

  /// The reference step a role points at (matched by value; the web shows the token reference).
  static String _refName(Color c) {
    for (final e in GzRefColors.all.entries) {
      if (e.value == c) return e.key;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final groups = <String, List<MapEntry<String, Color>>>{};
    for (final e in c.named.entries) {
      groups.putIfAbsent(e.key.split('.').first, () => []).add(e);
    }
    return _Section(
      title: gz.isAr ? 'الأدوار الدلالية' : 'Semantic roles',
      note: gz.isAr ? 'السطح اللوني الوحيد للمكوّنات. كل دور يسمّي درجة التدرّج التي يشير إليها.' : 'The only colour surface for components. Each role names the ramp step it points at.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final g in groups.entries) ...[
            if (g.key != groups.keys.first) const SizedBox(height: GzSpace.s4),
            GzLtr(child: GzText(g.key, role: GzTextRole.uiTitle, color: c.textPrimary)),
            const SizedBox(height: GzSpace.s2),
            for (final e in g.value)
              Container(
                constraints: const BoxConstraints(minHeight: GzSize.controlSm),
                padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s2),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
                child: Row(
                  children: [
                    Container(
                      width: GzSize.disk,
                      height: GzSize.disk,
                      decoration: BoxDecoration(
                        color: e.value,
                        borderRadius: BorderRadius.circular(GzRadius.xs),
                        border: Border.all(color: c.borderHairline, width: GzStroke.hair),
                      ),
                    ),
                    const SizedBox(width: GzSpace.s3),
                    Expanded(child: Align(alignment: AlignmentDirectional.centerStart, child: GzLtr(child: GzText(e.key, role: GzTextRole.bodyS, color: c.textStrong)))),
                    const SizedBox(width: GzSpace.s3),
                    GzLtr(child: GzText(_refName(e.value), role: GzTextRole.caption, color: c.textSecondary)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------------------------- type

/// Specimen strings of the web type section (design/src/gallery/tokens.tsx SAMPLE), so a role reads the same in both galleries.
const _typeSamples = <String, (String, String)>{
  'label': ('Your date', 'تاريخ زفافك'),
  'caption': ('Nothing is charged until the hotel approves.', 'لن يُخصم أي مبلغ حتى يوافق الفندق.'),
  'body-s': ('Hall, session and date are held while the hotel replies.', 'تُحجز القاعة والفترة والتاريخ إلى أن يردّ الفندق.'),
  'body': ('Request this date, free of charge, in under a minute.', 'اطلب هذا التاريخ مجاناً في أقل من دقيقة.'),
  'title': ('Aurelia Gulf Ballroom', 'قاعة أوريليا الخليج'),
  'button': ('Request this date', 'اطلب هذا التاريخ'),
  'pill': ('Pending', 'قيد الانتظار'),
  'tab': ('Discover', 'استكشف'),
  'ui-title': ('Needs your reply', 'بانتظار ردّك'),
  'ui-xl': ('Thursday 14 Jan', 'الخميس 14 يناير'),
  'd1': ('Aurelia Gulf Ballroom', 'قاعة أوريليا الخليج'),
  'd2': ('Aurelia Gulf Ballroom', 'قاعة أوريليا الخليج'),
  'd3': ('Aurelia Gulf', 'أوريليا الخليج'),
  'd4': ('Aurelia', 'أوريليا'),
  'd5': ('Aurelia', 'أوريليا'),
  'd6': ('Aurelia', 'أوريليا'),
  'brief': ('A women’s evening for 350 guests on Thursday 14 January in Salmiya.', 'حفل نسائي لعدد 350 مدعواً يوم الخميس 14 يناير في السالمية.'),
  'countdown': ('142', '142'),
  'compare-name': ('Aurelia Gulf Ballroom', 'قاعة أوريليا الخليج'),
  'wordmark': ('Ghazal', 'غزل'),
};

const _figureRoles = {'price', 'price-strong', 'price-total', 'kpi', 'fils-price', 'fils-total', 'cal-day', 'cal-price', 'badge', 'statusbar', 'timeline-time'};

class _TypeSection extends StatelessWidget {
  const _TypeSection();

  static String _fmt(TextStyle s) {
    String n(double v) {
      final r = (v * 100).roundToDouble() / 100;
      return r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toString();
    }

    final line = s.height! * s.fontSize!;
    final tracking = (s.letterSpacing ?? 0) != 0 ? ' · ${n(s.letterSpacing!)}px' : '';
    final words = (s.wordSpacing ?? 0) != 0 ? ' · ws ${n(s.wordSpacing!)}' : '';
    return '${n(s.fontSize!)}/${n(line)} · ${s.fontWeight!.value}$tracking$words';
  }

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    return _Section(
      title: gz.isAr ? 'الخطوط' : 'Type',
      note: gz.isAr
          ? 'الخطوط في هذه الصفحة هي ما تعرضه تطبيقات فلاتر: المسيري للعرض، ومانروب وأمرأي للواجهة وللأرقام. تختلف الأحجام والتباعد بين الكتابتين، لذا يُقاس كل دور مرتين.'
          : 'The fonts on this page are the ones the Flutter apps bundle: El Messiri for display, Manrope and Almarai for the interface, Manrope tabular digits for every number. Sizes and leading differ per script, so each role is measured twice.',
      child: Column(
        children: [
          for (final role in GzTextRole.values)
            Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: GzSpace.s3,
                    runSpacing: GzSpace.s1,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      GzLtr(child: GzText('.gz-t-${role.id}', role: GzTextRole.title, color: c.textGoldInk)),
                      GzLtr(child: GzText('EN ${_fmt(GzType.en.of(role))}', role: GzTextRole.caption, color: c.textSecondary)),
                      GzLtr(child: GzText('AR ${_fmt(GzType.ar.of(role))}', role: GzTextRole.caption, color: c.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: GzSpace.s2),
                  _Specimen(role: role, arabic: false),
                  const SizedBox(height: GzSpace.s2),
                  _Specimen(role: role, arabic: true),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Specimen extends StatelessWidget {
  const _Specimen({required this.role, required this.arabic});

  final GzTextRole role;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final sample = _typeSamples[role.id];
    final isFigure = role.id.startsWith('fig-') || _figureRoles.contains(role.id);
    var text = isFigure || sample == null ? '2,450' : (arabic ? sample.$2 : sample.$1);
    if (!arabic && role.uppercaseEn) text = text.toUpperCase();
    final style = (arabic ? GzType.ar : GzType.en).of(role).copyWith(color: c.textStrong, decoration: TextDecoration.none);
    return Directionality(
      textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
      child: SizedBox(width: double.infinity, child: Text(text, style: style)),
    );
  }
}

// ---------------------------------------------------------------------------------------------------------------- metrics

class _Metrics extends StatelessWidget {
  const _Metrics();

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    String t(String en, String ar) => gz.isAr ? ar : en;
    const steps = <(String, double)>[
      ('1', GzSpace.s1), ('2', GzSpace.s2), ('3', GzSpace.s3), ('4', GzSpace.s4), ('5', GzSpace.s5), ('6', GzSpace.s6),
      ('8', GzSpace.s8), ('10', GzSpace.s10), ('12', GzSpace.s12), ('16', GzSpace.s16), ('20', GzSpace.s20), ('24', GzSpace.s24),
    ];
    const radii = <(String, double)>[('xs', GzRadius.xs), ('sm', GzRadius.sm), ('md', GzRadius.md), ('lg', GzRadius.lg), ('pill', GzRadius.pill)];
    final elev = <(String, List<BoxShadow>)>[('e0', GzElevation.e0), ('e1', GzElevation.e1), ('e2', GzElevation.e2), ('e3', GzElevation.e3)];
    const controls = <(String, double)>[('sm', GzSize.controlSm), ('md', GzSize.controlMd), ('cta', GzSize.controlCta), ('lg', GzSize.controlLg)];
    Widget label(String s) => GzLtr(child: GzText(s, role: GzTextRole.caption, color: c.textSecondary));
    return _Section(
      title: t('Space, shape, elevation', 'المسافات والشكل والارتفاع'),
      note: t('A 4-point scale, one gutter (20), one section rhythm (32). Control heights are 44, 48, 52 and 56.', 'سلّم من 4 نقاط، وهامش واحد (20)، وإيقاع أقسام واحد (32). ارتفاعات العناصر 44 و48 و52 و56.'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final s in steps)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s2),
              child: Row(children: [
                SizedBox(width: GzSpace.s12, child: label('${s.$1} · ${s.$2.toStringAsFixed(0)}')),
                Container(width: s.$2, height: GzSpace.s3, color: c.markDecor),
              ]),
            ),
          const SizedBox(height: GzSpace.s4),
          Wrap(spacing: GzSpace.s4, runSpacing: GzSpace.s4, children: [
            for (final r in radii)
              Column(children: [
                Container(
                  width: GzSpace.s16,
                  height: GzSpace.s16,
                  decoration: BoxDecoration(
                    color: c.surfaceTint,
                    borderRadius: BorderRadius.circular(r.$2 > 100 ? GzSpace.s8 : r.$2),
                    border: Border.all(color: c.borderStrong, width: GzStroke.hair),
                  ),
                ),
                const SizedBox(height: GzSpace.s1),
                label('${r.$1} ${r.$2 > 100 ? 'full' : r.$2.toStringAsFixed(0)}'),
              ]),
          ]),
          const SizedBox(height: GzSpace.s4),
          Wrap(spacing: GzSpace.s4, runSpacing: GzSpace.s5, children: [
            for (final e in elev)
              Column(children: [
                Container(
                  width: GzSpace.s20,
                  height: GzSpace.s16,
                  decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.mdAll, boxShadow: e.$2, border: e.$1 == 'e1' ? Border.all(color: c.borderHairline, width: GzStroke.hair) : null),
                ),
                const SizedBox(height: GzSpace.s2),
                label(e.$1),
              ]),
          ]),
          const SizedBox(height: GzSpace.s4),
          Wrap(spacing: GzSpace.s4, runSpacing: GzSpace.s3, crossAxisAlignment: WrapCrossAlignment.end, children: [
            for (final k in controls)
              Column(children: [
                Container(width: GzSpace.s16, height: k.$2, decoration: BoxDecoration(color: c.actionPrimaryBg, borderRadius: GzRadius.smAll)),
                const SizedBox(height: GzSpace.s1),
                label('${k.$1} ${k.$2.toStringAsFixed(0)}'),
              ]),
          ]),
        ],
      ),
    );
  }
}

class _Motion extends StatelessWidget {
  const _Motion();

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final rows = <(String, Duration)>[
      ('fast', GzMotion.durationFast), ('base', GzMotion.durationBase), ('slow', GzMotion.durationSlow),
      ('expressive', GzMotion.durationExpressive), ('success', GzMotion.durationSuccess),
    ];
    return _Section(
      title: gz.isAr ? 'الحركة' : 'Motion',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s2),
            child: Row(children: [
              SizedBox(width: GzSpace.s24, child: GzLtr(child: GzText('${r.$1} ${r.$2.inMilliseconds}', role: GzTextRole.caption, color: c.textSecondary))),
              Container(width: r.$2.inMilliseconds / 4, height: GzSpace.s2, color: c.markKhayt),
            ]),
          ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------------------------------------------- icons

class _Icons extends StatelessWidget {
  const _Icons({this.names});

  final List<String>? names;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final list = names ?? GzIcons.byName.keys.toList();
    return _Section(
      title: gz.isAr ? 'الأيقونات' : 'Icons',
      note: gz.isAr
          ? 'فوسفور، مجموعة منتقاة. الأسهم والأقواس والرجوع والإرسال والقوائم والتراجع تنعكس بالعربية، وغيرها لا.'
          : 'Phosphor, curated subset. Arrows, chevrons, back, send, lists and undo flip in Arabic; nothing else does.',
      child: LayoutBuilder(builder: (context, box) {
        const cols = 4;
        final w = (box.maxWidth - (cols - 1) * GzSpace.s2) / cols;
        return Wrap(
          spacing: GzSpace.s2,
          runSpacing: GzSpace.s2,
          children: [
            for (final n in list)
              Container(
                width: w,
                padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3, horizontal: GzSpace.s1),
                decoration: BoxDecoration(
                  color: c.surfaceRaised,
                  borderRadius: GzRadius.mdAll,
                  border: Border.all(color: c.borderHairline, width: GzStroke.hair),
                ),
                child: Column(children: [
                  if (n == 'brand-divider')
                    const GzIcon.named('brand-divider', sizeDp: GzSize.thumbMd)
                  else if (n == 'brand-knot')
                    const GzIcon.named('brand-knot', sizeDp: GzSize.knotBooking, tone: GzIconTone.accent)
                  else
                    GzIcon.named(n, size: GzIconSize.lg, tone: GzIconTone.primary),
                  const SizedBox(height: GzSpace.s2),
                  SizedBox(
                    height: GzSpace.s10,
                    child: GzLtr(
                      // Names may wrap after a hyphen (zero-width space), never truncate.
                      child: GzText(n.replaceAll('-', '-\u200B'), role: GzTextRole.caption, color: GzIcons.mirrorInRtl.contains(n) ? c.textGoldInk : c.textSecondary, maxLines: 2, textAlign: TextAlign.center),
                    ),
                  ),
                ]),
              ),
          ],
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------------------------------------------- illustrations

class _Illustrations extends StatelessWidget {
  const _Illustrations({this.names});

  final List<GzIllustrationName>? names;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    String t(String en, String ar) => gz.isAr ? ar : en;
    final all = names ?? GzIllustrationName.values;
    // The web gallery sections: the spots, then the compositions by name prefix (illustration.tsx GROUPS).
    final groups = <(String, String?, bool Function(GzIllustrationName))>[
      (t('Spot drawings', 'رسوم مفردة'), t('${all.where((n) => n.kind == GzIllustrationKind.spot).length} drawings. Marked ones mirror in Arabic.', '${all.where((n) => n.kind == GzIllustrationKind.spot).length} رسمًا. المعلَّمة تنعكس بالعربية.'), (n) => n.kind == GzIllustrationKind.spot),
      (t('Onboarding', 'التعريف'), null, (n) => n.id.startsWith('onboard-')),
      (t('Empty states', 'الحالات الفارغة'), null, (n) => n.id.startsWith('empty-')),
      (t('Success', 'النجاح'), null, (n) => n.id.startsWith('success-')),
      (t('Partner', 'الشريك'), null, (n) => n.id.startsWith('partner-')),
    ];
    final c = gz.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var g = 0; g < groups.length; g++)
          if (all.any(groups[g].$3)) ...[
            if (groups.take(g).any((p) => all.any(p.$3))) const SizedBox(height: GzSpace.section),
            GzText(groups[g].$1, role: GzTextRole.d2, color: c.textStrong),
            if (groups[g].$2 != null) ...[
              const SizedBox(height: GzSpace.s2),
              GzText(groups[g].$2!, role: GzTextRole.bodyS, color: c.textSecondary),
            ],
            const SizedBox(height: GzSpace.s5),
            Wrap(
              spacing: GzSpace.s4,
              runSpacing: GzSpace.s4,
              children: [for (final n in all.where(groups[g].$3)) _IllustrationCell(n)],
            ),
          ],
      ],
    );
  }
}

class _IllustrationCell extends StatelessWidget {
  const _IllustrationCell(this.n);

  final GzIllustrationName n;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      constraints: const BoxConstraints(minWidth: 168),
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s4, bottom: GzSpace.s3, start: GzSpace.s3, end: GzSpace.s3),
      decoration: BoxDecoration(
        color: c.surfaceCanvas,
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: c.borderHairline, width: GzStroke.hair),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GzIllustration(n),
          const SizedBox(height: GzSpace.s2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GzText(n.id, role: GzTextRole.caption, color: n.mirror ? c.textGoldInk : c.textSecondary, textAlign: TextAlign.center),
              if (n.mirror) ...[
                const SizedBox(width: GzSpace.s1),
                const GzIcon.named('swap', size: GzIconSize.xs, tone: GzIconTone.accent, semanticLabel: 'mirrors'),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
