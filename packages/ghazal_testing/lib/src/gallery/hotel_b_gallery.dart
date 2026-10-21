// The partner gallery, part B: the Flutter twin of sections 6 to 10 of design/src/gallery/hotel.tsx (#/gallery/hotel): month (6), select
// (7), week (8), day (9), block (10). Same specimens, states and sample text as design/src/system/domain-hotel/gallery/CalendarSections.tsx,
// driven by the real calendar claims of Aurelia Gulf Hotel (V01, two halls) fetched through the hotel manager's repositories.
// Parity: `node tools/parity/parity.mjs --gallery hotel --sections 6,7,8,9,10` after `flutter test test/gallery/hotel_b_gallery_test.dart`.
// ghazal_testing may hold string literals (tests and galleries are exempt from the no-text-literal rule).
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart'
    show CalendarClaim, Hall, LocalDate, Occasion;
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/hotel/hotel_b.dart';
import 'package:ghazal_ui/src/inputs/gz_calendar_model.dart';
import 'package:ghazal_ui/src/nav/gz_nav_scope.dart';

import '../world.dart';
import 'gz_gallery.dart';

/// The fixtures the calendar sections draw: the two halls, the venue's claims for the availability window, and the occasions.
class HotelBData {
  const HotelBData({
    required this.halls,
    required this.claims,
    required this.occasions,
  });

  final List<Hall> halls;
  final List<CalendarClaim> claims;
  final List<Occasion> occasions;
}

/// Loads [HotelBData] as the hotel manager of V01 (real async: call it in `setUpAll`, never inside `testWidgets`).
Future<HotelBData> loadHotelBData(GzWorld world) async {
  final r = world.repos('hotel_manager', venueId: 'V01');
  // The venue's own hall order (the web gallery reads `getVenue(...).halls`): a mark sits in its hall's slot.
  final halls = (await r.venues.getVenue(venueId: 'V01')).venue.halls;
  // The calendar endpoint serves a window of at most a month and a bit: the three months the sections show, one call each.
  final claims = <CalendarClaim>[];
  for (final (from, to) in const [
    ('2026-11-01', '2026-11-30'),
    ('2026-12-01', '2026-12-31'),
    ('2027-01-01', '2027-01-31'),
  ]) {
    final cal = await r.partnerCalendar.getPartnerCalendar(
      from: LocalDate.parse(from),
      to: LocalDate.parse(to),
    );
    claims.addAll([for (final d in cal.days) ...d.claims]);
  }
  final cfg = await r.home.getAppConfig();
  return HotelBData(halls: halls, claims: claims, occasions: cfg.occasions);
}

/// The partner pages draw the hotel app's type (the web `AppContext = hotel`) and the story clock.
Widget hotelBGalleryWrap(Widget child) =>
    GzAppScope(app: GzAppKind.partner, child: gzStoryWrap(child));

/// The five sections, numbered as on the web page.
/// [data] is read when a section builds (after `setUpAll`), not when the list is made.
List<GzGallerySection> hotelBGallerySections(HotelBData Function() data) => [
  GzGallerySection('month', (c) => _MonthSection(data()), number: 6),
  GzGallerySection('select', (c) => _SelectSection(data()), number: 7),
  GzGallerySection('week', (c) => _WeekSection(data()), number: 8),
  GzGallerySection('day', (c) => _DaySection(data()), number: 9),
  GzGallerySection('block', (c) => _BlockSection(data()), number: 10),
];

String _t(BuildContext context, String en, String ar) =>
    context.gz.isAr ? ar : en;

/// `Section` of the hotel gallery kit: khayt, ui-title, the note, then the specimens (gap 24), each block 16 apart.
Widget _sec(
  BuildContext context, {
  required String title,
  required String note,
  required List<Widget> specs,
}) {
  final c = context.gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: GzThreadRule(draw: GzDraw.off),
      ),
      const SizedBox(height: GzSpace.s3),
      GzText(
        title,
        role: GzTextRole.uiTitle,
        color: c.textStrong,
        header: true,
      ),
      const SizedBox(height: GzSpace.s4),
      GzText(note, role: GzTextRole.bodyS, color: c.textSecondary),
      const SizedBox(height: GzSpace.s4),
      for (var i = 0; i < specs.length; i++) ...[
        if (i > 0) const SizedBox(height: GzSpace.s6),
        specs[i],
      ],
    ],
  );
}

/// `Spec`: a caption naming the state over the specimen, 8 apart.
Widget _spec(BuildContext context, String cap, Widget body) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    GzText(
      cap,
      role: GzTextRole.caption,
      color: context.gz.colors.textSecondary,
    ),
    const SizedBox(height: GzSpace.s2),
    body,
  ],
);

/// `Stage kind="panel"`: a paper panel with a hairline, padding 16.
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

class _MonthSection extends StatefulWidget {
  const _MonthSection(this.data);

  final HotelBData data;

  @override
  State<_MonthSection> createState() => _MonthSectionState();
}

