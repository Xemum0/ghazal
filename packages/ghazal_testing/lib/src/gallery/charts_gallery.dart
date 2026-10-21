// The charts gallery: the Flutter twin of design/src/gallery/charts.tsx (#/gallery/charts). Same 7 sections in the same order (the
// web section ids are the titles of the reference files: sparkline, bar, line, breakdown, funnel, ranked, heat), the same content
// from the same fixtures (packages/contracts/fixtures/hotel.json, venue V01, prototype day Thu 12 Nov 2026) embedded below.
// ghazal_testing may hold string literals (tests and galleries are exempt from the no-text-literal rule).
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_ui/src/charts/charts.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';

import 'gz_gallery.dart';

const List<String> chartsGalleryTitles = ['sparkline', 'bar', 'line', 'breakdown', 'funnel', 'ranked', 'heat'];

List<GzGallerySection> chartsGallerySections() {
  final builders = <WidgetBuilder>[_spark, _bar, _line, _breakdown, _funnel, _ranked, _heat];
  return [for (var i = 0; i < builders.length; i++) GzGallerySection(chartsGalleryTitles[i], builders[i])];
}

// ------------------------------------------------------------------------------------------------------------------ fixtures
const _views = [68, 106, 93, 100, 83, 72, 84, 68, 116, 117, 104, 78, 84, 103, 93, 129, 117, 105, 75, 82, 109, 106, 120, 123, 130, 118, 113, 98, 93, 129];
const _requests = [3, 4, 3, 4, 2, 3, 3, 2, 3, 3, 3, 3, 2, 3, 3, 3, 3, 3, 4, 3, 2, 4, 4, 4, 4, 3, 3, 3, 3, 4];
const _bought = [3, 2, 4, 3, 3, 2, 2, 3, 3, 3, 2, 2, 3, 3, 2, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 3, 3, 3, 2, 4];
const _redeemed = [0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1];
const _conversion = [441, 189, 430, 300, 361, 278, 238, 441, 259, 256, 192, 256, 357, 291, 215, 233, 256, 286, 400, 366, 275, 283, 250, 325, 308, 254, 265, 306, 215, 310];
const _windowFrom = '2026-10-14';
const _windowTo = '2026-11-12';
const _today = '2026-11-12';
// Next 28 days from today, one char per hall (V01 Danah, Majlis): b booked, h held, x blocked, o open.
const _month = ['bb', 'bo', 'bb', 'oo', 'oo', 'oo', 'ob', 'bb', 'oo', 'bo', 'oo', 'xx', 'oo', 'oo', 'bo', 'bb', 'bo', 'oo', 'oo', 'oo', 'oo', 'oo', 'bb', 'oo', 'oo', 'bo', 'oo', 'oo'];
const _vouchersBought = 38;
const _vouchersRedeemed = 9;

String _addDays(String iso, int n) {
  final d = DateTime.parse('${iso}T00:00:00Z').add(Duration(days: n));
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

List<GzHeatDay> _stripDays(int n) => [
      for (var i = 0; i < n; i++)
        GzHeatDay(
          iso: _addDays(_today, i),
          lanes: [
            for (final ch in _month[i].split(''))
              switch (ch) {
                'b' => GzLaneState.booked,
                'h' => GzLaneState.held,
                'x' => GzLaneState.blocked,
                _ => GzLaneState.open,
              },
          ],
          peak: const [4, 5, 6].contains(DateTime.parse('${_addDays(_today, i)}T00:00:00Z').weekday % 7),
        ),
    ];

// ----------------------------------------------------------------------------------------------------------- layout kit
String _t(BuildContext context, String en, String ar) => context.gz.isAr ? ar : en;

Widget _sec(BuildContext context, String title, String? note, List<Widget> children) {
  final c = context.gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      GzSectionHeader(title: title, voice: GzHeaderVoice.partner, draw: GzDraw.off),
      if (note != null) ...[const SizedBox(height: GzSpace.s4), GzText(note, role: GzTextRole.bodyS, color: c.textSecondary)],
      const SizedBox(height: GzSpace.s4),
      for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s6), children[i]],
    ],
  );
}

Widget _spec(BuildContext context, String cap, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [GzText(cap, role: GzTextRole.caption, color: context.gz.colors.textSecondary), const SizedBox(height: GzSpace.s2), child],
    );

Widget _row(List<Widget> children) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: GzSpace.s3), Expanded(child: children[i])]],
    );

Widget _panel(BuildContext context, Widget child) {
  final c = context.gz.colors;
  return Container(
    padding: const EdgeInsets.all(GzSpace.s4),
    decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
    child: child,
  );
}

String _day(BuildContext context, String iso) => context.gzFormat.date(iso, DateStyle.dayMonth);

