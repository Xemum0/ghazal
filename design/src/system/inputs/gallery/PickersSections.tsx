import { useMemo, useState } from 'react'
import { useFormat, useT } from '../../../i18n'
import { Calendar, type CalendarDayInfo, type DateRange } from '../Calendar'
import { DateField } from '../DateField'
import { SelectRow, type SelectOption } from '../SelectRow'
import { TimeSlotPicker, type TimeSession } from '../TimeSlotPicker'
import { Figures } from '../internal/Figures'
import { addDaysIso, weekdayOfIso } from '../internal/calendarModel'
import { L, Section, Spec, useGalleryLang } from './kit'

/** Fils per guest: Sunday to Wednesday 47, Thursday to Saturday 49 (ADR 0002 example prices). */
const WEEKDAY = 47000
const WEEKEND = 49000

/** January 2027 as the hotel would publish it: a few booked, held and blocked dates, per-day prices. */
function january2027(): Record<string, CalendarDayInfo> {
  const booked = ['2027-01-07', '2027-01-16', '2027-01-23', '2027-01-30', '2027-01-09']
  const held = ['2027-01-15', '2027-01-21']
  const blocked = ['2027-01-22', '2027-01-27']
  const out: Record<string, CalendarDayInfo> = {}
  for (let d = 1; d <= 31; d++) {
    const iso = `2027-01-${String(d).padStart(2, '0')}`
    const wd = weekdayOfIso(iso)
    const status = booked.includes(iso) ? 'booked' : held.includes(iso) ? 'held' : blocked.includes(iso) ? 'blocked' : 'available'
    out[iso] = { status, price: wd >= 4 ? WEEKEND : WEEKDAY }
  }
  return out
}

export function CalendarSection() {
  const { lang } = useGalleryLang()
  const f = useFormat()
  const t = useT('common')
  const days = useMemo(january2027, [])
  const today = f.isoDay(f.now())
  const [range, setRange] = useState<DateRange>({ start: '2027-01-03', end: '2027-01-06' })
  const basis = `${f.moneyParts(WEEKEND).currency} · ${t('commonUnitPerGuest')}`
  return (
    <Section
      id="calendar"
      title={L(lang, 'Calendar', 'التقويم')}
      note={L(
        lang,
        'Sunday-first, seven flex columns, cells 52 high and 44 wide at least. The Thursday to Saturday band is one block at the inline-end edge in both languages. Booked is struck, blocked is struck in a box, held carries a gold-700 bead, today an ink hairline, the chosen day the one gold fill.',
        'يبدأ الأسبوع بالأحد في سبعة أعمدة، والخلية بارتفاع 52 وعرض لا يقل عن 44. تشكّل أيام الخميس إلى السبت كتلة واحدة عند حافة النهاية في اللغتين. المحجوز مشطوب، والمغلق مشطوب داخل إطار، والمعلّق عليه خرزة ذهبية داكنة، واليوم بخط داكن، واليوم المختار هو التعبئة الذهبية الوحيدة.',
      )}
    >
      <Spec state={L(lang, 'Availability, one date chosen', 'التوفر، تاريخ واحد مختار')} wide>
        <Calendar
          label={L(lang, 'Wedding date', 'تاريخ الزفاف')}
          days={days}
          defaultValue="2027-01-14"
          defaultMonth={{ year: 2027, month: 1 }}
          minDate={today}
          summary
          priceBasis={basis}
        />
      </Spec>
      <Spec state={L(lang, 'Prices view', 'عرض الأسعار')} wide>
        <Calendar
          label={L(lang, 'Wedding date', 'تاريخ الزفاف')}
          days={days}
          defaultValue="2027-01-14"
          defaultMonth={{ year: 2027, month: 1 }}
          defaultView="prices"
          minDate={today}
          priceBasis={basis}
        />
      </Spec>
      <Spec state={L(lang, 'Range, the thread joins the ends', 'نطاق، الخيط يصل بين الطرفين')} wide>
        <Calendar
          mode="range"
          label={L(lang, 'Block dates', 'إغلاق التواريخ')}
          days={days}
          value={range}
          onChange={setRange}
          defaultMonth={{ year: 2027, month: 1 }}
          summary
          legend={false}
        />
      </Spec>
      <Spec state={L(lang, 'Today, past dates and the first selectable month', 'اليوم والتواريخ السابقة وأول شهر قابل للاختيار')} wide>
        <Calendar
          label={L(lang, 'Wedding date', 'تاريخ الزفاف')}
          defaultMonth={{ year: 2026, month: 11 }}
          minDate={today}
          days={{ '2026-11-14': { status: 'booked' }, '2026-11-20': { status: 'held' }, '2026-11-26': { status: 'blocked' } }}
        />
      </Spec>
    </Section>
  )
}