class _MonthSectionState extends State<_MonthSection> {
  String? _day = '2027-01-14';

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return _sec(
      context,
      title: _t(context, 'Month grid and agenda', 'عرض الشهر وجدول اليوم'),
      note: _t(
        context,
        'One mark per hall, in hall order: a solid disc is booked, a ring is on hold, a dash is blocked, a gold bead is a pending request. Tap a day and its agenda opens below.',
        'علامة لكل قاعة بترتيب القاعات: القرص المصمت محجوز، والحلقة محجوز مؤقتًا، والشرطة مغلق، والخرزة الذهبية طلب بانتظار الرد. انقروا على يوم لفتح جدوله أدناه.',
      ),
      specs: [
        _panel(
          context,
          GzHotelMonthGrid(
            halls: d.halls,
            claims: d.claims,
            defaultMonth: const GzYm(2027, 1),
            selected: _day,
            onSelectDate: (iso) => setState(() => _day = iso),
            label: _t(context, 'Calendar, January 2027', 'التقويم، يناير 2027'),
          ),
        ),
        if (_day != null)
          _panel(
            context,
            GzDayAgenda(date: _day!, halls: d.halls, claims: d.claims),
          ),
        _spec(
          context,
          _t(
            context,
            'The agenda of a day with a hold in one hall and a booking in the other',
            'جدول يوم فيه تثبيت مؤقت في قاعة وحجز في الأخرى',
          ),
          _panel(
            context,
            GzDayAgenda(date: '2026-12-10', halls: d.halls, claims: d.claims),
          ),
        ),
        _spec(
          context,
          _t(
            context,
            'The agenda of a day blocked in both halls',
            'جدول يوم مغلق في القاعتين',
          ),
          _panel(
            context,
            GzDayAgenda(date: '2026-11-23', halls: d.halls, claims: d.claims),
          ),
        ),
      ],
    );
  }
}

class _SelectSection extends StatefulWidget {
  const _SelectSection(this.data);

  final HotelBData data;

  @override
  State<_SelectSection> createState() => _SelectSectionState();
}

class _SelectSectionState extends State<_SelectSection> {
  GzDateRange _range = const GzDateRange(
    start: '2026-12-15',
    end: '2026-12-18',
  );

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return _sec(
      context,
      title: _t(context, 'Range selection', 'تحديد النطاق'),
      note: _t(
        context,
        'Press and hold, then drag; or tap a start and an end. A thread joins the endpoints; booked-out and past days refuse the selection.',
        'اضغطوا مطوّلًا ثم اسحبوا، أو انقروا على البداية ثم النهاية. يصل خيط ذهبي بين الطرفين، وترفض الأيام المحجوزة بالكامل أو الماضية التحديد.',
      ),
      specs: [
        const GzDragAffordance(),
        _panel(
          context,
          GzHotelMonthGrid(
            halls: d.halls,
            claims: d.claims,
            mode: GzHotelMonthMode.select,
            range: _range,
            onRangeChange: (r) => setState(() => _range = r),
            defaultMonth: const GzYm(2026, 12),
            label: _t(context, 'Choose dates', 'اختيار التواريخ'),
            legend: false,
          ),
        ),
      ],
    );
  }
}

class _WeekSection extends StatelessWidget {
  const _WeekSection(this.data);

  final HotelBData data;

  @override
  Widget build(BuildContext context) => _sec(
    context,
    title: _t(context, 'Week view', 'عرض الأسبوع'),
    note: _t(
      context,
      'Seven day rows, one lane per hall. Booked is a solid bar, on hold is hatched with its deadline, blocked is cross-hatched and struck, a request is a gold bead on an open lane.',
      'سبعة صفوف للأيام ولكل قاعة مسار. المحجوز شريط مصمت، والمحجوز مؤقتًا مخطط مع موعد انتهائه، والمغلق متقاطع الخطوط ومشطوب، والطلب خرزة ذهبية على مسار متاح.',
    ),
    specs: [
      _panel(
        context,
        GzHotelWeekView(
          halls: data.halls,
          claims: data.claims,
          date: '2026-12-10',
          label: _t(context, 'Week view', 'عرض الأسبوع'),
        ),
      ),
    ],
  );
}

class _DaySection extends StatelessWidget {
  const _DaySection(this.data);

  final HotelBData data;

  @override
  Widget build(BuildContext context) => _sec(
    context,
    title: _t(context, 'Day view', 'عرض اليوم'),
    note: _t(
      context,
      'Prep, event and teardown per hall; a free hall offers Block.',
      'التجهيز والحدث والفك لكل قاعة؛ والقاعة الشاغرة تتيح الإغلاق.',
    ),
    specs: [
      _panel(
        context,
        GzHotelDayView(
          date: '2026-11-12',
          halls: data.halls,
          claims: data.claims,
          now: '16:00',
        ),
      ),
      _spec(
        context,
        _t(
          context,
          'A day with a hold and a booking',
          'يوم فيه تثبيت مؤقت وحجز',
        ),
        _panel(
          context,
          GzHotelDayView(
            date: '2026-12-10',
            halls: data.halls,
            claims: data.claims,
          ),
        ),
      ),
      _spec(
        context,
        _t(context, 'An open day', 'يوم متاح'),
        _panel(
          context,
          GzHotelDayView(
            date: '2026-12-15',
            halls: data.halls,
            claims: data.claims,
          ),
        ),
      ),
    ],
  );
}

class _BlockSection extends StatelessWidget {
  const _BlockSection(this.data);

  final HotelBData data;

  @override
  Widget build(BuildContext context) => _sec(
    context,
    title: _t(context, 'Block dates sheet', 'ورقة إغلاق التواريخ'),
    note: _t(
      context,
      'Three taps from anywhere: pick the dates, the reason is Booked offline by default, Block is the one gold action.',
      'ثلاث نقرات من أي مكان: اختاروا التواريخ، والسبب الافتراضي حجز خارج غزل، والإغلاق هو الإجراء الذهبي الوحيد.',
    ),
    specs: [
      // The web page is a 390 x 844 viewport with the 34 dp home-indicator inset: the inline sheet takes at most 90% of it (760) and its body scrolls under the pinned footer.
      MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(padding: const EdgeInsets.only(bottom: 34)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 844),
          child: GzBlockDatesSheet(
            halls: data.halls,
            claims: data.claims,
            occasions: data.occasions,
            placement: GzBlockDatesPlacement.inline,
            defaultMonth: const GzYm(2026, 12),
            onRequestClose: () {},
          ),
        ),
      ),
    ],
  );
}
