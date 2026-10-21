// The inputs gallery: the Flutter twin of design/src/gallery/inputs.tsx (#/gallery/inputs). Same 14 sections in the same order (the file
// slugs are the web section ids: fields, phone, otp ...), the same specimens, states and sample text. Parity:
// `node tools/parity/parity.mjs --gallery inputs` after `flutter test test/gallery/inputs_gallery_test.dart`.
// ghazal_testing may hold string literals (tests and galleries are exempt from the no-text-literal rule).
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/inputs/inputs.dart';

import 'gz_gallery.dart';

/// The prototype's fixed clock: 2026-11-12 16:00 Asia/Kuwait (the web gallery reads the same "today").
final DateTime _fixedNow = DateTime.parse('2026-11-12T16:00:00+03:00');

/// The section ids (the web `data-gz-section` ids): the Flutter files are `NN-<id>.<lang>.png` like the web references.
const List<String> inputsGalleryIds = [
  'fields',
  'phone',
  'otp',
  'search',
  'textarea',
  'stepper',
  'range',
  'segmented',
  'chips',
  'toggles',
  'select',
  'calendar',
  'slots',
  'datefield',
];

/// Wraps every section in the formatter with the prototype's clock (the app installs the same scope from `gzFormatProvider`).
Widget inputsGalleryWrap(Widget child) => Builder(
  builder: (context) => GzFormatScope(
    format: GzFormat(locale: Locale(context.gz.locale.languageCode), now: () => _fixedNow),
    child: child,
  ),
);

/// The sections of the inputs gallery page.
List<GzGallerySection> inputsGallerySections() {
  final builders = <WidgetBuilder>[
    _fieldsSection,
    _phoneSection,
    _otpSection,
    _searchSection,
    _textAreaSection,
    _stepperSection,
    _rangeSection,
    _segmentedSection,
    _chipsSection,
    _togglesSection,
    _selectSection,
    _calendarSection,
    _slotsSection,
    _dateFieldSection,
  ];
  return [for (var i = 0; i < builders.length; i++) GzGallerySection(inputsGalleryIds[i], builders[i])];
}

// ---------------------------------------------------------------------------------------------------------------- kit
String _t(BuildContext context, String en, String ar) => context.gz.isAr ? ar : en;

/// `Section` of the web kit: khayt, d2 title, note (gap 8), then the specimens (gap 24) after a gap of 20.
Widget _sec(BuildContext context, {required String title, String? note, required List<Widget> specs}) {
  final c = context.gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: GzThreadRule(draw: GzDraw.off),
      ),
      const SizedBox(height: GzSpace.s2),
      GzText(title, role: GzTextRole.d2, color: c.textStrong, header: true),
      if (note != null) ...[const SizedBox(height: GzSpace.s2), GzText(note, role: GzTextRole.bodyS, color: c.textSecondary)],
      const SizedBox(height: GzSpace.s5),
      for (var i = 0; i < specs.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s6), specs[i]],
    ],
  );
}

/// `Spec`: a state caption over a hairline, then the live component(s) with a gap of 16.
Widget _spec(BuildContext context, String state, List<Widget> children) {
  final gz = context.gz;
  final c = gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
          ),
        ),
        child: Text(
          state,
          style: gz
              .text(GzTextRole.caption)
              .copyWith(color: c.textSecondary, fontWeight: gz.text(GzTextRole.title).fontWeight, decoration: TextDecoration.none),
        ),
      ),
      const SizedBox(height: GzSpace.s2),
      for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s4), children[i]],
    ],
  );
}

