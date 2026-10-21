// The client-d gallery sections (notification-row, payment, thread, booking-card, package-card, price-breakdown): the Flutter twin of
// the matching sections of design/src/gallery/client.tsx (#/gallery/client), numbers 20 to 25. Same specimens, states and sample text;
// every object comes from the real mock API (GzWorld). Parity: `node tools/parity/parity.mjs --gallery client --sections 20,21,22,23,24,25`
// after `flutter test test/gallery/client_d_gallery_test.dart`.
// ghazal_testing may hold string literals (tests and galleries are exempt from the no-text-literal rule).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_mock_api/ghazal_mock_api.dart' show packagePrice, JsonRead;
import 'package:ghazal_ui/src/client/client_bits.dart' show GzPriceAudience;
import 'package:ghazal_ui/src/client/client_d.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:path/path.dart' as p;

import '../world.dart';
import 'client_d_gallery_kit.dart';
import 'gz_gallery.dart';

/// The real objects the client-d sections show (loaded once, in real async, outside `testWidgets`).
class ClientDData {
  ClientDData._(this.hero, this.byRef, this.notifications, this.packages, this.prices, this.rich, this.extreme, this.venueName);

  /// The story request in each prepared state (`pending`, `approved`, `confirmed`, `redeemed`, `declined`, `expired`, `lapsed`, `cancelled`, `counter_offer`).
  final Map<String, BookingDetail> hero;
  final Map<String, BookingDetail> byRef;
  final List<AppNotification> notifications;
  final Map<String, Package> packages;
  final Map<String, GzPackagePrice?> prices;
  final Quote rich;
  final Booking extreme;
  final LocalizedText venueName;

  static ClientDData? _cached;

  static Future<ClientDData> load(GzWorld world) async {
    if (_cached != null) return _cached!;
    final reem = world.repos('reem');
    // the inbox first: moving the story adds its own notifications
    final notifications = (await reem.notifications.listNotifications(limit: 30)).items.take(7).toList();
    final hero = <String, BookingDetail>{};
    for (final point in const ['pending', 'approved', 'confirmed', 'redeemed', 'declined', 'expired', 'lapsed', 'cancelled', 'counter_offer']) {
      world.control.jumpToStory(point);
      hero[point] = await reem.requests.getRequest(requestId: 'bk-GZ-2611-0147');
    }
    world.control.jumpToStory('pending');
    // The seeded requests of other clients are read as if they were Reem's (this process only): the card shows what the API serves.
    final app = world.mock.app;
    final byRef = <String, BookingDetail>{};
    for (final ref in const ['GZ-2608-6N8F', 'GZ-2611-4W8Q', 'GZ-2611-2P8R', 'GZ-2608-1F7G', 'GZ-2611-3D9P', 'GZ-2610-2X4B']) {
      final row = app.db.get('Booking', 'bk-$ref')!;
      row['clientId'] = 'user-reem';
      app.db.put('Booking', row);
      final voucher = app.db.get('Voucher', row['voucherId'] as String);
      if (voucher != null) {
        voucher['clientId'] = 'user-reem';
        app.db.put('Voucher', voucher);
      }
      byRef[ref] = await reem.requests.getRequest(requestId: 'bk-$ref');
    }

    // packages through the API, their price through the engine for the story brief (14 Jan 2027, ladies, 350 guests)
    final packages = <String, Package>{};
    for (final v in const ['V01', 'V03', 'V07', 'V04']) {
      final detail = await reem.venues.getVenue(venueId: v, date: LocalDate.parse('2027-01-14'), guests: 350, audience: Audience.women);
      for (final o in detail.packages) {
        packages[o.package.id] = o.package;
      }
    }
    final engine = app.engine();
    GzPackagePrice? priceOf(String id, String venueId, String hallId, int hallMin, int guests) {
      final pkg = engine.packagesFor(venueId).firstWhere((x) => x['id'] == id);
      final venue = app.seed.rows('Venue').firstWhere((x) => x['id'] == venueId);
      final json = packagePrice(
        pkg: pkg,
        rules: engine.priceRules,
        windows: engine.activeWindows().where((w) => w['venueId'] == venueId).toList(),
        eventDate: '2027-01-14',
        now: app.now,
        hallId: hallId,
        guests: guests,
        hallMinGuests: hallMin,
        serviceChargeBps: venue.obj('policies').integer('serviceChargeBps'),
        voucherFeeFils: app.voucherFeeFils,
      );
      return json == null ? null : GzPackagePrice.fromJson(json.cast<String, Object?>());
    }

    final prices = <String, GzPackagePrice?>{
      'V01-ladies-weekend': priceOf('V01-ladies-weekend', 'V01', 'V01-danah', 300, 350),
      'V01-ladies-signature': priceOf('V01-ladies-signature', 'V01', 'V01-danah', 300, 350),
      'V03-lawn-evening': priceOf('V03-lawn-evening', 'V03', 'V03-lawn', 150, 300),
      'V07-hall-only': priceOf('V07-hall-only', 'V07', 'V07-ladies', 250, 350),
      'V04-villa-night': priceOf('V04-villa-night', 'V04', 'V04-garden', 20, 120),
    };

    final extras = engine.extrasFor('V01');
    final kosha = extras.firstWhere((e) => e['category'] == 'kosha', orElse: () => extras.first);
    final rich = await reem.venues.quoteVenue(
      venueId: 'V01',
      body: VenueQuoteInput(
        eventDate: LocalDate.parse('2027-01-21'),
        sections: const [QuoteSectionInput(hallId: 'V01-danah', audience: Audience.women, guests: 400, packageId: 'V01-ladies-weekend')],
        extras: [QuoteExtraInput(extraId: kosha['id'] as String, qty: 1)],
      ),
    );
    final stress = jsonDecode(File(p.join(_root(), 'packages/contracts/fixtures/stress/bookings.json')).readAsStringSync()) as Map<String, dynamic>;
    final extreme = Booking.fromJson({'version': 1, 'allowedActions': <Object?>[], ...((stress['bookings'] as List).first as Map).cast<String, Object?>()});
    final venue = await reem.venues.getVenue(venueId: 'V01');
    return _cached = ClientDData._(hero, byRef, notifications, packages, prices, rich, extreme, venue.venue.name);
  }

