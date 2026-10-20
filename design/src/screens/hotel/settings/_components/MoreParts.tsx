// The pieces of the More root (text diet, ADR 0034): the listing card (monogram, name, status, language completeness as two threads, the billing
// and preview rows), the venue tiles (glyph, count, one word), a ruled group of icon rows, and the contents of the three overlays (language,
// venue switcher, listing preview) plus the account-type sheet. Overlay content is drawn by the live navigator's sheet or, in a static frame,
// by the same `<Sheet>` around it. No sentence is on the screen: counts, dates and glyphs say it, the long form is the accessible name.
import type { ReactNode } from 'react'
import { flat, type IconName } from '@gz/tokens'
import { getVenue, hotelSettings } from '../../../../mock'
import { useFormat } from '../../../../i18n'
import { useDevice } from '../../../../shell/device/context'
import { useLang } from '../../../../shell/lang'
import { Avatar, Badge, Button, FactChip, Icon, IconListRow, IconStat, Photo, Rating, SectionHeader, StatusPill, imageSrc } from '../../../../system'
import { Fx } from './Fx'
import { UserText, VENUE_ID, useBi, useWords } from './bits'
import type { Billing } from './model'
import { useSettingsLocal } from './store'

// ---------------------------------------------------------------- the listing card

/** One language of the completeness line: its script glyph, a 2 px thread filled to the share (flex grow), the figure. The name and share are the accessible name. */
function CompletenessBar({ glyph, script, label, pct }: { glyph: string; script: 'ar' | 'en'; label: string; pct: number }) {
  const f = useFormat()
  return (
    <div className="hs-bar" data-gz-id="more.completeness" role="img" aria-label={`${label} ${f.plain(f.percent(pct))}`}>
      <span className="hs-bar__glyph gz-t-caption" lang={script} aria-hidden="true">
        {glyph}
      </span>
      <span className="hs-bar__track" aria-hidden="true">
        <span className="hs-bar__fill" style={{ flexGrow: pct }} />
        <span style={{ flexGrow: 100 - pct }} />
      </span>
      <span className="hs-bar__value gz-t-fig-body-s">{f.percent(pct)}</span>
    </div>
  )
}

export type CardState = 'live' | 'review' | 'draft'

export type ListingCardProps = {
  /** The business name in its own script. */
  name: string
  state: CardState
  /** A hotel or hall shows the language completeness; a provider shows how many listings are live and in review. */
  completeness?: { ar: number; en: number }
  listings?: { live: number; review: number }
  /** The billing row (hidden for roles that cannot open Billing and fees). */
  billing?: Billing
  onBilling?: () => void
  onPreview?: () => void
}

/** The plan as one fact: the crown of a major hotel, or the end date of the plan (a calendar, a timer when it is close, a clock-off when it is over). */
export function BillingFact({ billing }: { billing: Billing }) {
  const { t, c } = useWords()
  const f = useFormat()
  const date = billing.endsOn ? f.date(billing.endsOn, 'dayMonth') : ''
  switch (billing.status) {
    case 'exempt':
      return <FactChip icon="crown" tone="accent" label={t('hotelSettingsBillExempt')} />
    case 'contract':
      return <FactChip icon="notes" label={c('commonBillingContract')} />
    case 'active':
      return <FactChip icon="calendar" label={t('hotelSettingsBillEnds')} value={<Fx text={date} />} />
    case 'expiring':
      return <FactChip icon="timer" tone="accent" label={t('hotelSettingsBillEnds')} value={<Fx text={date} />} />
    case 'expired':
      return <FactChip icon="clock-off" tone="muted" label={t('hotelSettingsBillEnded')} value={<Fx text={date} />} />
    default:
      return null
  }
}

