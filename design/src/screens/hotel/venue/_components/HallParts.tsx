// The pieces of the hall editor (HL-VENU-04): session rows and the session sheet (name, start, end, buffers, platform presets), the
// three-state facility rows and the per-section facts. Times come from the formatter; nothing here types a digit.
import { useState } from 'react'
import type { Audience, AmenityState } from '../../../../mock'
import { Button, ChipGroup, Icon, SelectRow, useNav } from '../../../../system'
import { BilingualField, FieldError, SheetFrame } from './fields'
import { Figures, useBi, useV } from './bits'
import { useAudienceLabel } from './labels'
import type { HallModel, MusicFact, PhotographyFact, SessionModel } from './store'
import { AMENITY_ICON, BUFFER_MINUTES, SESSION_PRESETS, TIME_SLOTS, amenityDef } from './venue'
import './hall.css'

/** `9:00 PM` from `21:00`. */
export function useTimeLabel() {
  const { f } = useV()
  return (hhmm: string): string => {
    const [h, m] = hhmm.split(':').map(Number)
    return f.time(f.kuwaitDate(2027, 1, 14, h ?? 0, m ?? 0))
  }
}

/** A session that ends at or before its start crosses midnight. */
export const crossesMidnight = (s: Pick<SessionModel, 'start' | 'end'>) => s.end <= s.start

// ---------------------------------------------------------------- sessions

export function SessionRow({ s, onOpen, disabled }: { s: SessionModel; onOpen: () => void; disabled?: boolean }) {
  const { t, c } = useV()
  const bi = useBi()
  const time = useTimeLabel()
  return (
    <button type="button" className="gz-reset hv-ses gz-press" onClick={onOpen} disabled={disabled} data-gz="SessionRow">
      <span className="hv-ses__text">
        <span className="gz-t-title">
          <bdi dir="auto">{bi({ ar: s.nameAr, en: s.nameEn })}</bdi>
        </span>
        <span className="gz-t-body-s hv-ses__time">
          <Figures text={t('hotelVenueSessionLine', { from: time(s.start), to: time(s.end) })} />
        </span>
      </span>
      <Icon name="chevron-right" size="sm" tone="secondary" />
    </button>
  )
}

let seq = 0

export type SessionSheetProps = {
  /** The session being edited; omitted for a new one. */
  session?: SessionModel
  onSave: (s: SessionModel) => void
  onDelete?: () => void
}

export function SessionSheet({ session, onSave, onDelete }: SessionSheetProps) {
  const { t, c } = useV()
  const nav = useNav()
  const time = useTimeLabel()
  const [draft, setDraft] = useState<SessionModel>(() => session ?? { id: `session-new-${(seq += 1)}`, nameAr: '', nameEn: '', start: '20:00', end: '01:00', bufferBeforeMin: 60, bufferAfterMin: 60 })
  const patch = (p: Partial<SessionModel>) => setDraft(d => ({ ...d, ...p }))
  const named = draft.nameAr.trim() !== '' && draft.nameEn.trim() !== ''
  const slots = TIME_SLOTS.map(v => ({ value: v, label: time(v) }))
  const minutes = BUFFER_MINUTES.map(m => ({ value: m, label: m === 0 ? t('hotelVenueNone') : c('commonCountMinutes', { count: m }) }))
  const presetName = { afternoon: 'hotelVenuePresetAfternoon', evening: 'hotelVenuePresetEvening', full: 'hotelVenuePresetFull' } as const

  return (
    <SheetFrame
      footer={
        <>
          <Button
            variant="primary"
            fullWidth
            disabled={!named}
            reason={t('hotelVenueSessionNameNeeded')}
            onClick={() => {
              onSave({ ...draft, nameAr: draft.nameAr.trim(), nameEn: draft.nameEn.trim() })
              nav.closeSheet()
            }}
          >
            {c('commonActionSave')}
          </Button>
          {onDelete ? (
            <Button variant="destructive" iconStart="trash" fullWidth onClick={onDelete}>
              {t('hotelVenueSessionDelete')}
            </Button>
          ) : null}
        </>
      }
    >
      {session ? null : (
        <div className="hv-zone">
          <ChipGroup<string>
            label={t('hotelVenuePresetsLabel')}
            layout="rail"
            value={SESSION_PRESETS.find(p => p.start === draft.start && p.end === draft.end)?.id ?? null}
            onChange={id => {
              const p = SESSION_PRESETS.find(x => x.id === id)
              if (p) patch({ start: p.start, end: p.end })
            }}
            options={SESSION_PRESETS.map(p => ({ value: p.id, label: t(presetName[p.id]) }))}
          />
        </div>
      )}
      <BilingualField label={t('hotelVenueSessionName')} ar={draft.nameAr} en={draft.nameEn} onAr={v => patch({ nameAr: v })} onEn={v => patch({ nameEn: v })} maxLength={40} required={false} />
      <SelectRow<string> label={t('hotelVenueSessionStart')} value={draft.start} onChange={v => v && patch({ start: v })} options={slots} />
      <SelectRow<string>
        label={t('hotelVenueSessionEnd')}
        value={draft.end}
        onChange={v => v && patch({ end: v })}
        options={slots}
        helper={crossesMidnight(draft) ? t('hotelVenueSessionAfterMidnight') : undefined}
      />
      <div className="hv-zone">
        <span className="gz-t-label">{t('hotelVenueSessionSetup')}</span>
        <ChipGroup<number> label={t('hotelVenueSessionSetup')} layout="rail" value={draft.bufferBeforeMin} onChange={v => v !== null && patch({ bufferBeforeMin: v })} options={minutes.map(m => ({ ...m, label: <Figures text={m.label} /> }))} />
      </div>
      <div className="hv-zone">
        <span className="gz-t-label">{t('hotelVenueSessionTeardown')}</span>
        <ChipGroup<number> label={t('hotelVenueSessionTeardown')} layout="rail" value={draft.bufferAfterMin} onChange={v => v !== null && patch({ bufferAfterMin: v })} options={minutes.map(m => ({ ...m, label: <Figures text={m.label} /> }))} />
      </div>
    </SheetFrame>
  )
}

