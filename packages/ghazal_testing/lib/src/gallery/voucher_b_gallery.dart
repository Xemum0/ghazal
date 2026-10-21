// The voucher gallery, part B: the Flutter twin of sections 9 to 12 of design/src/gallery/voucher.tsx (#/gallery/voucher): listing,
// review-timeline, ad-plan and filters (the service-provider module and the search filters). Same specimens, states and sample text
// as design/src/system/domain-voucher/gallery/{ProviderSections,FilterSections}.tsx, driven by real objects from GzWorld.
// Parity: `node tools/parity/parity.mjs --gallery voucher --sections 9,10,11,12` after `flutter test test/gallery/voucher_b_gallery_test.dart`.
// ghazal_testing may hold string literals (tests and galleries are exempt from the no-text-literal rule).
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show AdPlan, AdPlanCycle, BillingView, Governorate, Listing, ListingStatus, LocalizedText;
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/filters/filters.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/provider/provider.dart';

import '../world.dart';
import 'gz_gallery.dart';

/// The real objects the sections read (fetched once, outside fake async, through the repositories the apps use).
class VoucherBData {
  VoucherBData._({
    required this.listings,
    required this.categories,
    required this.plans,
    required this.planBilling,
    required this.contractBilling,
    required this.governorates,
    required this.capacityMin,
    required this.capacityMax,
  });

  final Map<String, Listing> listings;
  final Map<String, LocalizedText> categories;
  final List<AdPlan> plans;
  final BillingView planBilling;
  final BillingView contractBilling;
  final List<Governorate> governorates;
  final int capacityMin;
  final int capacityMax;

  static Future<VoucherBData> load(GzWorld world) async {
    final zahra = world.repos('provider', providerId: 'vendor-flowers-zahra');
    final listings = {for (final l in (await zahra.partnerListings.listListings()).listings) l.id: l};
    final cats = await world.repos('reem').services.listServiceCategories();
    final billing = await zahra.partnerListings.getPartnerBilling();
    final hotel = await world.repos('hotel_manager', venueId: 'V01').partnerListings.getPartnerBilling();
    final guest = world.repos('guest');
    final areas = await guest.venues.listAreas();
    final rows = (await guest.venues.searchVenues(limit: 50)).items;
    // The bounds are the real hall capacities (the web reads every hall section's maxGuests).
    final caps = <int>[];
    for (final r in rows) {
      final v = (await guest.venues.getVenue(venueId: r.venue.id)).venue;
      caps.addAll([for (final h in v.halls) for (final s in h.sections) s.maxGuests]);
    }
    final lo = caps.reduce((a, b) => a < b ? a : b);
    final hi = caps.reduce((a, b) => a > b ? a : b);
    return VoucherBData._(
      listings: listings,
      categories: {for (final c in [...cats.primary, ...cats.secondary]) c.id.value: c.name},
      plans: [for (final p in billing.plans) p.plan],
      planBilling: billing,
      contractBilling: hotel,
      governorates: areas.governorates,
      capacityMin: (lo / 10).floor() * 10,
      capacityMax: (hi / 50).ceil() * 50,
    );
  }
}

/// The section ids (the web `data-gz-section` ids) and their place on the web page.
const List<(String, int)> voucherBGalleryIds = [('listing', 9), ('review-timeline', 10), ('ad-plan', 11), ('filters', 12)];

/// The four sections of this part; [data] is read when a section renders (after `VoucherBData.load`).
List<GzGallerySection> voucherBGallerySections(VoucherBData Function() data) => [
  GzGallerySection('listing', (c) => _listing(c, data()), number: 9),
  GzGallerySection('review-timeline', (c) => _timeline(c, data()), number: 10),
  GzGallerySection('ad-plan', (c) => _adPlan(c, data()), number: 11),
  GzGallerySection('filters', (c) => _filters(c, data()), number: 12),
];

// ---------------------------------------------------------------------------------------------------------------- kit
String _t(BuildContext context, String en, String ar) => context.gz.isAr ? ar : en;

/// `Section` of the web kit: khayt, d2 title, note (gap 8), then the specimens (gap 32) after a gap of 20.
Widget _sec(BuildContext context, {required String title, required String note, required List<Widget> specs}) {
  final c = context.gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(alignment: AlignmentDirectional.centerStart, child: GzThreadRule(draw: GzDraw.off)),
      const SizedBox(height: GzSpace.s2),
      GzText(title, role: GzTextRole.d2, color: c.textStrong, header: true),
      const SizedBox(height: GzSpace.s2),
      GzText(note, role: GzTextRole.bodyS, color: c.textSecondary),
      const SizedBox(height: GzSpace.s5),
      for (var i = 0; i < specs.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s8), specs[i]],
    ],
  );
}

/// `Spec`: a state caption over a hairline, then the live component(s) with a gap of 24 (12 under the caption).
Widget _spec(BuildContext context, String state, List<Widget> children, {double? bleedHeight}) {
  final gz = context.gz;
  final c = gz.colors;
  Widget body = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s6), children[i]],
    ],
  );
  if (bleedHeight != null) {
    // `.gc-spec__body--bleed`: margin-inline -20, the screen gives the whole 390 frame.
    body = SizedBox(height: bleedHeight, child: OverflowBox(minWidth: 390, maxWidth: 390, child: body));
  }
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
      const SizedBox(height: GzSpace.s3),
      body,
    ],
  );
}