export function ListingCard({ name, state, completeness, listings, billing, onBilling, onPreview }: ListingCardProps) {
  const { t, c } = useWords()
  const attention = billing ? billing.status === 'expiring' || billing.status === 'expired' || billing.needsChanges : false
  const held = state !== 'live'
  const pill =
    state === 'live' ? <StatusPill status="listing_active" /> : state === 'review' ? <StatusPill status="listing_review" /> : <StatusPill status="listing_draft" />
  const billingBody = billing ? (
    <>
      <Icon name="receipt" size="sm" tone="secondary" />
      <span className="hs-listing__label gz-t-title">{t('hotelSettingsMoreBilling')}</span>
      <BillingFact billing={billing} />
      {attention ? <span className="hs-listing__dot" role="img" aria-label={t('hotelSettingsMoreBillingAttention')} /> : null}
      {onBilling ? <Icon name="chevron-right" size="sm" tone="secondary" /> : null}
    </>
  ) : null
  return (
    <section className="hs-listing" data-gz="ListingCard" aria-label={t('hotelSettingsMoreListing')}>
      <div className="hs-listing__head">
        <span aria-hidden="true">
          <Avatar name={name} size="sm" voice="sans" />
        </span>
        <UserText role="d1" className="hs-listing__name">{name}</UserText>
        {pill}
      </div>
      {completeness ? (
        <div className="hs-listing__block" role="group" aria-label={t('hotelSettingsMoreCompleteness')}>
          <CompletenessBar glyph="ع" script="ar" label={t('hotelSettingsMoreLangAr')} pct={completeness.ar} />
          <CompletenessBar glyph="En" script="en" label={t('hotelSettingsMoreLangEn')} pct={completeness.en} />
        </div>
      ) : listings ? (
        <div className="hs-listing__block hs-listing__stats">
          <IconStat layout="inline" icon="megaphone" label={c('commonListingStatusActive')} value={String(listings.live)} tone="accent" />
          <IconStat layout="inline" icon="clock" label={c('commonListingStatusReview')} value={String(listings.review)} />
        </div>
      ) : null}
      {billing && onBilling ? (
        <button type="button" className="gz-reset hs-listing__row gz-press" data-gz-id="more.billing" onClick={onBilling}>
          {billingBody}
        </button>
      ) : billing ? (
        <div className="hs-listing__row">{billingBody}</div>
      ) : null}
      <button type="button" className="gz-reset hs-listing__row gz-press" data-gz-id="more.preview" onClick={onPreview} disabled={held}>
        <Icon name="eye" size="sm" tone={held ? 'disabled' : 'secondary'} />
        <span className="hs-listing__label gz-t-title">{t('hotelSettingsMorePreview')}</span>
        {held ? <span className="gz-sr-only">{t('hotelSettingsMorePreviewHeld')}</span> : <Icon name="chevron-right" size="sm" tone="secondary" />}
      </button>
    </section>
  )
}

// ---------------------------------------------------------------- the venue tiles

export type MoreTile = { id: string; icon: IconName; title: string; count?: number; onPress: () => void }

/**
 * Three tiles to a row (the venue's own pages: a glyph, a count and one word). The width is the frame's, computed from the gutter and gap
 * tokens, so every row has equal tiles at 360, 390 and 430 (a Flutter LayoutBuilder).
 */
export function VenueTiles({ title, tiles }: { title: string; tiles: readonly MoreTile[] }) {
  const f = useFormat()
  const { width } = useDevice()
  if (tiles.length === 0) return null
  const gap = flat['space.3']
  const size = Math.floor((width - 2 * flat['space.5'] - 2 * gap) / 3)
  return (
    <section className="hs-group" data-gz="MoreTiles" aria-label={title}>
      <div className="hs-group__head">
        <SectionHeader title={title} voice="hotel" />
      </div>
      <div className="hs-tiles">
        {tiles.map(tile => (
          <button key={tile.id} type="button" className="gz-reset hs-tile gz-press" style={{ inlineSize: size }} onClick={tile.onPress}>
            <span className="hs-tile__top">
              <Icon name={tile.icon} size="md" tone="primary" />
              {tile.count !== undefined ? <span className="hs-tile__count gz-t-fig-body-s">{f.integer(tile.count)}</span> : null}
            </span>
            <span className="hs-tile__label gz-t-body-s">{tile.title}</span>
          </button>
        ))}
      </div>
    </section>
  )
}

// ---------------------------------------------------------------- a ruled group

export type MoreRow = {
  id: string
  icon: IconName
  title: string
  /** A count, a fact, a badge or a switch at inline-end. */
  trailing?: ReactNode
  onPress?: () => void
  tone?: 'default' | 'danger'
  /** A row that holds its own control (the biometric switch): no chevron. */
  chevron?: boolean
}

export function MoreGroup({ title, rows }: { title?: string; rows: readonly MoreRow[] }) {
  if (rows.length === 0) return null
  return (
    <section className="hs-group" data-gz="MoreGroup" aria-label={title}>
      {title ? (
        <div className="hs-group__head">
          <SectionHeader title={title} voice="hotel" />
        </div>
      ) : null}
      <div className="hs-group__rows">
        {rows.map((row, i) => (
          <IconListRow
            key={row.id}
            title={row.title}
            icon={row.icon}
            trailing={row.trailing}
            chevron={row.chevron ?? Boolean(row.onPress)}
            onClick={row.onPress}
            tone={row.tone}
            last={i === rows.length - 1}
          />
        ))}
      </div>
    </section>
  )
}

// ---------------------------------------------------------------- overlays

/** Two options in their own script with a glyph disk and a check on the current one. Choosing flips direction and text at once. */
export function LanguageContent({ onChoose }: { onChoose: (lang: 'ar' | 'en') => void }) {
  const { t } = useWords()
  const { lang } = useLang()
  const options = [
    { value: 'ar' as const, label: 'العربية', glyph: 'ع' },
    { value: 'en' as const, label: 'English', glyph: 'En' },
  ]
  return (
    <div className="hs-lang">
      <div role="radiogroup" aria-label={t('hotelSettingsLanguageTitle')} className="hs-lang__list">
        {options.map(o => (
          <button key={o.value} type="button" role="radio" aria-checked={lang === o.value} className="gz-reset hs-lang__row gz-press" onClick={() => onChoose(o.value)}>
            <span className="hs-lang__glyph gz-t-label" lang={o.value} aria-hidden="true">
              {o.glyph}
            </span>
            <span lang={o.value} className="gz-t-body hs-lang__name">
              {o.label}
            </span>
            {lang === o.value ? <Icon name="check" size="sm" tone="primary" /> : null}
          </button>
        ))}
      </div>
    </div>
  )
}

