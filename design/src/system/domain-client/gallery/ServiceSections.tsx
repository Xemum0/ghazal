// Gallery: planner tiers, the 16 service tiles and vendor cards, from the planners and services fixtures.
import { useState } from 'react'
import { plannerPackages, serviceCategories, vendors } from '../../../mock'
import { ProviderNote } from '../ProviderNote'
import { PlannerTierCard, ServiceTile, VendorCard } from '../ServiceCards'
import { Row, Section, Spec, useL } from './kit'

export function PlannerSection() {
  const l = useL()
  const [pick, setPick] = useState('planner-gold')
  return (
    <Section
      id="planner-tier"
      title={l('Planner tiers', 'باقات المخطط')}
      note={l(
        'Silver, Gold and Royal are planner packages only. One, two and three gold beads mark the tier; there is no metallic colour. The 25% deposit is a proposal, arranged after the consultation.',
        'الفضية والذهبية والملكية لباقات المخطط فقط. تُرمز خرزة ذهبية واحدة أو اثنتان أو ثلاث إلى الباقة؛ ولا ألوان معدنية. العربون 25% مقترح يُتفق عليه بعد الاستشارة.',
      )}
    >
      <Spec state={l('Choose a tier · selected is an ink border', 'اختيار الباقة · المحددة بإطار حبري')}>
        {plannerPackages.map(pkg => (
          <PlannerTierCard key={pkg.id} pkg={pkg} selected={pick === pkg.id} onSelect={() => setPick(pkg.id)} onRequest={pick === pkg.id ? () => undefined : undefined} />
        ))}
      </Spec>
      <Spec state={l('Loading', 'التحميل')}>
        <PlannerTierCard pkg={plannerPackages[0]!} loading />
      </Spec>
    </Section>
  )
}

export function ServiceTileSection() {
  const l = useL()
  const pairs: (typeof serviceCategories)[] = []
  for (let i = 0; i < serviceCategories.length; i += 2) pairs.push(serviceCategories.slice(i, i + 2))
  return (
    <Section
      id="service-tile"
      title={l('Service tiles', 'بلاطات الخدمات')}
      note={l(
        'The 16 service categories as photograph tiles with a wall label: the name, then the price anchor with its unit. Two across.',
        'فئات الخدمات الست عشرة كبلاطات صور بلوحة تعريفية: الاسم ثم السعر التقريبي بوحدته. اثنتان في الصف.',
      )}
    >
      <Spec state={l('All 16 categories', 'الفئات الست عشرة كلها')}>
        {pairs.map((pair, i) => (
          <Row key={i}>
            {pair.map(c => (
              <ServiceTile key={c.id} category={c} onOpen={() => undefined} />
            ))}
          </Row>
        ))}
      </Spec>
      <Spec state={l('Pressed · loading', 'الضغط · التحميل')}>
        <Row>
          <ServiceTile category={serviceCategories[0]!} previewState="pressed" />
          <ServiceTile category={serviceCategories[0]!} loading />
        </Row>
      </Spec>
    </Section>
  )
}

export function VendorSection() {
  const l = useL()
  const [fav, setFav] = useState(false)
  const rated = vendors.find(v => v.rating && v.verified && v.femaleTeamForLadies)!
  const fresh = vendors.find(v => !v.rating)!
  const long = [...vendors].sort((a, b) => b.name.ar.length - a.name.ar.length)[0]!
  return (
    <Section
      id="vendor-card"
      title={l('Vendor card', 'بطاقة المورّد')}
      note={l(
        'A supplier: portfolio strip, monogram, name, rating or "New", area, the from price with its unit, plain facts and the verified mark. The row form is for lists and the saved tab.',
        'مورّد: شريط أعمال وحرف أول والاسم والتقييم أو «جديد» والمنطقة والسعر ابتداءً من بوحدته وحقائق واضحة وعلامة التوثيق. الصيغة المختصرة للقوائم وتبويب المفضلة.',
      )}
    >
      <Spec state={l('Verified · rated · female team · save heart', 'موثّق · مقيَّم · فريق نسائي · قلب الحفظ')}>
        <VendorCard vendor={rated} favourite={fav} onFavouriteChange={setFav} onOpen={() => undefined} />
      </Spec>
      <Spec state={l('New vendor (no rating) · longest name', 'مورّد جديد (بلا تقييم) · أطول اسم')}>
        <VendorCard vendor={fresh} onOpen={() => undefined} />
        <VendorCard vendor={long} onOpen={() => undefined} />
      </Spec>
      <Spec state={l('Row · pressed · loading', 'صف مختصر · الضغط · التحميل')}>
        <VendorCard vendor={rated} variant="row" onOpen={() => undefined} />
        <VendorCard vendor={fresh} variant="row" previewState="pressed" />
        <VendorCard vendor={rated} loading />
      </Spec>
      <Spec state={l('Provider note (CA-SVC-20) · glyph, one line, quiet external link · footer of Services, a row of Profile', 'ملاحظة المزوّد (CA-SVC-20) · رمز وسطر واحد ورابط خارجي هادئ · تذييل الخدمات وصف في الملف الشخصي')}>
        <ProviderNote variant="footer" />
        <ProviderNote variant="row" />
      </Spec>
    </Section>
  )
}