// -------------------------------------------------------------------------------------------------------------- listing
const _allStatuses = [
  ListingStatus.draft,
  ListingStatus.paymentPending,
  ListingStatus.pendingReview,
  ListingStatus.approved,
  ListingStatus.rejected,
  ListingStatus.active,
  ListingStatus.expired,
  ListingStatus.paused,
];

const _zahra = ['lst-flowers-zahra-draft', 'lst-flowers-zahra-table', 'lst-flowers-zahra-kosha', 'lst-flowers-zahra', 'lst-flowers-zahra-autumn'];

Widget _listing(BuildContext context, VoucherBData d) {
  String t(String en, String ar) => _t(context, en, ar);
  Widget card(String id, {bool exempt = false}) {
    final l = d.listings[id]!;
    return GzProviderListingCard(listing: l, categoryName: d.categories[l.categoryId.value], exempt: exempt, onOpen: () {});
  }

  return _sec(
    context,
    title: t('Listings and review status', 'الإعلانات وحالة المراجعة'),
    note: t(
      'A listing is never published on payment: every advertisement waits for a moderator, so Approved and Live are two different pills. The card shows the lifecycle, the plan line (or the honest “Rates announced soon” / “Exempt”) and, when the moderator said no, the first reason in plain words.',
      'لا يُنشر الإعلان بمجرد الدفع: ينتظر كل إعلان مراجعًا بشريًا، لذلك «تمت الموافقة» و«منشور» شارتان مختلفتان. تعرض البطاقة المرحلة وسطر الباقة (أو «الأسعار تُعلن قريبًا» / «معفى» بصدق) وعند الرفض أول سبب بالكلمات.',
    ),
    specs: [
      _spec(context, t('Status pills · every state', 'شارات الحالة · كل الحالات'), [
        Wrap(
          spacing: GzSpace.s3,
          runSpacing: GzSpace.s3,
          children: [for (final s in _allStatuses) GzListingStatusPill(status: s)],
        ),
      ]),
      _spec(context, t('Listing cards · draft · in review · not approved · live · ended', 'بطاقات الإعلانات · مسودة · قيد المراجعة · لم تتم الموافقة · منشور · انتهى'), [
        for (final id in _zahra) card(id),
      ]),
      _spec(context, t('A major hotel’s listing: the plan line says Exempt', 'إعلان فندق كبير: سطر الباقة يقول معفى'), [card('lst-flowers-zahra', exempt: true)]),
    ],
  );
}

// ------------------------------------------------------------------------------------------------------ review-timeline
Widget _timeline(BuildContext context, VoucherBData d) {
  String t(String en, String ar) => _t(context, en, ar);
  Widget tl(String id) => GzReviewTimeline(listing: d.listings[id]!);
  return _sec(
    context,
    title: t('Review timeline', 'مسار المراجعة'),
    note: t(
      'The audit trail of one listing on the Booking Thread’s rail: a knot per decision with its absolute time and who made it, then what is still ahead. A rejection lists its reasons in plain words, the moderator’s note, and how long the plan is kept for a resubmission.',
      'سجل مراجعة إعلان واحد على مسار خيط الحجز: عقدة لكل قرار بوقته المطلق ومن اتخذه، ثم ما ينتظر بعده. يسرد الرفض أسبابه بالكلمات وملاحظة المراجع ومدة بقاء الباقة لإعادة الإرسال.',
    ),
    specs: [
      _spec(context, t('In review · the review is the knot that is now', 'قيد المراجعة · المراجعة هي العقدة الحالية'), [tl('lst-flowers-zahra-table')]),
      _spec(context, t('Not approved · reasons and a note', 'لم تتم الموافقة · أسباب وملاحظة'), [tl('lst-flowers-zahra-kosha')]),
      _spec(context, t('Live · approved by a person, then published', 'منشور · وافق عليه شخص ثم نُشر'), [tl('lst-flowers-zahra')]),
      _spec(context, t('Draft', 'مسودة'), [tl('lst-flowers-zahra-draft')]),
    ],
  );
}