// ------------------------------------------------------------------------------------------------------------- sections
Widget _spark(BuildContext context) {
  return _sec(
    context,
    _t(context, 'Sparkline', 'مخطط مصغّر'),
    _t(context, 'A trend without numbers, 32 high. Mirrors in Arabic: the oldest value is at the inline-start.', 'اتجاه بلا أرقام بارتفاع 32. ينعكس في العربية: أقدم قيمة عند بداية السطر.'),
    [
      _row([
        _spec(
          context,
          _t(context, 'Views, 30 days', 'المشاهدات، 30 يومًا'),
          GzSparkline(values: _views, label: _t(context, 'Views, last 30 days', 'المشاهدات، آخر 30 يومًا'), description: '${context.gzFormat.integer(_views.first)} → ${context.gzFormat.integer(_views.last)}'),
        ),
        _spec(context, _t(context, 'Revenue', 'الإيرادات'), GzSparkline(values: _bought, label: _t(context, 'Vouchers bought, last 30 days', 'الكوبونات المشتراة، آخر 30 يومًا'))),
      ]),
      _row([
        _spec(
          context,
          _t(context, 'Conversion, accent line, no tint', 'التحويل، خط مميز دون تظليل'),
          GzSparkline(values: _conversion, label: _t(context, 'Conversion, last 30 days', 'التحويل، آخر 30 يومًا'), tone: GzSparkTone.accent, area: false),
        ),
        _spec(context, _t(context, 'Few points', 'نقاط قليلة'), GzSparkline(values: const [2, 3, 3, 5, 4, 6], label: _t(context, 'Bookings, 6 weeks', 'الحجوزات، 6 أسابيع'))),
      ]),
    ],
  );
}

Widget _bar(BuildContext context) {
  final f = context.gzFormat;
  final last14 = _requests.sublist(_requests.length - 14);
  String dateAt(int i) => _addDays(_windowFrom, _requests.length - 14 + i);
  return _sec(
    context,
    _t(context, 'Bar chart', 'مخطط أعمدة'),
    _t(context, 'One bar may be highlighted (the selected day: gold fill, value above). A hatched bar is a forecast: the pattern says so.', 'يمكن إبراز عمود واحد (اليوم المحدد: تعبئة ذهبية وقيمته فوقه). العمود المخطط تقدير: يقولها النمط.'),
    [
      _panel(
        context,
        GzBarChart(
          title: _t(context, 'Requests per day, last 14 days', 'الطلبات يوميًا، آخر 14 يومًا'),
          description: _t(context, 'Between 3 and 4 requests every day.', 'بين 3 و4 طلبات كل يوم.'),
          seriesLabel: _t(context, 'Requests', 'الطلبات'),
          formatAxis: f.integer,
          xLabel: (i) => _day(context, dateAt(i)),
          bars: [for (var i = 0; i < last14.length; i++) GzBar(id: dateAt(i), label: '$i', value: last14[i], highlight: i == last14.length - 1)],
        ),
      ),
      _panel(
        context,
        GzBarChart(
          title: _t(context, 'Vouchers bought, by week', 'الكوبونات المشتراة أسبوعيًا'),
          seriesLabel: _t(context, 'Vouchers', 'كوبونات'),
          hatchLabel: _t(context, 'Expected', 'متوقع'),
          formatAxis: f.integer,
          formatValue: f.integer,
          bars: [
            for (var i = 0; i < 6; i++)
              GzBar(
                id: 'w$i',
                label: f.integer(int.parse(_addDays(_today, const [-21, -14, -7, 0, 7, 14][i]).substring(8))),
                value: const [41, 54, 39, 29, 36, 22][i],
                highlight: i == 3,
                hatch: i > 3,
              ),
          ],
        ),
      ),
    ],
  );
}

