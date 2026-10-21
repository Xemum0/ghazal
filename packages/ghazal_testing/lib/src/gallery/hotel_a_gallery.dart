// The partner gallery, part A: the Flutter twin of sections 1 to 5 of design/src/gallery/hotel.tsx (#/gallery/hotel): request card,
// queue row, day timeline, 7-day strip, KPI tiles. Same specimens, states and sample text, driven by the real partner repositories
// (Aurelia Gulf Hotel, V01, the story day Thu 12 Nov 2026). ghazal_testing may hold string literals.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/hotel/hotel_a.dart';
import 'package:ghazal_ui/src/nav/gz_nav_scope.dart';

import '../world.dart';
import 'gz_gallery.dart';

/// The story day of the prototype and the venue of the partner persona.
const String hotelStoryToday = '2026-11-12';
const String hotelStoryNow = '16:00';
const String hotelVenueId = 'V01';

/// Everything the five sections show, fetched once through the repositories a partner screen would call.
class HotelAData {
  HotelAData({
    required this.requests,
    required this.needsYou,
    required this.halls,
    required this.packages,
    required this.claims,
    required this.analytics,
    required this.venueName,
  });

  final List<PartnerRequestRow> requests;
  final List<NeedsYouRow> needsYou;
  final List<Hall> halls;
  final Map<String, LocalizedText> packages;

  /// Claims of the next 28 days (`hallId|date` to claim), from the partner calendar.
  final Map<String, CalendarClaim> claims;
  final PartnerAnalytics analytics;
  final LocalizedText venueName;

  static Future<HotelAData> load(GzWorld world) async {
    final r = world.repos('hotel_manager', venueId: hotelVenueId);
    final today = LocalDate.parse(hotelStoryToday);
    final pending = await r.partnerRequests.listPartnerRequests(segment: RequestSegment.pending, limit: 20);
    final cal = await r.partnerCalendar.getPartnerCalendar(from: today, to: today.addDays(27));
    final packages = await r.partnerVenue.listPartnerPackages();
    final venue = await r.partnerVenue.getPartnerVenue();
    return HotelAData(
      requests: pending.items,
      needsYou: await r.partnerRequests.listNeedsYou(),
      halls: (await r.partnerVenue.listPartnerHalls()).halls,
      packages: {for (final p in packages.packages) p.package.id: p.package.name},
      claims: {for (final d in cal.days) for (final c in d.claims) '${c.hallId}|${c.date}': c},
      analytics: await r.partnerGrowth.getPartnerAnalytics(),
      venueName: venue.venue.name,
    );
  }

  PartnerRequestRow request(String bookingId) => requests.firstWhere((x) => x.booking.id == bookingId);
}

/// Section ids (the web `data-gz-section` ids) with their place on the web page.
const List<(int, String)> hotelAGalleryIds = [(1, 'request'), (2, 'row'), (3, 'timeline'), (4, 'strip'), (5, 'kpi')];

/// Wraps a section in the story formatter and the partner app type (the web page is an `AppContext` hotel).
Widget hotelGalleryWrap(Widget child) => gzStoryWrap(GzAppScope(app: GzAppKind.partner, child: child));

List<GzGallerySection> hotelAGallerySections(HotelAData Function() data) {
  final builders = <WidgetBuilder>[
    (c) => _request(c, data()),
    (c) => _row(c, data()),
    (c) => _timeline(c, data()),
    (c) => _strip(c, data()),
    (c) => _kpi(c, data()),
  ];
  return [for (var i = 0; i < builders.length; i++) GzGallerySection(hotelAGalleryIds[i].$2, builders[i], number: hotelAGalleryIds[i].$1)];
}

// ----------------------------------------------------------------------------------------------------------- layout kit
String _t(BuildContext context, String en, String ar) => context.gz.isAr ? ar : en;

Widget _sec(BuildContext context, String title, String note, List<Widget> children) {
  final c = context.gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      GzSectionHeader(title: title, voice: GzHeaderVoice.partner, draw: GzDraw.off),
      const SizedBox(height: GzSpace.s4),
      GzText(note, role: GzTextRole.bodyS, color: c.textSecondary),
      const SizedBox(height: GzSpace.s4),
      for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s6), children[i]],
    ],
  );
}

