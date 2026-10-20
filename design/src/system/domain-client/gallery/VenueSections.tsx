// Gallery: VenueCard in every variant and state, the rail width of ADR 0018 D8, and the stress cases (long Arabic name, no photos,
// no reviews, a government hall). Everything is driven by the fixtures through the story brief.
import { useState } from 'react'
import { stress, type CardPrice } from '../../../mock'
import { VenueCard } from '../VenueCard'
import { Row, Section, Spec, resultOf, STORY_BRIEF, useL } from './kit'

function useFlag(initial = false): [boolean, (v: boolean) => void] {
  return useState(initial)
}

function Live({ id, ...rest }: { id: string } & Partial<React.ComponentProps<typeof VenueCard>>) {
  const r = resultOf(id)
  const [fav, setFav] = useFlag(false)
  const [cmp, setCmp] = useFlag(false)
  return (
    <VenueCard
      venue={r.venue}
      price={r.price}
      availability={r.availability ?? undefined}
      date={STORY_BRIEF.date ?? undefined}
      badge={r.badge}
      tags={r.tags}
      guestRange={r.guestRange}
      sponsored={r.sponsored}
      favourite={fav}
      onFavouriteChange={setFav}
      compared={cmp}
      onCompareChange={setCmp}
      onOpen={() => undefined}
      {...rest}
    />
  )
}

const flat = (fils: number): CardPrice => ({ mode: 'flat_night', amount: { fils, currency: 'KWD' }, hasSeveralPackages: false, packageId: 'x', voucher: null, savings: null })

export function VenueCardSection() {
  const l = useL()
  return (
    <Section
      id="venue-card"
      title={l('Venue card', 'بطاقة القاعة')}
      note={l(
        'ADR 0018: an unframed plate. A 4:5 photograph, canvas disks in 44 targets, one badge, then the wall label: serif name with the rating at the end, area and guest range, tags only when there is more than one arrangement, a hairline, the availability line and the price line with its basis.',
        'القرار 0018: لوحة بلا إطار. صورة بنسبة 4:5، وأقراص بلون الخلفية داخل أهداف لمس بحجم 44، وشارة واحدة، ثم لوحة التعريف: الاسم بالخط ذي الزوائد والتقييم في النهاية، المنطقة وعدد الضيوف، والوسوم فقط عند تعدد الترتيبات، وخط رفيع، وسطر التوفر وسطر السعر مع أساسه.',
      )}
    >
      <Spec state={l('Card 4:5 · date and guests set · available, with the contextual Book action', 'بطاقة 4:5 · التاريخ والضيوف محددان · متاحة مع إجراء الحجز')}>
        <Live id="V01" />
      </Spec>
      <Spec state={l('Offer badge (the discount is the label) · saved · compared', 'شارة العرض (الخصم هو النص) · محفوظة · مضافة للمقارنة')}>
        <Live id="V09" />
      </Spec>
      <Spec state={l('Instant badge · two arrangements shown as tags', 'شارة الحجز الفوري · ترتيبان بوسمين')}>
        <Live id="V08" />
      </Spec>
      <Spec state={l('Sponsored: the disclosure stays on the meta line', 'إعلان: يبقى التنويه في سطر المعلومات')}>
        <Live id="V03" />
      </Spec>
      <Spec state={l('On hold on your date: icon and label, no Book', 'محجوزة مؤقتًا في تاريخكم: أيقونة ونص بلا زر حجز')}>
        <Live id="V07" />
      </Spec>
      <Spec state={l('Government hall: ministry line, rental fee, no Book', 'قاعة حكومية: سطر الوزارة ورسوم الإيجار بلا زر حجز')}>
        <Live id="V19" />
      </Spec>
      <Spec state={l('Feature · larger serif name, display price', 'مميزة · اسم أكبر وسعر بالخط ذي الزوائد')}>
        <Live id="V02" variant="feature" />
      </Spec>
      <Spec state={l('List 16:10 · photo dots (opt-in) · video affordance', 'قائمة 16:10 · نقاط الصور (اختيارية) · رمز الفيديو')}>
        <Live id="V01" variant="list" carousel />
      </Spec>
      <Spec state={l('Pressed (whole card scales .985)', 'حالة الضغط (البطاقة كلها تتقلص إلى .985)')}>
        <Live id="V05" previewState="pressed" />
      </Spec>
    </Section>
  )
}