  static String _root() {
    var dir = Directory.current.absolute;
    for (var i = 0; i < 8; i++) {
      if (File(p.join(dir.path, 'packages/contracts/fixtures/engine-cases.json')).existsSync()) return dir.path;
      dir = dir.parent;
    }
    throw StateError('repository root not found');
  }
}

GzBookingThread _thread(BookingDetail d, {GzBookingThreadVariant variant = GzBookingThreadVariant.full, GzDraw draw = GzDraw.mount, bool onDark = false}) =>
    GzBookingThread(booking: d.booking, voucherAt: d.voucher?.purchasedAt, variant: variant, draw: draw, onDark: onDark);

GzBookingCard _card(BookingDetail d, {GzBookingCardVariant variant = GzBookingCardVariant.card, bool loading = false, GzPreviewState? previewState}) =>
    GzBookingCard(booking: d.booking, target: d.target, halls: d.halls, voucherCode: d.voucher?.code, variant: variant, onOpen: () {}, loading: loading, previewState: previewState);

/// The sections, in the order of the web page; `number` is the place on the web page (the reference files are `NN-<id>.<lang>.png`).
List<GzGallerySection> clientDGallerySections(ClientDData Function() data) => [
  GzGallerySection('notification-row', (c) => _notificationSection(c, data()), number: 20),
  GzGallerySection('payment', (c) => _paymentSection(c, data()), number: 21),
  GzGallerySection('thread', (c) => _threadSection(c, data()), number: 22),
  GzGallerySection('booking-card', (c) => _bookingCardSection(c, data()), number: 23),
  GzGallerySection('package-card', (c) => _packageCardSection(c, data()), number: 24),
  GzGallerySection('price-breakdown', (c) => _priceBreakdownSection(c, data()), number: 25),
];