Widget _spec(BuildContext context, String cap, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [GzText(cap, role: GzTextRole.caption, color: context.gz.colors.textSecondary), const SizedBox(height: GzSpace.s2), child],
    );

Widget _panel(BuildContext context, Widget child) {
  final c = context.gz.colors;
  return Container(
    padding: const EdgeInsets.all(GzSpace.s4),
    decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
    child: child,
  );
}

/// A web `.hg-row`: equal-width children, stretched to the tallest (measured after the first layout: a sparkline's LayoutBuilder
/// has no intrinsic height, so `IntrinsicHeight` cannot do it).
Widget _row2(List<Widget> children) => _EqualRow(children: children);

class _EqualRow extends StatefulWidget {
  const _EqualRow({required this.children});

  final List<Widget> children;

  @override
  State<_EqualRow> createState() => _EqualRowState();
}

class _EqualRowState extends State<_EqualRow> {
  late final List<GlobalKey> _keys = [for (final _ in widget.children) GlobalKey()];
  double _min = 0;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      var h = 0.0;
      for (final k in _keys) {
        final box = k.currentContext?.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize && box.size.height > h) h = box.size.height;
      }
      if (h > _min + 0.01) setState(() => _min = h);
    });
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widget.children.length; i++) ...[
          if (i > 0) const SizedBox(width: GzSpace.s3),
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: _min),
              child: KeyedSubtree(key: _keys[i], child: widget.children[i]),
            ),
          ),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------------------------------------------------------- 1 request
const String _longName = 'عبدالرحمن بن محمد بن سلطان المطيري الدوسري';

Widget _request(BuildContext context, HotelAData d) {
  final lang = context.gz.locale.languageCode;
  // The web fixture has no other request on Reem's date (its caption says so); the API counts one, so the specimen sets it to 0.
  final reem = d.request('bk-GZ-2611-0147').copyWith(otherRequestsSameDate: 0);
  final dana = d.request('bk-GZ-2611-3K8D');
  final abdullah = d.request('bk-GZ-2611-5T2W');
  final maryam = d.request('bk-GZ-2611-6R9C');
  final gold = abdullah.copyWith(sla: abdullah.sla!.copyWith(state: SlaState.gold, elapsed: 0.62, minutesLeft: 9 * 60 + 10, minutesWaiting: 14 * 60 + 50), otherRequestsSameDate: 2);
  final urgent = dana.copyWith(booking: dana.booking.copyWith(eventDate: LocalDate.parse(hotelStoryToday).addDays(9)));
  final long = maryam.copyWith(
    booking: maryam.booking.copyWith(
      clientName: _longName,
      specialRequests: 'نرجو تجهيز الكوشة قبل الساعة السابعة مساءً مع وجود مدخل منفصل للعروس وأسرتها.',
    ),
  );
  GzRequestCard card(PartnerRequestRow r, {GzRequestCardState state = GzRequestCardState.viewed, bool? canCall, bool held = false, String? reason}) => GzRequestCard(
        request: r,
        packageName: d.packages[r.booking.sections.first.packageId],
        state: state,
        canCall: canCall,
        held: held,
        declineReason: reason,
        undoPaused: true,
      );
  String t(String en, String ar) => lang == 'ar' ? ar : en;
  return _sec(
    context,
    t('Request card', 'بطاقة الطلب'),
    t(
      'The triage card: one gold Accept, equal-weight Reschedule and Decline, the depleting reply bar, the check line or the conflict note, the compact Booking Thread. No swipe actions.',
      'بطاقة الفرز: زر قبول ذهبي واحد، وتغيير الموعد والاعتذار بوزن متساوٍ، وشريط مهلة الرد المتناقص، وسطر التحقق أو ملاحظة التعارض، وخيط الحجز المصغّر. لا إجراءات بالسحب.',
    ),
    [
      _spec(context, t('New · neutral window · no other request', 'جديد · مهلة عادية · لا طلبات أخرى'), card(reem, state: GzRequestCardState.newRequest)),
      _spec(context, t('Danger window (from 80% or under an hour) · event in 9 days: the Urgent tag', 'مهلة حرجة (من 80% أو أقل من ساعة) · المناسبة بعد 9 أيام: وسم عاجل'), card(urgent)),
      _spec(context, t('Gold window (from 50%) · +2 other requests, Compare link ', 'مهلة تنبيه (من 50%) · +2 طلبان آخران مع رابط المقارنة '), card(gold)),
      _spec(context, t('Long name, special requests, number not shared (no Call)', 'اسم طويل وطلبات خاصة ورقم غير مشارَك (بلا اتصال)'), card(long, canCall: false)),
      _spec(context, t('Date held for another couple · Accept disabled with its reason', 'التاريخ محجوز لعميل آخر · القبول معطّل مع سببه'), card(dana, held: true)),
      _spec(context, t('Accepting · Accept in flight, the pair held', 'قيد القبول · القبول جارٍ والزران الآخران معطّلان'), card(reem, state: GzRequestCardState.accepting)),
      _spec(context, t('Approved · awaiting the client for 24 hours, Undo for 8 seconds', 'تمت الموافقة · بانتظار العميل 24 ساعة مع تراجع لمدة 8 ثوانٍ'), card(reem, state: GzRequestCardState.accepted)),
      _spec(context, t('Declined · reason given', 'تم الاعتذار · مع ذكر السبب'), card(abdullah, state: GzRequestCardState.declined, reason: t('Date unavailable.', 'التاريخ غير متاح.'))),
    ],
  );
}

