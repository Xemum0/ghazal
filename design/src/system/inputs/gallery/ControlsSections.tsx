import { useState } from 'react'
import { useFormat } from '../../../i18n'
import { ChipGroup } from '../ChipGroup'
import { RangeSlider } from '../RangeSlider'
import { SegmentedControl } from '../SegmentedControl'
import { Stepper } from '../Stepper'
import { Tabs } from '../Tabs'
import { ToggleRow } from '../Toggle'
import { Figures } from '../internal/Figures'
import { Kd, L, Section, Spec, useGalleryLang } from './kit'

const PRESETS = [100, 150, 200, 300, 400, 500, 650, 800, 1000] as const

export function StepperSection() {
  const { lang } = useGalleryLang()
  const f = useFormat()
  const [guests, setGuests] = useState(350)
  return (
    <Section
      id="stepper"
      title={L(lang, 'Guests: stepper and presets', 'عدد المعازيم: العداد والقيم الجاهزة')}
      note={L(lang, 'A stepper by the package step plus preset chips (ADR 0012 D9). 44 px buttons, press and hold repeats, limits disable the button.', 'عداد بخطوة الباقة مع قيم جاهزة. أزرار بحجم 44، والضغط المطوّل يكرر الخطوة، وعند الحد يتعطل الزر.')}
    >
      <Spec state={L(lang, 'Filled, step 50', 'معبأ، الخطوة 50')} wide>
        <Stepper
          label={L(lang, 'Guests in this hall', 'المعازيم في هذه القاعة')}
          caption={<Figures text={f.minGuests(200)} />}
          value={guests}
          onChange={setGuests}
          min={100}
          max={1500}
          step={50}
          valueText={n => f.plain(f.guests(n))}
        />
        <ChipGroup<number>
          label={L(lang, 'Preset guest counts', 'أعداد جاهزة')}
          layout="wrap"
          value={(PRESETS as readonly number[]).includes(guests) ? guests : null}
          onChange={v => v !== null && setGuests(v)}
          options={PRESETS.map(n => ({
            value: n,
            label: <Figures text={`${f.integer(n)}${n === 1000 ? '+' : ''}`} />,
          }))}
        />
      </Spec>
      <Spec state={L(lang, 'At the minimum', 'عند الحد الأدنى')}>
        <Stepper label={L(lang, 'Guests', 'المعازيم')} defaultValue={100} min={100} max={1500} step={50} />
      </Spec>
      <Spec state={L(lang, 'Disabled', 'معطل')}>
        <Stepper label={L(lang, 'Guests', 'المعازيم')} defaultValue={350} min={100} max={1500} step={50} disabled />
      </Spec>
    </Section>
  )
}

export function RangeSection() {
  const { lang } = useGalleryLang()
  const f = useFormat()
  const [band, setBand] = useState<[number, number]>([20000, 35000])
  const say = (n: number) => f.plain(f.money(n * 1000, { mode: 'browse' }))
  return (
    <Section
      id="range"
      title={L(lang, 'Budget range', 'نطاق الميزانية')}
      note={L(lang, 'Handles mirror with the language: the minimum sits at the start edge. Value labels use the figures voice and keep the currency left of the number.', 'تنعكس المقابض مع اللغة فيقع الحد الأدنى عند حافة البداية. تظهر القيم بخط الأرقام وتبقى العملة على يسار الرقم.')}
    >
      <Spec state={L(lang, 'Filled', 'معبأ')} wide>
        <RangeSlider
          label={L(lang, 'Venue and catering budget', 'ميزانية القاعة والضيافة')}
          min={5000}
          max={50000}
          step={500}
          value={band}
          onChange={setBand}
          captions={[L(lang, 'From', 'من'), L(lang, 'To', 'إلى')]}
          thumbLabels={[L(lang, 'Lowest budget', 'أقل ميزانية'), L(lang, 'Highest budget', 'أعلى ميزانية')]}
          formatValue={n => <Kd kd={n} />}
          valueText={say}
          edgeLabels={[<Kd key="a" kd={5000} />, <Kd key="b" kd={50000} plus />]}
        />
      </Spec>
      <Spec state={L(lang, 'Narrow band', 'نطاق ضيق')}>
        <RangeSlider
          label={L(lang, 'Budget', 'الميزانية')}
          min={5000}
          max={50000}
          step={500}
          defaultValue={[10000, 12500]}
          captions={null}
          formatValue={n => <Kd kd={n} />}
          valueText={say}
        />
      </Spec>
      <Spec state={L(lang, 'Disabled', 'معطل')}>
        <RangeSlider
          label={L(lang, 'Budget', 'الميزانية')}
          min={5000}
          max={50000}
          step={500}
          defaultValue={[20000, 35000]}
          disabled
          captions={null}
          formatValue={n => <Kd kd={n} />}
          valueText={say}
        />
      </Spec>
    </Section>
  )
}