Widget _notificationSection(BuildContext c, ClientDData d) => cdSection(
  c,
  title: cdL(c, 'Notification row', 'صف الإشعار'),
  note: cdL(
    c,
    'A glyph in a tone disk (a reinforcement, never the only signal), the title, two lines of body, the time, and a gold bead while unread. Marketing is tagged.',
    'رمز داخل قرص بنبرة (تعزيز لا إشارة وحيدة) والعنوان وسطران من النص والوقت وخرزة ذهبية ما دام غير مقروء. الإشعارات التسويقية موسومة.',
  ),
  specimens: [
    cdSpec(c, cdL(c, 'The client inbox · unread first', 'صندوق إشعارات العميل · غير المقروء أولًا'), [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (var i = 0; i < d.notifications.length; i++) GzNotificationRow(notification: d.notifications[i], last: i == d.notifications.length - 1, onOpen: () {})],
      ),
    ]),
  ],
);

Widget _paymentSection(BuildContext c, ClientDData d) {
  const order = [GzPaymentMethodKey.applePay, GzPaymentMethodKey.knet, GzPaymentMethodKey.visa, GzPaymentMethodKey.mastercard];
  const android = [GzPaymentMethodKey.knet, GzPaymentMethodKey.googlePay, GzPaymentMethodKey.visa, GzPaymentMethodKey.mastercard];
  Widget row(GzPaymentMethodKey m) => GzPaymentMethodRow(method: m, selected: m == GzPaymentMethodKey.knet, onSelect: () {});
  return cdSection(
    c,
    title: cdL(c, 'Payment methods and receipt', 'طرق الدفع والإيصال'),
    note: cdL(
      c,
      'Marks are monochrome placeholders set in ink; no brand artwork is copied. iOS orders Apple Pay first, Android KNET first (ADR 0027). The only payment in the product is the KD 2 voucher: there is no cash row. Documents say KWD, with Western digits and three decimals.',
      'العلامات بدائل أحادية اللون بالحبر؛ ولا تُنسخ أي صور لعلامات تجارية. يبدأ iOS بـ Apple Pay، ويبدأ Android بكي نت (القرار 0027). الدفعة الوحيدة في المنتج هي كوبون بقيمة 2 د.ك: لا يوجد صف للدفع النقدي. تقول المستندات KWD بأرقام غربية وثلاث خانات عشرية.',
    ),
    specimens: [
      cdSpec(c, cdL(c, 'iOS order · radio rows · KNET selected', 'ترتيب iOS · صفوف اختيار · كي نت محددة'), [for (final m in order) row(m)]),
      cdSpec(c, cdL(c, 'Android order · unavailable · pressed', 'ترتيب Android · غير متاح · الضغط'), [
        for (final m in android) row(m),
        const GzPaymentMethodRow(method: GzPaymentMethodKey.applePay, unavailable: true),
        GzPaymentMethodRow(method: GzPaymentMethodKey.visa, note: cdL(c, 'Recommended after a KNET limit', 'موصى بها عند بلوغ حد كي نت'), previewState: GzPreviewState.pressed),
      ]),
      cdSpec(c, cdL(c, 'Receipt · the KD 2 voucher, issued by Ghazal', 'إيصال · كوبون بقيمة 2 د.ك صادر عن غزل'), [
        GzReceiptSheet(voucher: d.hero['pending']!.voucher!, targetName: d.hero['pending']!.target.name.of(c.gz.locale.languageCode)),
      ]),
    ],
  );
}

