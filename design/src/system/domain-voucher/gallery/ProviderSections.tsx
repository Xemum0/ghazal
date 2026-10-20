// Gallery: the service-provider module (ADR 0033 D7, D8): ListingStatusPill, ProviderListingCard, ReviewTimeline, AdPlanCard and MajorHotelBadge,
// driven by the listing fixtures of Zahra Floral Studio (draft, in review, rejected, live, ended) and the three ad plans. Plan rates are not
// decided: the fixtures carry null and every surface says "Rates announced soon"; the one number below is a sample marked for the gallery only.
import { useState } from 'react'
import { adPlans, listings, partnerBilling, type AdPlanCycle, type Listing } from '../../../mock'
import { Section, Spec, useL } from '../../domain-client/gallery/kit'
import { AdPlanCard } from '../../domain-provider/AdPlanCard'
import { ListingStatusPill } from '../../domain-provider/ListingStatusPill'
import { MajorHotelBadge } from '../../domain-provider/MajorHotelBadge'
import { BillingCard } from '../../domain-provider/BillingCard'
import { ProviderListingCard } from '../../domain-provider/ProviderListingCard'
import { ReviewTimeline } from '../../domain-provider/ReviewTimeline'

const L1 = (id: string): Listing => {
  const l = listings.find(x => x.id === id)
  if (!l) throw new Error(id)
  return l
}

const ZAHRA = ['lst-flowers-zahra-draft', 'lst-flowers-zahra-table', 'lst-flowers-zahra-kosha', 'lst-flowers-zahra', 'lst-flowers-zahra-autumn']

export function ListingSection() {
  const l = useL()
  return (
    <Section
      id="listing"
      title={l('Listings and review status', 'الإعلانات وحالة المراجعة')}
      note={l(
        'A listing is never published on payment: every advertisement waits for a moderator, so Approved and Live are two different pills. The card shows the lifecycle, the plan line (or the honest “Rates announced soon” / “Exempt”) and, when the moderator said no, the first reason in plain words.',
        'لا يُنشر الإعلان بمجرد الدفع: ينتظر كل إعلان مراجعًا بشريًا، لذلك «تمت الموافقة» و«منشور» شارتان مختلفتان. تعرض البطاقة المرحلة وسطر الباقة (أو «الأسعار تُعلن قريبًا» / «معفى» بصدق) وعند الرفض أول سبب بالكلمات.',
      )}
    >
      <Spec state={l('Status pills · every state', 'شارات الحالة · كل الحالات')}>
        <div className="gc-row gc-row--fixed">
          {(['draft', 'payment_pending', 'pending_review', 'approved', 'rejected', 'active', 'expired', 'paused'] as const).map(s => (
            <ListingStatusPill key={s} status={s} />
          ))}
        </div>
      </Spec>
      <Spec state={l('Listing cards · draft · in review · not approved · live · ended', 'بطاقات الإعلانات · مسودة · قيد المراجعة · لم تتم الموافقة · منشور · انتهى')}>
        {ZAHRA.map(id => (
          <ProviderListingCard key={id} listing={L1(id)} onOpen={() => undefined} />
        ))}
      </Spec>
      <Spec state={l('A major hotel’s listing: the plan line says Exempt', 'إعلان فندق كبير: سطر الباقة يقول معفى')}>
        <ProviderListingCard listing={L1('lst-flowers-zahra')} exempt onOpen={() => undefined} />
      </Spec>
    </Section>
  )
}