// ---------------------------------------------------------------------------------------------------------------- 2 row
Widget _row(BuildContext context, HotelAData d) {
  // The web fixture lists one row per kind (awaiting client, message, visit, review); the API lists every message and review.
  final seen = <TriageType>{};
  final others = d.needsYou.where((n) => n.item.type != TriageType.request && seen.add(n.item.type)).take(4).toList();
  return _sec(
    context,
    _t(context, 'Queue row', 'صف قائمة الانتظار'),
    _t(
      context,
      'The compact Needs-you row, 80 high: who, which date, what it is worth and how long is left. Time left is text with an icon in the SLA tone.',
      'صف بانتظاركم المختصر بارتفاع 80: من ومتى وكم قيمته وكم تبقى. الوقت المتبقي نص مع أيقونة بلون مستوى المهلة.',
    ),
    [
      _spec(
        context,
        _t(context, 'Requests: danger, neutral, new', 'طلبات: حرج، عادي، جديد'),
        _panel(context, Column(children: [for (var i = 0; i < 3; i++) GzRequestRow(request: d.requests[i], isNew: i == 2, flush: true, last: i == 2)])),
      ),
      _spec(
        context,
        _t(context, 'Other Needs-you items: message, balance, review, calendar check', 'عناصر أخرى بانتظاركم: رسالة، مبلغ متبقٍّ، تقييم، مراجعة التقويم'),
        _panel(context, Column(children: [for (var i = 0; i < others.length; i++) GzRequestRow.fromNeedsYou(others[i], flush: true, last: i == others.length - 1)])),
      ),
    ],
  );
}

// ----------------------------------------------------------------------------------------------------------- 3 timeline
String _minusMinutes(String hhmm, int mins) {
  final p = hhmm.split(':').map(int.parse).toList();
  final t = ((p[0] * 60 + p[1] - mins) % 1440 + 1440) % 1440;
  return '${(t ~/ 60).toString().padLeft(2, '0')}:${(t % 60).toString().padLeft(2, '0')}';
}

