// The hotel gallery, part C: the Flutter twin of sections 11-15 of design/src/gallery/hotel.tsx (#/gallery/hotel): booking, offer,
// venue, settings, review. Same specimens, states and sample text as design/src/system/domain-hotel/gallery/{Booking,Manage}Sections.tsx,
// driven by real objects of the Aurelia Gulf Hotel (HotelCData). Parity: `node tools/parity/parity.mjs --gallery hotel --sections 11,12,13,14,15`
// after `flutter test test/gallery/hotel_c_gallery_test.dart`. ghazal_testing may hold string literals.
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/src/client/client.dart' show GzNotificationRow;
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/hotel/hotel_c.dart';
import 'package:ghazal_ui/src/inputs/inputs.dart' show GzDateRange;

import 'gz_gallery.dart';
import 'hotel_c_gallery_data.dart';

/// The web `data-gz-section` ids of this file and their place on the hotel gallery page.
const Map<String, int> hotelCGalleryNumbers = {'booking': 11, 'offer': 12, 'venue': 13, 'settings': 14, 'review': 15};

/// The sections 11 to 15 of the hotel gallery page ([d] is read when a section renders: the data loads in `setUpAll`).
List<GzGallerySection> hotelCGallerySections(HotelCData Function() d) => [
  GzGallerySection('booking', (c) => _booking(c, d()), number: 11),
  GzGallerySection('offer', (c) => _offer(c, d()), number: 12),
  GzGallerySection('venue', (c) => _venue(c, d()), number: 13),
  GzGallerySection('settings', (c) => _settings(c, d()), number: 14),
  GzGallerySection('review', (c) => _review(c, d()), number: 15),
];

String _t(BuildContext context, String en, String ar) => context.gz.isAr ? ar : en;

// ------------------------------------------------------------------------------------------------------------------- kit
/// `Section` of the hotel gallery kit: khayt, ui-title heading (gap 12), the note, then the specimens (gap 24); 16 between the blocks.
Widget _sec(BuildContext context, {required String title, required String note, required List<Widget> specs}) {
  final c = context.gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: GzThreadRule(draw: GzDraw.off),
      ),
      const SizedBox(height: GzSpace.s3),
      GzText(title, role: GzTextRole.uiTitle, color: c.textStrong, header: true),
      const SizedBox(height: GzSpace.s4),
      GzText(note, role: GzTextRole.bodyS, color: c.textSecondary),
      const SizedBox(height: GzSpace.s4),
      for (var i = 0; i < specs.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s6), specs[i]],
    ],
  );
}

/// `Spec`: a caption naming the state (caption, secondary, gap 8) over the component(s).
Widget _spec(BuildContext context, String cap, List<Widget> children) {
  final c = context.gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      GzText(cap, role: GzTextRole.caption, color: c.textSecondary),
      const SizedBox(height: GzSpace.s2),
      ...children, // the web `.hg-spec__body` has no gap
    ],
  );
}

/// `Stage kind="panel"`: a paper panel with a hairline.
Widget _panel(BuildContext context, Widget child) {
  final c = context.gz.colors;
  return Container(
    padding: const EdgeInsets.all(GzSpace.s4),
    decoration: BoxDecoration(
      color: c.surfaceRaised,
      borderRadius: GzRadius.mdAll,
      border: Border.all(color: c.borderStrong, width: GzStroke.hair),
    ),
    child: child,
  );
}

