// Gallery: the compare tray, the range bar and the Compare table (thirds, Best in row, Differences only, labelled action bar).
import { useState } from 'react'
import { compareSet, getArea, venues, type CompareColumn } from '../../../mock'
import { BestInRow, CompareActionBar, CompareHeader, RangeBar } from '../CompareParts'
import { CompareTable } from '../CompareTable'
import { CompareTray } from '../CompareTray'
import { useBi } from '../bits'
import { Section, Spec, STORY_BRIEF, useL } from './kit'

const venueOf = (id: string) => {
  const v = venues.find(x => x.id === id)
  if (!v) throw new Error(id)
  return v
}

export function CompareTraySection() {
  const l = useL()
  const [ids, setIds] = useState(['V01', 'V05'])
  const [collapsed, setCollapsed] = useState(false)
  const pool = ['V01', 'V05', 'V07', 'V09']
  return (
    <Section
      id="compare-tray"
      title={l('Compare tray', 'شريط المقارنة')}
      note={l(
        'Floating, never nagging: it appears after the first add, says "Add one more" with hairline empty slots, becomes actionable at two, holds three at most, and collapses to a 44 capsule when idle. Try Add and Remove: the new slot settles in.',
        'عائم دون إزعاج: يظهر بعد أول إضافة، ويقول «أضيفوا قاعة أخرى» مع خانات فارغة بخط رفيع، ويصبح قابلًا للاستخدام عند قاعتين، ويتسع لثلاث كحد أقصى، وينكمش إلى كبسولة 44 عند الخمول. جرّبوا الإضافة والإزالة: تستقر الخانة الجديدة بحركة قصيرة.',
      )}
    >
      <Spec state={l('Interactive · tap the slot x to remove, the buttons to add', 'تفاعلي · المسوا × للإزالة والأزرار للإضافة')}>
        <CompareTray venues={ids.map(venueOf)} collapsed={collapsed} onRemove={id => setIds(ids.filter(x => x !== id))} onClear={() => setIds([])} onExpand={() => setCollapsed(false)} onOpen={() => setCollapsed(true)} />
        <div className="gc-row gc-row--wrap">
          {pool.map(id => (
            <button key={id} type="button" className="gz-reset gc-pill" disabled={ids.includes(id) || ids.length >= 3} onClick={() => setIds([...ids, id])}>
              + {id}
            </button>
          ))}
        </div>
      </Spec>
      <Spec state={l('One hall: "Add one more", nothing actionable', 'قاعة واحدة: «أضيفوا قاعة أخرى» دون إجراء')}>
        <CompareTray venues={[venueOf('V01')]} />
      </Spec>
      <Spec state={l('Two and three halls: "Compare (n/3)"', 'قاعتان وثلاث: «مقارنة (n/3)»')}>
        <CompareTray venues={[venueOf('V01'), venueOf('V05')]} />
        <CompareTray venues={[venueOf('V01'), venueOf('V05'), venueOf('V07')]} />
      </Spec>
      <Spec state={l('Collapsed to the idle capsule', 'منكمش إلى كبسولة الخمول')}>
        <CompareTray venues={[venueOf('V01'), venueOf('V05')]} collapsed />
      </Spec>
    </Section>
  )
}

export function CompareTableSection() {
  const l = useL()
  const bi = useBi()
  const [diff, setDiff] = useState(true)
  const [picked, setPicked] = useState<string | null>(null)
  const story = compareSet(['V01', 'V05', 'V07'], STORY_BRIEF)
  const units: CompareColumn[] = compareSet(['V01', 'V04', 'V19'], STORY_BRIEF)
  const noDate = compareSet(['V01', 'V05', 'V09'], { ...STORY_BRIEF, date: null })
  const origin = getArea('salmiya')
  const originName = origin ? bi(origin.name) : ''
  return (
    <Section
      id="compare-table"
      title={l('Compare table', 'جدول المقارنة')}
      note={l(
        'Three fluid thirds with no label column and no sideways scroll (130 / 120 / 143 at 390 / 360 / 430). Labels sit above the values; objective rows carry a gold-ink bead and the words "Best in row"; range bars show price and capacity with an ink tick at your guests. Differences only is on by default and says how many rows it hides. A hall turns gold only after it is picked.',
        'ثلاثة أعمدة مرنة متساوية بلا عمود للعناوين وبلا تمرير جانبي (130 / 120 / 143 عند 390 / 360 / 430). تقع العناوين فوق القيم؛ وتحمل الصفوف الموضوعية خرزة ذهبية داكنة وعبارة «الأفضل في هذا الصف»؛ وتعرض أشرطة النطاق السعر والسعة مع علامة حبرية عند عدد ضيوفكم. «الفروقات فقط» مفعّلة افتراضيًا وتذكر عدد الصفوف المخفية. لا تتذهّب القاعة إلا بعد اختيارها.',
      )}
    >
      <Spec bleed state={l('Story: Aurelia, Lumi Marina and Jawharat (ladies, 350 guests, Thu 14 Jan)', 'القصة: أوريليا ولومي مارينا وجوهرة (نسائي، 350 ضيفًا، الخميس 14 يناير)')}>
        <CompareTable columns={story} brief={STORY_BRIEF} origin={originName} differencesOnly={diff} onDifferencesOnlyChange={setDiff} pickedId={picked} onAction={id => setPicked(id)} />
      </Spec>
      <Spec bleed state={l('Three price units: per guest, a flat night, the ministry rental fee (Official channel)', 'ثلاث وحدات سعر: للضيف وليلة ثابتة ورسوم الوزارة (القناة الرسمية)')}>
        <CompareTable columns={units} brief={STORY_BRIEF} origin={originName} differencesOnly={false} onDifferencesOnlyChange={() => undefined} />
      </Spec>
      <Spec bleed state={l('No date set: price rows say "From", availability says "Pick a date"', 'بلا تاريخ: صفوف السعر تقول «من» والتوفر يقول «اختاروا تاريخًا»')}>
        <CompareTable columns={noDate} brief={{ ...STORY_BRIEF, date: null }} origin={originName} differencesOnly={false} onDifferencesOnlyChange={() => undefined} />
      </Spec>
    </Section>
  )
}