export function SegmentedSection() {
  const { lang } = useGalleryLang()
  return (
    <Section
      id="segmented"
      title={L(lang, 'Segmented control and tabs', 'التبديل بين الخيارات والتبويبات')}
      note={L(lang, 'The selected option is an ink pill with a gold thread that slides over 320 ms, signed by the direction. Tabs carry the thread on a hairline baseline.', 'الخيار المحدد قرص داكن بخيط ذهبي ينزلق خلال 320 ملّي ثانية باتجاه اللغة. أما التبويبات فيمر الخيط فيها على خط أساس رفيع.')}
    >
      <Spec state={L(lang, 'Availability | Prices', 'التوفر | الأسعار')}>
        <SegmentedControl
          label={L(lang, 'Calendar view', 'عرض التقويم')}
          defaultValue="availability"
          options={[
            { value: 'availability', label: L(lang, 'Availability', 'التوفر') },
            { value: 'prices', label: L(lang, 'Prices', 'الأسعار') },
          ]}
        />
      </Spec>
      <Spec state={L(lang, 'Hall (display face)', 'القاعة (الخط الزخرفي)')}>
        <SegmentedControl
          label={L(lang, 'Hall', 'القاعة')}
          face="hall"
          defaultValue="danah"
          options={[
            { value: 'danah', label: L(lang, 'Danah Ballroom', 'قاعة دانة') },
            { value: 'majlis', label: L(lang, 'Majlis Hall', 'قاعة المجلس') },
          ]}
        />
      </Spec>
      <Spec state={L(lang, 'Three options', 'ثلاثة خيارات')}>
        <SegmentedControl
          label={L(lang, 'Session', 'الفترة')}
          defaultValue="evening"
          options={[
            { value: 'afternoon', label: L(lang, 'Afternoon', 'عصرًا') },
            { value: 'evening', label: L(lang, 'Evening', 'مساءً') },
            { value: 'full', label: L(lang, 'Full day', 'يوم كامل') },
          ]}
        />
      </Spec>
      <Spec state={L(lang, 'Disabled', 'معطل')}>
        <SegmentedControl
          label={L(lang, 'Calendar view', 'عرض التقويم')}
          defaultValue="availability"
          disabled
          options={[
            { value: 'availability', label: L(lang, 'Availability', 'التوفر') },
            { value: 'prices', label: L(lang, 'Prices', 'الأسعار') },
          ]}
        />
      </Spec>
      <Spec state={L(lang, 'Tabs, equal width', 'تبويبات متساوية')} wide>
        <TabsDemo />
      </Spec>
      <Spec state={L(lang, 'Tabs, hugging and scrolling', 'تبويبات بحجم النص')} wide>
        <Tabs
          label={L(lang, 'Bookings', 'الحجوزات')}
          layout="hug"
          defaultValue="all"
          items={[
            { value: 'all', label: L(lang, 'All', 'الكل') },
            { value: 'pending', label: L(lang, 'Pending', 'قيد الانتظار') },
            { value: 'approved', label: L(lang, 'Approved', 'تمت الموافقة') },
            { value: 'confirmed', label: L(lang, 'Confirmed', 'مؤكدة') },
            { value: 'past', label: L(lang, 'Past', 'السابقة'), disabled: true },
          ]}
        />
      </Spec>
    </Section>
  )
}

function TabsDemo() {
  const { lang } = useGalleryLang()
  const f = useFormat()
  return (
    <Tabs
      label={L(lang, 'Venue sections', 'أقسام المكان')}
      defaultValue="about"
      items={[
        { value: 'about', label: L(lang, 'About', 'نبذة') },
        { value: 'halls', label: L(lang, 'Halls', 'القاعات'), count: f.plain(f.integer(3)) },
        { value: 'reviews', label: L(lang, 'Reviews', 'التقييمات'), count: f.plain(f.integer(128)) },
      ]}
    />
  )
}