// ---------------------------------------------------------------- facilities

const STATE_KEYS = { included: 'hotelVenueAmIncluded', extra: 'hotelVenueAmExtra', not_offered: 'hotelVenueAmNone' } as const

/** A facility as one row: glyph and name above, its state as the value; tapping opens the three-way picker. */
export function AmenityRows({ ids, states, onChange, disabled }: { ids: readonly string[]; states: Record<string, AmenityState>; onChange: (id: string, s: AmenityState) => void; disabled?: boolean }) {
  const { t } = useV()
  const bi = useBi()
  const audience = useAudienceLabel()
  const options = (['included', 'extra', 'not_offered'] as const).map(s => ({ value: s, label: t(STATE_KEYS[s]) }))
  const ladiesOnly = new Set(['separate-entrance', 'female-security'])
  return (
    <div className="hv-am" data-gz="AmenityRows">
      {ids.map(id => {
        const def = amenityDef(id)
        if (!def) return null
        const name = ladiesOnly.has(id) ? t('hotelVenueAmenityOf', { name: bi(def.label), audience: audience('women') }) : bi(def.label)
        return (
          <SelectRow<AmenityState>
            key={id}
            variant="row"
            label={name}
            value={states[id] ?? 'not_offered'}
            disabled={disabled}
            sheetTitle={t('hotelVenueAmenityChoose', { name })}
            options={options}
            onChange={v => v && onChange(id, v)}
            startAdornment={<Icon name={(AMENITY_ICON[id] ?? 'check') as never} size="md" tone="secondary" />}
          />
        )
      })}
    </div>
  )
}

// ---------------------------------------------------------------- section facts

export function SectionFacts({ audience, facts, onChange }: { audience: Audience; facts: NonNullable<HallModel['facts'][Audience]>; onChange: (next: NonNullable<HallModel['facts'][Audience]>) => void }) {
  const { t } = useV()
  const sectionKey = { women: 'hotelVenueSectionWomen', men: 'hotelVenueSectionMen', mixed: 'hotelVenueSectionMixed' } as const
  const photo: Array<{ value: PhotographyFact; label: string }> = [
    { value: 'female_only', label: t('hotelVenuePhotoFemale') },
    { value: 'allowed', label: t('hotelVenuePhotoAllowed') },
    { value: 'none', label: t('hotelVenuePhotoNone') },
  ]
  const music: Array<{ value: MusicFact; label: string }> = [
    { value: 'dj_or_band', label: t('hotelVenueMusicDj') },
    { value: 'live', label: t('hotelVenueMusicLive') },
    { value: 'duff_only', label: t('hotelVenueMusicDuff') },
    { value: 'none', label: t('hotelVenueMusicNone') },
  ]
  return (
    <div className="hv-facts" data-gz="SectionFacts">
      <span className="gz-t-title">{t(sectionKey[audience])}</span>
      <div className="hv-zone">
        <span className="gz-t-label">{t('hotelVenueFactPhoto')}</span>
        <ChipGroup<PhotographyFact> label={`${t(sectionKey[audience])}: ${t('hotelVenueFactPhoto')}`} value={facts.photography} onChange={v => v && onChange({ ...facts, photography: v })} options={photo} />
      </div>
      <div className="hv-zone">
        <span className="gz-t-label">{t('hotelVenueFactMusic')}</span>
        <ChipGroup<MusicFact> label={`${t(sectionKey[audience])}: ${t('hotelVenueFactMusic')}`} value={facts.music} onChange={v => v && onChange({ ...facts, music: v })} options={music} />
      </div>
    </div>
  )
}

export { FieldError }