export function ReviewTimelineSection() {
  const l = useL()
  return (
    <Section
      id="review-timeline"
      title={l('Review timeline', 'مسار المراجعة')}
      note={l(
        'The audit trail of one listing on the Booking Thread’s rail: a knot per decision with its absolute time and who made it, then what is still ahead. A rejection lists its reasons in plain words, the moderator’s note, and how long the plan is kept for a resubmission.',
        'سجل مراجعة إعلان واحد على مسار خيط الحجز: عقدة لكل قرار بوقته المطلق ومن اتخذه، ثم ما ينتظر بعده. يسرد الرفض أسبابه بالكلمات وملاحظة المراجع ومدة بقاء الباقة لإعادة الإرسال.',
      )}
    >
      <Spec state={l('In review · the review is the knot that is now', 'قيد المراجعة · المراجعة هي العقدة الحالية')}>
        <ReviewTimeline listing={L1('lst-flowers-zahra-table')} />
      </Spec>
      <Spec state={l('Not approved · reasons and a note', 'لم تتم الموافقة · أسباب وملاحظة')}>
        <ReviewTimeline listing={L1('lst-flowers-zahra-kosha')} />
      </Spec>
      <Spec state={l('Live · approved by a person, then published', 'منشور · وافق عليه شخص ثم نُشر')}>
        <ReviewTimeline listing={L1('lst-flowers-zahra')} />
      </Spec>
      <Spec state={l('Draft', 'مسودة')}>
        <ReviewTimeline listing={L1('lst-flowers-zahra-draft')} />
      </Spec>
    </Section>
  )
}

export function AdPlanSection() {
  const l = useL()
  const [cycle, setCycle] = useState<AdPlanCycle>('monthly')
  const sample = { ...adPlans[1]!, ratesFils: 45000 }
  return (
    <Section
      id="ad-plan"
      title={l('Advertising plans', 'باقات الإعلان')}
      note={l(
        'Weekly, monthly or annual. The rates are not decided, so a plan says “Rates announced soon” and never a number; a rate shows only after the Super Admin sets it. A major hotel sees “Exempt” and nothing is payable. Choosing a plan is not buying: the listing still waits for review.',
        'أسبوعي أو شهري أو سنوي. الأسعار لم تُحسم بعد، لذلك تقول الباقة «الأسعار تُعلن قريبًا» ولا تعرض رقمًا أبدًا؛ ويظهر السعر فقط بعد أن يحدده المدير العام. يرى الفندق الكبير «معفى» ولا شيء مستحق الدفع. اختيار الباقة ليس شراءً: يبقى الإعلان بانتظار المراجعة.',
      )}
    >
      <Spec state={l('Rates announced soon · choose one (monthly selected)', 'الأسعار تُعلن قريبًا · اختاروا باقة (الشهرية محددة)')}>
        <div role="radiogroup" aria-label={l('Advertising plan', 'باقة الإعلان')} className="gc-stack">
          {adPlans.map(p => (
            <AdPlanCard key={p.id} plan={p} selected={cycle === p.cycle} onSelect={() => setCycle(p.cycle)} />
          ))}
        </div>
      </Spec>
      <Spec state={l('Exempt · a major hotel (nothing to pay)', 'معفى · فندق كبير (لا شيء للدفع)')}>
        <div className="gc-stack">
          {adPlans.map(p => (
            <AdPlanCard key={p.id} plan={p} exempt selected={p.cycle === 'annual'} />
          ))}
        </div>
      </Spec>
      <Spec state={l('A rate set by the Super Admin (a gallery sample, not a price)', 'سعر حدده المدير العام (عيّنة للعرض وليست سعرًا)')}>
        <AdPlanCard plan={sample} />
      </Spec>
      <Spec state={l('Major hotel badge · chip and note (Partner app only)', 'شارة الفندق الكبير · شارة وملاحظة (تطبيق الشريك فقط)')}>
        <MajorHotelBadge />
        <MajorHotelBadge variant="note" />
      </Spec>
      <Spec state={l('Billing card · business contract (hotels and halls, no price) · major hotel · plan (service providers, rates soon)', 'بطاقة الفوترة · عقد عمل (فنادق وقاعات، بلا سعر) · فندق كبير · باقة (مقدّمو الخدمات، الأسعار قريبًا)')}>
        {partnerBilling
          .filter((b, i, all) => all.findIndex(x => x.mode === b.mode) === i)
          .map(b => (
            <BillingCard key={b.partnerAccountId} billing={b} />
          ))}
        <BillingCard billing={partnerBilling.find(b => b.mode === 'contract')!} majorHotel />
      </Spec>
    </Section>
  )
}