// ------------------------------------------------------------------------------------------------------------- 11 booking
Widget _booking(BuildContext context, HotelCData d) {
  final confirmed = d.confirmed.booking;
  final longName = confirmed.copyWith(
    clientName: 'عبدالرحمن بن محمد بن سلطان المطيري الدوسري',
    contact: confirmed.contact.copyWith(shared: false),
  );
  return _sec(
    context,
    title: _t(context, 'Request detail', 'تفاصيل الطلب'),
    note: _t(
      context,
      'The pieces of the one request screen: the guest card, the status with the vertical Booking Thread and the voucher block (what the client pays you directly, the standard price struck through, Redeem voucher), and the actions with what happens to the client’s voucher.',
      'مكوّنات شاشة الطلب الواحدة: بطاقة العميل، والحالة مع خيط الحجز العمودي وكتلة الكوبون (ما يدفعه العميل لكم مباشرة والسعر العادي مشطوبًا وزر استخدام الكوبون)، والإجراءات مع ما يحدث لكوبون العميل.',
    ),
    specs: [
      _spec(context, _t(context, 'Guest card · number shared', 'بطاقة العميل · الرقم مُشارَك'), [GzGuestCard(booking: confirmed)]),
      _spec(
        context,
        _t(
          context,
          'Guest card · long name, number not shared (Call disabled with its reason)',
          'بطاقة العميل · اسم طويل ورقم غير مُشارَك (الاتصال معطّل مع سببه)',
        ),
        [GzGuestCard(booking: longName, voucher: false)],
      ),
      _spec(
        context,
        _t(
          context,
          'Status · pending: the Approval knot is now (reply window)',
          'الحالة · بانتظار الرد: عقدة الموافقة هي الحالية (مهلة الرد)',
        ),
        [GzBookingStatusCard(booking: d.pending.booking, voucher: d.pending.voucher)],
      ),
      _spec(
        context,
        _t(
          context,
          'Status · approved: waiting for the client to confirm within 24 hours',
          'الحالة · تمت الموافقة: بانتظار تأكيد العميل خلال 24 ساعة',
        ),
        [GzBookingStatusCard(booking: d.approved.booking, voucher: d.approved.voucher)],
      ),
      _spec(context, _t(context, 'Status · confirmed: Redeem voucher offered', 'الحالة · مؤكد: زر استخدام الكوبون متاح'), [
        GzBookingStatusCard(booking: confirmed, voucher: d.confirmed.voucher, canRedeem: true),
      ]),
      _spec(
        context,
        _t(context, 'Status · redeemed, and a pending request with a date proposed', 'الحالة · تم الاستخدام، وطلب بانتظار موعد مقترح'),
        [
          GzBookingStatusCard(booking: d.redeemed.booking, voucher: d.redeemed.voucher),
          GzBookingStatusCard(booking: d.counter.booking, voucher: d.counter.voucher),
        ],
      ),
      _spec(context, _t(context, 'Actions with consequences (Admin or Manager)', 'الإجراءات مع عواقبها (المالك أو المدير)'), [
        _panel(context, const GzBookingActionList(actions: [GzBookingAction.reschedule, GzBookingAction.revoke, GzBookingAction.cancel])),
      ]),
    ],
  );
}

// --------------------------------------------------------------------------------------------------------------- 12 offer
Widget _offer(BuildContext context, HotelCData d) {
  final lang = context.gz.locale.languageCode;
  return _sec(
    context,
    title: _t(context, 'Voucher price window editor', 'محرر نافذة سعر الكوبون'),
    note: _t(
      context,
      'Step 1: when the lower voucher price applies and runs. The preview is the client app’s own card, with the real standard price struck through and the saving in exact money.',
      'الخطوة 1: متى ينطبق سعر الكوبون الأقل ومتى يعمل. المعاينة هي بطاقة تطبيق العملاء نفسها مع شطب السعر العادي الفعلي والتوفير بالمبلغ الدقيق.',
    ),
    specs: [
      _spec(context, _t(context, 'When: event dates, a time-boxed window, scheduled', 'المدة: تواريخ المناسبة ونافذة محددة المدة، مجدول'), [
        _OfferState(
          builder: (range, hours, setRange, setHours) => GzValidityRange(
            value: range,
            onDatesTap: () {},
            windowHours: hours,
            onWindowChange: setHours,
            endsAt: DateTime.parse('2026-11-13T16:00:00+03:00'),
            startsAt: DateTime.parse('2026-11-13T16:00:00+03:00'),
            status: GzValidityStatus.scheduled,
          ),
        ),
      ]),
      _spec(
        context,
        _t(
          context,
          'Live preview: a lower voucher price on Ladies’ Reception, Weekend',
          'معاينة حية: سعر كوبون أقل على الحفل النسائي في نهاية الأسبوع',
        ),
        [
          GzVoucherWindowPreview(
            venue: d.venue,
          area: d.area,
            title: d.flash.title.of(lang),
            standard: 18200000,
            voucher: 15400000,
            guests: 350,
            packageId: 'V01-ladies-weekend',
            date: LocalDate.parse('2026-12-03'),
          ),
        ],
      ),
    ],
  );
}

