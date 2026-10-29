// Gallery: the Home pieces of the client app, the brief (typeset sentence and structured card), category tiles, offers and the countdown.
import { useState } from 'react'
import { daysToWedding, heroBookingAs, requireVenue, venues, voucherWindows, weddingProfile, type Brief } from '../../../mock'
import { useFormat } from '../../../i18n'
import { BriefCard } from '../BriefCard'
import { BriefSentence } from '../BriefSentence'
import { CategoryTile } from '../CategoryTile'
import { CountdownCard } from '../CountdownCard'
import { VoucherWindowCard } from '../VoucherWindowCard'
import { Row, Section, Spec, STORY_BRIEF, useL } from './kit'

export function BriefSection() {
  const l = useL()
  const [field, setField] = useState<string | null>(null)
  const partial: Brief = { audience: 'women', guests: null, date: null, budget: null }
  const noBudgetCap: Brief = { ...STORY_BRIEF, budget: { min: { fils: 35000000, currency: 'KWD' }, max: null } }
  const manyAreas = { ...STORY_BRIEF, governorateIds: ['capital', 'hawalli', 'farwaniya', 'ahmadi'] }
  return (
    <Section
      id="brief"
      title={l('The brief', 'تفاصيل زفافكم')}
      note={l(
        'Home is a structured card with four rows of 64 and one gold action showing a live count. Everywhere else the brief is a typeset sentence, read-only, one 44+ target that opens the edit sheet; in the sheet each of the four decisions is underlined in gold and tappable.',
        'الرئيسية بطاقة منظّمة من أربعة صفوف بارتفاع 64 وإجراء ذهبي واحد بعدد حي. وفي بقية الشاشات تفاصيل الزفاف جملة مصفوفة للقراءة فقط، هدف لمس واحد يفتح ورقة التعديل؛ وفي الورقة يُرسم تحت كل قرار من القرارات الأربعة خط ذهبي ويمكن لمسه.',
      )}
    >
      <Spec state={l('Brief card · filled · live count', 'بطاقة التفاصيل · معبأة · عدد حي')}>
        <BriefCard brief={STORY_BRIEF} count={38} onEdit={f => setField(f)} onShow={() => undefined} />
        <p className="gc-cap gz-t-caption">{field ? `→ ${field}` : ' '}</p>
      </Spec>
      <Spec state={l('Partly empty: muted placeholders, no count (offline) · open budget · four governorates', 'ناقصة: نصوص بديلة هادئة بلا عدد (دون اتصال) · ميزانية مفتوحة · أربع محافظات')}>
        <BriefCard brief={partial} count={null} />
        <BriefCard brief={noBudgetCap} count={null} />
        <BriefCard brief={manyAreas} count={12} />
      </Spec>
      <Spec state={l('Loading the count: the gold action draws its thread once', 'تحميل العدد: يرسم الزر الذهبي خيطه مرة واحدة')}>
        <BriefCard brief={STORY_BRIEF} count={38} loading />
      </Spec>
      <Spec state={l('Sentence · results header (display, up to three lines)', 'الجملة · رأس النتائج (خط العرض حتى ثلاثة أسطر)')}>
        <BriefSentence brief={STORY_BRIEF} variant="results" onEdit={() => undefined} />
      </Spec>
      <Spec state={l('Sentence · compare header (budget omitted) · booking header (budget and area omitted)', 'الجملة · رأس المقارنة (بلا ميزانية) · رأس الحجز (بلا ميزانية ومنطقة)')}>
        <BriefSentence brief={STORY_BRIEF} variant="compare" onEdit={() => undefined} />
        <BriefSentence brief={STORY_BRIEF} variant="booking" onEdit={() => undefined} />
      </Spec>
      <Spec state={l('Sentence · edit form in the Brief sheet: four underlined decisions, each 44 high', 'الجملة · نموذج التعديل في الورقة: أربعة قرارات تحتها خط، لكل منها 44')}>
        <BriefSentence brief={STORY_BRIEF} variant="edit" onEditField={f => setField(f)} />
        <BriefSentence brief={partial} variant="edit" />
      </Spec>
    </Section>
  )
}

