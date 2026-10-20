// Gallery sections: the triage components (RequestCard, RequestRow). Driven by the hotel fixtures (requestsFor, needsYou).
import type { PendingRequest } from '@gz/contracts'
import { engine, meta, PROTOTYPE_TODAY, requestsFor } from '../../../mock'
import { useLang } from '../../../shell/lang'
import { RequestCard } from '../RequestCard'
import { L, Section, Spec } from './kit'

const LONG_NAME = 'عبدالرحمن بن محمد بن سلطان المطيري الدوسري'

export function RequestCardSection() {
  const { lang } = useLang()
  const list = requestsFor(meta.hotelVenueId)
  const [reem, dana, abdullah, maryam] = [
    list.find(r => r.booking.id === 'bk-GZ-2611-0147'),
    list.find(r => r.booking.id === 'bk-GZ-2611-3K8D'),
    list.find(r => r.booking.id === 'bk-GZ-2611-5T2W'),
    list.find(r => r.booking.id === 'bk-GZ-2611-6R9C'),
  ] as PendingRequest[]
  const gold: PendingRequest = { ...(abdullah as PendingRequest), sla: { state: 'gold', elapsed: 0.62, minutesLeft: 9 * 60 + 10, minutesWaiting: 14 * 60 + 50 }, otherRequestsSameDate: 2 }
  const urgent: PendingRequest = { ...(dana as PendingRequest), booking: { ...(dana as PendingRequest).booking, eventDate: engine.addDays(PROTOTYPE_TODAY, 9) } }
  const long: PendingRequest = { ...(maryam as PendingRequest), booking: { ...(maryam as PendingRequest).booking, clientName: LONG_NAME, specialRequests: 'نرجو تجهيز الكوشة قبل الساعة السابعة مساءً مع وجود مدخل منفصل للعروس وأسرتها.' } }
  return (
    <Section
      id="request"
      title={L(lang, 'Request card', 'بطاقة الطلب')}
      note={L(
        lang,
        'The triage card: one gold Accept, equal-weight Reschedule and Decline, the depleting reply bar, the check line or the conflict note, the compact Booking Thread. No swipe actions.',
        'بطاقة الفرز: زر قبول ذهبي واحد، وتغيير الموعد والاعتذار بوزن متساوٍ، وشريط مهلة الرد المتناقص، وسطر التحقق أو ملاحظة التعارض، وخيط الحجز المصغّر. لا إجراءات بالسحب.',
      )}
    >
      <Spec cap={L(lang, 'New · neutral window · no other request', 'جديد · مهلة عادية · لا طلبات أخرى')}>
        <RequestCard request={reem as PendingRequest} state="new" />
      </Spec>
      <Spec cap={L(lang, 'Danger window (from 80% or under an hour) · event in 9 days: the Urgent tag', 'مهلة حرجة (من 80% أو أقل من ساعة) · المناسبة بعد 9 أيام: وسم عاجل')}>
        <RequestCard request={urgent} />
      </Spec>
      <Spec cap={L(lang, 'Gold window (from 50%) · +2 other requests, Compare link ', 'مهلة تنبيه (من 50%) · +2 طلبان آخران مع رابط المقارنة ')}>
        <RequestCard request={gold} />
      </Spec>
      <Spec cap={L(lang, 'Long name, special requests, number not shared (no Call)', 'اسم طويل وطلبات خاصة ورقم غير مشارَك (بلا اتصال)')}>
        <RequestCard request={long} canCall={false} />
      </Spec>
      <Spec cap={L(lang, 'Date held for another couple · Accept disabled with its reason', 'التاريخ محجوز لعميل آخر · القبول معطّل مع سببه')}>
        <RequestCard request={dana as PendingRequest} held />
      </Spec>
      <Spec cap={L(lang, 'Accepting · Accept in flight, the pair held', 'قيد القبول · القبول جارٍ والزران الآخران معطّلان')}>
        <RequestCard request={reem as PendingRequest} state="accepting" />
      </Spec>
      <Spec cap={L(lang, 'Approved · awaiting the client for 24 hours, Undo for 8 seconds', 'تمت الموافقة · بانتظار العميل 24 ساعة مع تراجع لمدة 8 ثوانٍ')}>
        <RequestCard request={reem as PendingRequest} state="accepted" />
      </Spec>
      <Spec cap={L(lang, 'Declined · reason given', 'تم الاعتذار · مع ذكر السبب')}>
        <RequestCard request={abdullah as PendingRequest} state="declined" declineReason={L(lang, 'Date unavailable.', 'التاريخ غير متاح.')} />
      </Spec>
    </Section>
  )
}