export function SlotsSection() {
  const { lang } = useGalleryLang()
  const f = useFormat()
  const sessions = (evening: TimeSession['status'], full: TimeSession['status']): TimeSession[] => [
    { id: 'afternoon', label: L(lang, 'Afternoon', 'العصر'), start: { h: 12, m: 0 }, end: { h: 16, m: 0 }, price: 38000 },
    { id: 'evening', label: L(lang, 'Evening', 'المساء'), start: { h: 21, m: 0 }, end: { h: 2, m: 0 }, price: 49000, status: evening },
    { id: 'full', label: L(lang, 'Full day', 'يوم كامل'), start: { h: 12, m: 0 }, end: { h: 2, m: 0 }, price: 72000, status: full },
  ]
  const unit = L(lang, 'per guest', 'للضيف')
  return (
    <Section
      id="slots"
      title={L(lang, 'Sessions', 'الفترات')}
      note={L(lang, 'Afternoon, Evening and Full day (ADR 0002). Shown only when more than one session is free. A session that ends after midnight belongs to its start date.', 'العصر والمساء ويوم كامل. تظهر فقط عند توفر أكثر من فترة. الفترة التي تنتهي بعد منتصف الليل تتبع تاريخ بدايتها.')}
    >
      <Spec state={L(lang, 'All free, one chosen', 'كلها متاحة، واحدة مختارة')}>
        <TimeSlotPicker sessions={sessions('available', 'available')} defaultValue="evening" date="2027-01-14" priceUnit={unit} />
      </Spec>
      <Spec state={L(lang, 'Held and booked', 'معلّقة ومحجوزة')}>
        <TimeSlotPicker sessions={sessions('held', 'booked')} defaultValue="afternoon" date="2027-01-14" priceUnit={unit} />
      </Spec>
      <Spec state={L(lang, 'Nothing chosen yet', 'لم يتم الاختيار بعد')}>
        <TimeSlotPicker sessions={sessions('available', 'available')} date="2027-01-14" priceUnit={unit} />
      </Spec>
      <Spec state={L(lang, 'Disabled', 'معطل')}>
        <TimeSlotPicker sessions={sessions('available', 'available')} date="2027-01-14" disabled />
      </Spec>
      <p className="gz-t-caption ig-out">
        <Figures text={f.timeRange(f.kuwaitDate(2027, 1, 14, 21, 0), f.kuwaitDate(2027, 1, 15, 2, 0))} />
      </p>
    </Section>
  )
}

export function SelectSection() {
  const { lang } = useGalleryLang()
  const areas: SelectOption<string>[] = [
    { value: 'salmiya', label: L(lang, 'Salmiya', 'السالمية'), description: L(lang, 'Hawalli', 'حولي'), aliases: 'Salmiyah' },
    { value: 'hawalli', label: L(lang, 'Hawalli', 'حولي'), description: L(lang, 'Hawalli', 'حولي') },
    { value: 'jabriya', label: L(lang, 'Jabriya', 'الجابرية'), description: L(lang, 'Hawalli', 'حولي') },
    { value: 'mishref', label: L(lang, 'Mishref', 'مشرف'), description: L(lang, 'Hawalli', 'حولي'), aliases: 'Mishrif Meshref' },
    { value: 'shuwaikh', label: L(lang, 'Shuwaikh', 'الشويخ'), description: L(lang, 'Capital', 'العاصمة') },
    { value: 'bneid', label: L(lang, 'Bneid Al-Qar', 'بنيد القار'), description: L(lang, 'Capital', 'العاصمة'), aliases: 'Bnaid Al-Gar' },
    { value: 'fahaheel', label: L(lang, 'Fahaheel', 'الفحيحيل'), description: L(lang, 'Ahmadi', 'الأحمدي') },
    { value: 'jahra', label: L(lang, 'Jahra', 'الجهراء'), description: L(lang, 'Jahra', 'الجهراء'), disabled: true },
  ]
  const halls: SelectOption<string>[] = [
    { value: 'danah', label: L(lang, 'Danah Ballroom', 'قاعة دانة'), description: L(lang, 'Up to 650 guests', 'حتى 650 ضيفًا') },
    { value: 'majlis', label: L(lang, 'Majlis Hall', 'قاعة المجلس'), description: L(lang, 'Up to 300 guests', 'حتى 300 ضيف') },
  ]
  const [single, setSingle] = useState<string | null>('salmiya')
  const [multi, setMulti] = useState<string[]>(['salmiya', 'mishref'])
  return (
    <Section
      id="select"
      title={L(lang, 'Pickers', 'حقول الاختيار')}
      note={L(lang, 'No native select: a button opens a sheet with a listbox. The field variant is for forms, the row variant for the Home brief card. Search understands Arabic spelling variants and aliases.', 'لا توجد قائمة منسدلة أصلية: زر يفتح ورقة سفلية تحتوي القائمة. يصلح الحقل للنماذج ويصلح الصف لبطاقة الطلب في الرئيسية. يتجاوز البحث اختلافات الإملاء ويدعم الأسماء البديلة.')}
    >
      <Spec state={L(lang, 'Field, empty', 'حقل، فارغ')}>
        <SelectRow label={L(lang, 'Area', 'المنطقة')} placeholder={L(lang, 'Choose an area', 'اختر المنطقة')} options={areas} searchable sheetTitle={L(lang, 'Area', 'المنطقة')} helper={L(lang, 'Where the venue is.', 'موقع المكان.')} />
      </Spec>
      <Spec state={L(lang, 'Field, filled', 'حقل، معبأ')}>
        <SelectRow label={L(lang, 'Area', 'المنطقة')} options={areas} value={single} onChange={setSingle} searchable sheetTitle={L(lang, 'Area', 'المنطقة')} />
      </Spec>
      <Spec state={L(lang, 'Field, multiple', 'حقل، متعدد')}>
        <SelectRow selection="multiple" label={L(lang, 'Areas', 'المناطق')} options={areas} value={multi} onChange={setMulti} searchable sheetTitle={L(lang, 'Areas', 'المناطق')} />
      </Spec>
      <Spec state={L(lang, 'Field, focus', 'حقل، تركيز')}>
        <SelectRow label={L(lang, 'Area', 'المنطقة')} options={areas} defaultValue="mishref" forceFocus />
      </Spec>
      <Spec state={L(lang, 'Field, error', 'حقل، خطأ')}>
        <SelectRow label={L(lang, 'Area', 'المنطقة')} placeholder={L(lang, 'Choose an area', 'اختر المنطقة')} options={areas} error={L(lang, 'Choose an area to see halls.', 'اختر منطقة لعرض القاعات.')} />
      </Spec>
      <Spec state={L(lang, 'Field, disabled', 'حقل، معطل')}>
        <SelectRow label={L(lang, 'Hall', 'القاعة')} options={halls} defaultValue="danah" disabled disabledReason={L(lang, 'This hotel has one hall.', 'هذا الفندق فيه قاعة واحدة.')} />
      </Spec>
      <Spec state={L(lang, 'Rows in a brief card', 'صفوف في بطاقة الطلب')} wide>
        <div className="ig-card">
          <SelectRow variant="row" divider label={L(lang, 'Area', 'المنطقة')} options={areas} value={single} onChange={setSingle} searchable sheetTitle={L(lang, 'Area', 'المنطقة')} />
          <SelectRow variant="row" divider label={L(lang, 'Hall', 'القاعة')} placeholder={L(lang, 'Not decided', 'لم يتحدد بعد')} options={halls} />
          <SelectRow variant="row" label={L(lang, 'Hall', 'القاعة')} options={halls} defaultValue="majlis" disabled />
        </div>
      </Spec>
    </Section>
  )
}