const TILES: { en: string; ar: string; venue: string; types: string[] }[] = [
  { en: 'Hotel ballrooms', ar: 'قاعات الفنادق', venue: 'V01', types: ['hotel'] },
  { en: 'Palaces and halls', ar: 'القصور والقاعات', venue: 'V09', types: ['hall'] },
  { en: 'Outdoor and beach', ar: 'الهواء الطلق', venue: 'V03', types: ['outdoor', 'resort'] },
  { en: 'Villas and estates', ar: 'الفلل والعزب', venue: 'V04', types: ['villa'] },
  { en: 'Resorts', ar: 'المنتجعات', venue: 'V12', types: ['resort'] },
  { en: 'Convention centres', ar: 'مراكز المؤتمرات', venue: 'V08', types: ['convention'] },
]

export function CategoryTileSection() {
  const l = useL()
  const f = useFormat()
  const [sel, setSel] = useState<string | null>('V03')
  return (
    <Section
      id="category-tile"
      title={l('Category tiles', 'بلاطات التصنيفات')}
      note={l(
        'Six quick categories as photograph tiles, 4:5, radius 12. The name sits on one bottom scrim token in canvas text; the count under it comes from the formatter. No coloured chips, no icon grid.',
        'ستة تصنيفات سريعة كبلاطات صور بنسبة 4:5 وزوايا 12. يقع الاسم على تعتيم سفلي واحد بنص بلون الخلفية، والعدد تحته من المنسّق. لا شرائح ملوّنة ولا شبكة أيقونات.',
      )}
    >
      <Spec state={l('Over the photograph · two across · one selected', 'فوق الصورة · اثنتان في الصف · واحدة محددة')}>
        {[0, 2, 4].map(i => (
          <Row key={i}>
            {TILES.slice(i, i + 2).map(t => {
              const n = venues.filter(v => t.types.includes(v.type)).length
              return (
                <CategoryTile
                  key={t.venue}
                  label={l(t.en, t.ar)}
                  image={requireVenue(t.venue).cover?.file ?? null}
                  caption={f.plural(n, { '=1': l('1 hall', 'قاعة واحدة'), '=2': l('2 halls', 'قاعتان'), few: `{n} ${l('halls', 'قاعات')}`, other: `{n} ${l('halls', 'قاعة')}` })}
                  selected={sel === t.venue}
                  onOpen={() => setSel(sel === t.venue ? null : t.venue)}
                />
              )
            })}
          </Row>
        ))}
      </Spec>
      <Spec state={l('Wall-label form · no photograph · pressed · loading', 'صيغة اللوحة التعريفية · بلا صورة · الضغط · التحميل')}>
        <Row>
          <CategoryTile label={l('Hotel ballrooms', 'قاعات الفنادق')} image={requireVenue('V01').cover?.file ?? null} labelPlacement="under" caption={l('6 halls', '6 قاعات')} />
          <CategoryTile label={l('Government halls', 'القاعات الحكومية')} image={null} labelPlacement="under" caption={l('1 hall', 'قاعة واحدة')} />
          <CategoryTile label={l('Resorts', 'المنتجعات')} image={requireVenue('V12').cover?.file ?? null} previewState="pressed" />
        </Row>
        <Row>
          <CategoryTile label="" image={null} loading />
          <CategoryTile label="" image={null} loading labelPlacement="under" />
          <CategoryTile label="" image={null} loading />
        </Row>
      </Spec>
    </Section>
  )
}

