// Gallery sections: the hotel calendar (month grid with its agenda, the select mode, week view with hall lanes, day view, the block-dates
// sheet and the drag affordance), driven by the 206 calendar claims of Aurelia Gulf Hotel (two halls: Danah Ballroom, Majlis Hall).
import { useState } from 'react'
import { calendarClaims, getVenue, meta, PROTOTYPE_NOW, PROTOTYPE_TODAY } from '../../../mock'
import { useLang } from '../../../shell/lang'
import { BlockDatesSheet } from '../calendar/BlockDatesSheet'
import { DayAgenda } from '../calendar/DayAgenda'
import { DragAffordance } from '../calendar/DragAffordance'
import { HotelDayView } from '../calendar/HotelDayView'
import { HotelMonthGrid } from '../calendar/HotelMonthGrid'
import { HotelWeekView } from '../calendar/HotelWeekView'
import type { DateSpan } from '../calendar/model'
import { L, Section, Spec, Stage } from './kit'

const useVenue = () => {
  const venue = getVenue(meta.hotelVenueId)
  const claims = calendarClaims.filter(c => c.venueId === meta.hotelVenueId)
  return { halls: venue?.halls ?? [], claims }
}

export function MonthSection() {
  const { lang } = useLang()
  const { halls, claims } = useVenue()
  const [day, setDay] = useState<string | null>('2027-01-14')
  return (
    <Section
      id="month"
      title={L(lang, 'Month grid and agenda', 'عرض الشهر وجدول اليوم')}
      note={L(
        lang,
        'One mark per hall, in hall order: a solid disc is booked, a ring is on hold, a dash is blocked, a gold bead is a pending request. Tap a day and its agenda opens below.',
        'علامة لكل قاعة بترتيب القاعات: القرص المصمت محجوز، والحلقة محجوز مؤقتًا، والشرطة مغلق، والخرزة الذهبية طلب بانتظار الرد. انقروا على يوم لفتح جدوله أدناه.',
      )}
    >
      <Stage kind="panel">
        <HotelMonthGrid halls={halls} claims={claims} defaultMonth={{ year: 2027, month: 1 }} selected={day} onSelectDate={setDay} label={L(lang, 'Calendar, January 2027', 'التقويم، يناير 2027')} />
      </Stage>
      {day ? (
        <Stage kind="panel">
          <DayAgenda date={day} halls={halls} claims={claims} />
        </Stage>
      ) : null}
      <Spec cap={L(lang, 'The agenda of a day with a hold in one hall and a booking in the other', 'جدول يوم فيه تثبيت مؤقت في قاعة وحجز في الأخرى')}>
        <Stage kind="panel">
          <DayAgenda date="2026-12-10" halls={halls} claims={claims} />
        </Stage>
      </Spec>
      <Spec cap={L(lang, 'The agenda of a day blocked in both halls', 'جدول يوم مغلق في القاعتين')}>
        <Stage kind="panel">
          <DayAgenda date="2026-11-23" halls={halls} claims={claims} />
        </Stage>
      </Spec>
    </Section>
  )
}

export function SelectSection() {
  const { lang } = useLang()
  const { halls, claims } = useVenue()
  const [range, setRange] = useState<DateSpan>({ start: '2026-12-15', end: '2026-12-18' })
  return (
    <Section
      id="select"
      title={L(lang, 'Range selection', 'تحديد النطاق')}
      note={L(lang, 'Press and hold, then drag; or tap a start and an end. A thread joins the endpoints; booked-out and past days refuse the selection.', 'اضغطوا مطوّلًا ثم اسحبوا، أو انقروا على البداية ثم النهاية. يصل خيط ذهبي بين الطرفين، وترفض الأيام المحجوزة بالكامل أو الماضية التحديد.')}
    >
      <DragAffordance />
      <Stage kind="panel">
        <HotelMonthGrid halls={halls} claims={claims} mode="select" range={range} onRangeChange={setRange} defaultMonth={{ year: 2026, month: 12 }} label={L(lang, 'Choose dates', 'اختيار التواريخ')} legend={false} />
      </Stage>
    </Section>
  )
}

export function WeekSection() {
  const { lang } = useLang()
  const { halls, claims } = useVenue()
  return (
    <Section
      id="week"
      title={L(lang, 'Week view', 'عرض الأسبوع')}
      note={L(lang, 'Seven day rows, one lane per hall. Booked is a solid bar, on hold is hatched with its deadline, blocked is cross-hatched and struck, a request is a gold bead on an open lane.', 'سبعة صفوف للأيام ولكل قاعة مسار. المحجوز شريط مصمت، والمحجوز مؤقتًا مخطط مع موعد انتهائه، والمغلق متقاطع الخطوط ومشطوب، والطلب خرزة ذهبية على مسار متاح.')}
    >
      <Stage kind="panel">
        <HotelWeekView halls={halls} claims={claims} date="2026-12-10" label={L(lang, 'Week view', 'عرض الأسبوع')} />
      </Stage>
    </Section>
  )
}

export function DaySection() {
  const { lang } = useLang()
  const { halls, claims } = useVenue()
  return (
    <Section id="day" title={L(lang, 'Day view', 'عرض اليوم')} note={L(lang, 'Prep, event and teardown per hall; a free hall offers Block.', 'التجهيز والحدث والفك لكل قاعة؛ والقاعة الشاغرة تتيح الإغلاق.')}>
      <Stage kind="panel">
        <HotelDayView date={PROTOTYPE_TODAY} halls={halls} claims={claims} now={PROTOTYPE_NOW.slice(11, 16)} />
      </Stage>
      <Spec cap={L(lang, 'A day with a hold and a booking', 'يوم فيه تثبيت مؤقت وحجز')}>
        <Stage kind="panel">
          <HotelDayView date="2026-12-10" halls={halls} claims={claims} />
        </Stage>
      </Spec>
      <Spec cap={L(lang, 'An open day', 'يوم متاح')}>
        <Stage kind="panel">
          <HotelDayView date="2026-12-15" halls={halls} claims={claims} />
        </Stage>
      </Spec>
    </Section>
  )
}

export function BlockSection() {
  const { lang } = useLang()
  const { halls, claims } = useVenue()
  return (
    <Section id="block" title={L(lang, 'Block dates sheet', 'ورقة إغلاق التواريخ')} note={L(lang, 'Three taps from anywhere: pick the dates, the reason is Booked offline by default, Block is the one gold action.', 'ثلاث نقرات من أي مكان: اختاروا التواريخ، والسبب الافتراضي حجز خارج غزل، والإغلاق هو الإجراء الذهبي الوحيد.')}>
      <BlockDatesSheet halls={halls} claims={claims} placement="inline" defaultMonth={{ year: 2026, month: 12 }} />
    </Section>
  )
}