Widget _timeline(BuildContext context, HotelAData d) {
  final lang = context.gz.locale.languageCode;
  final f = context.gzFormat;
  final events = <GzTimelineEvent>[];
  for (final c in d.claims.values.where((c) => c.date.toString() == hotelStoryToday && c.kind == ClaimKind.booking)) {
    final hall = d.halls.firstWhere((h) => h.id == c.hallId);
    final session = hall.sessions.isEmpty ? null : hall.sessions.first;
    final hallName = hall.name.of(lang);
    final start = c.start?.toString() ?? session?.start.toString() ?? '21:00';
    final end = c.end?.toString() ?? session?.end.toString() ?? '02:00';
    final before = session?.bufferBeforeMin ?? 120;
    final after = session?.bufferAfterMin ?? 60;
    events.addAll([
      GzTimelineEvent(id: '${c.id}-setup', time: _minusMinutes(start, before), title: _t(context, 'Setup', 'التجهيز'), meta: hallName, kind: GzTimelineKind.prep),
      GzTimelineEvent(
        id: c.id,
        time: start,
        title: c.clientName ?? '',
        userTitle: true,
        status: GzStatus.confirmed,
        meta: '$hallName · ${f.guests(c.guests ?? 0)}',
      ),
      GzTimelineEvent(id: '${c.id}-down', time: _minusMinutes(end, -after), nextDay: true, title: _t(context, 'Teardown', 'الفك والتنظيف'), meta: hallName, kind: GzTimelineKind.prep),
    ]);
  }
  return _sec(
    context,
    _t(context, 'Day timeline', 'خط اليوم'),
    _t(
      context,
      'The vertical thread of the day. Done knots are gold, the ringed knot is now, open knots are hollow; the line is gold up to now. Setup and teardown are quiet.',
      'الخيط العمودي لليوم. العُقد المنجزة ذهبية، والعقدة المحاطة بحلقة هي الآن، والمفتوحة مجوفة، والخط ذهبي حتى الآن. التجهيز والفك بلون هادئ.',
    ),
    [
      _panel(context, GzDayTimeline(date: hotelStoryToday, events: events, now: hotelStoryNow)),
      _spec(context, _t(context, 'A day with nothing scheduled', 'يوم بلا مواعيد'), _panel(context, const GzDayTimeline(date: hotelStoryToday, events: []))),
      GzText(d.venueName.of(lang), role: GzTextRole.caption, color: context.gz.colors.textSecondary),
    ],
  );
}

