// Gallery sections 5 to 7 of the client page: venue-card, venue-compact, venue-stress (web VenueSections.tsx).
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/src/client/client_a.dart';
import 'package:ghazal_ui/src/core/core.dart' show GzPreviewState;
import 'package:ghazal_ui/src/foundation.dart';

import 'client_a_gallery_kit.dart';

final LocalDate _storyDate = LocalDate.parse('2027-01-14');

/// `Live`: a result row of the story brief with toggling heart and compare (the web gallery wires both to local state).
class _Live extends StatefulWidget {
  const _Live(this.id, {this.variant = GzVenueCardVariant.card, this.priceDropped = false, this.favourite, this.selected = false, this.onSelect, this.carousel = false, this.pressed = false});

  final String id;
  final GzVenueCardVariant variant;
  final bool priceDropped;
  final bool? favourite;
  final bool selected;
  final VoidCallback? onSelect;
  final bool carousel;
  final bool pressed;

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late bool _fav = widget.favourite ?? false;
  bool _cmp = false;

  @override
  Widget build(BuildContext context) {
    final r = clientAData.result(widget.id);
    return GzVenueCard(
      venue: r.venue,
      area: clientAData.areas[r.venue.areaId],
      gallery: clientAData.gallery[widget.id] ?? const [],
      price: r.price,
      availability: r.availability,
      date: _storyDate,
      badge: r.badge,
      tags: r.tags,
      guestRange: r.guestRange,
      sponsored: r.sponsored,
      variant: widget.variant,
      favourite: _fav,
      onFavouriteChange: (v) => setState(() => _fav = v),
      compared: _cmp,
      onCompareChange: (v) => setState(() => _cmp = v),
      onOpen: () {},
      selected: widget.selected,
      onSelect: widget.onSelect,
      priceDropped: widget.priceDropped,
      carousel: widget.carousel,
      previewState: widget.pressed ? GzPreviewState.pressed : null,
    );
  }
}

Widget venueCardSection(BuildContext context) {
  String l(String en, String ar) => caL(context, en, ar);
  return caSection(
    context,
    title: l('Venue card', 'بطاقة القاعة'),
    note: l(
      'ADR 0018: an unframed plate. A 4:5 photograph, canvas disks in 44 targets, one badge, then the wall label: serif name with the rating at the end, area and guest range, tags only when there is more than one arrangement, a hairline, the availability line and the price line with its basis.',
      'القرار 0018: لوحة بلا إطار. صورة بنسبة 4:5، وأقراص بلون الخلفية داخل أهداف لمس بحجم 44، وشارة واحدة، ثم لوحة التعريف: الاسم بالخط ذي الزوائد والتقييم في النهاية، المنطقة وعدد الضيوف، والوسوم فقط عند تعدد الترتيبات، وخط رفيع، وسطر التوفر وسطر السعر مع أساسه.',
    ),
    specs: [
      caSpec(context, l('Card 4:5 · date and guests set · available, with the contextual Book action', 'بطاقة 4:5 · التاريخ والضيوف محددان · متاحة مع إجراء الحجز'), [const _Live('V01')]),
      caSpec(context, l('Offer badge (the discount is the label) · saved · compared', 'شارة العرض (الخصم هو النص) · محفوظة · مضافة للمقارنة'), [const _Live('V09')]),
      caSpec(context, l('Instant badge · two arrangements shown as tags', 'شارة الحجز الفوري · ترتيبان بوسمين'), [const _Live('V08')]),
      caSpec(context, l('Sponsored: the disclosure stays on the meta line', 'إعلان: يبقى التنويه في سطر المعلومات'), [const _Live('V03')]),
      caSpec(context, l('On hold on your date: icon and label, no Book', 'محجوزة مؤقتًا في تاريخكم: أيقونة ونص بلا زر حجز'), [const _Live('V07')]),
      caSpec(context, l('Government hall: ministry line, rental fee, no Book', 'قاعة حكومية: سطر الوزارة ورسوم الإيجار بلا زر حجز'), [const _Live('V19')]),
      caSpec(context, l('Feature · larger serif name, display price', 'مميزة · اسم أكبر وسعر بالخط ذي الزوائد'), [const _Live('V02', variant: GzVenueCardVariant.feature)]),
      caSpec(context, l('List 16:10 · photo dots (opt-in) · video affordance', 'قائمة 16:10 · نقاط الصور (اختيارية) · رمز الفيديو'), [const _Live('V01', variant: GzVenueCardVariant.list, carousel: true)]),
      caSpec(context, l('Pressed (whole card scales .985)', 'حالة الضغط (البطاقة كلها تتقلص إلى .985)'), [const _Live('V05', pressed: true)]),
    ],
  );
}

class _CompareList extends StatefulWidget {
  const _CompareList();

  @override
  State<_CompareList> createState() => _CompareListState();
}