export function OfferSection() {
  const l = useL()
  const byId = (id: string) => {
    const o = voucherWindows.find(x => x.id === id)
    if (!o) throw new Error(id)
    return o
  }
  const live = voucherWindows.filter(x => x.status === 'active')
  const ended = voucherWindows.find(x => x.status === 'ended')
  const scheduled = voucherWindows.find(x => x.status === 'scheduled')
  return (
    <Section
      id="offer-card"
      title={l('Voucher price window', 'بطاقة سعر الكوبون')}
      note={l(
        'The rose panel: voucher-price drops and quiet notes only. The lower voucher rate with its unit, the venue’s own title in the serif, the conditions as plain facts. There is no coupon code (the voucher is the code). An ended or scheduled window is muted and has no action; there is never a countdown or a scarcity line.',
        'اللوحة الوردية: لتخفيضات سعر الكوبون والملاحظات الهادئة فقط. سعر الكوبون الأقل بوحدته وعنوان المكان بالخط ذي الزوائد والشروط كحقائق واضحة. لا يوجد رمز كوبون (الكوبون نفسه هو الرمز). النافذة المنتهية أو المجدولة باهتة بلا إجراء؛ ولا عدّاد ولا عبارة ندرة أبدًا.',
      )}
    >
      <Spec state={l('Per guest · weekdays and event window', 'للضيف · أيام الأسبوع ونافذة المناسبات')}>
        {live[0] ? <VoucherWindowCard window={live[0]} onOpen={() => undefined} /> : null}
      </Spec>
      <Spec state={l('Another venue · another rate', 'مكان آخر · سعر آخر')}>
        {live[1] ? <VoucherWindowCard window={live[1]} onOpen={() => undefined} /> : null}
        {live[2] ? <VoucherWindowCard window={live[2]} onOpen={() => undefined} /> : null}
      </Spec>
      <Spec state={l('Ended · scheduled · pressed · loading', 'منتهية · مجدولة · الضغط · التحميل')}>
        {ended ? <VoucherWindowCard window={ended} /> : null}
        {scheduled ? <VoucherWindowCard window={scheduled} /> : null}
        {live[0] ? <VoucherWindowCard window={byId(live[0].id)} previewState="pressed" /> : null}
        {live[0] ? <VoucherWindowCard window={live[0]} loading /> : null}
      </Spec>
    </Section>
  )
}

export function CountdownSection() {
  const l = useL()
  const booking = heroBookingAs('confirmed')
  const days = daysToWedding()
  const where = `${requireVenue(booking.venueId ?? 'V01').name[l('en', 'ar')]}`
  const date = weddingProfile.weddingDate
  const rows: { days: number; note: [string, string]; progress?: number }[] = [
    { days: 365, note: ['A year to go (365)', 'سنة (365)'], progress: 0.04 },
    { days: 180, note: ['Six months (180)', 'ستة أشهر (180)'], progress: 0.5 },
    { days, note: ['Plain count · the story, 63 days', 'عدّ عادي · القصة 63 يومًا'], progress: 0.83 },
    { days: 30, note: ['One month (30)', 'شهر (30)'], progress: 0.9 },
    { days: 7, note: ['One week (7): guest count locks', 'أسبوع (7): تثبيت عدد الضيوف'], progress: 0.97 },
    { days: 1, note: ['Tomorrow', 'غدًا'], progress: 0.99 },
    { days: 0, note: ['Today', 'اليوم'], progress: 1 },
  ]
  return (
    <Section
      id="countdown"
      title={l('Countdown card', 'بطاقة العدّ التنازلي')}
      note={l(
        'The one ink panel of the screen. Whole days only: the serif numeral, the unit, one calm sentence that changes at 365, 180, 30, 7, tomorrow and today, and a gold thread showing how much of the wait has passed.',
        'اللوحة الداكنة الوحيدة في الشاشة. أيام كاملة فقط: الرقم بالخط ذي الزوائد والوحدة وجملة هادئة تتغير عند 365 و180 و30 و7 وغدًا واليوم، وخيط ذهبي يبيّن ما انقضى من الانتظار.',
      )}
    >
      {rows.map(r => (
        <Spec key={r.days} state={l(...r.note)}>
          <CountdownCard days={r.days} eventDate={date} where={where} progress={r.progress} actionLabel={r.days > 7 ? l('View your booking', 'عرض حجزكم') : l('Open the day plan', 'فتح خطة اليوم')} onAction={() => undefined} />
        </Spec>
      ))}
      <Spec state={l('Loading', 'التحميل')}>
        <CountdownCard days={days} eventDate={date} loading />
      </Spec>
    </Section>
  )
}