Widget _threadSection(BuildContext c, ClientDData d) {
  final rows = <(String, String, BookingDetail)>[
    ('Pending: the venue has until Fri 13 Nov, 12:40 PM', 'بانتظار الرد: أمام المكان حتى الجمعة 13 نوفمبر 12:40 م', d.hero['pending']!),
    ('Approved: confirm within 24 hours', 'تمت الموافقة: التأكيد خلال 24 ساعة', d.hero['approved']!),
    ('Confirmed: show the code at the venue', 'مؤكد: اعرضوا الرمز لدى المكان', d.hero['confirmed']!),
    ('Redeemed at the venue: all five knots tied', 'تم الاستخدام لدى المكان: العقد الخمس مربوطة', d.hero['redeemed']!),
    ('Completed', 'مكتمل', d.byRef['GZ-2608-6N8F']!),
    ('Not accepted: Approval ends in a danger knot', 'لم يُقبل الطلب: تنتهي الموافقة بعقدة حمراء', d.hero['declined']!),
    ('Expired: the venue did not reply', 'انتهت المهلة: لم يرد المكان', d.hero['expired']!),
    ('Lapsed: the client did not confirm within 24 hours (Confirmation ends)', 'انتهت المهلة: لم يؤكد العميل خلال 24 ساعة (ينتهي التأكيد)', d.hero['lapsed']!),
    ('Cancelled', 'ملغي', d.hero['cancelled']!),
    ('A service provider request: pending', 'طلب من مقدّم خدمة: بانتظار الرد', d.byRef['GZ-2611-4W8Q']!),
  ];
  return cdSection(
    c,
    title: cdL(c, 'Booking Thread', 'خيط الحجز'),
    note: cdL(
      c,
      'Voucher, Request, Approval, Confirmed (24 h), Redeemed at the venue. A knot ties only when its event is recorded; times are absolute; the line runs gold up to where you are and draws on once from the start. Status is never the thread alone: every knot has a label and a glyph.',
      'الكوبون، الطلب، الموافقة، التأكيد (24 ساعة)، الاستخدام لدى المكان. لا تُربط العقدة إلا عند تسجيل حدثها؛ الأوقات مطلقة؛ ويمتد الخط الذهبي حتى موضعكم ويُرسم مرة واحدة من البداية. لا يكفي الخيط وحده: لكل عقدة نص ورمز.',
    ),
    specimens: [
      cdSpec(c, cdL(c, 'Full · every ADR 0033 status', 'كامل · كل حالات القرار 0033'), [
        Align(alignment: AlignmentDirectional.centerStart, child: GzButton(label: cdL(c, 'Replay the draw-on', 'إعادة رسم الخيط'), variant: GzButtonVariant.tertiary, iconStart: GzIcons.refresh, onPressed: () {})),
        for (final r in rows) cdCell(c, cdL(c, r.$1, r.$2), _thread(r.$3)),
      ]),
      cdSpec(c, cdL(c, 'Compact · 12 px knots, the current label only (list rows, partner request card)', 'مصغّر · عقد 12 والنص الحالي فقط (صفوف القوائم)'), [
        for (final r in rows.take(8)) _thread(r.$3, variant: GzBookingThreadVariant.compact, draw: GzDraw.off),
      ]),
      cdSpec(c, cdL(c, 'Vertical · booking detail: past knots with absolute times, at most two faint future knots', 'عمودي · تفاصيل الحجز: العقد السابقة بأوقات مطلقة وعقدتان باهتتان كحد أقصى'), [
        _thread(d.hero['approved']!, variant: GzBookingThreadVariant.vertical),
        _thread(d.byRef['GZ-2611-2P8R']!, variant: GzBookingThreadVariant.vertical),
        _thread(d.hero['declined']!, variant: GzBookingThreadVariant.vertical),
      ]),
      cdSpec(ink: true, c, cdL(c, 'On dark · confirmation hero, countdown', 'على الخلفية الداكنة · شاشة التأكيد والعد التنازلي'), [
        _thread(d.hero['confirmed']!, onDark: true),
        _thread(d.hero['approved']!, onDark: true, variant: GzBookingThreadVariant.compact, draw: GzDraw.off),
        _thread(d.byRef['GZ-2608-1F7G']!, onDark: true, variant: GzBookingThreadVariant.vertical),
      ]),
    ],
  );
}

