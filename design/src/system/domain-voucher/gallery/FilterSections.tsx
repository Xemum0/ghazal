// Gallery: the search filters of the owner's feature list (governorate, venue type, capacity range, pricing structure). Thin wrappers over the
// shared ChipGroup, RangeSlider and SegmentedControl, driven by the fixtures (the six governorates and the real hall capacities).
import { useState } from 'react'
import { getVenue, venues } from '../../../mock'
import { Section, Spec, useL } from '../../domain-client/gallery/kit'
import { CapacityRange } from '../../domain-filters/CapacityRange'
import { GovernorateFilter } from '../../domain-filters/GovernorateFilter'
import { PricingStructureToggle, type PricingStructureValue } from '../../domain-filters/PricingStructureToggle'
import { VenueTypeChips, type VenueTypeValue } from '../../domain-filters/VenueTypeChips'

void getVenue

export function FilterSection() {
  const l = useL()
  const [gov, setGov] = useState<string[]>([])
  const [types, setTypes] = useState<VenueTypeValue[]>(['hotel'])
  const [structure, setStructure] = useState<PricingStructureValue>('per_person')
  const caps = venues.flatMap(v => v.halls.flatMap(h => h.sections.map(s => s.maxGuests)))
  const min = Math.floor(Math.min(...caps) / 10) * 10
  const max = Math.ceil(Math.max(...caps) / 50) * 50
  return (
    <Section
      id="filters"
      title={l('Search filters', 'مرشحات البحث')}
      note={l(
        'The owner’s filter list as four small components over the shared inputs: governorate (wrapping multi-select chips with a pin glyph, one per governorate of the configured list, no exact area: ADR 0038), venue type (private hall, governmental facility, hotel), capacity range (a dual slider whose start value sits at the inline-start, mirrored in Arabic) and pricing structure (per person or packages).',
        'قائمة المرشحات التي حدّدها المالك في أربعة مكوّنات صغيرة فوق المدخلات المشتركة: المحافظة (شرائح متعددة الاختيار تلتف على أكثر من سطر برمز دبوس لكل محافظة من القائمة المضبوطة، دون منطقة محددة: ADR 0038) ونوع المكان (قاعة خاصة ومنشأة حكومية وفندق) ونطاق السعة (منزلق مزدوج تقع قيمة البداية عند بداية السطر وينعكس في العربية) وطريقة التسعير (للضيف أو باقات).',
      )}
    >
      <Spec state={l('Governorate · wrapping chips, multi-select · none lit = every governorate · the host writes the count in its title', 'المحافظة · شرائح تلتف، اختيار متعدد · لا شيء مضاء = كل المحافظات · المضيف يكتب العدد في عنوانه')}>
        <GovernorateFilter value={gov} onChange={setGov} />
      </Spec>
      <Spec state={l('Venue type · multi-select with a glyph each', 'نوع المكان · اختيار متعدد برمز لكل نوع')}>
        <VenueTypeChips value={types} onChange={setTypes} />
      </Spec>
      <Spec state={l('Capacity range · minimum to maximum guests', 'نطاق السعة · من أقل إلى أكثر عدد ضيوف')}>
        <CapacityRange min={min} max={max} step={10} defaultValue={[250, 500]} />
      </Spec>
      <Spec state={l('Pricing structure · per person | packages · with “All”', 'طريقة التسعير · للضيف | باقات · مع «الكل»')}>
        <PricingStructureToggle value={structure} onChange={setStructure} />
        <PricingStructureToggle includeAll />
      </Spec>
    </Section>
  )
}
