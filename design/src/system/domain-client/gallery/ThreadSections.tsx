// Gallery: the Booking Thread in its three variants, on canvas and on ink, for every ADR 0003 status, driven by the seeded bookings.
import { useState } from 'react'
import { getBooking, heroBookingAs, type Booking } from '../../../mock'
import { Button } from '../../core'
import { BookingThread } from '../BookingThread'
import { Section, Spec, useL } from './kit'

const REF = (ref: string): Booking => {
  const b = getBooking(ref)
  if (!b) throw new Error(`fixture ${ref} missing`)
  return b
}

const STATUS_ROWS: { label: [string, string]; booking: () => Booking }[] = [
  { label: ['Pending: the venue has until Fri 13 Nov, 12:40 PM', 'بانتظار الرد: أمام المكان حتى الجمعة 13 نوفمبر 12:40 م'], booking: () => heroBookingAs('pending') },
  { label: ['Approved: confirm within 24 hours', 'تمت الموافقة: التأكيد خلال 24 ساعة'], booking: () => heroBookingAs('approved') },
  { label: ['Confirmed: show the code at the venue', 'مؤكد: اعرضوا الرمز لدى المكان'], booking: () => heroBookingAs('confirmed') },
  { label: ['Redeemed at the venue: all five knots tied', 'تم الاستخدام لدى المكان: العقد الخمس مربوطة'], booking: () => heroBookingAs('redeemed') },
  { label: ['Completed', 'مكتمل'], booking: () => REF('GZ-2608-6N8F') },
  { label: ['Not accepted: Approval ends in a danger knot', 'لم يُقبل الطلب: تنتهي الموافقة بعقدة حمراء'], booking: () => heroBookingAs('declined') },
  { label: ['Expired: the venue did not reply', 'انتهت المهلة: لم يرد المكان'], booking: () => heroBookingAs('expired') },
  { label: ['Lapsed: the client did not confirm within 24 hours (Confirmation ends)', 'انتهت المهلة: لم يؤكد العميل خلال 24 ساعة (ينتهي التأكيد)'], booking: () => heroBookingAs('lapsed') },
  { label: ['Cancelled', 'ملغي'], booking: () => heroBookingAs('cancelled') },
  { label: ['A service provider request: pending', 'طلب من مقدّم خدمة: بانتظار الرد'], booking: () => REF('GZ-2611-4W8Q') },
]

export function ThreadSection() {
  const l = useL()
  const [replay, setReplay] = useState(0)
  return (
    <Section
      id="thread"
      title={l('Booking Thread', 'خيط الحجز')}
      note={l(
        'Voucher, Request, Approval, Confirmed (24 h), Redeemed at the venue. A knot ties only when its event is recorded; times are absolute; the line runs gold up to where you are and draws on once from the start. Status is never the thread alone: every knot has a label and a glyph.',
        'الكوبون، الطلب، الموافقة، التأكيد (24 ساعة)، الاستخدام لدى المكان. لا تُربط العقدة إلا عند تسجيل حدثها؛ الأوقات مطلقة؛ ويمتد الخط الذهبي حتى موضعكم ويُرسم مرة واحدة من البداية. لا يكفي الخيط وحده: لكل عقدة نص ورمز.',
      )}
    >
      <Spec state={l('Full · every ADR 0033 status', 'كامل · كل حالات القرار 0033')}>
        <div className="gc-replay">
          <Button variant="tertiary" iconStart="refresh" onClick={() => setReplay(n => n + 1)}>
            {l('Replay the draw-on', 'إعادة رسم الخيط')}
          </Button>
        </div>
        {STATUS_ROWS.map((r, i) => (
          <div className="gc-cell" key={`${i}-${replay}`}>
            <p className="gc-cap gz-t-caption">{l(...r.label)}</p>
            <BookingThread booking={r.booking()} draw="mount" />
          </div>
        ))}
      </Spec>
      <Spec state={l('Compact · 12 px knots, the current label only (list rows, partner request card)', 'مصغّر · عقد 12 والنص الحالي فقط (صفوف القوائم)')}>
        {STATUS_ROWS.slice(0, 8).map((r, i) => (
          <BookingThread key={i} booking={r.booking()} variant="compact" draw={false} />
        ))}
      </Spec>
      <Spec state={l('Vertical · booking detail: past knots with absolute times, at most two faint future knots', 'عمودي · تفاصيل الحجز: العقد السابقة بأوقات مطلقة وعقدتان باهتتان كحد أقصى')}>
        <BookingThread booking={heroBookingAs('approved')} variant="vertical" draw="mount" />
        <BookingThread booking={REF('GZ-2611-2P8R')} variant="vertical" draw="mount" />
        <BookingThread booking={heroBookingAs('declined')} variant="vertical" draw="mount" />
      </Spec>
      <Spec tone="ink" state={l('On dark · confirmation hero, countdown', 'على الخلفية الداكنة · شاشة التأكيد والعد التنازلي')}>
        <BookingThread booking={heroBookingAs('confirmed')} onDark draw="mount" />
        <BookingThread booking={heroBookingAs('approved')} onDark variant="compact" draw={false} />
        <BookingThread booking={REF('GZ-2608-1F7G')} onDark variant="vertical" draw="mount" />
      </Spec>
    </Section>
  )
}