/// `Kd`: a budget value in the numeric voice, the currency label left of the number in BOTH languages (ADR 0010 D7).
Widget _kd(BuildContext context, int kd, {bool plus = false, bool edge = false}) {
  final gz = context.gz;
  final c = gz.colors;
  final f = context.gzFormat;
  final m = f.moneyParts(kd * 1000);
  final cur = gz.isAr ? m.currency : m.currency.toUpperCase();
  // In the edge labels the amount inherits the caption role and its secondary ink; in the value labels it is the fig-title figure.
  final role = edge ? GzTextRole.caption : GzTextRole.figTitle;
  final amount = GzFigures.inlineStyle(gz.locale, role).copyWith(
    fontWeight: edge ? gz.text(GzTextRole.caption).fontWeight : gz.text(GzTextRole.priceStrong).fontWeight,
    color: edge ? c.textSecondary : c.textStrong,
    height: gz.text(role).height,
    decoration: TextDecoration.none,
  );
  final line = gz.text(role);
  return Directionality(
    textDirection: TextDirection.ltr,
    // The edge row is one caption line high: the label-voice currency must not stretch it.
    child: ConstrainedBox(
      constraints: edge ? BoxConstraints(maxHeight: (line.fontSize ?? 14) * (line.height ?? 1.4)) : const BoxConstraints(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textBaseline: TextBaseline.alphabetic,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        children: [
          Text(
            cur,
            style: gz.text(GzTextRole.label).copyWith(color: c.textSecondary, decoration: TextDecoration.none),
          ),
          const SizedBox(width: GzSpace.s1),
          Text('${m.integer}${plus ? '+' : ''}', style: amount),
          if (!m.fractionIsZero) Text(m.fraction, style: amount),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------------------------------------------- 1 fields
Widget _fieldsSection(BuildContext context) {
  final l10n = context.gzL10n;
  String t(String en, String ar) => _t(context, en, ar);
  return _sec(
    context,
    title: t('Text fields', 'حقول النص'),
    note: t(
      '56 high, radius 8, paper, ink-500 hairline. Focus turns the border ink-900 at 2 px; error adds an icon and a message; names pick their own direction, email and URL are explicit LTR islands that still start at the screen edge.',
      'الارتفاع 56 والزوايا 8 على سطح ورقي بخط رفيع. عند التركيز يصبح الإطار داكنًا بسماكة 2، وعند الخطأ تظهر أيقونة ورسالة. الأسماء تتبع اتجاه كتابتها، أما البريد والروابط فتُعرض من اليسار إلى اليمين وتبدأ من حافة الشاشة.',
    ),
    specs: [
      _spec(context, t('Empty', 'فارغ'), [
        GzTextField(
          label: t('Full name', 'الاسم الكامل'),
          placeholder: t('Name as on your ID', 'الاسم كما في الهوية'),
          helper: t('Arabic or English, four parts are fine.', 'يمكنك الكتابة بالعربية أو الإنجليزية.'),
        ),
      ]),
      _spec(context, t('Filled', 'معبأ'), [
        GzTextField(label: t('Full name', 'الاسم الكامل'), defaultValue: t('Reem Al-Dosari', 'ريم عبدالله الدوسري'), clearable: true),
      ]),
      _spec(context, t('Focus', 'تركيز'), [
        GzTextField(label: t('Full name', 'الاسم الكامل'), defaultValue: t('Reem Al-Dosari', 'ريم عبدالله الدوسري'), forceFocus: true),
      ]),
      _spec(context, t('Error', 'خطأ'), [GzTextField(label: t('Full name', 'الاسم الكامل'), error: l10n.commonFieldRequired)]),
      _spec(context, t('Disabled with a reason', 'معطل مع السبب'), [
        GzTextField(
          label: t('Wedding date', 'تاريخ الزفاف'),
          defaultValue: t('Thu 14 Jan 2027', 'الخميس 14 يناير 2027'),
          disabled: true,
          disabledReason: t('The date is fixed once the hotel approves.', 'يتعذر التعديل بعد موافقة الفندق.'),
        ),
      ]),
      _spec(context, t('Optional, with adornments', 'اختياري مع عناصر جانبية'), [
        GzTextField(
          label: t('Coupon', 'رمز الخصم'),
          optional: true,
          dir: GzFieldDir.ltr,
          defaultValue: 'GZ-WELCOME',
          startAdornment: const GzIcon(GzIcons.offer, size: GzIconSize.sm),
          endAdornment: GzText(t('Applied', 'مطبق'), role: GzTextRole.caption, color: context.gz.colors.iconSecondary),
        ),
      ]),
      _spec(context, t('Email: LTR island', 'البريد: اتجاه من اليسار'), [
        GzTextField(
          label: t('Email', 'البريد الإلكتروني'),
          dir: GzFieldDir.ltr,
          keyboardType: TextInputType.emailAddress,
          defaultValue: 'reem@example.com',
          helper: t('Receipts and invoices only.', 'للإيصالات والفواتير فقط.'),
        ),
      ]),
      _spec(context, t('Loading', 'جارٍ التحقق'), [
        GzTextField(label: t('Coupon', 'رمز الخصم'), dir: GzFieldDir.ltr, defaultValue: 'GZ-WELCOME', loading: true),
      ]),
      _spec(context, t('Verification code (one box per digit)', 'رمز التحقق (خانة لكل رقم)'), [
        GzOtpInput(label: t('Code sent to WhatsApp', 'الرمز المرسل عبر واتساب'), helper: t('Enter the 6 digits.', 'أدخل الأرقام الستة.')),
      ]),
    ],
  );
}

// ---------------------------------------------------------------------------------------------------------------- 2 phone
Widget _phoneSection(BuildContext context) {
  String t(String en, String ar) => _t(context, en, ar);
  return _sec(
    context,
    title: t('Phone', 'رقم الجوال'),
    note: t(
      'One LTR compound field in both languages: the fixed +965 chip, then 8 digits grouped 4 + 4. Eastern digits and +965 prefixes are normalised on entry. Label, hint and error follow the screen.',
      'حقل واحد من اليسار إلى اليمين في اللغتين: رمز +965 ثابت ثم 8 أرقام بمجموعتين. تُحوَّل الأرقام الهندية وتُحذف مقدمة +965 عند الإدخال. العنوان والتلميح والخطأ تتبع اتجاه الشاشة.',
    ),
    specs: [
      _spec(context, t('Empty', 'فارغ'), [GzPhoneField(helper: t('We send a code on WhatsApp.', 'سنرسل لك رمزًا عبر واتساب.'))]),
      _spec(context, t('Filled', 'معبأ'), [const GzPhoneField(defaultValue: '50000012')]),
      _spec(context, t('Focus', 'تركيز'), [const GzPhoneField(defaultValue: '5000', forceFocus: true)]),
      _spec(context, t('Error', 'خطأ'), [
        GzPhoneField(
          defaultValue: '70001234',
          error: t('Numbers starting with 7 are not used in Kuwait.', 'الأرقام التي تبدأ بالرقم 7 غير مستخدمة في الكويت.'),
        ),
      ]),
      _spec(context, t('Disabled', 'معطل'), [
        GzPhoneField(
          defaultValue: '50000012',
          disabled: true,
          disabledReason: t('Change it from account security.', 'يتم التغيير من إعدادات الأمان.'),
        ),
      ]),
    ],
  );
}

// ---------------------------------------------------------------------------------------------------------------- 3 otp
Widget _otpSection(BuildContext context) {
  String t(String en, String ar) => _t(context, en, ar);
  final code = t('Code', 'الرمز');
  return _sec(
    context,
    title: t('One-time code', 'رمز التحقق'),
    note: t(
      'Six boxes, digit 1 on the left even on an Arabic screen. Auto-advance, paste and autofill spread across the boxes. Errors shake once (not under reduced motion).',
      'ست خانات والرقم الأول عن اليسار حتى في الشاشة العربية. ينتقل المؤشر تلقائيًا ويُوزَّع اللصق والتعبئة التلقائية على الخانات. يهتز الصف مرة واحدة عند الخطأ ولا يهتز مع تقليل الحركة.',
    ),
    specs: [
      _spec(context, t('Empty', 'فارغ'), [GzOtpInput(label: code)]),
      _spec(context, t('Partly filled', 'معبأ جزئيًا'), [GzOtpInput(label: code, defaultValue: '482')]),
      _spec(context, t('Focus', 'تركيز'), [GzOtpInput(label: code, forceFocus: true)]),
      _spec(context, t('Error', 'خطأ'), [
        GzOtpInput(label: code, defaultValue: '482915', error: t('That code is not right. Try again.', 'الرمز غير صحيح. حاول مرة أخرى.')),
      ]),
      _spec(context, t('Verifying', 'جارٍ التحقق'), [GzOtpInput(label: code, defaultValue: '482915', loading: true)]),
      _spec(context, t('Disabled', 'معطل'), [
        GzOtpInput(label: code, disabled: true, disabledReason: t('Too many attempts. Try again later.', 'محاولات كثيرة. حاول لاحقًا.')),
      ]),
    ],
  );
}

// ---------------------------------------------------------------------------------------------------------------- 4 search
Widget _searchSection(BuildContext context) {
  String t(String en, String ar) => _t(context, en, ar);
  final prompt = t('Search halls, areas or hotels', 'ابحث عن قاعة أو منطقة أو فندق');
  return _sec(
    context,
    title: t('Search', 'البحث'),
    note: t(
      '48 by default, 44 in compact bars and sheets. The query takes its own direction.',
      'الارتفاع 48 افتراضيًا و44 في الأشرطة المدمجة. اتجاه النص يتبع لغة الكتابة.',
    ),
    specs: [
      _spec(context, t('Empty, 48', 'فارغ، 48'), [GzSearchField(placeholder: prompt)]),
      _spec(context, t('Filled, 44', 'معبأ، 44'), [GzSearchField(size: GzSearchSize.sm, defaultValue: t('Salmiya', 'السالمية'))]),
      _spec(context, t('Focus', 'تركيز'), [GzSearchField(placeholder: prompt, forceFocus: true)]),
      _spec(context, t('Loading', 'جارٍ البحث'), [GzSearchField(defaultValue: t('Mishref', 'مشرف'), loading: true)]),
      _spec(context, t('Disabled', 'معطل'), [
        GzSearchField(placeholder: t('Search is unavailable offline', 'البحث غير متاح بدون اتصال'), disabled: true),
      ]),
    ],
  );
}

// ---------------------------------------------------------------------------------------------------------------- 5 textarea
Widget _textAreaSection(BuildContext context) {
  final l10n = context.gzL10n;
  String t(String en, String ar) => _t(context, en, ar);
  final label = t('Notes for the hotel', 'ملاحظات للفندق');
  return _sec(
    context,
    title: t('Text area', 'نص متعدد الأسطر'),
    note: t(
      'Grows with the text up to eight lines; the counter sits at the end of the hint line.',
      'يكبر مع النص حتى ثمانية أسطر، ويظهر العداد في نهاية سطر التلميح.',
    ),
    specs: [
      _spec(context, t('Empty', 'فارغ'), [
        GzTextArea(
          label: label,
          optional: true,
          placeholder: t('Anything the hotel should know', 'أي شيء تودّ إبلاغ الفندق به'),
          maxLength: 300,
        ),
      ]),
      _spec(context, t('Filled', 'معبأ'), [
        GzTextArea(
          label: label,
          optional: true,
          maxLength: 300,
          defaultValue: t(
            'We would like a separate entrance for the ladies reception and a quiet room for the bride before the entrance.',
            'نرغب بمدخل مستقل للحفل النسائي وغرفة هادئة للعروس قبل الدخول.',
          ),
        ),
      ]),
      _spec(context, t('Error', 'خطأ'), [GzTextArea(label: label, error: l10n.commonFieldRequired, maxLength: 300)]),
      _spec(context, t('Disabled', 'معطل'), [
        GzTextArea(label: label, defaultValue: t('Sent with your request.', 'أُرسلت مع طلبك.'), disabled: true),
      ]),
    ],
  );
}

// ---------------------------------------------------------------------------------------------------------------- 6 stepper
const List<int> _presets = [100, 150, 200, 300, 400, 500, 650, 800, 1000];

Widget _stepperSection(BuildContext context) {
  String t(String en, String ar) => _t(context, en, ar);
  final f = context.gzFormat;
  return _sec(
    context,
    title: t('Guests: stepper and presets', 'عدد المعازيم: العداد والقيم الجاهزة'),
    note: t(
      'A stepper by the package step plus preset chips (ADR 0012 D9). 44 px buttons, press and hold repeats, limits disable the button.',
      'عداد بخطوة الباقة مع قيم جاهزة. أزرار بحجم 44، والضغط المطوّل يكرر الخطوة، وعند الحد يتعطل الزر.',
    ),
    specs: [
      _spec(context, t('Filled, step 50', 'معبأ، الخطوة 50'), [
        StatefulBuilder(
          builder: (context, set) => _StepperDemo(
            f: f,
            label: t('Guests in this hall', 'المعازيم في هذه القاعة'),
            presetsLabel: t('Preset guest counts', 'أعداد جاهزة'),
          ),
        ),
      ]),
      _spec(context, t('At the minimum', 'عند الحد الأدنى'), [
        GzStepper(label: t('Guests', 'المعازيم'), defaultValue: 100, min: 100, max: 1500, step: 50),
      ]),
      _spec(context, t('Disabled', 'معطل'), [
        GzStepper(label: t('Guests', 'المعازيم'), defaultValue: 350, min: 100, max: 1500, step: 50, disabled: true),
      ]),
    ],
  );
}

class _StepperDemo extends StatefulWidget {
  const _StepperDemo({required this.f, required this.label, required this.presetsLabel});

  final GzFormat f;
  final String label;
  final String presetsLabel;

  @override
  State<_StepperDemo> createState() => _StepperDemoState();
}

class _StepperDemoState extends State<_StepperDemo> {
  int guests = 350;

  @override
  Widget build(BuildContext context) {
    final f = widget.f;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzStepper(
          label: widget.label,
          caption: f.minGuests(200),
          value: guests,
          onChanged: (v) => setState(() => guests = v),
          min: 100,
          max: 1500,
          step: 50,
          valueText: (n) => f.plain(f.guests(n)),
        ),
        const SizedBox(height: GzSpace.s4),
        GzChipGroup<int>(
          label: widget.presetsLabel,
          value: _presets.contains(guests) ? guests : null,
          onChanged: (v) {
            if (v != null) setState(() => guests = v);
          },
          options: [for (final n in _presets) GzChipOption(value: n, label: '${f.integer(n)}${n == 1000 ? '+' : ''}')],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------------------------------------------- 7 range
Widget _rangeSection(BuildContext context) {
  String t(String en, String ar) => _t(context, en, ar);
  final f = context.gzFormat;
  String say(double n, GzRangeEdge e) => f.plain(f.money(n.round() * 1000));
  Widget kd(BuildContext c, double n, GzRangeEdge e) => _kd(c, n.round());
  return _sec(
    context,
    title: t('Budget range', 'نطاق الميزانية'),
    note: t(
      'Handles mirror with the language: the minimum sits at the start edge. Value labels use the figures voice and keep the currency left of the number.',
      'تنعكس المقابض مع اللغة فيقع الحد الأدنى عند حافة البداية. تظهر القيم بخط الأرقام وتبقى العملة على يسار الرقم.',
    ),
    specs: [
      _spec(context, t('Filled', 'معبأ'), [
        GzRangeSlider(
          label: t('Venue and catering budget', 'ميزانية القاعة والضيافة'),
          min: 5000,
          max: 50000,
          step: 500,
          defaultValue: (20000, 35000),
          captions: (t('From', 'من'), t('To', 'إلى')),
          thumbLabels: (t('Lowest budget', 'أقل ميزانية'), t('Highest budget', 'أعلى ميزانية')),
          formatValue: kd,
          valueText: say,
          edgeLabels: (_kd(context, 5000, edge: true), _kd(context, 50000, plus: true, edge: true)),
        ),
      ]),
      _spec(context, t('Narrow band', 'نطاق ضيق'), [
        GzRangeSlider(
          label: t('Budget', 'الميزانية'),
          min: 5000,
          max: 50000,
          step: 500,
          defaultValue: (10000, 12500),
          showCaptions: false,
          formatValue: kd,
          valueText: say,
        ),
      ]),
      _spec(context, t('Disabled', 'معطل'), [
        GzRangeSlider(
          label: t('Budget', 'الميزانية'),
          min: 5000,
          max: 50000,
          step: 500,
          defaultValue: (20000, 35000),
          disabled: true,
          showCaptions: false,
          formatValue: kd,
          valueText: say,
        ),
      ]),
    ],
  );
}

// ---------------------------------------------------------------------------------------------------------------- 8 segmented
Widget _segmentedSection(BuildContext context) {
  String t(String en, String ar) => _t(context, en, ar);
  final f = context.gzFormat;
  final view = [
    GzSegmentedOption(value: 'availability', label: t('Availability', 'التوفر')),
    GzSegmentedOption(value: 'prices', label: t('Prices', 'الأسعار')),
  ];
  return _sec(
    context,
    title: t('Segmented control and tabs', 'التبديل بين الخيارات والتبويبات'),
    note: t(
      'The selected option is an ink pill with a gold thread that slides over 320 ms, signed by the direction. Tabs carry the thread on a hairline baseline.',
      'الخيار المحدد قرص داكن بخيط ذهبي ينزلق خلال 320 ملّي ثانية باتجاه اللغة. أما التبويبات فيمر الخيط فيها على خط أساس رفيع.',
    ),
    specs: [
      _spec(context, t('Availability | Prices', 'التوفر | الأسعار'), [
        GzSegmentedControl<String>(label: t('Calendar view', 'عرض التقويم'), defaultValue: 'availability', options: view),
      ]),
      _spec(context, t('Hall (display face)', 'القاعة (الخط الزخرفي)'), [
        GzSegmentedControl<String>(
          label: t('Hall', 'القاعة'),
          face: GzSegmentedFace.hall,
          defaultValue: 'danah',
          options: [
            GzSegmentedOption(value: 'danah', label: t('Danah Ballroom', 'قاعة دانة')),
            GzSegmentedOption(value: 'majlis', label: t('Majlis Hall', 'قاعة المجلس')),
          ],
        ),
      ]),
      _spec(context, t('Three options', 'ثلاثة خيارات'), [
        GzSegmentedControl<String>(
          label: t('Session', 'الفترة'),
          defaultValue: 'evening',
          options: [
            GzSegmentedOption(value: 'afternoon', label: t('Afternoon', 'عصرًا')),
            GzSegmentedOption(value: 'evening', label: t('Evening', 'مساءً')),
            GzSegmentedOption(value: 'full', label: t('Full day', 'يوم كامل')),
          ],
        ),
      ]),
      _spec(context, t('Disabled', 'معطل'), [
        GzSegmentedControl<String>(label: t('Calendar view', 'عرض التقويم'), defaultValue: 'availability', disabled: true, options: view),
      ]),
      _spec(context, t('Tabs, equal width', 'تبويبات متساوية'), [
        GzTabs<String>(
          label: t('Venue sections', 'أقسام المكان'),
          defaultValue: 'about',
          items: [
            GzTabsItem(value: 'about', label: t('About', 'نبذة')),
            GzTabsItem(value: 'halls', label: t('Halls', 'القاعات'), count: f.plain(f.integer(3))),
            GzTabsItem(value: 'reviews', label: t('Reviews', 'التقييمات'), count: f.plain(f.integer(128))),
          ],
        ),
      ]),
      _spec(context, t('Tabs, hugging and scrolling', 'تبويبات بحجم النص'), [
        GzTabs<String>(
          label: t('Bookings', 'الحجوزات'),
          layout: GzTabsLayout.hug,
          defaultValue: 'all',
          items: [
            GzTabsItem(value: 'all', label: t('All', 'الكل')),
            GzTabsItem(value: 'pending', label: t('Pending', 'قيد الانتظار')),
            GzTabsItem(value: 'approved', label: t('Approved', 'تمت الموافقة')),
            GzTabsItem(value: 'confirmed', label: t('Confirmed', 'مؤكدة')),
            GzTabsItem(value: 'past', label: t('Past', 'السابقة'), disabled: true),
          ],
        ),
      ]),
    ],
  );
}

// ---------------------------------------------------------------------------------------------------------------- 9 chips
Widget _chipsSection(BuildContext context) {
  String t(String en, String ar) => _t(context, en, ar);
  final f = context.gzFormat;
  final bands = <(String, int, int?)>[
    ('u5', 0, 5000),
    ('5-10', 5000, 10000),
    ('10-20', 10000, 20000),
    ('20-35', 20000, 35000),
    ('35+', 35000, null),
  ];
  String bandLabel(int lo, int? hi) => hi == null
      ? '${f.integer(lo)}+'
      : lo == 0
      ? t('Under ${f.integer(hi)}', 'أقل من ${f.integer(hi)}')
      : f.numberRange(lo, hi);
  return _sec(
    context,
    title: t('Choice chips', 'شرائح الاختيار'),
    note: t(
      'Single choice is a radio group, multiple choice a set of toggles. Selected = ink border and the gold bead, never a gold fill.',
      'الاختيار الواحد مجموعة اختيار مفردة، والمتعدد مجموعة أزرار تبديل. المحدد بإطار داكن وخرزة ذهبية، ولا تعبئة ذهبية أبدًا.',
    ),
    specs: [
      _spec(context, t('Single', 'اختيار واحد'), [
        GzChipGroup<String>(
          label: t('Budget band', 'نطاق الميزانية'),
          defaultValue: '20-35',
          options: [for (final (value, lo, hi) in bands) GzChipOption(value: value, label: bandLabel(lo, hi))],
        ),
      ]),
      _spec(context, t('Multiple', 'اختيار متعدد'), [
        GzChipGroup<String>.multiple(
          label: t('Audience', 'نوع الحفل'),
          defaultValues: const ['women'],
          options: [
            GzChipOption(value: 'women', label: t('Ladies’ reception', 'الحفل النسائي')),
            GzChipOption(value: 'men', label: t('Men’s reception', 'الحفل الرجالي')),
            GzChipOption(value: 'mixed', label: t('Mixed', 'مختلط')),
          ],
        ),
      ]),
      _spec(context, t('Rail with a disabled chip', 'شريط أفقي مع شريحة معطلة'), [
        GzChipGroup<String>(
          label: t('Area', 'المنطقة'),
          layout: GzChipLayout.rail,
          defaultValue: 'salmiya',
          options: [
            GzChipOption(value: 'salmiya', label: t('Salmiya', 'السالمية')),
            GzChipOption(value: 'hawalli', label: t('Hawalli', 'حولي')),
            GzChipOption(value: 'mishref', label: t('Mishref', 'مشرف')),
            GzChipOption(value: 'jabriya', label: t('Jabriya', 'الجابرية'), disabled: true),
            GzChipOption(value: 'shuwaikh', label: t('Shuwaikh', 'الشويخ')),
          ],
        ),
      ]),
    ],
  );
}

// ---------------------------------------------------------------------------------------------------------------- 10 toggles
Widget _togglesSection(BuildContext context) {
  String t(String en, String ar) => _t(context, en, ar);
  return _sec(
    context,
    title: t('Toggle rows', 'صفوف التبديل'),
    note: t(
      'The whole row is the target; the switch is ink with a check, never gold.',
      'الصف كله قابل للنقر، والمفتاح داكن مع علامة صح ولا يستخدم الذهبي أبدًا.',
    ),
    specs: [
      _spec(context, t('On', 'مفعّل'), [
        GzToggleRow(
          title: t('Booking updates', 'تحديثات الحجز'),
          description: t('When the hotel replies or a payment is due.', 'عند رد الفندق أو استحقاق دفعة.'),
          defaultChecked: true,
        ),
      ]),
      _spec(context, t('Off', 'متوقف'), [
        GzToggleRow(
          title: t('Offers and news', 'العروض والأخبار'),
          description: t('At most one message a week.', 'رسالة واحدة كحد أقصى في الأسبوع.'),
        ),
      ]),
      _spec(context, t('Disabled with a reason', 'معطل مع السبب'), [
        GzToggleRow(
          title: t('Payment reminders', 'تذكيرات الدفع'),
          defaultChecked: true,
          disabled: true,
          disabledReason: t('Always on while a payment is due.', 'تبقى مفعّلة ما دامت هناك دفعة مستحقة.'),
        ),
      ]),
    ],
  );
}

// ---------------------------------------------------------------------------------------------------------------- 11 select
Widget _selectSection(BuildContext context) {
  String t(String en, String ar) => _t(context, en, ar);
  final hawalli = t('Hawalli', 'حولي');
  final areas = <GzSelectOption<String>>[
    GzSelectOption(value: 'salmiya', label: t('Salmiya', 'السالمية'), description: hawalli, aliases: 'Salmiyah'),
    GzSelectOption(value: 'hawalli', label: t('Hawalli', 'حولي'), description: hawalli),
    GzSelectOption(value: 'jabriya', label: t('Jabriya', 'الجابرية'), description: hawalli),
    GzSelectOption(value: 'mishref', label: t('Mishref', 'مشرف'), description: hawalli, aliases: 'Mishrif Meshref'),
    GzSelectOption(value: 'shuwaikh', label: t('Shuwaikh', 'الشويخ'), description: t('Capital', 'العاصمة')),
    GzSelectOption(value: 'bneid', label: t('Bneid Al-Qar', 'بنيد القار'), description: t('Capital', 'العاصمة'), aliases: 'Bnaid Al-Gar'),
    GzSelectOption(value: 'fahaheel', label: t('Fahaheel', 'الفحيحيل'), description: t('Ahmadi', 'الأحمدي')),
    GzSelectOption(value: 'jahra', label: t('Jahra', 'الجهراء'), description: t('Jahra', 'الجهراء'), disabled: true),
  ];
  final halls = <GzSelectOption<String>>[
    GzSelectOption(value: 'danah', label: t('Danah Ballroom', 'قاعة دانة'), description: t('Up to 650 guests', 'حتى 650 ضيفًا')),
    GzSelectOption(value: 'majlis', label: t('Majlis Hall', 'قاعة المجلس'), description: t('Up to 300 guests', 'حتى 300 ضيف')),
  ];
  void tap() {}
  final c = context.gz.colors;
  Widget card(List<Widget> rows) => Container(
    padding: const EdgeInsets.symmetric(horizontal: GzSpace.s4),
    decoration: BoxDecoration(
      color: c.surfaceRaised,
      borderRadius: GzRadius.mdAll,
      border: Border.all(color: c.borderStrong, width: GzStroke.hair),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++)
          i == 0
              ? rows[i]
              : DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                    ),
                  ),
                  child: rows[i],
                ),
      ],
    ),
  );
  return _sec(
    context,
    title: t('Pickers', 'حقول الاختيار'),
    note: t(
      'No native select: a button opens a sheet with a listbox. The field variant is for forms, the row variant for the Home brief card. Search understands Arabic spelling variants and aliases.',
      'لا توجد قائمة منسدلة أصلية: زر يفتح ورقة سفلية تحتوي القائمة. يصلح الحقل للنماذج ويصلح الصف لبطاقة الطلب في الرئيسية. يتجاوز البحث اختلافات الإملاء ويدعم الأسماء البديلة.',
    ),
    specs: [
      _spec(context, t('Field, empty', 'حقل، فارغ'), [
        GzSelectRow<String>(
          label: t('Area', 'المنطقة'),
          placeholder: t('Choose an area', 'اختر المنطقة'),
          options: areas,
          onTap: tap,
          helper: t('Where the venue is.', 'موقع المكان.'),
        ),
      ]),
      _spec(context, t('Field, filled', 'حقل، معبأ'), [
        GzSelectRow<String>(label: t('Area', 'المنطقة'), options: areas, values: const ['salmiya'], onTap: tap),
      ]),
      _spec(context, t('Field, multiple', 'حقل، متعدد'), [
        GzSelectRow<String>(label: t('Areas', 'المناطق'), options: areas, values: const ['salmiya', 'mishref'], onTap: tap),
      ]),
      _spec(context, t('Field, focus', 'حقل، تركيز'), [
        GzSelectRow<String>(label: t('Area', 'المنطقة'), options: areas, values: const ['mishref'], onTap: tap, forceFocus: true),
      ]),
      _spec(context, t('Field, error', 'حقل، خطأ'), [
        GzSelectRow<String>(
          label: t('Area', 'المنطقة'),
          placeholder: t('Choose an area', 'اختر المنطقة'),
          options: areas,
          onTap: tap,
          error: t('Choose an area to see halls.', 'اختر منطقة لعرض القاعات.'),
        ),
      ]),
      _spec(context, t('Field, disabled', 'حقل، معطل'), [
        GzSelectRow<String>(
          label: t('Hall', 'القاعة'),
          options: halls,
          values: const ['danah'],
          disabled: true,
          disabledReason: t('This hotel has one hall.', 'هذا الفندق فيه قاعة واحدة.'),
        ),
      ]),
      _spec(context, t('Rows in a brief card', 'صفوف في بطاقة الطلب'), [
        card([
          GzSelectRow<String>(
            variant: GzSelectVariant.row,
            divider: true,
            label: t('Area', 'المنطقة'),
            options: areas,
            values: const ['salmiya'],
            onTap: tap,
          ),
          GzSelectRow<String>(
            variant: GzSelectVariant.row,
            divider: true,
            label: t('Hall', 'القاعة'),
            placeholder: t('Not decided', 'لم يتحدد بعد'),
            options: halls,
            onTap: tap,
          ),
          GzSelectRow<String>(
            variant: GzSelectVariant.row,
            label: t('Hall', 'القاعة'),
            options: halls,
            values: const ['majlis'],
            disabled: true,
          ),
        ]),
      ]),
    ],
  );
}

// ---------------------------------------------------------------------------------------------------------------- 12 calendar
const int _weekday = 47000;
const int _weekend = 49000;

/// January 2027 as the hotel would publish it: a few booked, held and blocked dates, per-day prices.
Map<String, GzCalendarDayInfo> _january2027() {
  const booked = ['2027-01-07', '2027-01-16', '2027-01-23', '2027-01-30', '2027-01-09'];
  const held = ['2027-01-15', '2027-01-21'];
  const blocked = ['2027-01-22', '2027-01-27'];
  final out = <String, GzCalendarDayInfo>{};
  for (var d = 1; d <= 31; d++) {
    final iso = '2027-01-${d.toString().padLeft(2, '0')}';
    final wd = gzWeekdayOfIso(iso);
    final status = booked.contains(iso)
        ? GzDayStatus.booked
        : held.contains(iso)
        ? GzDayStatus.held
        : blocked.contains(iso)
        ? GzDayStatus.blocked
        : GzDayStatus.available;
    out[iso] = GzCalendarDayInfo(status: status, price: wd >= 4 ? _weekend : _weekday);
  }
  return out;
}

String _basis(BuildContext context) {
  final f = context.gzFormat;
  return context.gzL10n.uiInputsCalendarPriceBasis(f.moneyParts(_weekend).currency, context.gzL10n.commonUnitPerGuest);
}

Widget _calendarSection(BuildContext context) {
  String t(String en, String ar) => _t(context, en, ar);
  final f = context.gzFormat;
  final days = _january2027();
  final today = f.isoDay(f.now());
  final basis = _basis(context);
  const jan = GzYm(2027, 1);
  return _sec(
    context,
    title: t('Calendar', 'التقويم'),
    note: t(
      'Sunday-first, seven flex columns, cells 52 high and 44 wide at least. The Thursday to Saturday band is one block at the inline-end edge in both languages. Booked is struck, blocked is struck in a box, held carries a gold-700 bead, today an ink hairline, the chosen day the one gold fill.',
      'يبدأ الأسبوع بالأحد في سبعة أعمدة، والخلية بارتفاع 52 وعرض لا يقل عن 44. تشكّل أيام الخميس إلى السبت كتلة واحدة عند حافة النهاية في اللغتين. المحجوز مشطوب، والمغلق مشطوب داخل إطار، والمعلّق عليه خرزة ذهبية داكنة، واليوم بخط داكن، واليوم المختار هو التعبئة الذهبية الوحيدة.',
    ),
    specs: [
      _spec(context, t('Availability, one date chosen', 'التوفر، تاريخ واحد مختار'), [
        GzCalendar(
          label: t('Wedding date', 'تاريخ الزفاف'),
          days: days,
          defaultValue: '2027-01-14',
          defaultMonth: jan,
          minDate: today,
          summary: true,
          priceBasis: basis,
        ),
      ]),
      _spec(context, t('Prices view', 'عرض الأسعار'), [
        GzCalendar(
          label: t('Wedding date', 'تاريخ الزفاف'),
          days: days,
          defaultValue: '2027-01-14',
          defaultMonth: jan,
          defaultView: GzCalendarView.prices,
          minDate: today,
          priceBasis: basis,
        ),
      ]),
      _spec(context, t('Range, the thread joins the ends', 'نطاق، الخيط يصل بين الطرفين'), [
        GzCalendar.range(
          label: t('Block dates', 'إغلاق التواريخ'),
          days: days,
          defaultValue: const GzDateRange(start: '2027-01-03', end: '2027-01-06'),
          defaultMonth: jan,
          summary: true,
          legend: false,
        ),
      ]),
      _spec(context, t('Today, past dates and the first selectable month', 'اليوم والتواريخ السابقة وأول شهر قابل للاختيار'), [
        GzCalendar(
          label: t('Wedding date', 'تاريخ الزفاف'),
          defaultMonth: const GzYm(2026, 11),
          minDate: today,
          days: const {
            '2026-11-14': GzCalendarDayInfo(status: GzDayStatus.booked),
            '2026-11-20': GzCalendarDayInfo(status: GzDayStatus.held),
            '2026-11-26': GzCalendarDayInfo(status: GzDayStatus.blocked),
          },
        ),
      ]),
    ],
  );
}

// ---------------------------------------------------------------------------------------------------------------- 13 slots
Widget _slotsSection(BuildContext context) {
  String t(String en, String ar) => _t(context, en, ar);
  final f = context.gzFormat;
  List<GzTimeSession> sessions(GzSessionStatus evening, GzSessionStatus full) => [
    GzTimeSession(
      id: 'afternoon',
      label: t('Afternoon', 'العصر'),
      start: const GzTimeOfDay(12, 0),
      end: const GzTimeOfDay(16, 0),
      price: 38000,
    ),
    GzTimeSession(
      id: 'evening',
      label: t('Evening', 'المساء'),
      start: const GzTimeOfDay(21, 0),
      end: const GzTimeOfDay(2, 0),
      price: 49000,
      status: evening,
    ),
    GzTimeSession(
      id: 'full',
      label: t('Full day', 'يوم كامل'),
      start: const GzTimeOfDay(12, 0),
      end: const GzTimeOfDay(2, 0),
      price: 72000,
      status: full,
    ),
  ];
  final unit = t('per guest', 'للضيف');
  return _sec(
    context,
    title: t('Sessions', 'الفترات'),
    note: t(
      'Afternoon, Evening and Full day (ADR 0002). Shown only when more than one session is free. A session that ends after midnight belongs to its start date.',
      'العصر والمساء ويوم كامل. تظهر فقط عند توفر أكثر من فترة. الفترة التي تنتهي بعد منتصف الليل تتبع تاريخ بدايتها.',
    ),
    specs: [
      _spec(context, t('All free, one chosen', 'كلها متاحة، واحدة مختارة'), [
        GzTimeSlotPicker(
          sessions: sessions(GzSessionStatus.available, GzSessionStatus.available),
          defaultValue: 'evening',
          date: '2027-01-14',
          priceUnit: unit,
        ),
      ]),
      _spec(context, t('Held and booked', 'معلّقة ومحجوزة'), [
        GzTimeSlotPicker(
          sessions: sessions(GzSessionStatus.held, GzSessionStatus.booked),
          defaultValue: 'afternoon',
          date: '2027-01-14',
          priceUnit: unit,
        ),
      ]),
      _spec(context, t('Nothing chosen yet', 'لم يتم الاختيار بعد'), [
        GzTimeSlotPicker(sessions: sessions(GzSessionStatus.available, GzSessionStatus.available), date: '2027-01-14', priceUnit: unit),
      ]),
      _spec(context, t('Disabled', 'معطل'), [
        GzTimeSlotPicker(sessions: sessions(GzSessionStatus.available, GzSessionStatus.available), date: '2027-01-14', disabled: true),
      ]),
      GzText(
        f.timeRange(f.kuwaitDate(2027, 1, 14, hour: 21), f.kuwaitDate(2027, 1, 15, hour: 2)),
        role: GzTextRole.caption,
        color: context.gz.colors.textSecondary,
        figures: true,
      ),
    ],
  );
}

// ---------------------------------------------------------------------------------------------------------------- 14 datefield
Widget _dateFieldSection(BuildContext context) {
  String t(String en, String ar) => _t(context, en, ar);
  void tap() {}
  final label = t('Wedding date', 'تاريخ الزفاف');
  return _sec(
    context,
    title: t('Date field', 'حقل التاريخ'),
    note: t(
      'Opens the calendar in a sheet (no native date input). Confirm commits, closing discards. In Arabic the summary adds the Hijri line.',
      'يفتح التقويم في ورقة سفلية بلا حقل تاريخ أصلي. التأكيد يحفظ الاختيار والإغلاق يلغيه. في العربية يضيف الملخص سطر التاريخ الهجري.',
    ),
    specs: [
      _spec(context, t('Empty', 'فارغ'), [
        GzDateField(label: label, onTap: tap, helper: t('Gregorian dates, Kuwait time.', 'تواريخ ميلادية بتوقيت الكويت.')),
      ]),
      _spec(context, t('Filled', 'معبأ'), [GzDateField(label: label, onTap: tap, value: '2027-01-14')]),
      _spec(context, t('Range', 'نطاق'), [
        GzDateField.range(
          label: t('Blocked dates', 'التواريخ المغلقة'),
          onTap: tap,
          value: const GzDateRange(start: '2027-01-03', end: '2027-01-06'),
        ),
      ]),
      _spec(context, t('Focus', 'تركيز'), [GzDateField(label: label, onTap: tap, value: '2027-01-14', forceFocus: true)]),
      _spec(context, t('Error', 'خطأ'), [
        GzDateField(label: label, onTap: tap, error: t('Choose a date to continue.', 'اختر تاريخًا للمتابعة.')),
      ]),
      _spec(context, t('Disabled', 'معطل'), [
        GzDateField(
          label: label,
          value: '2027-01-14',
          disabled: true,
          disabledReason: t('Fixed once the hotel approves.', 'يتعذر التعديل بعد موافقة الفندق.'),
        ),
      ]),
    ],
  );
}