export function VenueCompactSection() {
  const l = useL()
  const [pick, setPick] = useState('V05')
  const ids = ['V05', 'V07', 'V09']
  return (
    <Section
      id="venue-compact"
      title={l('Compact, saved and compare rows', 'الصفوف المصغّرة والمحفوظة والمقارنة')}
      note={l(
        '72 by 88 thumbnail, name, area and the price line; no tags, no availability. Saved adds the heart and a real price-drop note; compare is a choice row for the Replace sheet.',
        'صورة مصغّرة 72 في 88 والاسم والمنطقة وسطر السعر؛ بلا وسوم ولا سطر توفر. المحفوظة تضيف القلب وملاحظة انخفاض سعر حقيقية؛ وصف المقارنة صف اختيار لورقة الاستبدال.',
      )}
    >
      <Spec state={l('Compact · carousels and the tray detail', 'مصغّرة · القوائم الأفقية وتفاصيل الشريط')}>
        <Live id="V01" variant="compact" />
        <Live id="V19" variant="compact" />
      </Spec>
      <Spec state={l('Saved · heart on · price dropped', 'محفوظة · القلب مفعّل · انخفض السعر')}>
        <Live id="V09" variant="saved" priceDropped favourite />
        <Live id="V05" variant="saved" favourite />
      </Spec>
      <Spec state={l('Compare · replace which one · selected / not', 'مقارنة · أي قاعة تُستبدل · محددة / غير محددة')}>
        {ids.map(id => (
          <Live key={id} id={id} variant="compare" selected={pick === id} onSelect={() => setPick(id)} />
        ))}
      </Spec>
    </Section>
  )
}

export function VenueStressSection() {
  const l = useL()
  const [long, none, fresh] = stress.venues
  const longPrice: CardPrice = { mode: 'exact', amount: { fils: 985000, currency: 'KWD' }, guests: 1200, packageId: 'x', tier: 'weekend', voucher: null, savings: null }
  const cheap: CardPrice = { mode: 'from_guests', amount: { fils: 480, currency: 'KWD' }, guests: 20, packageId: 'x', tier: 'weekday', voucher: null, savings: null }
  return (
    <Section
      id="venue-stress"
      title={l('Venue card · stress', 'بطاقة القاعة · حالات الضغط')}
      note={l(
        'The Kuwait stress set: a very long mixed-script name, no photographs, no reviews, a three-digit and a six-digit price, and skeletons. The name wraps to two lines then truncates; nothing overlaps the rating.',
        'حالات الضغط الكويتية: اسم طويل جدًا بخطين مختلطين، وقاعة بلا صور، وأخرى بلا تقييمات، وسعر من ثلاث خانات وآخر من ست، وهياكل التحميل. يلتف الاسم على سطرين ثم يُقتطع ولا يتداخل مع التقييم.',
      )}
    >
      <Spec state={l('Long mixed-script name', 'اسم طويل بخطين مختلطين')}>
        {long ? <VenueCard venue={long} price={longPrice} tags={['women', 'men']} guestRange={{ min: 200, max: 1200 }} onOpen={() => undefined} onFavouriteChange={() => undefined} onCompareChange={() => undefined} /> : null}
      </Spec>
      <Spec state={l('No photographs · three-digit price', 'بلا صور · سعر من ثلاث خانات')}>
        {none ? <VenueCard venue={none} price={flat(480000)} onOpen={() => undefined} onFavouriteChange={() => undefined} /> : null}
      </Spec>
      <Spec state={l('No reviews: "New", never 0.0 · price from KD 0.480', 'بلا تقييمات: «جديد» لا 0.0 · سعر من 0.480')}>
        {fresh ? <VenueCard venue={fresh} price={cheap} onOpen={() => undefined} onFavouriteChange={() => undefined} /> : null}
      </Spec>
      <Spec state={l('Rail card at 72% of the frame (ADR 0018 D8)', 'بطاقة القائمة الأفقية بعرض 72% (القرار 0018)')}>
        <Row>
          <div className="gc-rail">
            <Live id="V05" variant="card" />
          </div>
        </Row>
      </Spec>
      <Spec state={l('Skeleton · card, list, compact', 'هيكل التحميل · بطاقة وقائمة ومصغّرة')}>
        <VenueCard venue={resultOf('V01').venue} loading />
        <VenueCard venue={resultOf('V01').venue} loading variant="list" />
        <VenueCard venue={resultOf('V01').venue} loading variant="compact" />
      </Spec>
    </Section>
  )
}