class _OfferState extends StatefulWidget {
  const _OfferState({required this.builder});

  final Widget Function(GzDateRange range, int hours, ValueChanged<GzDateRange> setRange, ValueChanged<int> setHours) builder;

  @override
  State<_OfferState> createState() => _OfferStateState();
}

class _OfferStateState extends State<_OfferState> {
  GzDateRange _range = const GzDateRange(start: '2026-12-03', end: '2026-12-05');
  int _hours = 24;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_range, _hours, (r) => setState(() => _range = r), (h) => setState(() => _hours = h));
}

// --------------------------------------------------------------------------------------------------------------- 13 venue
PriceRule? _weekendRule(PackageEditor e) {
  bool priced(PriceRule r) => r.perGuest != null || r.flat != null;
  for (final r in e.rules) {
    if (r.tier == PriceTier.weekend && priced(r)) return r;
  }
  for (final r in e.rules) {
    if (priced(r)) return r;
  }
  return null;
}

Widget _venue(BuildContext context, HotelCData d) {
  final pkgs = d.packages.take(3).toList();
  final gallery = d.venue.gallery.take(8).toList();
  final tiles = [
    for (var i = 0; i < gallery.length; i++)
      GzPhotoTile.fromGallery(gallery[i], status: i == 3 ? GzPhotoStatus.review : (i == 6 ? GzPhotoStatus.rejected : GzPhotoStatus.live)),
  ];
  return _sec(
    context,
    title: _t(context, 'Packages and photos', 'الباقات والصور'),
    note: _t(
      context,
      'Edit the standard and voucher price, minimum guests and inclusions in place; manage the photo grid with a cover marker, zone tags, status chips and a reorder mode with plain Move buttons.',
      'عدّلوا السعر العادي وسعر الكوبون والحد الأدنى للضيوف وما تشمله الباقة في مكانه؛ وأدِيروا شبكة الصور بعلامة الغلاف ووسوم المناطق وشارات الحالة ووضع إعادة ترتيب بأزرار نقل واضحة.',
    ),
    specs: [
      _panel(
        context,
        Column(
          children: [
            for (var i = 0; i < pkgs.length; i++)
              () {
                final r = _weekendRule(pkgs[i]);
                return GzPackageEditorRow(
                  pkg: pkgs[i].package,
                  priceFils: r?.perGuest?.fils ?? r?.flat?.fils ?? 0,
                  voucherFils: r?.voucherPerGuest?.fils ?? r?.voucherFlat?.fils,
                  defaultExpanded: i == 0,
                  last: i == pkgs.length - 1,
                );
              }(),
          ],
        ),
      ),
      _spec(
        context,
        _t(
          context,
          'Photos: cover, zone tags, under review, rejected, Add tile',
          'الصور: الغلاف ووسوم المناطق وقيد المراجعة والمرفوضة وبلاطة الإضافة',
        ),
        [GzPhotoManagerGrid(items: tiles, imageOf: (t) => d.imageFor(t.id))],
      ),
      _spec(context, _t(context, 'Reorder mode: handle and Move earlier / Move later', 'وضع إعادة الترتيب: المقبض وزرا التقديم والتأخير'), [
        GzPhotoManagerGrid(items: tiles.take(5).toList(), reorder: true, imageOf: (t) => d.imageFor(t.id)),
      ]),
    ],
  );
}