Widget _bookingCardSection(BuildContext c, ClientDData d) => cdSection(
  c,
  title: cdL(c, 'Booking card', 'بطاقة الحجز'),
  note: cdL(
    c,
    'A request as a panel: venue or provider, hall, status pill beside the voucher chip, three key facts (date, guests, voucher price), the compact thread with its current label, and the reference as a left-to-right isolate. An approved request carries one calm line with the time left to confirm. One stretched target.',
    'الطلب كلوحة: المكان أو مقدّم الخدمة والقاعة وشارة الحالة بجانب شارة الكوبون وثلاث حقائق (التاريخ والضيوف وسعر الكوبون) والخيط المصغّر مع نصه الحالي، ورقم الحجز بعزل من اليسار إلى اليمين. الطلب الموافَق عليه يحمل سطرًا هادئًا بالوقت المتبقي للتأكيد. هدف لمس واحد ممتد.',
  ),
  specimens: [
    cdSpec(c, cdL(c, 'Pending · the story request, voucher attached', 'بانتظار الرد · طلب القصة والكوبون مرفق'), [_card(d.hero['pending']!)]),
    cdSpec(c, cdL(c, 'Approved · confirm within 24 hours', 'تمت الموافقة · التأكيد خلال 24 ساعة'), [_card(d.hero['approved']!)]),
    cdSpec(c, cdL(c, 'Confirmed · a date proposed by the venue (chip beside the status)', 'مؤكد · موعد مقترح من المكان (شارة بجانب الحالة)'), [_card(d.hero['confirmed']!), _card(d.hero['counter_offer']!)]),
    cdSpec(c, cdL(c, 'A service provider request · redeemed', 'طلب من مقدّم خدمة · تم استخدام الكوبون'), [_card(d.byRef['GZ-2611-3D9P']!), _card(d.byRef['GZ-2610-2X4B']!, variant: GzBookingCardVariant.row)]),
    cdSpec(c, cdL(c, 'Not accepted · expired · cancelled (rows, dense lists)', 'لم يُقبل · انتهت المهلة · ملغي (صفوف مختصرة)'), [
      _card(d.hero['declined']!, variant: GzBookingCardVariant.row),
      _card(d.hero['expired']!, variant: GzBookingCardVariant.row),
      _card(d.hero['cancelled']!, variant: GzBookingCardVariant.row),
    ]),
    cdSpec(c, cdL(c, 'Pressed · loading', 'الضغط · التحميل'), [_card(d.hero['pending']!, previewState: GzPreviewState.pressed), _card(d.hero['pending']!, loading: true)]),
  ],
);

Widget _packageCardSection(BuildContext c, ClientDData d) {
  Package pk(String id) => d.packages[id]!;
  GzPackageCard card(String id, {int guests = 350, bool selected = false, bool unavailable = false, bool loading = false, bool guest = false, GzPreviewState? preview, Package? pkg, bool select = true}) => GzPackageCard(
    pkg: pkg ?? pk(id),
    price: loading ? null : d.prices[id],
    guests: guests,
    selected: selected,
    onSelect: select ? () {} : null,
    unavailable: unavailable,
    loading: loading,
    audience: guest ? GzPriceAudience.guest : GzPriceAudience.member,
    previewState: preview,
  );
  final weekend = pk('V01-ladies-weekend');
  final longName = weekend.copyWith(
    id: 'long',
    name: const LocalizedText(
      en: 'Ladies’ Reception with the Grand Kosha, Zaffa Procession and Full Buffet',
      ar: 'الحفل النسائي الكبير مع الكوشة الملكية والزفّة وبوفيه العشاء الكامل لجميع الضيوف',
    ),
  );
  return cdSection(
    c,
    title: cdL(c, 'Package card', 'بطاقة الباقة'),
    note: cdL(
      c,
      'A choice, not a banner: serif name, the structure (per person or package), the voucher price in the basis it is sold in with the standard price struck through, minimum guests as a fact, inclusions with checks, what is not covered. Selected is an ink border and a gold bead; the total for the guests and the saving sit under the name.',
      'اختيار لا لافتة: اسم بالخط ذي الزوائد وطريقة التسعير (للضيف أو باقة) وسعر الكوبون بأساس بيعه مع السعر العادي مشطوبًا والحد الأدنى للضيوف كحقيقة والمشمولات بعلامات صح وما لا يشمله. المحددة بإطار حبري وخرزة ذهبية؛ والإجمالي للضيوف والتوفير تحت الاسم.',
    ),
    specimens: [
      cdSpec(c, cdL(c, 'Per guest · selected / not · 350 guests', 'للضيف · محددة / غير محددة · 350 ضيفًا'), [
        card('V01-ladies-weekend', selected: true),
        card('V01-ladies-signature'),
      ]),
      cdSpec(c, cdL(c, 'Flat plus per guest · hall only · flat villa night', 'ثابت مع سعر للضيف · القاعة فقط · ليلة فيلا بسعر ثابت'), [
        card('V03-lawn-evening', guests: 300),
        card('V07-hall-only'),
        card('V04-villa-night', guests: 120),
      ]),
      cdSpec(c, cdL(c, 'Guest (signed out): the standard price and a locked voucher line', 'زائر (غير مسجّل): السعر العادي وسطر كوبون مقفل'), [card('V01-ladies-weekend', guest: true)]),
      cdSpec(c, cdL(c, 'Unavailable on the date · long name · loading', 'غير متاحة في التاريخ · اسم طويل · تحميل'), [
        card('V01-ladies-signature', unavailable: true, select: false),
        card('V01-ladies-weekend', pkg: longName),
        card('V01-ladies-weekend', loading: true),
      ]),
      cdSpec(c, cdL(c, 'Pressed', 'الضغط'), [card('V01-ladies-weekend', preview: GzPreviewState.pressed)]),
    ],
  );
}