Widget _line(BuildContext context) {
  final f = context.gzFormat;
  String pick(int i) => _day(context, _addDays(_windowFrom, i));
  return _sec(
    context,
    _t(context, 'Line chart', 'مخطط خطي'),
    _t(context, 'The area under the main line is a flat tint. A second series is a gold line or a dashed comparison line. First and last dates are labelled; the table twin below shows every value.',
        'المساحة تحت الخط الرئيسي تظليل مسطّح. السلسلة الثانية خط ذهبي أو خط متقطع للمقارنة. يُذكر أول التواريخ وآخرها، والجدول أدناه يعرض كل القيم.'),
    [
      _panel(
        context,
        GzLineChart(
          title: _t(context, 'Vouchers bought per day, 30 days', 'الكوبونات المشتراة يوميًا، 30 يومًا'),
          formatAxis: f.integer,
          formatValue: f.integer,
          xLabel: pick,
          series: [GzLineSeries(id: 'rev', label: _t(context, 'Vouchers bought', 'الكوبونات المشتراة'), values: _bought, area: true)],
        ),
      ),
      _panel(
        context,
        GzLineChart(
          title: _t(context, 'Requests and vouchers redeemed per day', 'الطلبات والكوبونات المستخدمة يوميًا'),
          formatAxis: f.integer,
          xLabel: pick,
          series: [
            GzLineSeries(id: 'req', label: _t(context, 'Requests', 'الطلبات'), values: _requests, area: true),
            GzLineSeries(id: 'bk', label: _t(context, 'Redeemed', 'مستخدمة'), values: _redeemed, tone: GzLineTone.accent),
          ],
        ),
      ),
      _panel(
        context,
        GzLineChart(
          title: _t(context, 'Views, last 15 days against the 15 before', 'المشاهدات، آخر 15 يومًا مقابل الـ15 قبلها'),
          formatAxis: f.integer,
          xLabel: (i) => _day(context, _addDays(_windowTo, i - 14)),
          showTable: true,
          series: [
            GzLineSeries(id: 'now', label: _t(context, 'Last 15 days', 'آخر 15 يومًا'), values: _views.sublist(15), area: true),
            GzLineSeries(id: 'before', label: _t(context, 'Previous 15 days', 'الـ15 يومًا السابقة'), values: _views.sublist(0, 15), dashed: true),
          ],
        ),
      ),
    ],
  );
}

({int booked, int held, int blocked, int open, int total}) _tally(List<GzHeatDay> month) {
  int n(GzLaneState s) => month.fold(0, (a, d) => a + d.lanes.where((l) => l == s).length);
  final total = month.length * month.first.lanes.length;
  return (booked: n(GzLaneState.booked), held: n(GzLaneState.held), blocked: n(GzLaneState.blocked), open: total - n(GzLaneState.booked) - n(GzLaneState.held) - n(GzLaneState.blocked), total: total);
}

Widget _breakdown(BuildContext context) {
  final f = context.gzFormat;
  final t = _tally(_stripDays(28));
  return _sec(
    context,
    _t(context, 'Breakdown', 'التوزيع'),
    _t(context, 'A stacked bar by default; a donut for one hero share. Parts differ by pattern and label; shares are printed.', 'شريط مكدّس افتراضيًا، وحلقة لحصة واحدة بارزة. تختلف الأجزاء بالنمط والتسمية وتُطبع الحصص.'),
    [
      _panel(
        context,
        GzBreakdownChart(
          title: _t(context, 'Hall-nights, next 28 days', 'ليالي القاعات، 28 يومًا القادمة'),
          formatValue: f.integer,
          formatShare: (n) => f.percent(n),
          segments: [
            GzSegment(id: 'booked', label: _t(context, 'Booked', 'محجوز'), value: t.booked, tone: GzSegmentTone.strong),
            GzSegment(id: 'held', label: _t(context, 'On hold', 'محجوز مؤقتًا'), value: t.held, tone: GzSegmentTone.gold, pattern: GzFillPattern.hatch),
            GzSegment(id: 'blocked', label: _t(context, 'Blocked', 'مغلق'), value: t.blocked, tone: GzSegmentTone.quiet, pattern: GzFillPattern.cross),
            GzSegment(id: 'open', label: _t(context, 'Open', 'متاح'), value: t.open, tone: GzSegmentTone.open),
          ],
        ),
      ),
      _panel(
        context,
        GzBreakdownChart(
          variant: GzBreakdownVariant.donut,
          title: _t(context, 'Vouchers this month', 'كوبونات هذا الشهر'),
          formatValue: f.integer,
          formatShare: (n) => f.percent(n),
          center: GzDonutCenter(value: f.percent((_vouchersRedeemed / _vouchersBought * 100).round()), caption: _t(context, 'redeemed', 'مستخدمة')),
          segments: [
            GzSegment(id: 'recv', label: _t(context, 'Redeemed', 'مستخدمة'), value: _vouchersRedeemed, tone: GzSegmentTone.strong),
            GzSegment(id: 'due', label: _t(context, 'Not yet redeemed', 'لم تُستخدم بعد'), value: _vouchersBought - _vouchersRedeemed, tone: GzSegmentTone.gold, pattern: GzFillPattern.hatch),
          ],
        ),
      ),
    ],
  );
}