// ----------------------------------------------------------------------------------------------------------- 14 settings
Widget _settings(BuildContext context, HotelCData d) {
  HoursRule? hoursOf(int wd) {
    for (final r in d.hours) {
      if (r.days.contains(wd)) return r;
    }
    return null;
  }

  const open = {0: true, 1: true, 2: true, 3: true, 4: true, 5: true, 6: false};
  return _sec(
    context,
    title: _t(context, 'Staff and hours', 'الموظفون والساعات'),
    note: _t(
      context,
      'Roles explained in one line and as a check list; hours with custom time buttons and the past-midnight label',
      'الأدوار موضّحة بسطر واحد وبقائمة صلاحيات؛ والساعات بأزرار وقت مخصصة وعلامة تجاوز منتصف الليل',
    ),
    specs: [
      _panel(
        context,
        Column(
          children: [
            for (var i = 0; i < d.staff.length; i++)
              GzStaffRow(staff: d.staff[i], defaultExpanded: d.staff[i].role == StaffRole.reception, last: i == d.staff.length - 1),
          ],
        ),
      ),
      _panel(
        context,
        Column(
          children: [
            for (var wd = 0; wd < 7; wd++)
              GzBusinessHoursRow(
                weekday: wd,
                open: open[wd]!,
                from: hoursOf(wd)?.open.toString() ?? '09:00',
                to: hoursOf(wd)?.close.toString() ?? '22:00',
                onOpenChange: (_) {},
                onCopy: wd == 0 ? () {} : null,
                last: wd == 6,
              ),
          ],
        ),
      ),
      _spec(context, _t(context, 'Invalid: opening and closing at the same time', 'غير صالح: الفتح والإغلاق في الوقت نفسه'), [
        _panel(context, const GzBusinessHoursRow(weekday: 4, open: true, from: '09:00', to: '09:00', invalid: true, last: true)),
      ]),
    ],
  );
}

// ------------------------------------------------------------------------------------------------------------ 15 review
Widget _review(BuildContext context, HotelCData d) {
  final needs = d.reviews.where((r) => r.ownerReply == null && r.replyDraft != null).firstOrNull;
  final replied = d.reviews.where((r) => r.ownerReply != null).firstOrNull;
  final plain = d.reviews.where((r) => r.ownerReply == null && r.replyDraft == null && r.id != needs?.id).firstOrNull;
  return _sec(
    context,
    title: _t(context, 'Reviews and notifications', 'التقييمات والإشعارات'),
    note: _t(
      context,
      'Reply once, report abuse; the hotel never edits or hides a review. Notifications reuse the system row with the hotel kinds.',
      'رد واحد وإبلاغ عن الإساءة؛ ولا يعدّل الفندق التقييم ولا يخفيه. تستخدم الإشعارات الصف نفسه مع أنواع الفندق.',
    ),
    specs: [
      _panel(
        context,
        Column(
          children: [
            if (needs != null) GzReviewReplyCard(review: needs, state: GzReviewReplyState.needsReply),
            if (replied != null) GzReviewReplyCard(review: replied, state: GzReviewReplyState.replied),
            if (plain != null) GzReviewReplyCard(review: plain, state: GzReviewReplyState.reported, last: true),
          ],
        ),
      ),
      _spec(
        context,
        _t(
          context,
          'Hotel notifications (new request, message, cancellation, payment, review)',
          'إشعارات الفندق (طلب جديد، رسالة، إلغاء، دفعة، تقييم)',
        ),
        [
          _panel(
            context,
            Column(
              children: [
                for (var i = 0; i < d.notifications.length; i++)
                  GzNotificationRow(notification: d.notifications[i], last: i == d.notifications.length - 1),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}
