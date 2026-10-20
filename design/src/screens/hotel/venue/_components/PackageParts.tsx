// The pieces of the package editor (HL-VENU-03): a day-tier price block, the "What couples see" preview, the inclusion chips and the sheet that
// adds an inclusion (from the facilities list, or written in both languages).
import { useState } from 'react'
import type { IconName } from '@gz/tokens'
import { amenityDefs, type Bilingual } from '../../../../mock'
import { Button, ChipGroup, Icon, Switch, useNav } from '../../../../system'
import { BilingualField, FieldError, PriceField, SheetFrame } from './fields'
import { FactLine, Figures, useBi, useV } from './bits'
import { useTierDays } from './labels'
import { needsFlat, needsGuest, standardTotal, voucherAboveStandard, voucherState, voucherTotal } from './pricing'
import type { PackageModel, TierModel } from './store'
import { sample, weekdayOf, platform } from './venue'
import './package.css'

// ---------------------------------------------------------------- tiers

export type TierKey = 'weekday' | 'weekend'

export type TierEditorProps = {
  tier: TierKey
  model: TierModel
  basis: PackageModel['basis']
  locked?: boolean
  /** Show "enter a price" on a standard field that is still empty. */
  showEmpty?: boolean
  onChange: (next: TierModel) => void
}

/**
 * One set of days ("Weekday, Sun to Wed"): a switch, and when it is on two price groups on the basis the structure asks for: the standard
 * price and the voucher price (voucher <= standard; empty = no voucher price). The line under the voucher group says what clients are
 * offered, from the same rule the engine applies (the saving must beat the KD 2 voucher fee).
 */
export function TierEditor({ tier, model, basis, locked, showEmpty, onChange }: TierEditorProps) {
  const { t, c, f } = useV()
  const days = useTierDays()
  const title = days(tier)
  const flat = needsFlat(basis)
  const guest = needsGuest(basis)
  const { guests: sampleGuests } = sample()
  const above = voucherAboveStandard(model)
  const { state, saving } = voucherState(basis, model, sampleGuests)
  const aboveText = (kind: 'flat' | 'guest') => (above[kind] ? t(kind === 'flat' ? 'hotelVenueVoucherAboveFlat' : 'hotelVenueVoucherAboveGuest') : undefined)
  return (
    <div className="hv-tier" data-on={model.on || undefined} data-gz="TierEditor">
      <div className="hv-tier__head">
        <div className="hv-tier__text">
          <span className="gz-t-title">{title}</span>
        </div>
        <Switch checked={model.on} disabled={locked} onChange={on => onChange({ ...model, on })} label={t('hotelVenueDaysSwitch', { days: title })} />
      </div>
      {model.on ? (
        <>
          <div className="hv-tier__group">
            <span className="gz-t-label hv-tier__gtitle">
              <Icon name="coins" size="xs" tone="secondary" />
              {t('hotelVenueStd')}
            </span>
            {flat ? (
              <PriceField label={t('hotelVenueStdFlat')} fils={model.flatFils} disabled={locked} onChange={v => onChange({ ...model, flatFils: v })} error={showEmpty && model.flatFils === null ? t('hotelVenueNeedPrice') : undefined} />
            ) : null}
            {guest ? (
              <PriceField label={t('hotelVenueStdPerGuest')} fils={model.perGuestFils} disabled={locked} onChange={v => onChange({ ...model, perGuestFils: v })} error={showEmpty && model.perGuestFils === null ? t('hotelVenueNeedPrice') : undefined} />
            ) : null}
          </div>
          <div className="hv-tier__group hv-tier__group--voucher">
            <span className="gz-t-label hv-tier__gtitle">
              <Icon name="ticket" size="xs" tone="secondary" />
              {t('hotelVenueVch')}
            </span>
            {flat ? (
              <PriceField label={t('hotelVenueVchFlat')} fils={model.voucherFlatFils} disabled={locked} onChange={v => onChange({ ...model, voucherFlatFils: v })} error={aboveText('flat')} />
            ) : null}
            {guest ? (
              <PriceField label={t('hotelVenueVchPerGuest')} fils={model.voucherPerGuestFils} disabled={locked} onChange={v => onChange({ ...model, voucherPerGuestFils: v })} error={aboveText('guest')} />
            ) : null}
            {state === 'below-fee' ? <FactLine icon="warning-circle">{t('hotelVenueVchBelowFee', { fee: f.money(platform.voucherFeeFils, { mode: 'browse' }) })}</FactLine> : null}
            {state === 'ok' ? (
              <FactLine icon="check-circle">
                <Figures text={t('hotelVenueVchSaving', { amount: f.money(saving, { mode: 'browse' }) })} />
              </FactLine>
            ) : null}
          </div>
        </>
      ) : null}
    </div>
  )
}

