// Flutter-only sections of the inputs gallery (the web gallery has no twin: numbers 15 and up, so the parity board skips them). They show
// the variants the F3 pilots needed from the kit: icon tabs (counts, every label), chips (glyph, muted count, widget label, expand),
// the hero and compact stepper, a rich checkbox label, the phone value against the chip, the range slider with its values below.
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/inputs/inputs.dart';

import 'gz_gallery.dart';

/// The Flutter-only sections (numbers 15 to 18).
List<GzGallerySection> inputsVariantSections() => [
  GzGallerySection('icon-tabs', _iconTabsSection, number: 15),
  GzGallerySection('chip-options', _chipOptionsSection, number: 16),
  GzGallerySection('stepper-variants', _stepperVariantsSection, number: 17),
  GzGallerySection('field-variants', _fieldVariantsSection, number: 18),
];

String _t(BuildContext context, String en, String ar) => context.gz.isAr ? ar : en;

Widget _sec(BuildContext context, {required String title, required List<Widget> specs}) {
  final c = context.gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(alignment: AlignmentDirectional.centerStart, child: GzThreadRule(draw: GzDraw.off)),
      const SizedBox(height: GzSpace.s2),
      GzText(title, role: GzTextRole.d2, color: c.textStrong, header: true),
      const SizedBox(height: GzSpace.s5),
      for (var i = 0; i < specs.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s6), specs[i]],
    ],
  );
}

Widget _spec(BuildContext context, String state, List<Widget> children) {
  final gz = context.gz;
  final c = gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair)),
        ),
        child: Text(
          state,
          style: gz.text(GzTextRole.caption).copyWith(color: c.textSecondary, fontWeight: gz.text(GzTextRole.title).fontWeight, decoration: TextDecoration.none),
        ),
      ),
      const SizedBox(height: GzSpace.s2),
      for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s4), children[i]],
    ],
  );
}

Widget _iconTabsSection(BuildContext context) {
  String t(String en, String ar) => _t(context, en, ar);
  return _sec(
    context,
    title: t('Icon tabs', 'تبويبات بأيقونات'),
    specs: [
      _spec(context, t('Counts on the glyph, the chosen word under it', 'عدّاد على الأيقونة والكلمة تحت المختار'), [
        GzIconTabs<String>(
          label: t('Filters', 'الفلاتر'),
          defaultValue: 'all',
          items: [
            GzIconTabItem(value: 'all', icon: GzIcons.hall, label: t('All', 'الكل'), count: 10),
            GzIconTabItem(value: 'req', icon: GzIcons.ticket, label: t('Requests', 'الطلبات'), count: 6),
            GzIconTabItem(value: 'visits', icon: GzIcons.calendar, label: t('Visits', 'الزيارات'), count: 1),
            GzIconTabItem(value: 'rev', icon: GzIcons.star, label: t('Reviews', 'التقييمات')),
          ],
        ),
      ]),
      _spec(context, t('Every word shown', 'كل الكلمات ظاهرة'), [
        GzIconTabs<String>(
          label: t('Browse', 'تصفح'),
          labels: GzIconTabsLabels.all,
          defaultValue: 'venues',
          items: [
            GzIconTabItem(value: 'venues', icon: GzIcons.hall, label: t('Venues', 'القاعات')),
            GzIconTabItem(value: 'services', icon: GzIcons.flower, label: t('Services', 'الخدمات')),
          ],
        ),
      ]),
    ],
  );
}