/** The venues of this account: a monogram, the name, the role held there and what waits (a clock and a count). The sister venue is demo state only. */
export function VenueSwitcherContent({ pendingHere, onChoose }: { pendingHere: number; onChoose: (venueId: string) => void }) {
  const { t, c } = useWords()
  const f = useFormat()
  const bi = useBi()
  const active = useSettingsLocal(s => s.activeVenue)
  const here = getVenue(VENUE_ID)
  const sister = hotelSettings.sister
  const rows = [
    { id: VENUE_ID, name: here ? bi(here.name) : '', role: t('hotelSettingsRoleOwner'), pending: pendingHere },
    ...(sister ? [{ id: sister.id, name: bi(sister.name), role: t(sister.role === 'reception' ? 'hotelSettingsRoleReception' : 'hotelSettingsRoleManager'), pending: sister.pending }] : []),
  ]
  return (
    <div className="hs-switch">
      <ul className="hs-switch__list">
        {rows.map(r => (
          <li key={r.id} className="hs-switch__item">
            <button type="button" className="gz-reset hs-switch__row gz-press" aria-current={r.id === active || undefined} onClick={() => onChoose(r.id)}>
              <span aria-hidden="true">
                <Avatar name={r.name} size="sm" voice="sans" />
              </span>
              <span className="hs-switch__text">
                <UserText role="d1">{r.name}</UserText>
                <span className="hs-switch__meta">
                  <Badge variant="quiet" bead={false}>
                    {r.role}
                  </Badge>
                  {r.pending > 0 ? <FactChip icon="clock" size="sm" tone="muted" label={c('commonStatusPending')} value={f.integer(r.pending)} /> : null}
                </span>
              </span>
              {r.id === active ? <Icon name="check" size="sm" tone="primary" label={t('hotelSettingsSwitchCurrent')} /> : null}
            </button>
          </li>
        ))}
      </ul>
    </div>
  )
}

export type PreviewSubject = { name: string; cover: { file: string; alt: { en: string; ar: string } } | null; area?: string; rating?: { average: number | null; count: number } }

/** What couples see: the cover photograph, the name, the area and the rating, in the same order as the client's venue page. */
export function PreviewContent({ subject, onClose }: { subject: PreviewSubject | null; onClose: () => void }) {
  const { c } = useWords()
  const bi = useBi()
  if (!subject) return null
  return (
    <div className="hs-preview">
      {subject.cover ? (
        <div className="hs-preview__photo">
          <Photo src={imageSrc(subject.cover.file)} alt={bi(subject.cover.alt)} sizes="390px" priority />
        </div>
      ) : null}
      <div className="hs-preview__text">
        <UserText role="d2">{subject.name}</UserText>
        <p className="gz-t-body-s hs-preview__meta">
          {subject.area ? <bdi dir="auto">{subject.area}</bdi> : null}
          {subject.rating && subject.rating.average !== null ? <Rating value={subject.rating.average} count={subject.rating.count} /> : null}
        </p>
      </div>
      <Button variant="secondary" fullWidth onClick={onClose}>
        {c('commonActionClose')}
      </Button>
    </div>
  )
}

/** The two account types of the Partner app, a check on the one in use, and the way to set up the other one (A-06). */
export function AccountTypeContent({ current, onChoose, onSetup }: { current: 'venue' | 'provider'; onChoose: (type: 'venue' | 'provider') => void; onSetup: () => void }) {
  const { t } = useWords()
  const options = [
    { value: 'venue' as const, icon: 'hotel' as const, title: t('hotelSettingsAcctVenue') },
    { value: 'provider' as const, icon: 'megaphone' as const, title: t('hotelSettingsAcctProvider') },
  ]
  return (
    <div className="hs-acct">
      <div role="radiogroup" aria-label={t('hotelSettingsAcctTitle')} className="hs-acct__list">
        {options.map(o => (
          <button key={o.value} type="button" role="radio" aria-checked={current === o.value} className="gz-reset hs-acct__row gz-press" onClick={() => onChoose(o.value)}>
            <span className="hs-acct__disk" aria-hidden="true">
              <Icon name={o.icon} size="md" tone="primary" />
            </span>
            <span className="gz-t-title hs-acct__name">{o.title}</span>
            {current === o.value ? <Icon name="check" size="sm" tone="primary" /> : null}
          </button>
        ))}
      </div>
      <Button variant="tertiary" iconStart="plus" onClick={onSetup}>
        {t('hotelSettingsAcctSetup')}
      </Button>
    </div>
  )
}