Widget _funnel(BuildContext context) {
  final f = context.gzFormat;
  final ar = context.gz.isAr;
  return _sec(
    context,
    _t(context, 'Funnel', 'مسار التحويل'),
    _t(context, 'Bars grow from the inline-start in proportion to the first stage; the outcome is the one gold bar.', 'تنمو الأعمدة من بداية السطر نسبةً إلى المرحلة الأولى، والنتيجة هي العمود الذهبي الوحيد.'),
    [
      _panel(
        context,
        GzFunnelBars(
          title: _t(context, 'From views to redeemed vouchers', 'من المشاهدات إلى الكوبونات المستخدمة'),
          valueLabel: _t(context, 'Count', 'العدد'),
          formatValue: f.integer,
          formatStep: (p, prev) => ar ? '${f.percent(p, maxFraction: 1)} من $prev' : '${f.percent(p, maxFraction: 1)} of ${prev.toLowerCase()}',
          stages: [
            GzFunnelStage(id: 'views', label: _t(context, 'Views', 'المشاهدات'), value: 1296),
            GzFunnelStage(id: 'clicks', label: _t(context, 'Clicks', 'النقرات'), value: 238),
            GzFunnelStage(id: 'requests', label: _t(context, 'Requests', 'الطلبات'), value: 41),
            GzFunnelStage(id: 'confirmed', label: _t(context, 'Confirmed', 'مؤكدة'), value: 12),
            GzFunnelStage(id: 'redeemed', label: _t(context, 'Redeemed', 'مستخدمة'), value: 9),
          ],
        ),
      ),
    ],
  );
}

Widget _ranked(BuildContext context) {
  final f = context.gzFormat;
  const names = [
    ('V01-ladies-weekend', 'Ladies’ Reception, Weekend', 'الحفل النسائي · نهاية الأسبوع', 5),
    ('V01-ladies-weekday', 'Ladies’ Reception, Weekday', 'الحفل النسائي · أيام الأسبوع', 3),
    ('V01-men-reception', 'Men’s Reception', 'الحفل الرجالي', 2),
    ('V01-ladies-signature', 'Ladies’ Signature Evening', 'الحفل النسائي المتكامل', 1),
    ('V01-full-night', 'Full-Night Package', 'ليلة الزفاف المتكاملة', 1),
  ];
  return _sec(context, _t(context, 'Top packages', 'أكثر الباقات حجزًا'), null, [
    _panel(
      context,
      GzRankedBars(
        title: _t(context, 'Confirmed bookings by package', 'الحجوزات المؤكدة حسب الباقة'),
        valueLabel: _t(context, 'Confirmed', 'مؤكدة'),
        formatValue: f.integer,
        items: [for (final n in names) GzRankedItem(id: n.$1, label: _t(context, n.$2, n.$3), value: n.$4)],
      ),
    ),
  ]);
}

Widget _heat(BuildContext context) {
  final f = context.gzFormat;
  final month = _stripDays(28);
  final t = _tally(month);
  final halls = [_t(context, 'Danah Ballroom', 'قاعة الدانة'), _t(context, 'Majlis Hall', 'قاعة المجلس')];
  return _sec(
    context,
    _t(context, 'Occupancy strip', 'شريط الإشغال'),
    _t(context, 'One row per hall. Filled = booked, hatched = on hold, crossed = blocked, outlined = open. Thu to Sat sit on the peak wash.',
        'صف لكل قاعة. المملوء محجوز، والمخطط محجوز مؤقتًا، والمتقاطع مغلق، والمحدد بإطار متاح. الخميس إلى السبت على خلفية الذروة.'),
    [
      _panel(
        context,
        GzHeatStrip(
          title: _t(context, 'Occupancy, next 28 days', 'الإشغال، 28 يومًا القادمة'),
          laneLabels: halls,
          dayLabel: (iso) => _day(context, iso),
          days: month,
          legend: GzHeatLegend(
            booked: _t(context, 'Booked', 'محجوز'),
            held: _t(context, 'On hold', 'محجوز مؤقتًا'),
            open: _t(context, 'Open', 'متاح'),
            peak: _t(context, 'Thu to Sat', 'الخميس إلى السبت'),
            blocked: _t(context, 'Blocked', 'مغلق'),
          ),
          counts: GzHeatCounts(booked: f.integer(t.booked), held: f.integer(t.held), open: f.integer(t.open), blocked: f.integer(t.blocked)),
        ),
      ),
      _panel(
        context,
        GzHeatStrip(
          title: _t(context, 'Occupancy, next 14 days', 'الإشغال، 14 يومًا القادمة'),
          laneLabels: halls,
          dayLabel: (iso) => _day(context, iso),
          days: month.sublist(0, 14),
          laneHeight: 20,
          legend: GzHeatLegend(
            booked: _t(context, 'Booked', 'محجوز'),
            held: _t(context, 'On hold', 'محجوز مؤقتًا'),
            open: _t(context, 'Open', 'متاح'),
            peak: _t(context, 'Thu to Sat', 'الخميس إلى السبت'),
          ),
        ),
      ),
    ],
  );
}
