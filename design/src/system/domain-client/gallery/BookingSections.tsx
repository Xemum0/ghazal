// Gallery: BookingCard, PackageCard and PriceBreakdown, driven by the seeded bookings, packages and the pricing engine.
import { useState } from 'react'
import {
  PROTOTYPE_NOW, engine, getBooking, heroBookingAs, meta, packagesFor, priceRules, quoteFor, requireVenue, stress,
  type Package,
} from '../../../mock'
import { BookingCard } from '../BookingCard'
import { PackageCard } from '../PackageCard'
import { PriceBreakdown } from '../PriceBreakdown'
import { Section, Spec, STORY_BRIEF, useL } from './kit'

const DATE = STORY_BRIEF.date ?? '2027-01-14'

function priceOf(pkg: Package, hallId: string, hallMin: number, guests: number, date = DATE) {
  const venue = requireVenue(pkg.venueId)
  return engine.packagePrice({
    pkg,
    rules: priceRules,
    eventDate: date,
    now: PROTOTYPE_NOW,
    hallId,
    guests,
    hallMinGuests: hallMin,
    serviceChargeBps: venue.policies.serviceChargeBps,
    voucherFeeFils: meta.config.voucherFeeFils,
  })
}

export function BookingCardSection() {
  const l = useL()
  const ref = (r: string) => {
    const b = getBooking(r)
    if (!b) throw new Error(`fixture ${r}`)
    return b
  }
  return (
    <Section
      id="booking-card"
      title={l('Booking card', 'بطاقة الحجز')}
      note={l(
        'A request as a panel: venue or provider, hall, status pill beside the voucher chip, three key facts (date, guests, voucher price), the compact thread with its current label, and the reference as a left-to-right isolate. An approved request carries one calm line with the time left to confirm. One stretched target.',
        'الطلب كلوحة: المكان أو مقدّم الخدمة والقاعة وشارة الحالة بجانب شارة الكوبون وثلاث حقائق (التاريخ والضيوف وسعر الكوبون) والخيط المصغّر مع نصه الحالي، ورقم الحجز بعزل من اليسار إلى اليمين. الطلب الموافَق عليه يحمل سطرًا هادئًا بالوقت المتبقي للتأكيد. هدف لمس واحد ممتد.',
      )}
    >
      <Spec state={l('Pending · the story request, voucher attached', 'بانتظار الرد · طلب القصة والكوبون مرفق')}>
        <BookingCard booking={heroBookingAs('pending')} onOpen={() => undefined} />
      </Spec>
      <Spec state={l('Approved · confirm within 24 hours', 'تمت الموافقة · التأكيد خلال 24 ساعة')}>
        <BookingCard booking={heroBookingAs('approved')} onOpen={() => undefined} />
      </Spec>
      <Spec state={l('Confirmed · a date proposed by the venue (chip beside the status)', 'مؤكد · موعد مقترح من المكان (شارة بجانب الحالة)')}>
        <BookingCard booking={heroBookingAs('confirmed')} onOpen={() => undefined} />
        <BookingCard booking={heroBookingAs('counter_offer')} onOpen={() => undefined} />
      </Spec>
      <Spec state={l('A service provider request · redeemed', 'طلب من مقدّم خدمة · تم استخدام الكوبون')}>
        <BookingCard booking={ref('GZ-2611-3D9P')} onOpen={() => undefined} />
        <BookingCard booking={ref('GZ-2610-2X4B')} variant="row" onOpen={() => undefined} />
      </Spec>
      <Spec state={l('Not accepted · expired · cancelled (rows, dense lists)', 'لم يُقبل · انتهت المهلة · ملغي (صفوف مختصرة)')}>
        <BookingCard booking={heroBookingAs('declined')} variant="row" onOpen={() => undefined} />
        <BookingCard booking={heroBookingAs('expired')} variant="row" onOpen={() => undefined} />
        <BookingCard booking={heroBookingAs('cancelled')} variant="row" onOpen={() => undefined} />
      </Spec>
      <Spec state={l('Pressed · loading', 'الضغط · التحميل')}>
        <BookingCard booking={heroBookingAs('pending')} previewState="pressed" />
        <BookingCard booking={heroBookingAs('pending')} loading />
      </Spec>
    </Section>
  )
}

