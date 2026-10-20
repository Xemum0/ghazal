// Charts gallery: Sparkline, BarChart, LineChart, BreakdownChart (stacked bar and donut), FunnelBars, RankedBars, HeatStrip, driven by
// the partner fixtures (analytics, calendar claims). Rendered at #/gallery/charts?lang=en|ar. Optional `&only=line,heat`.
// Everything is drawn from tokens; time axes run in reading direction (right to left in Arabic) while digits stay Western and LTR.
import { analytics, calendarClaims, engine, getPackage, getVenue, meta, PROTOTYPE_TODAY } from '../mock'
import { useFormat } from '../i18n'
import { useLang } from '../shell/lang'
import { BarChart, BreakdownChart, FunnelBars, HeatStrip, LineChart, RankedBars, Sparkline, type HeatDay, type LaneState } from '../system/charts'
import { L, Page, Row, Section, Spec, Stage } from '../system/domain-hotel/gallery/kit'

export default function ChartsGallery() {
  const { lang } = useLang()
  const f = useFormat()
  const venue = getVenue(meta.hotelVenueId)
  const series = (id: string) => analytics.series.find(s => s.id === id)
  const views = series('views')?.points ?? []
  const requests = series('requests')?.points ?? []
  const bookings = series('vouchers_redeemed')?.points ?? []
  const revenue = series('vouchers_bought')?.points ?? []
  const conversion = series('conversion')?.points ?? []
  const pick = (id: string, pts: { date: string; value: number }[]) => (i: number) => f.date(pts[i]?.date ?? analytics.window.from, 'dayMonth') + (id ? '' : '')

  // Next 28 days of occupancy, one lane per hall.
  const halls = venue?.halls ?? []
  const stripDays = (n: number): HeatDay[] =>
    Array.from({ length: n }, (_, i) => {
      const iso = engine.addDays(PROTOTYPE_TODAY, i)
      const lanes: LaneState[] = halls.map(h => {
        const c = calendarClaims.find(x => x.hallId === h.id && x.date === iso)
        return !c ? 'open' : c.kind === 'hold' ? 'held' : c.kind === 'block' ? 'blocked' : c.kind === 'booking' ? 'booked' : 'open'
      })
      return { iso, lanes, peak: [4, 5, 6].includes(engine.weekdayOf(iso)) }
    })
  const month = stripDays(28)
  const tally = (state: LaneState) => month.reduce((a, d) => a + d.lanes.filter(l => l === state).length, 0)
  const lanesTotal = month.length * halls.length
  const dayShort = (iso: string) => f.date(iso, 'dayMonth')

  const last14 = requests.slice(-14)
  const highlightAt = last14.length - 1

  return (
    <Page
      eyebrow={L(lang, 'Design system', 'نظام التصميم')}
      title={L(lang, 'Charts', 'المخططات')}
      lede={L(
        lang,
        'Seven charts drawn from tokens, no library. Time runs in reading direction, so Arabic reads right to left; the value axis never flips; digits stay Western. Every chart has a title, a description and a table twin, and parts are told apart by pattern and label, never by colour alone.',
        'سبعة مخططات مرسومة من الرموز دون مكتبة. يجري الزمن باتجاه القراءة فيُقرأ المخطط العربي من اليمين إلى اليسار، ولا ينقلب محور القيم، وتبقى الأرقام غربية. لكل مخطط عنوان ووصف وجدول مقابل، وتتمايز الأجزاء بالنمط والتسمية لا باللون وحده.',
      )}
    >
      <Section id="sparkline" title={L(lang, 'Sparkline', 'مخطط مصغّر')} note={L(lang, 'A trend without numbers, 32 high. Mirrors in Arabic: the oldest value is at the inline-start.', 'اتجاه بلا أرقام بارتفاع 32. ينعكس في العربية: أقدم قيمة عند بداية السطر.')}>
        <Row wrap={false}>
          <Spec cap={L(lang, 'Views, 30 days', 'المشاهدات، 30 يومًا')}>
            <Sparkline values={views.map(p => p.value)} label={L(lang, 'Views, last 30 days', 'المشاهدات، آخر 30 يومًا')} description={`${f.integer(views[0]?.value ?? 0)} → ${f.integer(views.at(-1)?.value ?? 0)}`} />
          </Spec>
          <Spec cap={L(lang, 'Revenue', 'الإيرادات')}>
            <Sparkline values={revenue.map(p => p.value)} label={L(lang, 'Vouchers bought, last 30 days', 'الكوبونات المشتراة، آخر 30 يومًا')} />
          </Spec>
        </Row>
        <Row wrap={false}>
          <Spec cap={L(lang, 'Conversion, accent line, no tint', 'التحويل، خط مميز دون تظليل')}>
            <Sparkline values={conversion.map(p => p.value)} label={L(lang, 'Conversion, last 30 days', 'التحويل، آخر 30 يومًا')} tone="accent" area={false} />
          </Spec>
          <Spec cap={L(lang, 'Few points', 'نقاط قليلة')}>
            <Sparkline values={[2, 3, 3, 5, 4, 6]} label={L(lang, 'Bookings, 6 weeks', 'الحجوزات، 6 أسابيع')} />
          </Spec>
        </Row>
      </Section>

      <Section id="bar" title={L(lang, 'Bar chart', 'مخطط أعمدة')} note={L(lang, 'One bar may be highlighted (the selected day: gold fill, value above). A hatched bar is a forecast: the pattern says so.', 'يمكن إبراز عمود واحد (اليوم المحدد: تعبئة ذهبية وقيمته فوقه). العمود المخطط تقدير: يقولها النمط.')}>
        <Stage kind="panel">
          <BarChart
            title={L(lang, 'Requests per day, last 14 days', 'الطلبات يوميًا، آخر 14 يومًا')}
            description={L(lang, 'Between 3 and 4 requests every day.', 'بين 3 و4 طلبات كل يوم.')}
            seriesLabel={L(lang, 'Requests', 'الطلبات')}
            formatAxis={n => f.integer(n)}
            xLabel={i => f.date(last14[i]?.date ?? PROTOTYPE_TODAY, 'dayMonth')}
            bars={last14.map((p, i) => ({ id: p.date, label: String(i), value: p.value, highlight: i === highlightAt }))}
          />
        </Stage>
        <Stage kind="panel">
          <BarChart
            title={L(lang, 'Vouchers bought, by week', 'الكوبونات المشتراة أسبوعيًا')}
            seriesLabel={L(lang, 'Vouchers', 'كوبونات')}
            hatchLabel={L(lang, 'Expected', 'متوقع')}
            formatAxis={n => f.integer(n)}
            formatValue={n => f.integer(n)}
            bars={[-21, -14, -7, 0, 7, 14].map((off, i) => ({
              id: `w${i}`,
              label: f.integer(Number(engine.addDays(PROTOTYPE_TODAY, off).slice(8))),
              value: [41, 54, 39, 29, 36, 22][i] as number,
              highlight: off === 0,
              pattern: off > 0 ? ('hatch' as const) : ('solid' as const),
            }))}
          />
        </Stage>
      </Section>

      <Section id="line" title={L(lang, 'Line chart', 'مخطط خطي')} note={L(lang, 'The area under the main line is a flat tint. A second series is a gold line or a dashed comparison line. First and last dates are labelled; the table twin below shows every value.', 'المساحة تحت الخط الرئيسي تظليل مسطّح. السلسلة الثانية خط ذهبي أو خط متقطع للمقارنة. يُذكر أول التواريخ وآخرها، والجدول أدناه يعرض كل القيم.')}>
        <Stage kind="panel">
          <LineChart
            title={L(lang, 'Vouchers bought per day, 30 days', 'الكوبونات المشتراة يوميًا، 30 يومًا')}
            formatAxis={n => f.integer(n)}
            formatValue={n => f.integer(n)}
            xLabel={pick('r', revenue)}
            series={[{ id: 'rev', label: L(lang, 'Vouchers bought', 'الكوبونات المشتراة'), values: revenue.map(p => p.value), area: true }]}
          />
        </Stage>
        <Stage kind="panel">
          <LineChart
            title={L(lang, 'Requests and vouchers redeemed per day', 'الطلبات والكوبونات المستخدمة يوميًا')}
            formatAxis={n => f.integer(n)}
            xLabel={pick('q', requests)}
            series={[
              { id: 'req', label: L(lang, 'Requests', 'الطلبات'), values: requests.map(p => p.value), area: true },
              { id: 'bk', label: L(lang, 'Redeemed', 'مستخدمة'), values: bookings.map(p => p.value), tone: 'accent' },
            ]}
          />
        </Stage>
        <Stage kind="panel">
          <LineChart
            title={L(lang, 'Views, last 15 days against the 15 before', 'المشاهدات، آخر 15 يومًا مقابل الـ15 قبلها')}
            formatAxis={n => f.integer(n)}
            xLabel={i => f.date(engine.addDays(analytics.window.to, i - 14), 'dayMonth')}
            showTable
            series={[
              { id: 'now', label: L(lang, 'Last 15 days', 'آخر 15 يومًا'), values: views.slice(-15).map(p => p.value), area: true },
              { id: 'before', label: L(lang, 'Previous 15 days', 'الـ15 يومًا السابقة'), values: views.slice(0, 15).map(p => p.value), dashed: true },
            ]}
          />
        </Stage>
      </Section>

      <Section id="breakdown" title={L(lang, 'Breakdown', 'التوزيع')} note={L(lang, 'A stacked bar by default; a donut for one hero share. Parts differ by pattern and label; shares are printed.', 'شريط مكدّس افتراضيًا، وحلقة لحصة واحدة بارزة. تختلف الأجزاء بالنمط والتسمية وتُطبع الحصص.')}>
        <Stage kind="panel">
          <BreakdownChart
            title={L(lang, 'Hall-nights, next 28 days', 'ليالي القاعات، 28 يومًا القادمة')}
            formatValue={n => f.integer(n)}
            formatShare={n => f.percent(n)}
            segments={[
              { id: 'booked', label: L(lang, 'Booked', 'محجوز'), value: tally('booked'), tone: 'strong' },
              { id: 'held', label: L(lang, 'On hold', 'محجوز مؤقتًا'), value: tally('held'), tone: 'gold', pattern: 'hatch' },
              { id: 'blocked', label: L(lang, 'Blocked', 'مغلق'), value: tally('blocked'), tone: 'quiet', pattern: 'cross' },
              { id: 'open', label: L(lang, 'Open', 'متاح'), value: lanesTotal - tally('booked') - tally('held') - tally('blocked'), tone: 'open' },
            ]}
          />
        </Stage>
        <Stage kind="panel">
          <BreakdownChart
            variant="donut"
            title={L(lang, 'Vouchers this month', 'كوبونات هذا الشهر')}
            formatValue={n => f.integer(n)}
            formatShare={n => f.percent(n)}
            center={{ value: f.percent(Math.round((analytics.tiles.vouchersRedeemed / Math.max(1, analytics.tiles.vouchersBought)) * 100)), caption: L(lang, 'redeemed', 'مستخدمة') }}
            segments={[
              { id: 'recv', label: L(lang, 'Redeemed', 'مستخدمة'), value: analytics.tiles.vouchersRedeemed, tone: 'strong' },
              { id: 'due', label: L(lang, 'Not yet redeemed', 'لم تُستخدم بعد'), value: Math.max(0, analytics.tiles.vouchersBought - analytics.tiles.vouchersRedeemed), tone: 'gold', pattern: 'hatch' },
            ]}
          />
        </Stage>
      </Section>

      <Section id="funnel" title={L(lang, 'Funnel', 'مسار التحويل')} note={L(lang, 'Bars grow from the inline-start in proportion to the first stage; the outcome is the one gold bar.', 'تنمو الأعمدة من بداية السطر نسبةً إلى المرحلة الأولى، والنتيجة هي العمود الذهبي الوحيد.')}>
        <Stage kind="panel">
          <FunnelBars
            title={L(lang, 'From views to redeemed vouchers', 'من المشاهدات إلى الكوبونات المستخدمة')}
            valueLabel={L(lang, 'Count', 'العدد')}
            formatValue={n => f.integer(n)}
            formatStep={(p, prev) => L(lang, `${f.percent(p, { maxFraction: 1 })} of ${prev.toLowerCase()}`, `${f.percent(p, { maxFraction: 1 })} من ${prev}`)}
            stages={[
              { id: 'views', label: L(lang, 'Views', 'المشاهدات'), value: analytics.funnel.views },
              { id: 'clicks', label: L(lang, 'Clicks', 'النقرات'), value: analytics.funnel.clicks },
              { id: 'requests', label: L(lang, 'Requests', 'الطلبات'), value: analytics.funnel.requests },
              { id: 'confirmed', label: L(lang, 'Confirmed', 'مؤكدة'), value: analytics.funnel.confirmed },
              { id: 'redeemed', label: L(lang, 'Redeemed', 'مستخدمة'), value: analytics.funnel.redeemed },
            ]}
          />
        </Stage>
      </Section>

      <Section id="ranked" title={L(lang, 'Top packages', 'أكثر الباقات حجزًا')}>
        <Stage kind="panel">
          <RankedBars
            title={L(lang, 'Confirmed bookings by package', 'الحجوزات المؤكدة حسب الباقة')}
            valueLabel={L(lang, 'Confirmed', 'مؤكدة')}
            formatValue={n => f.integer(n)}
            items={analytics.topPackages.map(t => ({ id: t.packageId, label: getPackage(t.packageId)?.name[lang] ?? t.packageId, value: t.confirmed }))}
          />
        </Stage>
      </Section>

      <Section id="heat" title={L(lang, 'Occupancy strip', 'شريط الإشغال')} note={L(lang, 'One row per hall. Filled = booked, hatched = on hold, crossed = blocked, outlined = open. Thu to Sat sit on the peak wash.', 'صف لكل قاعة. المملوء محجوز، والمخطط محجوز مؤقتًا، والمتقاطع مغلق، والمحدد بإطار متاح. الخميس إلى السبت على خلفية الذروة.')}>
        <Stage kind="panel">
          <HeatStrip
            title={L(lang, 'Occupancy, next 28 days', 'الإشغال، 28 يومًا القادمة')}
            laneLabels={halls.map(h => h.name[lang])}
            dayLabel={dayShort}
            days={month}
            legend={{ booked: L(lang, 'Booked', 'محجوز'), held: L(lang, 'On hold', 'محجوز مؤقتًا'), open: L(lang, 'Open', 'متاح'), peak: L(lang, 'Thu to Sat', 'الخميس إلى السبت'), blocked: L(lang, 'Blocked', 'مغلق') }}
            counts={{ booked: f.integer(tally('booked')), held: f.integer(tally('held')), open: f.integer(lanesTotal - tally('booked') - tally('held') - tally('blocked')), blocked: f.integer(tally('blocked')) }}
          />
        </Stage>
        <Stage kind="panel">
          <HeatStrip
            title={L(lang, 'Occupancy, next 14 days', 'الإشغال، 14 يومًا القادمة')}
            laneLabels={halls.map(h => h.name[lang])}
            dayLabel={dayShort}
            days={month.slice(0, 14)}
            laneHeight={20}
            legend={{ booked: L(lang, 'Booked', 'محجوز'), held: L(lang, 'On hold', 'محجوز مؤقتًا'), open: L(lang, 'Open', 'متاح'), peak: L(lang, 'Thu to Sat', 'الخميس إلى السبت') }}
          />
        </Stage>
      </Section>
    </Page>
  )
}
