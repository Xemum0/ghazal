// The client gallery, part B: the Flutter twin of sections 8 to 12 of design/src/gallery/client.tsx (compare-tray, compare-table,
// compare-parts, reviews, venue-info). Same specimens, states and sample text as the web gallery files CompareSections.tsx and
// VenueInfoSections.tsx, built from real objects of the mock (GzWorld). The file slugs are the web section ids.
// Parity: `node tools/parity/parity.mjs --gallery client --sections 8,9,10,11,12` after `flutter test test/gallery/client_b_gallery_test.dart`.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/src/client/client_b.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:path/path.dart' as p;

import '../world.dart';
import 'client_b_gallery_kit.dart';
import 'gz_gallery.dart';

/// The data the sections read, fetched once through the real repositories (never hand-built models).
class ClientBGalleryData {
  ClientBGalleryData({
    required this.story,
    required this.units,
    required this.noDate,
    required this.venues,
    required this.details,
    required this.areaNames,
    required this.photos,
    required this.reviews,
    required this.amenityDefs,
    required this.date,
  });

  /// Columns of the three table specimens (V01 V05 V07, V01 V04 V19, V01 V05 V09).
  final List<CompareColumn> story;
  final List<CompareColumn> units;
  final List<CompareColumn> noDate;

  /// Venue summaries by id (V01, V05, V07, V09).
  final Map<String, VenueSummary> venues;
  final Map<String, Venue> details;
  final Map<String, LocalizedText> areaNames;

  /// Second gallery photograph (else the cover) per venue, the photos row.
  final Map<String, ImageRef> photos;
  final List<Review> reviews;
  final List<AmenityDef> amenityDefs;
  final LocalDate date;

  static ImageRef _ref(GalleryItem g) => ImageRef(
    id: g.id,
    file: g.file,
    baseUrl: g.baseUrl,
    width: g.width,
    height: g.height,
    orientation: g.orientation,
    aspect: g.aspect,
    blurhash: g.blurhash,
    alt: g.alt,
  );

  static Future<ClientBGalleryData> load(GzWorld world) async {
    final repos = world.repos('reem');
    final date = LocalDate.parse('2027-01-14');
    Future<List<CompareColumn>> compare(List<String> ids, {LocalDate? on}) async => (await repos.venues.compareVenues(
      body: CompareInput(venueIds: ids, date: on, guests: 350, audience: Audience.women, originId: 'ref-salmiya'),
    )).columns;
    final story = await compare(['V01', 'V05', 'V07'], on: date);
    final units = await compare(['V01', 'V04', 'V19'], on: date);
    final noDate = await compare(['V01', 'V05', 'V09']);
    final venues = {
      for (final c in [...story, ...units, ...noDate]) c.venue.id: c.venue,
    };
    final details = <String, Venue>{};
    for (final id in ['V01', 'V03', 'V04', 'V05', 'V07', 'V09', 'V19']) {
      details[id] = (await repos.venues.getVenue(venueId: id)).venue;
    }
    final photos = <String, ImageRef>{
      for (final e in details.entries)
        if (e.value.gallery.length > 1) e.key: _ref(e.value.gallery[1]) else if (e.value.cover != null) e.key: e.value.cover!,
    };
    final areas = await repos.venues.listAreas();
    final reviews = (await repos.reviews.listVenueReviews(venueId: 'V01', limit: 50)).items;
    var dir = Directory.current.absolute;
    for (var i = 0; i < 8 && !File(p.join(dir.path, 'packages/contracts/fixtures/engine-cases.json')).existsSync(); i++) {
      dir = dir.parent;
    }
    final defs = (jsonDecode(File(p.join(dir.path, 'packages/ghazal_mock_api/assets/seed/AmenityDef.seed.json')).readAsStringSync()) as List)
        .map((e) => AmenityDef.fromJson((e as Map).cast<String, Object?>()))
        .toList();
    return ClientBGalleryData(
      story: story,
      units: units,
      noDate: noDate,
      venues: venues,
      details: details,
      areaNames: {for (final a in areas.areas) a.id: a.name},
      photos: photos,
      reviews: reviews,
      amenityDefs: defs,
      date: date,
    );
  }
}

/// The section ids (the web `data-gz-section` ids) with their place on the web page.
const List<(int, String)> clientBGalleryIds = [(8, 'compare-tray'), (9, 'compare-table'), (10, 'compare-parts'), (11, 'reviews'), (12, 'venue-info')];

