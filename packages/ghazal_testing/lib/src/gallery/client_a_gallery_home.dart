// Gallery sections 1 to 4 of the client page: brief, category-tile, offer-card, countdown (web HomeSections.tsx).
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/src/client/client_a.dart';
import 'package:ghazal_ui/src/core/core.dart' show GzFormatScope, GzPreviewState;
import 'package:ghazal_ui/src/foundation.dart';

import 'client_a_gallery_kit.dart';

Widget briefSection(BuildContext context) {
  String l(String en, String ar) => caL(context, en, ar);
  final story = clientAData.brief;
  final partial = const GzBrief(audience: Audience.women);
  final noBudgetCap = GzBrief(audience: story.audience, guests: story.guests, date: story.date, areas: story.areas, budgetMinFils: 35000000);
  final area = clientAData.areas;
  final manyAreas = GzBrief(
    audience: story.audience,
    guests: story.guests,
    date: story.date,
    areas: [for (final id in ['salmiya', 'sharq', 'jabriya', 'mishref']) area[id]!],
    budgetMinFils: story.budgetMinFils,
    budgetMaxFils: story.budgetMaxFils,
  );
  return caSection(
    context,
    title: l('The brief', 'تفاصيل زفافكم'),
    note: l(
      'Home is a structured card with four rows of 64 and one gold action showing a live count. Everywhere else the brief is a typeset sentence, read-only, one 44+ target that opens the edit sheet; in the sheet each of the four decisions is underlined in gold and tappable.',
      'الرئيسية بطاقة منظّمة من أربعة صفوف بارتفاع 64 وإجراء ذهبي واحد بعدد حي. وفي بقية الشاشات تفاصيل الزفاف جملة مصفوفة للقراءة فقط، هدف لمس واحد يفتح ورقة التعديل؛ وفي الورقة يُرسم تحت كل قرار من القرارات الأربعة خط ذهبي ويمكن لمسه.',
    ),
    specs: [
      // The web prints an empty caption paragraph (a space) under the card: zero high, but it is a flex item, so the gap of 24 stays.
      caSpec(context, l('Brief card · filled · live count', 'بطاقة التفاصيل · معبأة · عدد حي'), [GzBriefCard(brief: story, count: 38, onEdit: (_) {}, onShow: () {}), const SizedBox.shrink()]),
      caSpec(context, l('Partly empty: muted placeholders, no count (offline) · open budget · four areas', 'ناقصة: نصوص بديلة هادئة بلا عدد (دون اتصال) · ميزانية مفتوحة · أربع مناطق'), [
        GzBriefCard(brief: partial, onShow: () {}),
        GzBriefCard(brief: noBudgetCap, onShow: () {}),
        GzBriefCard(brief: manyAreas, count: 12, onShow: () {}),
      ]),
      caSpec(context, l('Loading the count: the gold action draws its thread once', 'تحميل العدد: يرسم الزر الذهبي خيطه مرة واحدة'), [GzBriefCard(brief: story, count: 38, loading: true, onShow: () {})]),
      caSpec(context, l('Sentence · results header (display, up to three lines)', 'الجملة · رأس النتائج (خط العرض حتى ثلاثة أسطر)'), [GzBriefSentence(brief: story, onEdit: () {})]),
      caSpec(context, l('Sentence · compare header (budget omitted) · booking header (budget and area omitted)', 'الجملة · رأس المقارنة (بلا ميزانية) · رأس الحجز (بلا ميزانية ومنطقة)'), [
        GzBriefSentence(brief: story, variant: GzBriefSentenceVariant.compare, onEdit: () {}),
        GzBriefSentence(brief: story, variant: GzBriefSentenceVariant.booking, onEdit: () {}),
      ]),
      caSpec(context, l('Sentence · edit form in the Brief sheet: four underlined decisions, each 44 high', 'الجملة · نموذج التعديل في الورقة: أربعة قرارات تحتها خط، لكل منها 44'), [
        GzBriefSentence(brief: story, variant: GzBriefSentenceVariant.edit, onEditField: (_) {}),
        GzBriefSentence(brief: partial, variant: GzBriefSentenceVariant.edit, onEditField: (_) {}),
      ]),
    ],
  );
}