// ---------------------------------------------------------------- preview

/**
 * `What couples see` (ADR 0004 grammar with two prices, voucher-model section 6): the three price lines of the client card, recomputed
 * on every edit from integer fils. The voucher price is the headline, the standard price sits under it with the saving. A tier whose
 * saving does not beat the voucher fee shows the standard price alone, exactly as the client app does.
 */
export function PackagePreview({ m, name }: { m: PackageModel; name: string }) {
  const { t, c, f } = useV()
  const { eventDate, guests: sampleGuests } = sample()
  const guests = Math.min(Math.max(sampleGuests, m.minGuests), m.maxGuests)
  const day = platform.weekendTierDays.includes(weekdayOf(eventDate)) ? m.weekend : m.weekday

  type Quote = { std: number; vch: number | null }
  const quoteOf = (tier: TierModel, n: number): Quote | null => {
    const std = standardTotal(m.basis, tier, n)
    if (std === null) return null
    const { state } = voucherState(m.basis, tier, n)
    return { std, vch: state === 'ok' ? voucherTotal(m.basis, tier, n) : null }
  }
  const offered = ([['weekday', m.weekday], ['weekend', m.weekend]] as const).filter(([, tier]) => tier.on)
  const priced = offered.map(([key, tier]) => ({ key, at: quoteOf(tier, guests), min: quoteOf(tier, m.minGuests) }))
  const lowest = priced.filter(p => p.at !== null && p.min !== null).sort((a, b) => (a.at?.vch ?? a.at?.std ?? 0) - (b.at?.vch ?? b.at?.std ?? 0))[0]
  const onDate = day.on ? quoteOf(day, guests) : null

  const money = (n: number) => f.money(n, { mode: 'browse' })
  const lines: Array<{ key: string; label: string; icon: IconName; quote: Quote | null | undefined; head: (q: Quote) => string; tail?: string; off?: string }> = [
    { key: 'date', label: t('hotelVenuePvDate'), icon: 'calendar' as const, quote: onDate, head: q => f.priceForGuests(q.vch ?? q.std, guests), tail: `${f.date(eventDate, 'short')} · ${c('commonAvailabilityFree')}`, off: t('hotelVenuePvOff') },
    { key: 'guests', label: t('hotelVenuePvGuests'), icon: 'guests' as const, quote: lowest?.at, head: q => f.priceForGuests(q.vch ?? q.std, guests, 'from'), tail: lowest ? c(lowest.key === 'weekday' ? 'commonTierWeekday' : 'commonTierWeekend') : undefined, off: t('hotelVenueTierNeeded') },
    { key: 'none', label: t('hotelVenuePvNone'), icon: 'user' as const, quote: lowest?.min, head: q => f.fromPriceMin(q.vch ?? q.std, m.minGuests), off: t('hotelVenueTierNeeded') },
  ]
  return (
    <div className="hv-pv" data-gz="PackagePreview">
      <span className="gz-t-title hv-pv__name">
        <bdi dir="auto">{name || t('hotelVenuePvNoName')}</bdi>
      </span>
      <div className="hv-pv__lines">
        {lines.map(l => (
          <div key={l.key} className="hv-pv__line">
            <span className="hv-pv__label">
              <Icon name={l.icon} size="xs" tone="secondary" />
              <span className="gz-sr-only">{l.label}</span>
            </span>
            {l.quote ? (
              <>
                <span className="gz-t-body-s hv-pv__value hv-pv__value--head">
                  {l.quote.vch !== null ? <Icon name="ticket" size="xs" tone="secondary" /> : null}
                  <Figures text={l.head(l.quote)} />
                  {l.tail ? <span className="hv-pv__tail"><Figures text={l.tail} /></span> : null}
                </span>
                {l.quote.vch !== null ? (
                  <span className="gz-t-caption hv-pv__std">
                    <Figures text={t('hotelVenuePvStandard', { standard: money(l.quote.std) })} />
                  </span>
                ) : null}
              </>
            ) : (
              <span className="gz-t-body-s hv-pv__off">{l.off}</span>
            )}
          </div>
        ))}
      </div>
    </div>
  )
}