export function ComparePartsSection() {
  const l = useL()
  const rail = [
    { value: 650, max: 650, mark: 350, label: l('Up to 650 guests', 'حتى 650 ضيفًا'), markLabel: l('your 350', 'عددكم 350') },
    { value: 300, max: 650, mark: 350, label: l('Up to 300 guests', 'حتى 300 ضيف'), markLabel: l('your 350', 'عددكم 350') },
    { value: 500, max: 650, label: l('Up to 500 guests', 'حتى 500 ضيف') },
  ]
  const header = ['V01', 'V05', 'V07'].map((id, i) => ({ venue: venueOf(id), badge: [l('Lowest price', 'الأقل سعرًا'), l('Best rated', 'الأعلى تقييمًا'), undefined][i] }))
  return (
    <Section
      id="compare-parts"
      title={l('Compare parts', 'أجزاء المقارنة')}
      note={l(
        'The pieces, for reuse by the planner package table: header (expanded 4:5 thumbs and collapsed to 40), range bars, the Best in row marker and the labelled action bar.',
        'الأجزاء لإعادة استخدامها في جدول باقات المخطط: الرأس (صور 4:5 وهو مطوي إلى 40) وأشرطة النطاق وعلامة «الأفضل في هذا الصف» وشريط الإجراءات المسمّى.',
      )}
    >
      <Spec bleed state={l('Header · expanded', 'الرأس · موسّع')}>
        <CompareHeader columns={header} onRemove={() => undefined} />
      </Spec>
      <Spec bleed state={l('Header · tap to open, a pick control (the second hall chosen), names up to four lines', 'الرأس · اللمس للفتح وعنصر اختيار (القاعة الثانية مختارة) وأسماء حتى أربعة أسطر')}>
        <CompareHeader columns={header} onOpen={() => undefined} onPick={() => undefined} pickedId={header[1]?.venue.id ?? null} nameLines={4} onRemove={() => undefined} />
      </Spec>
      <Spec bleed state={l('Header · collapsed on scroll (200 ms height tween in the screen)', 'الرأس · مطوي عند التمرير (تحريك الارتفاع 200 م.ث في الشاشة)')}>
        <CompareHeader columns={header} compact />
      </Spec>
      <Spec state={l('Range bars · capacity with the tick at your 350 · a hall below your count', 'أشرطة النطاق · السعة مع علامة عند 350 · قاعة أقل من عددكم')}>
        {[0, 1, 2].map(i => {
          const r = rail[i]!
          return <RangeBar key={i} value={r.value} max={r.max} mark={r.mark} markLabel={r.markLabel} label={r.label} />
        })}
      </Spec>
      <Spec state={l('Best in row', 'الأفضل في هذا الصف')}>
        <p className="gz-t-body-s">
          <BestInRow>
            <span className="gz-t-price-strong">18,200</span>
          </BestInRow>
        </p>
      </Spec>
      <Spec bleed state={l('Action bar · nothing picked (three equal secondaries)', 'شريط الإجراءات · لا اختيار (ثلاثة أزرار ثانوية متساوية)')}>
        <CompareActionBar
          columns={[
            { id: 'a', name: 'فندق أوريليا الخليج', kind: 'voucher', label: l('Get voucher', 'الحصول على كوبون') },
            { id: 'b', name: 'Lumi Marina Hotel', kind: 'dates', label: l('See dates', 'التواريخ') },
            { id: 'c', name: 'Government Hall', kind: 'official', label: l('Official', 'رسمي') },
          ]}
        />
      </Spec>
      <Spec bleed state={l('Action bar · the picked hall turns gold', 'شريط الإجراءات · القاعة المختارة تتذهّب')}>
        <CompareActionBar
          pickedId="a"
          columns={[
            { id: 'a', name: 'Aurelia Gulf Hotel', kind: 'voucher', label: l('Get voucher', 'الحصول على كوبون') },
            { id: 'b', name: 'Lumi Marina Hotel', kind: 'voucher', label: l('Get voucher', 'الحصول على كوبون') },
            { id: 'c', name: 'Madar Grand Hotel', kind: 'voucher', label: l('Get voucher', 'الحصول على كوبون') },
          ]}
        />
      </Spec>
    </Section>
  )
}