class _Tile {
  const _Tile(this.en, this.ar, this.venue, this.types);

  final String en;
  final String ar;
  final String venue;
  final List<String> types;
}

const List<_Tile> _tiles = [
  _Tile('Hotel ballrooms', 'قاعات الفنادق', 'V01', ['hotel']),
  _Tile('Palaces and halls', 'القصور والقاعات', 'V09', ['hall']),
  _Tile('Outdoor and beach', 'الهواء الطلق', 'V03', ['outdoor', 'resort']),
  _Tile('Villas and estates', 'الفلل والعزب', 'V04', ['villa']),
  _Tile('Resorts', 'المنتجعات', 'V12', ['resort']),
  _Tile('Convention centres', 'مراكز المؤتمرات', 'V08', ['convention']),
];

String? _cover(String id) {
  final cover = clientAData.result(id).venue.cover;
  return cover == null ? null : (cover.baseUrl ?? cover.file);
}

Widget categoryTileSection(BuildContext context) {
  String l(String en, String ar) => caL(context, en, ar);
  final f = GzFormatScope.of(context);
  const sel = 'V03';
  String caption(_Tile t) {
    final n = clientAData.results.values.where((r) => t.types.contains(r.venue.type.value)).length;
    return f.plural(n, {'=1': l('1 hall', 'قاعة واحدة'), '=2': l('2 halls', 'قاعتان'), 'few': '{n} ${l('halls', 'قاعات')}', 'other': '{n} ${l('halls', 'قاعة')}'});
  }

  Widget tile(_Tile t) => GzCategoryTile(label: l(t.en, t.ar), image: _cover(t.venue), caption: caption(t), selected: t.venue == sel, onOpen: () {});
  return caSection(
    context,
    title: l('Category tiles', 'بلاطات التصنيفات'),
    note: l(
      'Six quick categories as photograph tiles, 4:5, radius 12. The name sits on one bottom scrim token in canvas text; the count under it comes from the formatter. No coloured chips, no icon grid.',
      'ستة تصنيفات سريعة كبلاطات صور بنسبة 4:5 وزوايا 12. يقع الاسم على تعتيم سفلي واحد بنص بلون الخلفية، والعدد تحته من المنسّق. لا شرائح ملوّنة ولا شبكة أيقونات.',
    ),
    specs: [
      caSpec(context, l('Over the photograph · two across · one selected', 'فوق الصورة · اثنتان في الصف · واحدة محددة'), [
        for (final i in [0, 2, 4]) caRow([tile(_tiles[i]), tile(_tiles[i + 1])]),
      ]),
      caSpec(context, l('Wall-label form · no photograph · pressed · loading', 'صيغة اللوحة التعريفية · بلا صورة · الضغط · التحميل'), [
        caRow([
          GzCategoryTile(label: l('Hotel ballrooms', 'قاعات الفنادق'), image: _cover('V01'), placement: GzCategoryTilePlacement.under, caption: l('6 halls', '6 قاعات')),
          GzCategoryTile(label: l('Government halls', 'القاعات الحكومية'), placement: GzCategoryTilePlacement.under, caption: l('1 hall', 'قاعة واحدة')),
          GzCategoryTile(label: l('Resorts', 'المنتجعات'), image: _cover('V12'), previewState: GzPreviewState.pressed),
        ]),
        caRow([
          const GzCategoryTile(label: '', loading: true),
          const GzCategoryTile(label: '', loading: true, placement: GzCategoryTilePlacement.under),
          const GzCategoryTile(label: '', loading: true),
        ]),
      ]),
    ],
  );
}