export function ChipsSection() {
  const { lang } = useGalleryLang()
  const f = useFormat()
  const bands: Array<[string, number, number | null]> = [
    ['u5', 0, 5000],
    ['5-10', 5000, 10000],
    ['10-20', 10000, 20000],
    ['20-35', 20000, 35000],
    ['35+', 35000, null],
  ]
  return (
    <Section
      id="chips"
      title={L(lang, 'Choice chips', 'شرائح الاختيار')}
      note={L(lang, 'Single choice is a radio group, multiple choice a set of toggles. Selected = ink border and the gold bead, never a gold fill.', 'الاختيار الواحد مجموعة اختيار مفردة، والمتعدد مجموعة أزرار تبديل. المحدد بإطار داكن وخرزة ذهبية، ولا تعبئة ذهبية أبدًا.')}
    >
      <Spec state={L(lang, 'Single', 'اختيار واحد')} wide>
        <ChipGroup<string>
          label={L(lang, 'Budget band', 'نطاق الميزانية')}
          defaultValue="20-35"
          options={bands.map(([value, lo, hi]) => ({
            value,
            label:
              hi === null ? (
                <Figures text={`${f.integer(lo)}+`} />
              ) : lo === 0 ? (
                <Figures text={L(lang, `Under ${f.integer(hi)}`, `أقل من ${f.integer(hi)}`)} />
              ) : (
                <Figures text={f.numberRange(lo, hi)} />
              ),
          }))}
        />
      </Spec>
      <Spec state={L(lang, 'Multiple', 'اختيار متعدد')} wide>
        <ChipGroup<string>
          selection="multiple"
          label={L(lang, 'Audience', 'نوع الحفل')}
          defaultValue={['women']}
          options={[
            { value: 'women', label: L(lang, 'Ladies’ reception', 'الحفل النسائي') },
            { value: 'men', label: L(lang, 'Men’s reception', 'الحفل الرجالي') },
            { value: 'mixed', label: L(lang, 'Mixed', 'مختلط') },
          ]}
        />
      </Spec>
      <Spec state={L(lang, 'Rail with a disabled chip', 'شريط أفقي مع شريحة معطلة')} wide>
        <ChipGroup<string>
          label={L(lang, 'Area', 'المنطقة')}
          layout="rail"
          defaultValue="salmiya"
          options={[
            { value: 'salmiya', label: L(lang, 'Salmiya', 'السالمية') },
            { value: 'hawalli', label: L(lang, 'Hawalli', 'حولي') },
            { value: 'mishref', label: L(lang, 'Mishref', 'مشرف') },
            { value: 'jabriya', label: L(lang, 'Jabriya', 'الجابرية'), disabled: true },
            { value: 'shuwaikh', label: L(lang, 'Shuwaikh', 'الشويخ') },
          ]}
        />
      </Spec>
    </Section>
  )
}

export function TogglesSection() {
  const { lang } = useGalleryLang()
  return (
    <Section
      id="toggles"
      title={L(lang, 'Toggle rows', 'صفوف التبديل')}
      note={L(lang, 'The whole row is the target; the switch is ink with a check, never gold.', 'الصف كله قابل للنقر، والمفتاح داكن مع علامة صح ولا يستخدم الذهبي أبدًا.')}
    >
      <Spec state={L(lang, 'On', 'مفعّل')}>
        <ToggleRow title={L(lang, 'Booking updates', 'تحديثات الحجز')} description={L(lang, 'When the hotel replies or a payment is due.', 'عند رد الفندق أو استحقاق دفعة.')} defaultChecked />
      </Spec>
      <Spec state={L(lang, 'Off', 'متوقف')}>
        <ToggleRow title={L(lang, 'Offers and news', 'العروض والأخبار')} description={L(lang, 'At most one message a week.', 'رسالة واحدة كحد أقصى في الأسبوع.')} />
      </Spec>
      <Spec state={L(lang, 'Disabled with a reason', 'معطل مع السبب')}>
        <ToggleRow title={L(lang, 'Payment reminders', 'تذكيرات الدفع')} defaultChecked disabled disabledReason={L(lang, 'Always on while a payment is due.', 'تبقى مفعّلة ما دامت هناك دفعة مستحقة.')} />
      </Spec>
    </Section>
  )
}
