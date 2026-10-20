// The pickers of Wedding info (CL-PROF-02). Date, areas and budget are the SAME panels the Brief sheet uses (CL-DISC-02), so a couple answers
// the same question the same way wherever they meet it; role and guests are asked here (the Brief has one guest count, the wedding file
// has ladies and men separately). Each sheet keeps a draft and writes the profile (and the Brief fields it feeds) on Done, or on the tap
// for a single choice; dismissing discards. Autosave per field: no Save button anywhere on the screen.
import { useState } from 'react'
import type { WeddingProfileState } from '../../../../shell/state'
import { useFormat, useT } from '../../../../i18n'
import { Icon, Stepper, useNav } from '../../../../system'
import type { BriefDraft, PanelProps } from '../../discover/_components/brief/types'
import { AreaPanel } from '../../discover/_components/brief/AreaPanel'
import { BudgetPanel } from '../../discover/_components/brief/BudgetPanel'
import { DatePanel } from '../../discover/_components/brief/DatePanel'
import '../../discover/_components/brief/brief.css'
import { ChoiceList, DoneButton, SheetBox } from './parts'
import { BUDGET_CEILING_FILS, commitWedding } from './wedding'
import './wedding-sheets.css'

export type WeddingField = 'role' | 'date' | 'guests' | 'budget' | 'areas'

/** What a saved edit tells the screen (the quiet toast "Saved"). */
export type OnSaved = () => void

const draftOf = (p: WeddingProfileState): BriefDraft => ({
  brief: {
    date: p.weddingDate,
    guests: p.guests.women || null,
    audience: p.searching[0] ?? 'women',
    areaIds: p.areaIds,
    budget: p.venueBudget ? { min: p.venueBudget.min, max: p.venueBudget.max.fils >= BUDGET_CEILING_FILS ? null : p.venueBudget.max } : null,
    dateMode: p.weddingDate ? p.dateMode : 'undecided',
  },
  split: true,
  counts: { women: p.guests.women, men: p.guests.men },
})

// ---------------------------------------------------------------- role

const ROLES = ['bride', 'groom', 'family', 'planner'] as const

export function RoleSheet({ profile, onSaved }: { profile: WeddingProfileState; onSaved: OnSaved }) {
  const t = useT('client-profile')
  const nav = useNav()
  const label: Record<(typeof ROLES)[number], string> = {
    bride: t('clientProfileWedRoleBride'),
    groom: t('clientProfileWedRoleGroom'),
    family: t('clientProfileWedRoleFamily'),
    planner: t('clientProfileWedRolePlanner'),
  }
  return (
    <SheetBox title={t('clientProfileWedRole')}>
      <ChoiceList
        label={t('clientProfileWedRole')}
        value={profile.role}
        onChange={role => {
          commitWedding({ role })
          nav.closeSheet()
          onSaved()
        }}
        options={ROLES.map(r => ({ value: r, title: label[r] }))}
      />
    </SheetBox>
  )
}

// ---------------------------------------------------------------- date, areas, budget (the Brief's panels)

type PanelField = 'date' | 'budget' | 'areas'

export function BriefPanelSheet({ field, profile, onSaved }: { field: PanelField; profile: WeddingProfileState; onSaved: OnSaved }) {
  const t = useT('client-profile')
  const nav = useNav()
  const [draft, setDraft] = useState<BriefDraft>(() => draftOf(profile))
  const props: PanelProps = { draft, set: setDraft }
  const b = draft.brief

  const done = () => {
    if (field === 'date') commitWedding({ weddingDate: b.date ?? null, dateMode: b.date ? (b.dateMode === 'flexible_month' ? 'flexible_month' : 'exact') : 'undecided' })
    else if (field === 'areas') commitWedding({ areaIds: b.areaIds ?? [] })
    else commitWedding({ venueBudget: b.budget ? { min: b.budget.min, max: b.budget.max ?? { fils: BUDGET_CEILING_FILS, currency: 'KWD' } } : null })
    nav.closeSheet()
    onSaved()
  }
  const title = field === 'date' ? t('clientProfileWedDate') : field === 'areas' ? t('clientProfileWedAreas') : t('clientProfileWedBudget')

  return (
    <SheetBox title={title} fill footer={<DoneButton onClick={done} />}>
      {field === 'date' ? <DatePanel {...props} /> : field === 'areas' ? <AreaPanel {...props} /> : <BudgetPanel {...props} />}
    </SheetBox>
  )
}

// ---------------------------------------------------------------- guests

const GUESTS_MAX = 1500

/** A section is its symbol (abstract, no faces, ADR 0034 section 2); the word is the accessible name. */
const section = (icon: 'section-women' | 'section-men', name: string) => (
  <span className="gzpr-sec">
    <Icon name={icon} size="lg" />
    <span className="gz-sr-only">{name}</span>
  </span>
)

export function GuestsSheet({ profile, onSaved }: { profile: WeddingProfileState; onSaved: OnSaved }) {
  const t = useT('client-profile')
  const f = useFormat()
  const nav = useNav()
  const [counts, setCounts] = useState(profile.guests)
  return (
    <SheetBox title={t('clientProfileWedGuests')} footer={<DoneButton onClick={() => { commitWedding({ guests: counts }); nav.closeSheet(); onSaved() }} />}>
      <div className="gzpr-wsheet">
        <Stepper label={section('section-women', t('clientProfileWedLadies'))} min={0} max={GUESTS_MAX} step={10} value={counts.women} onChange={women => setCounts(c => ({ ...c, women }))} valueText={n => f.guests(n)} />
        <Stepper label={section('section-men', t('clientProfileWedMen'))} min={0} max={GUESTS_MAX} step={10} value={counts.men} onChange={men => setCounts(c => ({ ...c, men }))} valueText={n => f.guests(n)} />
      </div>
    </SheetBox>
  )
}

// ---------------------------------------------------------------- one entry point

export function WeddingSheet({ field, profile, onSaved }: { field: WeddingField; profile: WeddingProfileState; onSaved: OnSaved }) {
  if (field === 'role') return <RoleSheet profile={profile} onSaved={onSaved} />
  if (field === 'guests') return <GuestsSheet profile={profile} onSaved={onSaved} />
  return <BriefPanelSheet field={field} profile={profile} onSaved={onSaved} />
}
