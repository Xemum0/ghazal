// Gallery sections: Today and analytics (RequestRow, DayTimeline, WeekStrip, KpiTile, VoucherActivityCard, OccupancyMeter), driven by the
// partner fixtures: the pending queue, today's claims and the 30-day analytics series (vouchers, ADR 0033: no revenue or finance block).
import { analytics, calendarClaims, engine, getHall, getVenue, meta, needsYou, PROTOTYPE_NOW, PROTOTYPE_TODAY, requestsFor } from '../../../mock'
import { useFormat } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { Figures } from '../internal/bits'
import { DayTimeline, type TimelineEvent } from '../DayTimeline'
import { KpiTile } from '../KpiTile'
import { OccupancyMeter } from '../OccupancyMeter'
import { RequestRow } from '../RequestRow'
import { VoucherActivityCard } from '../VoucherActivityCard'
import { WeekStrip, type StripDay, type StripMark } from '../WeekStrip'
import { L, Row, Section, Spec, Stage } from './kit'

export function RequestRowSection() {
  const { lang } = useLang()
  const requests = requestsFor(meta.hotelVenueId)
  const queue = needsYou(meta.hotelVenueId)
  const others = queue.filter(q => q.item.type !== 'request').slice(0, 4)
  return (
    <Section
      id="row"
      title={L(lang, 'Queue row', 'صف قائمة الانتظار')}
      note={L(lang, 'The compact Needs-you row, 80 high: who, which date, what it is worth and how long is left. Time left is text with an icon in the SLA tone.', 'صف بانتظاركم المختصر بارتفاع 80: من ومتى وكم قيمته وكم تبقى. الوقت المتبقي نص مع أيقونة بلون مستوى المهلة.')}
    >
      <Spec cap={L(lang, 'Requests: danger, neutral, new', 'طلبات: حرج، عادي، جديد')}>
        <Stage kind="panel">
          <div className="hg-list">
            {requests.slice(0, 3).map((r, i) => (
              <RequestRow key={r.booking.id} request={r} isNew={i === 2} flush last={i === 2} />
            ))}
          </div>
        </Stage>
      </Spec>
      <Spec cap={L(lang, 'Other Needs-you items: message, balance, review, calendar check', 'عناصر أخرى بانتظاركم: رسالة، مبلغ متبقٍّ، تقييم، مراجعة التقويم')}>
        <Stage kind="panel">
          <div className="hg-list">
            {others.map(({ item, sla }, i) => (
              <RequestRow key={item.id} item={item} sla={sla} flush last={i === others.length - 1} />
            ))}
          </div>
        </Stage>
      </Spec>
    </Section>
  )
}

export function TimelineSection() {
  const { lang } = useLang()
  const f = useFormat()
  const venue = getVenue(meta.hotelVenueId)
  const minusMinutes = (hhmm: string, mins: number) => {
    const [h, m] = hhmm.split(':').map(Number) as [number, number]
    const t = ((h * 60 + m - mins) % 1440 + 1440) % 1440
    return `${String(Math.floor(t / 60)).padStart(2, '0')}:${String(t % 60).padStart(2, '0')}`
  }
  const today = calendarClaims.filter(c => c.date === PROTOTYPE_TODAY && c.venueId === meta.hotelVenueId && c.kind === 'booking')
  const events: TimelineEvent[] = today.flatMap(c => {
    const found = getHall(c.hallId)
    const session = found?.hall.sessions[0]
    const hall = found ? found.hall.name[lang] : ''
    const start = c.start ?? session?.start ?? '21:00'
    const end = c.end ?? session?.end ?? '02:00'
    const before = session?.bufferBeforeMin ?? 120
    const after = session?.bufferAfterMin ?? 60
    const crosses = end < start
    return [
      { id: `${c.id}-setup`, time: minusMinutes(start, before), title: L(lang, 'Setup', 'التجهيز'), meta: hall, kind: 'prep' as const },
      {
        id: c.id,
        time: start,
        title: c.clientName ?? '',
        userTitle: true,
        kind: 'event' as const,
        status: 'confirmed' as const,
        meta: <Figures text={`${hall} · ${f.guests(c.guests ?? 0)}`} />,
      },
      { id: `${c.id}-down`, time: minusMinutes(end, -after), nextDay: crosses || end >= start, title: L(lang, 'Teardown', 'الفك والتنظيف'), meta: hall, kind: 'prep' as const },
    ]
  })
  const clock = PROTOTYPE_NOW.slice(11, 16)
  return (
    <Section
      id="timeline"
      title={L(lang, 'Day timeline', 'خط اليوم')}
      note={L(lang, 'The vertical thread of the day. Done knots are gold, the ringed knot is now, open knots are hollow; the line is gold up to now. Setup and teardown are quiet.', 'الخيط العمودي لليوم. العُقد المنجزة ذهبية، والعقدة المحاطة بحلقة هي الآن، والمفتوحة مجوفة، والخط ذهبي حتى الآن. التجهيز والفك بلون هادئ.')}
    >
      <Stage kind="panel">
        <DayTimeline date={PROTOTYPE_TODAY} events={events} now={clock} />
      </Stage>
      <Spec cap={L(lang, 'A day with nothing scheduled', 'يوم بلا مواعيد')}>
        <Stage kind="panel">
          <DayTimeline date={PROTOTYPE_TODAY} events={[]} />
        </Stage>
      </Spec>
      <p className="gz-t-caption hg-cap">{venue ? venue.name[lang] : ''}</p>
    </Section>
  )
}