export function PackageCardSection() {
  const l = useL()
  const v01 = packagesFor('V01')
  const weekend = v01.find(p => p.id === 'V01-ladies-weekend')!
  const signature = v01.find(p => p.id === 'V01-ladies-signature')!
  const lawn = packagesFor('V03').find(p => p.id === 'V03-lawn-evening')!
  const hallOnly = packagesFor('V07').find(p => p.id === 'V07-hall-only')!
  const villa = packagesFor('V04').find(p => p.id === 'V04-villa-night')!
  const [pick, setPick] = useState(weekend.id)
  const longName: Package = { ...weekend, id: 'long', name: { en: 'Ladies’ Reception with the Grand Kosha, Zaffa Procession and Full Buffet', ar: 'الحفل النسائي الكبير مع الكوشة الملكية والزفّة وبوفيه العشاء الكامل لجميع الضيوف' } }
  return (
    <Section
      id="package-card"
      title={l('Package card', 'بطاقة الباقة')}
      note={l(
        'A choice, not a banner: serif name, the structure (per person or package), the voucher price in the basis it is sold in with the standard price struck through, minimum guests as a fact, inclusions with checks, what is not covered. Selected is an ink border and a gold bead; the total for the guests and the saving sit under the name.',
        'اختيار لا لافتة: اسم بالخط ذي الزوائد وطريقة التسعير (للضيف أو باقة) وسعر الكوبون بأساس بيعه مع السعر العادي مشطوبًا والحد الأدنى للضيوف كحقيقة والمشمولات بعلامات صح وما لا يشمله. المحددة بإطار حبري وخرزة ذهبية؛ والإجمالي للضيوف والتوفير تحت الاسم.',
      )}
    >
      <Spec state={l('Per guest · selected / not · 350 guests', 'للضيف · محددة / غير محددة · 350 ضيفًا')}>
        {[weekend, signature].map(pkg => (
          <PackageCard key={pkg.id} pkg={pkg} price={priceOf(pkg, 'V01-danah', 300, 350)} guests={350} selected={pick === pkg.id} onSelect={() => setPick(pkg.id)} />
        ))}
      </Spec>
      <Spec state={l('Flat plus per guest · hall only · flat villa night', 'ثابت مع سعر للضيف · القاعة فقط · ليلة فيلا بسعر ثابت')}>
        <PackageCard pkg={lawn} price={priceOf(lawn, 'V03-lawn', 150, 300)} guests={300} onSelect={() => undefined} />
        <PackageCard pkg={hallOnly} price={priceOf(hallOnly, 'V07-ladies', 250, 350)} guests={350} onSelect={() => undefined} />
        <PackageCard pkg={villa} price={priceOf(villa, 'V04-garden', 20, 120)} guests={120} onSelect={() => undefined} />
      </Spec>
      <Spec state={l('Guest (signed out): the standard price and a locked voucher line', 'زائر (غير مسجّل): السعر العادي وسطر كوبون مقفل')}>
        <PackageCard pkg={weekend} price={priceOf(weekend, 'V01-danah', 300, 350)} guests={350} audience="guest" onSelect={() => undefined} />
      </Spec>
      <Spec state={l('Unavailable on the date · long name · loading', 'غير متاحة في التاريخ · اسم طويل · تحميل')}>
        <PackageCard pkg={signature} price={priceOf(signature, 'V01-danah', 300, 350)} guests={350} unavailable />
        <PackageCard pkg={longName} price={priceOf(weekend, 'V01-danah', 300, 350)} guests={350} onSelect={() => undefined} />
        <PackageCard pkg={weekend} loading />
      </Spec>
      <Spec state={l('Pressed', 'الضغط')}>
        <PackageCard pkg={weekend} price={priceOf(weekend, 'V01-danah', 300, 350)} guests={350} onSelect={() => undefined} previewState="pressed" />
      </Spec>
    </Section>
  )
}