/// The sections of this part. [data] is read lazily: the test fills it in `setUpAll`.
List<GzGallerySection> clientBGallerySections(ClientBGalleryData Function() data) => [
  for (final (n, id) in clientBGalleryIds)
    GzGallerySection(id, switch (id) {
      'compare-tray' => (c) => _traySection(c, data()),
      'compare-table' => (c) => _tableSection(c, data()),
      'compare-parts' => (c) => _partsSection(c, data()),
      'reviews' => (c) => _reviewsSection(c, data()),
      _ => (c) => _venueInfoSection(c, data()),
    }, number: n),
];

// ------------------------------------------------------------------------------------------------------------------ tray
Widget _traySection(BuildContext context, ClientBGalleryData d) {
  String t(String en, String ar) => gcT(context, en, ar);
  final v = d.venues;
  return gcSection(
    context,
    title: t('Compare tray', 'شريط المقارنة'),
    note: t(
      'Floating, never nagging: it appears after the first add, says "Add one more" with hairline empty slots, becomes actionable at two, holds three at most, and collapses to a 44 capsule when idle. Try Add and Remove: the new slot settles in.',
      'عائم دون إزعاج: يظهر بعد أول إضافة، ويقول «أضيفوا قاعة أخرى» مع خانات فارغة بخط رفيع، ويصبح قابلًا للاستخدام عند قاعتين، ويتسع لثلاث كحد أقصى، وينكمش إلى كبسولة 44 عند الخمول. جرّبوا الإضافة والإزالة: تستقر الخانة الجديدة بحركة قصيرة.',
    ),
    specs: [
      gcSpec(context, t('Interactive · tap the slot x to remove, the buttons to add', 'تفاعلي · المسوا × للإزالة والأزرار للإضافة'), [
        _TrayDemo(venues: d.venues),
      ]),
      gcSpec(context, t('One hall: "Add one more", nothing actionable', 'قاعة واحدة: «أضيفوا قاعة أخرى» دون إجراء'), [
        GzCompareTray(venues: [v['V01']!]),
      ]),
      gcSpec(context, t('Two and three halls: "Compare (n/3)"', 'قاعتان وثلاث: «مقارنة (n/3)»'), [
        GzCompareTray(venues: [v['V01']!, v['V05']!]),
        GzCompareTray(venues: [v['V01']!, v['V05']!, v['V07']!]),
      ]),
      gcSpec(context, t('Collapsed to the idle capsule', 'منكمش إلى كبسولة الخمول'), [
        GzCompareTray(venues: [v['V01']!, v['V05']!], collapsed: true, expand: true),
      ]),
    ],
  );
}

class _TrayDemo extends StatefulWidget {
  const _TrayDemo({required this.venues});

  final Map<String, VenueSummary> venues;

  @override
  State<_TrayDemo> createState() => _TrayDemoState();
}

class _TrayDemoState extends State<_TrayDemo> {
  List<String> ids = ['V01', 'V05'];
  bool collapsed = false;