// -------------------------------------------------------------------------------------------------------------- 4 strip
Widget _strip(BuildContext context, HotelAData d) {
  final f = context.gzFormat;
  final today = LocalDate.parse(hotelStoryToday);
  List<GzStripDay> make(int n) => [
        for (var i = 0; i < n; i++)
          GzStripDay(iso: today.addDays(i).toString(), marks: [
            for (final h in d.halls)
              switch (d.claims['${h.id}|${today.addDays(i)}']?.kind) {
                null => GzStripMark.open,
                ClaimKind.booking || ClaimKind.block => GzStripMark.confirmed,
                _ => GzStripMark.pending,
              },
          ]),
      ];
  final c = context.gz.colors;
  return _sec(
    context,
    _t(context, '7-day strip', 'شريط الأيام السبعة'),
    _t(
      context,
      'One mark per hall: confirmed solid ink, pending or on hold gold, open an outline. Today has the ink outline; the selected day is the one gold fill.',
      'علامة لكل قاعة: المؤكد حبر مصمت، وبانتظار الرد أو المحجوز مؤقتًا ذهبي، والمتاح إطار. لليوم إطار حبري، واليوم المحدد هو التعبئة الذهبية الوحيدة.',
    ),
    [
      _panel(context, GzWeekStrip(label: _t(context, 'Next 7 days', 'الأيام السبعة القادمة'), days: make(7), today: hotelStoryToday, selected: today.addDays(2).toString())),
      _spec(
        context,
        _t(context, '14 days, nothing selected, with the open-weekends footer', '14 يومًا دون تحديد مع سطر عطلات الأسبوع المتاحة'),
        _panel(
          context,
          GzWeekStrip(
            label: _t(context, 'Next 14 days', 'الأربعة عشر يومًا القادمة'),
            days: make(14),
            today: hotelStoryToday,
            footer: GzText(
              _t(context, '${f.integer(9)} open weekend dates in the next 60 days', '${f.integer(9)} تواريخ متاحة في نهاية الأسبوع خلال 60 يومًا'),
              role: GzTextRole.caption,
              color: c.textSecondary,
              figures: true,
            ),
          ),
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------------------------------------------- 5 kpi
Widget _kpi(BuildContext context, HotelAData d) {
  final f = context.gzFormat;
  final a = d.analytics;
  List<KpiPoint> series(KpiId id) => a.series.where((s) => s.id == id).map((s) => s.points).firstOrNull ?? const [];
  List<num> values(KpiId id) => [for (final p in series(id)) p.value];
  String vs() => _t(context, 'vs last month', 'مقارنة بالشهر الماضي');
  GzKpiTrend trend(KpiId id, String en, String ar) => GzKpiTrend(values: values(id), label: _t(context, en, ar));

  final today = LocalDate.parse(hotelStoryToday);
  var booked = 0, held = 0, blocked = 0;
  const nights = 28;
  for (var i = 0; i < nights; i++) {
    for (final h in d.halls) {
      switch (d.claims['${h.id}|${today.addDays(i)}']?.kind) {
        case ClaimKind.booking:
          booked++;
        case ClaimKind.hold:
          held++;
        case ClaimKind.block:
          blocked++;
        default:
      }
    }
  }
  final period = '${f.date(a.range.from.toString(), DateStyle.dayMonth)} – ${f.date(a.range.to.toString(), DateStyle.dayMonth)}';
  return _sec(
    context,
    _t(context, 'KPI tiles and money', 'المؤشرات والمبالغ'),
    _t(
      context,
      'Figures in Cairo, never serif; the delta carries an icon, a sign and a word; sparklines mirror in Arabic.',
      'الأرقام بخط القاهرة وليس بخط ذي زوائد؛ ويحمل التغيّر أيقونة وإشارة وكلمة؛ وتنعكس المخططات المصغّرة في العربية.',
    ),
    [
      _row2([
        GzKpiTile(label: _t(context, 'Views', 'المشاهدات'), value: GzKpiValue.count(a.tiles.views.value), delta: a.tiles.views.deltaPct, deltaLabel: vs(), trend: trend(KpiId.views, 'Views, last 30 days', 'المشاهدات، آخر 30 يومًا')),
        GzKpiTile(label: _t(context, 'Requests', 'الطلبات'), value: GzKpiValue.count(a.tiles.requests), delta: -6, deltaLabel: vs(), trend: trend(KpiId.requests, 'Requests, last 30 days', 'الطلبات، آخر 30 يومًا')),
      ]),
      _row2([
        GzKpiTile(
          label: _t(context, 'Conversion', 'التحويل'),
          value: GzKpiValue.percent(a.tiles.conversionBps / 100),
          delta: 0,
          deltaLabel: _t(context, 'unchanged', 'دون تغيير'),
          trend: trend(KpiId.conversion, 'Conversion, last 30 days', 'التحويل، آخر 30 يومًا'),
        ),
        GzKpiTile(label: _t(context, 'Confirmed', 'مؤكدة'), value: GzKpiValue.count(a.tiles.confirmed)),
      ]),
      GzKpiTile(
        hero: true,
        label: _t(context, 'Vouchers redeemed this month', 'كوبونات تم استخدامها هذا الشهر'),
        value: GzKpiValue.count(a.tiles.vouchersRedeemed),
        sub: _t(context, '${f.integer(a.tiles.vouchersBought)} bought for this venue', '${f.integer(a.tiles.vouchersBought)} كوبونًا مشترى لهذا المكان'),
        delta: 12,
        deltaLabel: vs(),
        trend: trend(KpiId.vouchersRedeemed, 'Vouchers redeemed, last 30 days', 'الكوبونات المستخدمة، آخر 30 يومًا'),
      ),
      GzVoucherActivityCard(
        title: _t(context, 'Vouchers this month', 'كوبونات هذا الشهر'),
        period: period,
        bought: a.tiles.vouchersBought,
        delta: 12,
        daily: [for (final p in series(KpiId.vouchersBought)) GzVoucherDay(date: p.date.toString(), value: p.value)],
        requests: a.tiles.requests,
        awaitingClient: (a.tiles.approved - a.tiles.confirmed).clamp(0, 1 << 30),
        redeemed: a.tiles.vouchersRedeemed,
      ),
      GzOccupancyMeter(
        title: _t(context, 'Occupancy, next 28 days', 'الإشغال، 28 يومًا القادمة'),
        booked: booked,
        held: held,
        blocked: blocked,
        open: nights * d.halls.length - booked - held - blocked,
      ),
    ],
  );
}