Widget _priceBreakdownSection(BuildContext c, ClientDData d) {
  final story = d.hero['pending']!.booking;
  final name = d.venueName.of(c.gz.locale.languageCode);
  GzPriceBreakdown bd(List<PriceLine> lines, QuoteTotals totals, GzBreakdownStage stage, {bool showLines = true, bool showSettlement = true, String? venue, bool loading = false}) =>
      GzPriceBreakdown(lines: lines, totals: totals, stage: stage, venueName: venue ?? name, showLines: showLines, showSettlement: showSettlement, loading: loading);
  Booking b(String k) => d.hero[k]!.booking;
  return cdSection(
    c,
    title: cdL(c, 'Price breakdown', 'تفاصيل السعر'),
    note: cdL(
      c,
      'Figures voice, three decimals, quiet .000. Each line carries the voucher amount with the standard amount struck through beneath it, then the totals (standard struck, voucher total as the headline, the saving), then who is paid what: the KD 2 voucher to Ghazal (paid once) and the voucher total to the venue directly after the client confirms. No deposit, no balance, no cancellation schedule.',
      'صوت الأرقام بثلاث خانات عشرية و.000 هادئة. كل سطر يحمل مبلغ الكوبون مع المبلغ العادي مشطوبًا تحته، ثم الإجماليات (العادي مشطوب وإجمالي الكوبون هو العنوان والتوفير)، ثم لمن يُدفع كل مبلغ: كوبون بقيمة 2 د.ك لغزل مرة واحدة، وإجمالي الكوبون للمكان مباشرة بعد التأكيد. بلا عربون ولا متبقٍّ ولا جدول إلغاء.',
    ),
    specimens: [
      cdSpec(c, cdL(c, 'Review · the story request: nothing more to pay Ghazal', 'المراجعة · طلب القصة: لا مبلغ إضافي لغزل'), [bd(story.lines, story.totals, GzBreakdownStage.review)]),
      cdSpec(c, cdL(c, 'Approved: totals and who is paid, no lines', 'تمت الموافقة: الإجماليات ولمن يُدفع دون الأسطر'), [bd(b('approved').lines, b('approved').totals, GzBreakdownStage.approved, showLines: false)]),
      cdSpec(c, cdL(c, 'Confirmed: pay the venue, then show the code', 'مؤكد: ادفعوا للمكان ثم اعرضوا الرمز'), [bd(b('confirmed').lines, b('confirmed').totals, GzBreakdownStage.confirmed, showLines: false)]),
      cdSpec(c, cdL(c, 'Redeemed · totals only (settlement block hidden)', 'تم الاستخدام · الإجماليات فقط'), [
        bd(b('redeemed').lines, b('redeemed').totals, GzBreakdownStage.redeemed, showLines: false),
        bd(b('redeemed').lines, b('redeemed').totals, GzBreakdownStage.redeemed, showLines: false, showSettlement: false, venue: ''),
      ]),
      cdSpec(c, cdL(c, 'Many lines: package, extra and service charge', 'أسطر كثيرة: باقة وإضافة ورسوم خدمة'), [bd(d.rich.lines, d.rich.totals, GzBreakdownStage.review)]),
      cdSpec(c, cdL(c, 'Stress: a very large total', 'ضغط: إجمالي كبير جدًا'), [bd(d.extreme.lines, d.extreme.totals, GzBreakdownStage.review, showLines: false)]),
      cdSpec(c, cdL(c, 'Loading', 'التحميل'), [bd(story.lines, story.totals, GzBreakdownStage.review, loading: true)]),
    ],
  );
}