  @override
  Widget build(BuildContext context) {
    const pool = ['V01', 'V05', 'V07', 'V09'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzCompareTray(
          venues: [for (final id in ids) widget.venues[id]!],
          collapsed: collapsed,
          expand: true,
          onRemove: (id) => setState(() => ids = ids.where((x) => x != id).toList()),
          onClear: () => setState(() => ids = []),
          onExpand: () => setState(() => collapsed = false),
          onOpen: () => setState(() => collapsed = true),
        ),
        const SizedBox(height: GzSpace.s6),
        Row(
          children: [
            for (var i = 0; i < pool.length; i++) ...[
              if (i > 0) const SizedBox(width: GzSpace.s3),
              Expanded(
                child: GcPill(
                  label: '+ ${pool[i]}',
                  onPressed: ids.contains(pool[i]) || ids.length >= 3 ? null : () => setState(() => ids = [...ids, pool[i]]),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------------------------------------------------------ table
Widget _tableSection(BuildContext context, ClientBGalleryData d) {
  String t(String en, String ar) => gcT(context, en, ar);
  return gcSection(
    context,
    title: t('Compare table', 'جدول المقارنة'),
    note: t(
      'Three fluid thirds with no label column and no sideways scroll (130 / 120 / 143 at 390 / 360 / 430). Labels sit above the values; objective rows carry a gold-ink bead and the words "Best in row"; range bars show price and capacity with an ink tick at your guests. Differences only is on by default and says how many rows it hides. A hall turns gold only after it is picked.',
      'ثلاثة أعمدة مرنة متساوية بلا عمود للعناوين وبلا تمرير جانبي (130 / 120 / 143 عند 390 / 360 / 430). تقع العناوين فوق القيم؛ وتحمل الصفوف الموضوعية خرزة ذهبية داكنة وعبارة «الأفضل في هذا الصف»؛ وتعرض أشرطة النطاق السعر والسعة مع علامة حبرية عند عدد ضيوفكم. «الفروقات فقط» مفعّلة افتراضيًا وتذكر عدد الصفوف المخفية. لا تتذهّب القاعة إلا بعد اختيارها.',
    ),
    specs: [
      gcSpec(
        context,
        t(
          'Story: Aurelia, Lumi Marina and Jawharat (ladies, 350 guests, Thu 14 Jan)',
          'القصة: أوريليا ولومي مارينا وجوهرة (نسائي، 350 ضيفًا، الخميس 14 يناير)',
        ),
        [_TableDemo(d: d)],
        bleed: true,
      ),
      gcSpec(
        context,
        t(
          'Three price units: per guest, a flat night, the ministry rental fee (Official channel)',
          'ثلاث وحدات سعر: للضيف وليلة ثابتة ورسوم الوزارة (القناة الرسمية)',
        ),
        [
          GzCompareTable(
            columns: d.units,
            date: d.date,
            guests: 350,
            origin: _origin(context),
            areaNames: _areas(context, d),
            photos: d.photos,
            differencesOnly: false,
            onDifferencesOnlyChange: (_) {},
          ),
        ],
        bleed: true,
      ),
      gcSpec(
        context,
        t('No date set: price rows say "From", availability says "Pick a date"', 'بلا تاريخ: صفوف السعر تقول «من» والتوفر يقول «اختاروا تاريخًا»'),
        [
          GzCompareTable(
            columns: d.noDate,
            guests: 350,
            origin: _origin(context),
            areaNames: _areas(context, d),
            photos: d.photos,
            differencesOnly: false,
            onDifferencesOnlyChange: (_) {},
          ),
        ],
        bleed: true,
      ),
    ],
  );
}

String _origin(BuildContext context) => gcT(context, 'Salmiya', 'السالمية');

Map<String, String> _areas(BuildContext context, ClientBGalleryData d) => {
  for (final e in d.areaNames.entries) e.key: e.value.of(context.gz.locale.languageCode),
};

class _TableDemo extends StatefulWidget {
  const _TableDemo({required this.d});

  final ClientBGalleryData d;

  @override
  State<_TableDemo> createState() => _TableDemoState();
}

class _TableDemoState extends State<_TableDemo> {
  bool diff = true;
  String? picked;

  @override
  Widget build(BuildContext context) => GzCompareTable(
    columns: widget.d.story,
    date: widget.d.date,
    guests: 350,
    origin: _origin(context),
    areaNames: _areas(context, widget.d),
    photos: widget.d.photos,
    differencesOnly: diff,
    onDifferencesOnlyChange: (v) => setState(() => diff = v),
    pickedId: picked,
    onAction: (id, kind) => setState(() => picked = id),
  );
}

// ------------------------------------------------------------------------------------------------------------------ parts
Widget _partsSection(BuildContext context, ClientBGalleryData d) {
  String t(String en, String ar) => gcT(context, en, ar);
  final cols = [
    for (final id in ['V01', 'V05', 'V07']) GzCompareHeaderColumn(venue: d.venues[id]!, areaName: _areas(context, d)[d.venues[id]!.areaId]),
  ];
  final header = [
    GzCompareHeaderColumn(venue: cols[0].venue, areaName: cols[0].areaName, badge: t('Lowest price', 'الأقل سعرًا')),
    GzCompareHeaderColumn(venue: cols[1].venue, areaName: cols[1].areaName, badge: t('Best rated', 'الأعلى تقييمًا')),
    cols[2],
  ];
  Widget rail(int value, int max, {int? mark, String? markLabel, required String label}) =>
      GzRangeBar(value: value, max: max, mark: mark, markLabel: markLabel, label: label);
  GzCompareActionColumn act(String id, String name, GzCompareActionKind kind, String label) =>
      GzCompareActionColumn(id: id, name: name, kind: kind, label: label);
  return gcSection(
    context,
    title: t('Compare parts', 'أجزاء المقارنة'),
    note: t(
      'The pieces, for reuse by the planner package table: header (expanded 4:5 thumbs and collapsed to 40), range bars, the Best in row marker and the labelled action bar.',
      'الأجزاء لإعادة استخدامها في جدول باقات المخطط: الرأس (صور 4:5 وهو مطوي إلى 40) وأشرطة النطاق وعلامة «الأفضل في هذا الصف» وشريط الإجراءات المسمّى.',
    ),
    specs: [
      gcSpec(context, t('Header · expanded', 'الرأس · موسّع'), [GzCompareHeader(columns: header, onRemove: (_) {})], bleed: true),
      gcSpec(
        context,
        t(
          'Header · tap to open, a pick control (the second hall chosen), names up to four lines',
          'الرأس · اللمس للفتح وعنصر اختيار (القاعة الثانية مختارة) وأسماء حتى أربعة أسطر',
        ),
        [GzCompareHeader(columns: header, onOpen: (_) {}, onPick: (_) {}, pickedId: header[1].venue.id, nameLines: 4, onRemove: (_) {})],
        bleed: true,
      ),
      gcSpec(
        context,
        t('Header · collapsed on scroll (200 ms height tween in the screen)', 'الرأس · مطوي عند التمرير (تحريك الارتفاع 200 م.ث في الشاشة)'),
        [GzCompareHeader(columns: header, compact: true)],
        bleed: true,
      ),
      gcSpec(
        context,
        t('Range bars · capacity with the tick at your 350 · a hall below your count', 'أشرطة النطاق · السعة مع علامة عند 350 · قاعة أقل من عددكم'),
        [
          rail(650, 650, mark: 350, markLabel: t('your 350', 'عددكم 350'), label: t('Up to 650 guests', 'حتى 650 ضيفًا')),
          rail(300, 650, mark: 350, markLabel: t('your 350', 'عددكم 350'), label: t('Up to 300 guests', 'حتى 300 ضيف')),
          rail(500, 650, label: t('Up to 500 guests', 'حتى 500 ضيف')),
        ],
      ),
      gcSpec(context, t('Best in row', 'الأفضل في هذا الصف'), [
        GzBestInRow(
          child: GzText('18,200', role: GzTextRole.priceStrong, color: context.gz.colors.textStrong),
        ),
      ]),
      gcSpec(context, t('Action bar · nothing picked (three equal secondaries)', 'شريط الإجراءات · لا اختيار (ثلاثة أزرار ثانوية متساوية)'), [
        GzCompareActionBar(
          columns: [
            act('a', 'فندق أوريليا الخليج', GzCompareActionKind.voucher, t('Get voucher', 'الحصول على كوبون')),
            act('b', 'Lumi Marina Hotel', GzCompareActionKind.dates, t('See dates', 'التواريخ')),
            act('c', 'Government Hall', GzCompareActionKind.official, t('Official', 'رسمي')),
          ],
        ),
      ], bleed: true),
      gcSpec(context, t('Action bar · the picked hall turns gold', 'شريط الإجراءات · القاعة المختارة تتذهّب'), [
        GzCompareActionBar(
          pickedId: 'a',
          columns: [
            act('a', 'Aurelia Gulf Hotel', GzCompareActionKind.voucher, t('Get voucher', 'الحصول على كوبون')),
            act('b', 'Lumi Marina Hotel', GzCompareActionKind.voucher, t('Get voucher', 'الحصول على كوبون')),
            act('c', 'Madar Grand Hotel', GzCompareActionKind.voucher, t('Get voucher', 'الحصول على كوبون')),
          ],
        ),
      ], bleed: true),
    ],
  );
}

// ------------------------------------------------------------------------------------------------------------------ reviews
Widget _reviewsSection(BuildContext context, ClientBGalleryData d) {
  String t(String en, String ar) => gcT(context, en, ar);
  final v = d.details['V01']!;
  final lang = context.gz.locale.languageCode;
  final replied = d.reviews.firstWhere((r) => r.ownerReply != null);
  final plain = d.reviews.firstWhere((r) => r.ownerReply == null && r.rating >= 4.8);
  final critical = d.reviews.firstWhere((r) => r.rating < 4);
  final shots = [
    for (final g in v.gallery)
      if (g.zone == MediaZone.buffet || g.zone == MediaZone.stageKosha) g.baseUrl ?? g.file,
  ].take(3).toList();
  final longText = LocalizedText(en: '${plain.text.en} ${plain.text.en}', ar: '${plain.text.ar} ${plain.text.ar} ${plain.text.ar}');
  return gcSection(
    context,
    title: t('Reviews and rating', 'التقييمات'),
    note: t(
      'Ruled blocks, not cards. A monogram, never a face; the text as typed, in its own language; empty-room photographs only; the owner’s reply set apart. The summary uses figures, not the serif, and a venue with no reviews says "New", never 0.0.',
      'كتل مفصولة بخطوط لا بطاقات. حرف أول لا وجه؛ والنص كما كُتب بلغته؛ وصور لقاعات فارغة فقط؛ وردّ المكان منفصل. الملخص بأرقام لا بالخط ذي الزوائد، والقاعة بلا تقييمات تقول «جديد» لا 0.0.',
    ),
    specs: [
      gcSpec(context, t('Rating summary · average, stars, count, four category bars', 'ملخص التقييم · المتوسط والنجوم والعدد وأربعة أشرطة'), [
        GzRatingSummary(rating: v.rating),
      ]),
      gcSpec(context, t('No reviews yet (stress S03)', 'بلا تقييمات بعد (حالة ضغط S03)'), [
        const GzRatingSummary(rating: RatingSummary(average: null, count: 0, categories: null)),
      ]),
      gcSpec(context, t('Review with the owner’s reply', 'تقييم مع ردّ المكان'), [GzReviewCard(review: replied, venueName: v.name.of(lang))]),
      gcSpec(context, t('With photographs · verified booking · long text collapses', 'مع صور · حجز موثّق · النص الطويل يُطوى'), [
        GzReviewCard(
          review: plain.copyWith(text: longText),
          photos: shots,
        ),
      ]),
      gcSpec(context, t('A critical review · anonymous guest', 'تقييم نقدي · ضيف مجهول'), [GzReviewCard(review: critical.copyWith(anonymous: true))]),
    ],
  );
}

// ------------------------------------------------------------------------------------------------------------------ venue info
Widget _venueInfoSection(BuildContext context, ClientBGalleryData d) {
  String t(String en, String ar) => gcT(context, en, ar);
  final lang = context.gz.locale.languageCode;
  final v = d.details['V01']!;
  final facts = v.halls.first.sections.first.policy;
  final origin = GzMapOrigin(id: 'ref-salmiya', name: t('Salmiya', 'السالمية'));
  String areaOf(Venue x) => _areas(context, d)[x.areaId] ?? '';
  return gcSection(
    context,
    title: t('Facilities, rules, questions and location', 'المرافق والقواعد والأسئلة والموقع'),
    note: t(
      'Facilities in three states with icon and words, rules as plain labelled facts, the venue’s own questions in the accordion, and a static map drawn from tokens: no tiles, no blur, one pin.',
      'المرافق بثلاث حالات بأيقونة ونص، والقواعد كحقائق واضحة بعناوين، وأسئلة المكان في الأكورديون، وخريطة ثابتة مرسومة من الرموز: بلا بلاطات ولا ضبابية ودبوس واحد.',
    ),
    specs: [
      gcSpec(context, t('Amenity grid · included, extra with a price anchor, not offered', 'شبكة المرافق · مشمول وإضافة بسعر تقريبي وغير متوفر'), [
        GzAmenityGrid(amenities: v.amenities, defs: d.amenityDefs, collapsedCount: 10),
      ]),
      gcSpec(context, t('Policy list · plain facts, never a judgement', 'قائمة القواعد · حقائق واضحة دون أحكام'), [
        GzPolicyList(
          facts: facts,
          extra: [
            GzPolicyTerm(label: t('Children', 'الأطفال'), value: v.policies.children.women.of(lang)),
            GzPolicyTerm(label: t('Dress code', 'اللباس'), value: v.policies.dressCode.of(lang)),
          ],
        ),
      ]),
      gcSpec(context, t('FAQ accordion · single open', 'أسئلة شائعة · سؤال واحد مفتوح'), [
        GzFaqAccordion(items: v.faq, defaultOpenId: v.faq.isEmpty ? null : v.faq.first.id),
      ]),
      gcSpec(context, t('Map preview · static illustration, a pin, the drive time', 'معاينة الخريطة · رسم ثابت ودبوس ووقت القيادة'), [
        GzMapPreview(venue: v, areaName: areaOf(v), origin: origin, onOpen: () {}),
        GzMapPreview(venue: d.details['V03']!, areaName: areaOf(d.details['V03']!), origin: origin),
      ]),
    ],
  );
}
