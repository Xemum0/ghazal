// GuestsPanel (CL-DISC-02): one three-way section control (ladies, men, mixed), a stepper and preset chips. Ladies and men are the two
// separate receptions and each keeps its own count (the story: ladies 350, men 400); mixed is one celebration with one count. The Brief
// carries only the count and the reception being searched. ADR 0034: the old switch and its two sentences became the third option.
import { IconSegmented, ChipGroup, Icon, Stepper } from '../../../../../system'
import { useFormat, useT } from '../../../../../i18n'
import { useLabels } from '../labels'
import type { PanelProps } from './types'

const PRESETS = [100, 150, 200, 250, 300, 350, 400, 500]
const MIN = 20
const MAX = 1500

export function GuestsPanel({ draft, set }: PanelProps) {
  const t = useT('client-discover')
  const f = useFormat()
  const L = useLabels()
  const { brief, split, counts } = draft
  const section = split ? (brief.audience === 'men' ? 'men' : 'women') : 'mixed'
  const value = brief.guests ?? (section === 'men' ? counts.men : counts.women)

  const setGuests = (n: number) =>
    set(d => ({
      ...d,
      brief: { ...d.brief, guests: n },
      counts: section === 'men' ? { ...d.counts, men: n } : section === 'women' ? { ...d.counts, women: n } : { women: n, men: n },
    }))
  /** Ladies and men are two receptions with their own counts; mixed is one celebration (the count carries over). */
  const pickSection = (v: 'women' | 'men' | 'mixed') =>
    set(d =>
      v === 'mixed'
        ? { ...d, split: false, brief: { ...d.brief, audience: 'mixed', guests: d.brief.guests ?? d.counts.women } }
        : { ...d, split: true, brief: { ...d.brief, audience: v, guests: d.counts[v] } },
    )

  return (
    <div className="gzd-br__panel" data-gz-id="brief.guests">
      <IconSegmented<'women' | 'men' | 'mixed'>
        label={t('clientDiscoverBriefGuestsSection')}
        labels="all"
        value={section}
        onChange={pickSection}
        options={[
          { value: 'women', icon: 'section-women', label: L.arrangement('women') },
          { value: 'men', icon: 'section-men', label: L.arrangement('men') },
          { value: 'mixed', icon: 'section-mixed', label: L.arrangement('mixed') },
        ]}
      />
      <Stepper
        label={<Icon name="users-three" size="md" tone="secondary" />}
        min={MIN}
        max={MAX}
        step={10}
        value={value}
        onChange={setGuests}
        valueText={n => f.guests(n)}
      />
      <ChipGroup
        label={t('clientDiscoverBriefGuestsPresets')}
        selection="single"
        value={PRESETS.includes(value) ? value : null}
        onChange={n => n !== null && setGuests(n)}
        options={PRESETS.map(n => ({ value: n, label: <bdi dir="ltr">{f.integer(n)}</bdi> }))}
      />
    </div>
  )
}