Widget _chipOptionsSection(BuildContext context) {
  String t(String en, String ar) => _t(context, en, ar);
  final f = context.gzFormat;
  return _sec(
    context,
    title: t('Chip options', 'خيارات الشرائح'),
    specs: [
      _spec(context, t('Glyph chips (single choice)', 'شرائح بأيقونة (اختيار واحد)'), [
        GzChipGroup<String>(
          label: t('Session', 'الفترة'),
          defaultValue: 'sunset',
          options: [
            GzChipOption(value: 'sun', label: f.integer(10), icon: GzIcons.sun, semanticLabel: t('Morning 10', 'الصباح 10')),
            GzChipOption(value: 'sunset', label: f.integer(5), icon: GzIcons.sunset, semanticLabel: t('Evening 5', 'المساء 5')),
            GzChipOption(value: 'moon', label: f.integer(9), icon: GzIcons.moon, semanticLabel: t('Night 9', 'الليل 9')),
          ],
        ),
      ]),
      _spec(context, t('A muted count after the label', 'عدد خافت بعد الاسم'), [
        GzChipGroup<String>.multiple(
          label: t('Areas', 'المناطق'),
          defaultValues: const ['salmiya'],
          options: [
            GzChipOption(value: 'salmiya', label: t('Salmiya', 'السالمية'), count: f.integer(12)),
            GzChipOption(value: 'hawalli', label: t('Hawalli', 'حولي'), count: f.integer(7)),
            GzChipOption(value: 'jabriya', label: t('Jabriya', 'الجابرية'), count: f.integer(3)),
          ],
        ),
      ]),
      _spec(context, t('Equal tiles: expand', 'بلاطات متساوية'), [
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: GzSpace.s2),
              Expanded(
                child: GzChip(
                  label: [f.integer(100), f.integer(150), f.integer(1000)][i] + (i == 2 ? '+' : ''),
                  figures: true,
                  expand: true,
                  selected: i == 1,
                  onPressed: () {},
                ),
              ),
            ],
          ],
        ),
      ]),
    ],
  );
}

Widget _stepperVariantsSection(BuildContext context) {
  String t(String en, String ar) => _t(context, en, ar);
  final c = context.gz.colors;
  final f = context.gzFormat;
  return _sec(
    context,
    title: t('Stepper variants', 'أشكال العداد'),
    specs: [
      _spec(context, t('Hero', 'كبير'), [
        GzStepper(variant: GzStepperVariant.hero, semanticLabel: t('Expected guests', 'عدد الضيوف'), defaultValue: 350, min: 100, max: 1500, step: 50),
      ]),
      _spec(context, t('A glyph as the label', 'أيقونة بدل العنوان'), [
        GzStepper(
          labelWidget: GzIcon(GzIcons.usersThree, size: GzIconSize.md, color: c.iconSecondary),
          semanticLabel: t('Guests', 'المعازيم'),
          defaultValue: 350,
          min: 100,
          max: 1500,
          step: 50,
          valueText: f.guests,
        ),
      ]),
      _spec(context, t('Compact, no title', 'مضغوط بلا عنوان'), [
        Align(alignment: AlignmentDirectional.centerEnd, child: GzStepper(compact: true, defaultValue: 2, min: 0, max: 5)),
      ]),
    ],
  );
}

Widget _fieldVariantsSection(BuildContext context) {
  String t(String en, String ar) => _t(context, en, ar);
  final c = context.gz.colors;
  return _sec(
    context,
    title: t('Field variants', 'أشكال الحقول'),
    specs: [
      _spec(context, t('Phone: digits at the screen start (kit)', 'الهاتف: الأرقام عند بداية الشاشة'), [GzPhoneField(defaultValue: '50001234')]),
      _spec(context, t('Phone: digits against the +965 chip', 'الهاتف: الأرقام بجانب +965'), [
        GzPhoneField(defaultValue: '50001234', valueAlign: GzPhoneValueAlign.chip),
      ]),
      _spec(context, t('Email value at the physical left', 'البريد عند اليسار'), [
        GzTextField(defaultValue: 'hind@aurelia.example', dir: GzFieldDir.ltr, textAlign: TextAlign.start),
      ]),
      _spec(context, t('Range: values below the rail', 'النطاق: القيم تحت الشريط'), [
        GzRangeSlider(min: 0, max: 100, label: t('Budget', 'الميزانية'), defaultValue: (20, 70), showCaptions: false, valuesAt: GzRangeValues.below),
      ]),
      _spec(context, t('Checkbox with a rich label', 'خانة بنص غني'), [
        GzCheckbox(
          label: t('I agree to the terms', 'أوافق على الشروط'),
          labelWidget: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: t('I agree to the ', 'أوافق على ')),
                TextSpan(
                  text: t('terms', 'الشروط'),
                  style: TextStyle(decoration: TextDecoration.underline, color: c.textStrong),
                ),
              ],
            ),
          ),
          defaultChecked: true,
        ),
      ]),
    ],
  );
}