class _CompareListState extends State<_CompareList> {
  String _pick = 'V05';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < 3; i++) ...[
        if (i > 0) const SizedBox(height: GzSpace.s6),
        _Live(const ['V05', 'V07', 'V09'][i], variant: GzVenueCardVariant.compare, selected: _pick == const ['V05', 'V07', 'V09'][i], onSelect: () => setState(() => _pick = const ['V05', 'V07', 'V09'][i])),
      ],
    ],
  );
}

Widget venueCompactSection(BuildContext context) {
  String l(String en, String ar) => caL(context, en, ar);
  return caSection(
    context,
    title: l('Compact, saved and compare rows', 'الصفوف المصغّرة والمحفوظة والمقارنة'),
    note: l(
      '72 by 88 thumbnail, name, area and the price line; no tags, no availability. Saved adds the heart and a real price-drop note; compare is a choice row for the Replace sheet.',
      'صورة مصغّرة 72 في 88 والاسم والمنطقة وسطر السعر؛ بلا وسوم ولا سطر توفر. المحفوظة تضيف القلب وملاحظة انخفاض سعر حقيقية؛ وصف المقارنة صف اختيار لورقة الاستبدال.',
    ),
    specs: [
      caSpec(context, l('Compact · carousels and the tray detail', 'مصغّرة · القوائم الأفقية وتفاصيل الشريط'), [const _Live('V01', variant: GzVenueCardVariant.compact), const _Live('V19', variant: GzVenueCardVariant.compact)]),
      caSpec(context, l('Saved · heart on · price dropped', 'محفوظة · القلب مفعّل · انخفض السعر'), [
        const _Live('V09', variant: GzVenueCardVariant.saved, priceDropped: true, favourite: true),
        const _Live('V05', variant: GzVenueCardVariant.saved, favourite: true),
      ]),
      caSpec(context, l('Compare · replace which one · selected / not', 'مقارنة · أي قاعة تُستبدل · محددة / غير محددة'), [const _CompareList()]),
    ],
  );
}

Widget _stress(BuildContext context, VenueSummary? v, CardPrice price, {List<Audience> tags = const [], GuestRange? range, bool compare = true}) {
  if (v == null) return const SizedBox.shrink();
  return GzVenueCard(
    venue: v,
    area: clientAData.areas[v.areaId],
    price: price,
    tags: tags,
    guestRange: range,
    onOpen: () {},
    onFavouriteChange: (_) {},
    onCompareChange: compare ? (_) {} : null,
  );
}

Widget venueStressSection(BuildContext context) {
  String l(String en, String ar) => caL(context, en, ar);
  final d = clientAData;
  final long = d.stress[0], none = d.stress[1], fresh = d.stress[2];
  const longPrice = CardPriceExact(voucher: null, savings: null, amount: MoneyAmount(985000), guests: 1200, packageId: 'x', tier: PriceTier.weekend);
  const cheap = CardPriceFromGuests(voucher: null, savings: null, amount: MoneyAmount(480), guests: 20, packageId: 'x', tier: PriceTier.weekday);
  const flat = CardPriceFlatNight(voucher: null, savings: null, amount: MoneyAmount(480000), hasSeveralPackages: false, packageId: 'x');
  return caSection(
    context,
    title: l('Venue card · stress', 'بطاقة القاعة · حالات الضغط'),
    note: l(
      'The Kuwait stress set: a very long mixed-script name, no photographs, no reviews, a three-digit and a six-digit price, and skeletons. The name wraps to two lines then truncates; nothing overlaps the rating.',
      'حالات الضغط الكويتية: اسم طويل جدًا بخطين مختلطين، وقاعة بلا صور، وأخرى بلا تقييمات، وسعر من ثلاث خانات وآخر من ست، وهياكل التحميل. يلتف الاسم على سطرين ثم يُقتطع ولا يتداخل مع التقييم.',
    ),
    specs: [
      caSpec(context, l('Long mixed-script name', 'اسم طويل بخطين مختلطين'), [_stress(context, long, longPrice, tags: const [Audience.women, Audience.men], range: const GuestRange(min: 200, max: 1200))]),
      caSpec(context, l('No photographs · three-digit price', 'بلا صور · سعر من ثلاث خانات'), [_stress(context, none, flat, compare: false)]),
      caSpec(context, l('No reviews: "New", never 0.0 · price from KD 0.480', 'بلا تقييمات: «جديد» لا 0.0 · سعر من 0.480'), [_stress(context, fresh, cheap, compare: false)]),
      caSpec(context, l('Rail card at 72% of the frame (ADR 0018 D8)', 'بطاقة القائمة الأفقية بعرض 72% (القرار 0018)'), [
        Align(alignment: AlignmentDirectional.centerStart, child: const SizedBox(width: 280, child: _Live('V05'))),
      ]),
      caSpec(context, l('Skeleton · card, list, compact', 'هيكل التحميل · بطاقة وقائمة ومصغّرة'), [
        GzVenueCard(venue: d.result('V01').venue, loading: true),
        GzVenueCard(venue: d.result('V01').venue, loading: true, variant: GzVenueCardVariant.list),
        GzVenueCard(venue: d.result('V01').venue, loading: true, variant: GzVenueCardVariant.compact),
      ]),
    ],
  );
}
