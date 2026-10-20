// Gallery sections: the booking detail pieces (GuestCard, BookingStatusCard, BookingActionList), driven by the shared story request
// GZ-2611-0147 in its states (pending, approved, confirmed, redeemed) and the stress fixtures (long names). ADR 0033: no payment schedule,
// no documents row, a voucher block and the redeem action.
import { heroVariants, bookings, meta } from '../../../mock'
import { useLang } from '../../../shell/lang'
import { BookingActionList } from '../booking/BookingActionList'
import { BookingStatusCard } from '../booking/BookingStatusCard'
import { GuestCard } from '../booking/GuestCard'
import { L, Section, Spec, Stage } from './kit'

export function BookingSection() {
  const { lang } = useLang()
  const pending = bookings.find(b => b.id === meta.story.bookingId)
  const approved = heroVariants.approved.booking
  const confirmed = heroVariants.confirmed.booking
  const redeemed = heroVariants.redeemed.booking
  const counter = heroVariants.counter_offer.booking
  const longName = { ...confirmed, clientName: 'عبدالرحمن بن محمد بن سلطان المطيري الدوسري', contact: { ...confirmed.contact, shared: false } }
  return (
    <Section
      id="booking"
      title={L(lang, 'Request detail', 'تفاصيل الطلب')}
      note={L(lang, 'The pieces of the one request screen: the guest card, the status with the vertical Booking Thread and the voucher block (what the client pays you directly, the standard price struck through, Redeem voucher), and the actions with what happens to the client’s voucher.', 'مكوّنات شاشة الطلب الواحدة: بطاقة العميل، والحالة مع خيط الحجز العمودي وكتلة الكوبون (ما يدفعه العميل لكم مباشرة والسعر العادي مشطوبًا وزر استخدام الكوبون)، والإجراءات مع ما يحدث لكوبون العميل.')}
    >
      <Spec cap={L(lang, 'Guest card · number shared', 'بطاقة العميل · الرقم مُشارَك')}>
        <GuestCard booking={confirmed} />
      </Spec>
      <Spec cap={L(lang, 'Guest card · long name, number not shared (Call disabled with its reason)', 'بطاقة العميل · اسم طويل ورقم غير مُشارَك (الاتصال معطّل مع سببه)')}>
        <GuestCard booking={longName} voucher={false} />
      </Spec>
      <Spec cap={L(lang, 'Status · pending: the Approval knot is now (reply window)', 'الحالة · بانتظار الرد: عقدة الموافقة هي الحالية (مهلة الرد)')}>
        {pending ? <BookingStatusCard booking={pending} /> : null}
      </Spec>
      <Spec cap={L(lang, 'Status · approved: waiting for the client to confirm within 24 hours', 'الحالة · تمت الموافقة: بانتظار تأكيد العميل خلال 24 ساعة')}>
        <BookingStatusCard booking={approved} />
      </Spec>
      <Spec cap={L(lang, 'Status · confirmed: Redeem voucher offered', 'الحالة · مؤكد: زر استخدام الكوبون متاح')}>
        <BookingStatusCard booking={confirmed} canRedeem />
      </Spec>
      <Spec cap={L(lang, 'Status · redeemed, and a pending request with a date proposed', 'الحالة · تم الاستخدام، وطلب بانتظار موعد مقترح')}>
        <BookingStatusCard booking={redeemed} />
        <BookingStatusCard booking={counter} />
      </Spec>
      <Spec cap={L(lang, 'Actions with consequences (Admin or Manager)', 'الإجراءات مع عواقبها (المالك أو المدير)')}>
        <Stage kind="panel">
          <BookingActionList actions={['reschedule', 'revoke', 'cancel']} />
        </Stage>
      </Spec>
    </Section>
  )
}