Widget offerSection(BuildContext context) {
  String l(String en, String ar) => caL(context, en, ar);
  final d = clientAData;
  final live = d.live;
  Widget card(VoucherWindow w, {bool loading = false, bool pressed = false}) =>
      GzVoucherWindowCard(window: w, venueName: d.venueNames[w.venueId], onOpen: () {}, loading: loading, previewState: pressed ? GzPreviewState.pressed : null);
  return caSection(
    context,
    title: l('Voucher price window', 'بطاقة سعر الكوبون'),
    note: l(
      'The rose panel: voucher-price drops and quiet notes only. The lower voucher rate with its unit, the venue’s own title in the serif, the conditions as plain facts. There is no coupon code (the voucher is the code). An ended or scheduled window is muted and has no action; there is never a countdown or a scarcity line.',
      'اللوحة الوردية: لتخفيضات سعر الكوبون والملاحظات الهادئة فقط. سعر الكوبون الأقل بوحدته وعنوان المكان بالخط ذي الزوائد والشروط كحقائق واضحة. لا يوجد رمز كوبون (الكوبون نفسه هو الرمز). النافذة المنتهية أو المجدولة باهتة بلا إجراء؛ ولا عدّاد ولا عبارة ندرة أبدًا.',
    ),
    specs: [
      caSpec(context, l('Per guest · weekdays and event window', 'للضيف · أيام الأسبوع ونافذة المناسبات'), [card(live[0])]),
      caSpec(context, l('Another venue · another rate', 'مكان آخر · سعر آخر'), [card(live[1]), card(live[2])]),
      caSpec(context, l('Ended · scheduled · pressed · loading', 'منتهية · مجدولة · الضغط · التحميل'), [
        card(d.ended),
        card(d.scheduled),
        card(live[0], pressed: true),
        card(live[0], loading: true),
      ]),
    ],
  );
}

Widget countdownSection(BuildContext context) {
  String l(String en, String ar) => caL(context, en, ar);
  final f = GzFormatScope.of(context);
  final d = clientAData;
  final where = d.venueNames['V01']!.of(context.gz.locale.languageCode);
  final date = d.weddingDate.toString();
  final days = f.daysUntil(date);
  final rows = <({int days, String en, String ar, double progress})>[
    (days: 365, en: 'A year to go (365)', ar: 'سنة (365)', progress: 0.04),
    (days: 180, en: 'Six months (180)', ar: 'ستة أشهر (180)', progress: 0.5),
    (days: days, en: 'Plain count · the story, 63 days', ar: 'عدّ عادي · القصة 63 يومًا', progress: 0.83),
    (days: 30, en: 'One month (30)', ar: 'شهر (30)', progress: 0.9),
    (days: 7, en: 'One week (7): guest count locks', ar: 'أسبوع (7): تثبيت عدد الضيوف', progress: 0.97),
    (days: 1, en: 'Tomorrow', ar: 'غدًا', progress: 0.99),
    (days: 0, en: 'Today', ar: 'اليوم', progress: 1),
  ];
  return caSection(
    context,
    title: l('Countdown card', 'بطاقة العدّ التنازلي'),
    note: l(
      'The one ink panel of the screen. Whole days only: the serif numeral, the unit, one calm sentence that changes at 365, 180, 30, 7, tomorrow and today, and a gold thread showing how much of the wait has passed.',
      'اللوحة الداكنة الوحيدة في الشاشة. أيام كاملة فقط: الرقم بالخط ذي الزوائد والوحدة وجملة هادئة تتغير عند 365 و180 و30 و7 وغدًا واليوم، وخيط ذهبي يبيّن ما انقضى من الانتظار.',
    ),
    specs: [
      for (final r in rows)
        caSpec(context, l(r.en, r.ar), [
          GzCountdownCard(
            days: r.days,
            eventDate: date,
            where: where,
            progress: r.progress,
            actionLabel: r.days > 7 ? l('View your booking', 'عرض حجزكم') : l('Open the day plan', 'فتح خطة اليوم'),
            onAction: () {},
          ),
        ]),
      caSpec(context, l('Loading', 'التحميل'), [GzCountdownCard(days: days, eventDate: date, loading: true)]),
    ],
  );
}
