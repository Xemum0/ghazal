// Gallery page for the inputs (design/src/system/inputs). Rendered at #/gallery/inputs?lang=en|ar.
// Optional `&only=fields,calendar` renders just those sections (used by the screenshot checks); no value renders all of them.
// Section files and the page CSS live next to the components in system/inputs/gallery.
import { useLang } from '../shell/lang'
import { useRoute } from '../shell/router'
import { L } from '../system/inputs/gallery/kit'
import { ChipsSection, RangeSection, SegmentedSection, StepperSection, TogglesSection } from '../system/inputs/gallery/ControlsSections'
import { OtpSection, PhoneSection, SearchSection, TextAreaSection, TextFieldsSection } from '../system/inputs/gallery/FieldsSections'
import { CalendarSection, DateFieldSection, SelectSection, SlotsSection } from '../system/inputs/gallery/PickersSections'

const SECTIONS = [
  ['fields', TextFieldsSection],
  ['phone', PhoneSection],
  ['otp', OtpSection],
  ['search', SearchSection],
  ['textarea', TextAreaSection],
  ['stepper', StepperSection],
  ['range', RangeSection],
  ['segmented', SegmentedSection],
  ['chips', ChipsSection],
  ['toggles', TogglesSection],
  ['select', SelectSection],
  ['calendar', CalendarSection],
  ['slots', SlotsSection],
  ['datefield', DateFieldSection],
] as const

export default function InputsGallery() {
  const { lang } = useLang()
  const only = useRoute().params.get('only')?.split(',').filter(Boolean)
  return (
    <div className="ig" data-gz="InputsGallery">
      {only ? null : (
        <header className="ig-hero">
          <p className="gz-t-label">{L(lang, 'Design system', 'نظام التصميم')}</p>
          <h1 className="gz-t-d3 ig-hero__title">{L(lang, 'Inputs', 'حقول الإدخال')}</h1>
          <p className="gz-t-body-s">
            {L(
              lang,
              'Fields, choices and pickers. Every state in both languages: empty, filled, focus, error, disabled. Phone numbers and money stay left to right inside Arabic screens.',
              'حقول وخيارات ومنتقيات. كل الحالات باللغتين: فارغ ومعبأ وتركيز وخطأ ومعطل. تبقى أرقام الهاتف والمبالغ من اليسار إلى اليمين داخل الشاشات العربية.',
            )}
          </p>
        </header>
      )}
      {SECTIONS.filter(([id]) => !only || only.includes(id)).map(([id, Section]) => (
        <Section key={id} />
      ))}
    </div>
  )
}
