// Small pieces the payment screens share (text diet, ADR 0034: glyphs and figures, no captions).
//   VenuePlate   thumbnail, the venue or provider name (display face) and its facts (icon + value): what the voucher is bound to
//   PayFacts     amount + method, then what the voucher is for: the facts under the title of the two waiting screens
//   PayTimer     a timer glyph and mm:ss in the figures voice; gold-ink in the last minute, no alarm, no motion
//   TermsStrip   three glyphs with two words each: the voucher in one line, and the info glyph that opens the full explainer
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { useFormat, useT } from '../../../../i18n'
import { FactChip, FactRow, Icon, Photo, imageSrc, useBi } from '../../../../system'
import { cx } from '../../../../system/core/cx'
import type { ImageRef, Bilingual } from '../../../../mock'
import { useLang } from '../../../../shell/lang'
import { METHOD_ICON, METHOD_SHORT, voucherFeeFils, type MethodKey } from './data'
import { Fx } from './Fx'
import './parts.css'

// ---------------------------------------------------------------- VenuePlate

export type VenuePlateProps = {
  name: Bilingual
  cover: ImageRef | null
  /** A FactRow of what the voucher is bound to (hall or package, date, guests). */
  facts: ReactNode
}

export function VenuePlate({ name, cover, facts }: VenuePlateProps) {
  const { lang } = useLang()
  const bi = useBi()
  return (
    <div className="pm-plate" data-gz="VenuePlate">
      <div className="pm-plate__head">
        {cover ? <Photo className="pm-plate__img" src={imageSrc(cover.file)} alt={cover.alt[lang]} sizes="64px" priority /> : <span className="pm-plate__img pm-plate__img--empty" />}
        <p className="pm-plate__name gz-t-d1">
          <bdi dir="auto">{bi(name)}</bdi>
        </p>
      </div>
      {facts}
    </div>
  )
}

// ---------------------------------------------------------------- PayFacts

export type PayFactsProps = {
  method: MethodKey
  /** The venue or provider the voucher is for. */
  forName: Bilingual
}

/** What is being paid, as facts, in the same two lines at every width: the amount with its method, then what the voucher is for. */
export function PayFacts({ method, forName }: PayFactsProps) {
  const t = useT('client-payment')
  const f = useFormat()
  const bi = useBi()
  return (
    <div className="pm-payfacts" data-gz="PayFacts">
      <FactRow className="pm-facts" label={t('clientPaymentLabelAmount')}>
        <FactChip icon="coins" label={t('clientPaymentLabelAmount')} value={<Fx text={f.money(voucherFeeFils(), { mode: 'exact' })} />} />
        <FactChip icon={METHOD_ICON[method]} label={t('clientPaymentLabelMethod')} value={t(METHOD_SHORT[method])} />
      </FactRow>
      <FactRow className="pm-facts" label={t('clientPaymentLabelVoucherFor')}>
        <FactChip icon="ticket" label={t('clientPaymentLabelVoucherFor')} value={<bdi dir="auto">{bi(forName)}</bdi>} tone="muted" />
      </FactRow>
    </div>
  )
}

// ---------------------------------------------------------------- PayTimer

/** `09:42` from whole milliseconds: two figure groups from the formatter, one LTR island. */
export function useClockText(ms: number): string {
  const f = useFormat()
  const total = Math.max(0, Math.floor(ms / 1000))
  const two = (n: number) => (n < 10 ? `${f.plain(f.integer(0))}${f.plain(f.integer(n))}` : f.plain(f.integer(n)))
  return `${two(Math.floor(total / 60))}:${two(total % 60)}`
}

export type PayTimerProps = {
  ms: number
}

export function PayTimer({ ms }: PayTimerProps) {
  const t = useT('client-payment')
  const text = useClockText(ms)
  const urgent = ms <= 60_000
  return (
    <div className="pm-timer" data-gz="PayTimer" role="timer" aria-label={t('clientPaymentTimerSr', { time: text })}>
      <Icon name="timer" size="sm" tone={urgent ? 'accent' : 'secondary'} />
      <bdi dir="ltr" className={cx('pm-timer__value gz-t-fig-xl', urgent && 'is-last-minute')}>
        {text}
      </bdi>
    </div>
  )
}

// ---------------------------------------------------------------- TermsStrip

export type TermItem = { icon: IconName; label: string }

export type TermsStripProps = {
  items: readonly TermItem[]
  /** The accessible name of the info glyph at the end. */
  infoLabel: string
  onInfo: () => void
}

/** The voucher in three glyphs and six words. The whole strip is one target (44+ high): it opens the explainer, the info glyph says so. */
export function TermsStrip({ items, infoLabel, onInfo }: TermsStripProps) {
  return (
    <button type="button" className="gz-reset gz-press pm-terms" data-gz="TermsStrip" data-gz-id="terms" onClick={onInfo}>
      <span className="pm-terms__list">
        {items.map(it => (
          <span key={it.icon} className="pm-terms__item">
            <span className="pm-terms__disk" aria-hidden="true">
              <Icon name={it.icon} size="md" />
            </span>
            <span className="pm-terms__label gz-t-caption">{it.label}</span>
          </span>
        ))}
      </span>
      <span className="pm-terms__info" aria-hidden="true">
        <Icon name="info" size="sm" tone="secondary" />
      </span>
      <span className="gz-sr-only">{infoLabel}</span>
    </button>
  )
}

export type { Bilingual }