// -------------------------------------------------------------------------------------------------------------- ad-plan
Widget _adPlan(BuildContext context, VoucherBData d) {
  String t(String en, String ar) => _t(context, en, ar);
  final sample = d.plans[1].copyWith(ratesFils: 45000);
  final contract = d.contractBilling;
  return _sec(
    context,
    title: t('Advertising plans', 'باقات الإعلان'),
    note: t(
      'Weekly, monthly or annual. The rates are not decided, so a plan says “Rates announced soon” and never a number; a rate shows only after the Super Admin sets it. A major hotel sees “Exempt” and nothing is payable. Choosing a plan is not buying: the listing still waits for review.',
      'أسبوعي أو شهري أو سنوي. الأسعار لم تُحسم بعد، لذلك تقول الباقة «الأسعار تُعلن قريبًا» ولا تعرض رقمًا أبدًا؛ ويظهر السعر فقط بعد أن يحدده المدير العام. يرى الفندق الكبير «معفى» ولا شيء مستحق الدفع. اختيار الباقة ليس شراءً: يبقى الإعلان بانتظار المراجعة.',
    ),
    specs: [
      _spec(context, t('Rates announced soon · choose one (monthly selected)', 'الأسعار تُعلن قريبًا · اختاروا باقة (الشهرية محددة)'), [
        _PlanChoice(plans: d.plans),
      ]),
      _spec(context, t('Exempt · a major hotel (nothing to pay)', 'معفى · فندق كبير (لا شيء للدفع)'), [
        _Stack([for (final p in d.plans) GzAdPlanCard(plan: p, exempt: true, selected: p.cycle == AdPlanCycle.annual)]),
      ]),
      _spec(context, t('A rate set by the Super Admin (a gallery sample, not a price)', 'سعر حدده المدير العام (عيّنة للعرض وليست سعرًا)'), [
        GzAdPlanCard(plan: sample),
      ]),
      _spec(context, t('Major hotel badge · chip and note (Partner app only)', 'شارة الفندق الكبير · شارة وملاحظة (تطبيق الشريك فقط)'), [
        const Align(alignment: AlignmentDirectional.centerStart, child: GzMajorHotelBadge()),
        const Align(alignment: AlignmentDirectional.centerStart, child: GzMajorHotelBadge(variant: GzMajorHotelVariant.note)),
      ]),
      _spec(
        context,
        t(
          'Billing card · business contract (hotels and halls, no price) · major hotel · plan (service providers, rates soon)',
          'بطاقة الفوترة · عقد عمل (فنادق وقاعات، بلا سعر) · فندق كبير · باقة (مقدّمو الخدمات، الأسعار قريبًا)',
        ),
        [
          GzBillingCard(billing: contract, majorHotel: false),
          GzBillingCard(billing: d.planBilling),
          GzBillingCard(billing: contract, majorHotel: true),
        ],
      ),
    ],
  );
}

/// The plan radio group of the first specimen: choosing one selects it (monthly at first).
class _PlanChoice extends StatefulWidget {
  const _PlanChoice({required this.plans});

  final List<AdPlan> plans;

  @override
  State<_PlanChoice> createState() => _PlanChoiceState();
}

class _PlanChoiceState extends State<_PlanChoice> {
  AdPlanCycle _cycle = AdPlanCycle.monthly;

  @override
  Widget build(BuildContext context) => _Stack([
    for (final p in widget.plans) GzAdPlanCard(plan: p, selected: _cycle == p.cycle, onSelect: () => setState(() => _cycle = p.cycle)),
  ]);
}

/// `.gc-stack`: a column with a gap of 32.
class _Stack extends StatelessWidget {
  const _Stack(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s8), children[i]],
    ],
  );
}

// ---------------------------------------------------------------------------------------------------------------- filters
Widget _filters(BuildContext context, VoucherBData d) {
  String t(String en, String ar) => _t(context, en, ar);
  return _sec(
    context,
    title: t('Search filters', 'مرشحات البحث'),
    note: t(
      'The owner’s filter list as four small components over the shared inputs: governorate (one scrolling rail of the six governorates), venue type (private hall, governmental facility, hotel), capacity range (a dual slider whose start value sits at the inline-start, mirrored in Arabic) and pricing structure (per person or packages).',
      'قائمة المرشحات التي حدّدها المالك في أربعة مكوّنات صغيرة فوق المدخلات المشتركة: المحافظة (شريط واحد للمحافظات الست) ونوع المكان (قاعة خاصة ومنشأة حكومية وفندق) ونطاق السعة (منزلق مزدوج تقع قيمة البداية عند بداية السطر وينعكس في العربية) وطريقة التسعير (للضيف أو باقات).',
    ),
    specs: [
      _spec(context, t('Governorate · a rail (All Kuwait first) · the screen owns the gutter', 'المحافظة · شريط (كل الكويت أولًا) · الشاشة تتولى الهامش'), [
        SizedBox(height: GzSize.controlSm, child: GzGovernorateFilter(governorates: d.governorates)),
      ], bleedHeight: GzSize.controlSm),
      _spec(context, t('Venue type · multi-select with a glyph each', 'نوع المكان · اختيار متعدد برمز لكل نوع'), [
        const GzVenueTypeChips(defaultValues: [GzVenueType.hotel]),
      ]),
      _spec(context, t('Capacity range · minimum to maximum guests', 'نطاق السعة · من أقل إلى أكثر عدد ضيوف'), [
        GzCapacityRange(min: d.capacityMin, max: d.capacityMax, defaultValue: (250, 500)),
      ]),
      _spec(context, t('Pricing structure · per person | packages · with “All”', 'طريقة التسعير · للضيف | باقات · مع «الكل»'), [
        const GzPricingStructureToggle(defaultValue: GzPricingStructure.perPerson),
        const GzPricingStructureToggle(includeAll: true),
      ]),
    ],
  );
}