// ---------------------------------------------------------------- inclusions

export function InclusionChips({ items, onRemove, onAdd, disabled }: { items: readonly Bilingual[]; onRemove: (index: number) => void; onAdd: () => void; disabled?: boolean }) {
  const { t } = useV()
  const bi = useBi()
  return (
    <ul className="hv-inc" data-gz="InclusionChips">
      {items.map((item, i) => (
        <li key={`${item.en}-${i}`} className="hv-inc__chip gz-t-body-s">
          <bdi dir="auto" className="hv-inc__label">
            {bi(item)}
          </bdi>
          <button type="button" className="gz-reset hv-inc__x gz-press" aria-label={t('hotelVenueInclusionRemove', { name: bi(item) })} disabled={disabled} onClick={() => onRemove(i)}>
            <Icon name="close" size="xs" />
          </button>
        </li>
      ))}
      <li>
        <button type="button" className="gz-reset hv-inc__chip hv-inc__chip--add gz-t-body-s gz-press" disabled={disabled} onClick={onAdd}>
          <Icon name="plus" size="xs" />
          {t('hotelVenueInclusionAdd')}
        </button>
      </li>
    </ul>
  )
}

const POOL_GROUPS = new Set(['space', 'service', 'production'])

/** Add to the package: pick from the facilities taxonomy (bilingual already) or write a free entry in both languages. */
export function InclusionSheet({ have, onAdd }: { have: readonly Bilingual[]; onAdd: (items: Bilingual[]) => void }) {
  const { t, c } = useV()
  const bi = useBi()
  const nav = useNav()
  const taken = new Set(have.map(h => h.en))
  const pool = amenityDefs.filter(a => POOL_GROUPS.has(a.group) && !taken.has(a.label.en))
  const [picked, setPicked] = useState<string[]>([])
  const [ar, setAr] = useState('')
  const [en, setEn] = useState('')
  const half = (ar.trim() !== '') !== (en.trim() !== '')
  const own = ar.trim() !== '' && en.trim() !== ''
  const ready = (picked.length > 0 || own) && !half

  const add = () => {
    if (!ready) return
    const items: Bilingual[] = pool.filter(a => picked.includes(a.id)).map(a => a.label)
    if (own) items.push({ ar: ar.trim(), en: en.trim() })
    onAdd(items)
    nav.closeSheet()
  }

  return (
    <SheetFrame
      footer={
        <Button variant="primary" fullWidth disabled={!ready} reason={half ? t('hotelVenueInclusionBoth') : undefined} onClick={add}>
          {c('commonActionAdd')}
        </Button>
      }
    >
      <div className="hv-zone">
        <span className="gz-t-label">{t('hotelVenueInclusionPick')}</span>
        <ChipGroup<string>
          label={t('hotelVenueInclusionPick')}
          selection="multiple"
          value={picked}
          onChange={setPicked}
          options={pool.map(a => ({ value: a.id, label: bi(a.label) }))}
        />
      </div>
      <div className="hv-zone">
        <span className="gz-t-label">{t('hotelVenueInclusionOwn')}</span>
        <BilingualField label={t('hotelVenueInclusionOwnLabel')} ar={ar} en={en} onAr={setAr} onEn={setEn} maxLength={60} required={false} />
        {half ? <FieldError>{t('hotelVenueInclusionBoth')}</FieldError> : null}
      </div>
    </SheetFrame>
  )
}