export function DateFieldSection() {
  const { lang } = useGalleryLang()
  const f = useFormat()
  const days = useMemo(january2027, [])
  const today = f.isoDay(f.now())
  const basis = `${f.moneyParts(WEEKEND).currency} · ${L(lang, 'per guest', 'للضيف')}`
  const [d, setD] = useState<string | null>('2027-01-14')
  const [r, setR] = useState<DateRange>({ start: addDaysIso('2027-01-03', 0), end: '2027-01-06' })
  return (
    <Section
      id="datefield"
      title={L(lang, 'Date field', 'حقل التاريخ')}
      note={L(lang, 'Opens the calendar in a sheet (no native date input). Confirm commits, closing discards. In Arabic the summary adds the Hijri line.', 'يفتح التقويم في ورقة سفلية بلا حقل تاريخ أصلي. التأكيد يحفظ الاختيار والإغلاق يلغيه. في العربية يضيف الملخص سطر التاريخ الهجري.')}
    >
      <Spec state={L(lang, 'Empty', 'فارغ')}>
        <DateField label={L(lang, 'Wedding date', 'تاريخ الزفاف')} days={days} minDate={today} defaultView="prices" priceBasis={basis} helper={L(lang, 'Gregorian dates, Kuwait time.', 'تواريخ ميلادية بتوقيت الكويت.')} />
      </Spec>
      <Spec state={L(lang, 'Filled', 'معبأ')}>
        <DateField label={L(lang, 'Wedding date', 'تاريخ الزفاف')} days={days} minDate={today} value={d} onChange={setD} priceBasis={basis} />
      </Spec>
      <Spec state={L(lang, 'Range', 'نطاق')}>
        <DateField mode="range" label={L(lang, 'Blocked dates', 'التواريخ المغلقة')} days={days} value={r} onChange={setR} />
      </Spec>
      <Spec state={L(lang, 'Focus', 'تركيز')}>
        <DateField label={L(lang, 'Wedding date', 'تاريخ الزفاف')} days={days} minDate={today} defaultValue="2027-01-14" forceFocus />
      </Spec>
      <Spec state={L(lang, 'Error', 'خطأ')}>
        <DateField label={L(lang, 'Wedding date', 'تاريخ الزفاف')} days={days} minDate={today} error={L(lang, 'Choose a date to continue.', 'اختر تاريخًا للمتابعة.')} />
      </Spec>
      <Spec state={L(lang, 'Disabled', 'معطل')}>
        <DateField label={L(lang, 'Wedding date', 'تاريخ الزفاف')} defaultValue="2027-01-14" disabled disabledReason={L(lang, 'Fixed once the hotel approves.', 'يتعذر التعديل بعد موافقة الفندق.')} />
      </Spec>
    </Section>
  )
}