export function StripSection() {
  const { lang } = useLang()
  const f = useFormat()
  const venue = getVenue(meta.hotelVenueId)
  const halls = venue?.halls ?? []
  const make = (n: number): StripDay[] =>
    Array.from({ length: n }, (_, i) => {
      const iso = engine.addDays(PROTOTYPE_TODAY, i)
      const marks: StripMark[] = halls.map(h => {
        const c = calendarClaims.find(x => x.hallId === h.id && x.date === iso)
        return !c ? 'open' : c.kind === 'booking' || c.kind === 'block' ? 'confirmed' : 'pending'
      })
      return { iso, marks }
    })
  return (
    <Section
      id="strip"
      title={L(lang, '7-day strip', 'شريط الأيام السبعة')}
      note={L(lang, 'One mark per hall: confirmed solid ink, pending or on hold gold, open an outline. Today has the ink outline; the selected day is the one gold fill.', 'علامة لكل قاعة: المؤكد حبر مصمت، وبانتظار الرد أو المحجوز مؤقتًا ذهبي، والمتاح إطار. لليوم إطار حبري، واليوم المحدد هو التعبئة الذهبية الوحيدة.')}
    >
      <Stage kind="panel">
        <WeekStrip label={L(lang, 'Next 7 days', 'الأيام السبعة القادمة')} days={make(7)} selected={engine.addDays(PROTOTYPE_TODAY, 2)} />
      </Stage>
      <Spec cap={L(lang, '14 days, nothing selected, with the open-weekends footer', '14 يومًا دون تحديد مع سطر عطلات الأسبوع المتاحة')}>
        <Stage kind="panel">
          <WeekStrip
            label={L(lang, 'Next 14 days', 'الأربعة عشر يومًا القادمة')}
            days={make(14)}
            footer={
              <p className="gz-t-caption hg-cap">
                <Figures text={L(lang, `${f.integer(9)} open weekend dates in the next 60 days`, `${f.integer(9)} تواريخ متاحة في نهاية الأسبوع خلال 60 يومًا`)} />
              </p>
            }
          />
        </Stage>
      </Spec>
    </Section>
  )
}