export function PriceBreakdownSection() {
  const l = useL()
  const story = heroBookingAs('pending')
  const rich = quoteFor({
    venueId: 'V01',
    eventDate: '2027-01-21',
    sections: [{ hallId: 'V01-danah', audience: 'women', guests: 400, packageId: 'V01-ladies-weekend' }],
    extras: [{ extraId: requireExtra('V01'), qty: 1 }],
  })
  const extreme = stress.bookings[0]
  const venue = requireVenue('V01').name
  const name = useL()(venue.en, venue.ar)
  return (
    <Section
      id="price-breakdown"
      title={l('Price breakdown', 'تفاصيل السعر')}
      note={l(
        'Figures voice, three decimals, quiet .000. Each line carries the voucher amount with the standard amount struck through beneath it, then the totals (standard struck, voucher total as the headline, the saving), then who is paid what: the KD 2 voucher to Ghazal (paid once) and the voucher total to the venue directly after the client confirms. No deposit, no balance, no cancellation schedule.',
        'صوت الأرقام بثلاث خانات عشرية و.000 هادئة. كل سطر يحمل مبلغ الكوبون مع المبلغ العادي مشطوبًا تحته، ثم الإجماليات (العادي مشطوب وإجمالي الكوبون هو العنوان والتوفير)، ثم لمن يُدفع كل مبلغ: كوبون بقيمة 2 د.ك لغزل مرة واحدة، وإجمالي الكوبون للمكان مباشرة بعد التأكيد. بلا عربون ولا متبقٍّ ولا جدول إلغاء.',
      )}
    >
      <Spec state={l('Review · the story request: nothing more to pay Ghazal', 'المراجعة · طلب القصة: لا مبلغ إضافي لغزل')}>
        <PriceBreakdown quote={story} stage="review" venueName={name} />
      </Spec>
      <Spec state={l('Approved: totals and who is paid, no lines', 'تمت الموافقة: الإجماليات ولمن يُدفع دون الأسطر')}>
        <PriceBreakdown quote={heroBookingAs('approved')} stage="approved" venueName={name} showLines={false} />
      </Spec>
      <Spec state={l('Confirmed: pay the venue, then show the code', 'مؤكد: ادفعوا للمكان ثم اعرضوا الرمز')}>
        <PriceBreakdown quote={heroBookingAs('confirmed')} stage="confirmed" venueName={name} showLines={false} />
      </Spec>
      <Spec state={l('Redeemed · totals only (settlement block hidden)', 'تم الاستخدام · الإجماليات فقط')}>
        <PriceBreakdown quote={heroBookingAs('redeemed')} stage="redeemed" venueName={name} showLines={false} />
        <PriceBreakdown quote={heroBookingAs('redeemed')} stage="redeemed" showLines={false} showSettlement={false} />
      </Spec>
      <Spec state={l('Many lines: package, extra and service charge', 'أسطر كثيرة: باقة وإضافة ورسوم خدمة')}>
        <PriceBreakdown quote={rich} stage="review" venueName={name} />
      </Spec>
      {extreme ? (
        <Spec state={l('Stress: a very large total', 'ضغط: إجمالي كبير جدًا')}>
          <PriceBreakdown quote={extreme} stage="review" showLines={false} venueName={name} />
        </Spec>
      ) : null}
      <Spec state={l('Loading', 'التحميل')}>
        <PriceBreakdown quote={story} loading />
      </Spec>
    </Section>
  )
}

import { extrasFor } from '../../../mock'
function requireExtra(venueId: string): string {
  const e = extrasFor(venueId).find(x => x.category === 'kosha') ?? extrasFor(venueId)[0]
  if (!e) throw new Error('no extras')
  return e.id
}