export function AnalyticsSection() {
  const { lang } = useLang()
  const f = useFormat()
  const series = (id: string) => analytics.series.find(s => s.id === id)?.points ?? []
  const views = series('views')
  const revenue = series('vouchers_bought')
  const redeemedSeries = series('vouchers_redeemed')
  const conversion = series('conversion')
  const requests = series('requests')
  const claims = calendarClaims.filter(c => c.venueId === meta.hotelVenueId)
  const halls = getVenue(meta.hotelVenueId)?.halls ?? []
  const nights = 28
  let booked = 0
  let held = 0
  let blocked = 0
  for (let i = 0; i < nights; i += 1) {
    const iso = engine.addDays(PROTOTYPE_TODAY, i)
    for (const h of halls) {
      const c = claims.find(x => x.hallId === h.id && x.date === iso)
      if (c?.kind === 'booking') booked += 1
      else if (c?.kind === 'hold') held += 1
      else if (c?.kind === 'block') blocked += 1
    }
  }
  return (
    <Section
      id="kpi"
      title={L(lang, 'KPI tiles and money', 'المؤشرات والمبالغ')}
      note={L(lang, 'Figures in Cairo, never serif; the delta carries an icon, a sign and a word; sparklines mirror in Arabic.', 'الأرقام بخط القاهرة وليس بخط ذي زوائد؛ ويحمل التغيّر أيقونة وإشارة وكلمة؛ وتنعكس المخططات المصغّرة في العربية.')}
    >
      <Row wrap={false}>
        <KpiTile
          label={L(lang, 'Views', 'المشاهدات')}
          value={{ kind: 'count', value: analytics.tiles.views.value }}
          delta={analytics.tiles.views.deltaPct}
          deltaLabel={L(lang, 'vs last month', 'مقارنة بالشهر الماضي')}
          trend={{ values: views.map(p => p.value), label: L(lang, 'Views, last 30 days', 'المشاهدات، آخر 30 يومًا') }}
        />
        <KpiTile
          label={L(lang, 'Requests', 'الطلبات')}
          value={{ kind: 'count', value: analytics.tiles.requests }}
          delta={-6}
          deltaLabel={L(lang, 'vs last month', 'مقارنة بالشهر الماضي')}
          trend={{ values: requests.map(p => p.value), label: L(lang, 'Requests, last 30 days', 'الطلبات، آخر 30 يومًا') }}
        />
      </Row>
      <Row wrap={false}>
        <KpiTile
          label={L(lang, 'Conversion', 'التحويل')}
          value={{ kind: 'percent', value: analytics.tiles.conversionBps / 100 }}
          delta={0}
          deltaLabel={L(lang, 'unchanged', 'دون تغيير')}
          trend={{ values: conversion.map(p => p.value), label: L(lang, 'Conversion, last 30 days', 'التحويل، آخر 30 يومًا') }}
        />
        <KpiTile label={L(lang, 'Confirmed', 'مؤكدة')} value={{ kind: 'count', value: analytics.tiles.confirmed }} />
      </Row>
      <KpiTile
        hero
        label={L(lang, 'Vouchers redeemed this month', 'كوبونات تم استخدامها هذا الشهر')}
        value={{ kind: 'count', value: analytics.tiles.vouchersRedeemed }}
        sub={<Figures text={L(lang, `${f.integer(analytics.tiles.vouchersBought)} bought for this venue`, `${f.integer(analytics.tiles.vouchersBought)} كوبونًا مشترى لهذا المكان`)} />}
        delta={12}
        deltaLabel={L(lang, 'vs last month', 'مقارنة بالشهر الماضي')}
        trend={{ values: redeemedSeries.map(p => p.value), label: L(lang, 'Vouchers redeemed, last 30 days', 'الكوبونات المستخدمة، آخر 30 يومًا') }}
      />
      <VoucherActivityCard
        title={L(lang, 'Vouchers this month', 'كوبونات هذا الشهر')}
        period={`${f.date(analytics.range.from, 'dayMonth')} – ${f.date(analytics.range.to, 'dayMonth')}`}
        bought={analytics.tiles.vouchersBought}
        delta={12}
        daily={revenue}
        requests={analytics.tiles.requests}
        awaitingClient={Math.max(0, analytics.tiles.approved - analytics.tiles.confirmed)}
        redeemed={analytics.tiles.vouchersRedeemed}
      />
      <OccupancyMeter title={L(lang, 'Occupancy, next 28 days', 'الإشغال، 28 يومًا القادمة')} booked={booked} held={held} blocked={blocked} open={nights * halls.length - booked - held - blocked} />
    </Section>
  )
}
