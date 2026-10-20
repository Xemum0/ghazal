// WindowActions: the sheet behind a row of the voucher prices list (HL-GROW-01). The window's price and facts, how it is doing as three
// figures (vouchers, requests, confirmed), how couples see it behind a glyph toggle, and the three things a venue can do: Pause or Resume,
// Duplicate, End now. Pause and End reach couples at once, and requests already sent keep their price: that sentence is behind the (i) of the
// sheet. Both actions are disabled in place when the app is offline (ADR 0008 D10: never queued). Ending asks first because it cannot be
// undone. The standing voucher prices have no window to pause: their sheet sends the venue to the package prices.
import { useState } from 'react'
import { useFormat } from '../../../../i18n'
import { Banner, Button, FactChip, FactRow, Icon, IconStat, InfoButton, Price, Tag } from '../../../../system'
import { useBi, useWords } from './bits'
import { PreviewStrip } from './PreviewStrip'
import { SheetFrame } from './SheetFrame'
import { UnitGlyph, useWindowFacts } from './WindowRow'
import { getPackage } from '../../../../mock'
import { standardOf, voucherPackages, windowPerformance, windowRate, type WindowRecord } from './model'
import './window-actions.css'

export type WindowActionsProps = {
  window: WindowRecord
  offline?: boolean
  onPauseToggle: () => void
  onDuplicate: () => void
  onEnd: () => void
  onClose?: () => void
}

export function WindowActions({ window: w, offline = false, onPauseToggle, onDuplicate, onEnd, onClose }: WindowActionsProps) {
  const f = useFormat()
  const bi = useBi()
  const { t } = useWords()
  const facts = useWindowFacts()
  const ended = w.status === 'ended'
  const { standard, unit } = standardOf(w)
  const rate = windowRate(w)
  const [showPreview, setShowPreview] = useState(false)
  const perf = windowPerformance(w)
  const events = facts.events(w, true)
  const run = facts.run(w)
  const names = w.packageIds.map(id => bi(getPackage(id)?.name))

  const footer = (
    <>
      {ended ? null : (
        <Button variant="secondary" fullWidth iconStart={w.paused ? 'play' : 'pause'} disabled={offline} onClick={onPauseToggle}>
          {w.paused ? t('hotelGrowResume') : t('hotelGrowPause')}
        </Button>
      )}
      <Button variant="secondary" fullWidth iconStart="copy" onClick={onDuplicate}>
        {t('hotelGrowDuplicate')}
      </Button>
      {ended ? null : (
        <Button variant="destructive" fullWidth iconStart="close" disabled={offline} onClick={onEnd}>
          {t('hotelGrowEndNow')}
        </Button>
      )}
    </>
  )

  return (
    <SheetFrame
      title={<bdi dir="auto">{bi(w.title)}</bdi>}
      footer={footer}
      onClose={onClose}
      info={
        <InfoButton title={t('hotelGrowEffectTitle')}>
          <p>{t('hotelGrowEffectNote')}</p>
        </InfoButton>
      }
    >
      <div className="go-act__what">
        <UnitGlyph unit={unit} />
        <Price fils={rate} mode="browse" size="strong" was={standard > rate ? standard : undefined} />
        {w.paused ? <Tag icon="pause">{t('hotelGrowPaused')}</Tag> : null}
      </div>
      <div className="go-act__scope">
        <FactChip icon="package" value={<bdi dir="auto">{names.length === 0 ? f.integer(voucherPackages().length) : names.length > 1 ? f.integer(names.length) : names[0]}</bdi>} label={t('hotelGrowFactPackages')} size="sm" tone="muted" />
        {events ? <FactChip icon={events.icon} value={events.node} label={events.label} size="sm" tone="muted" /> : null}
        {run ? <FactChip icon={run.icon} value={run.node} label={run.label} size="sm" tone="muted" /> : null}
      </div>

      <div className="go-act__stats">
        <span className="go-act__stat">
          <IconStat icon="ticket" value={f.integer(perf.vouchers)} label={t('hotelGrowStatVouchers')} />
        </span>
        <span className="go-act__stat">
          <IconStat icon="clipboard" value={f.integer(perf.requests)} label={t('hotelGrowStatRequests')} />
        </span>
        <span className="go-act__stat">
          <IconStat icon="calendar-check" value={f.integer(perf.confirmed)} label={t('hotelGrowStatConfirmed')} />
        </span>
      </div>

      <section className="go-act__preview" aria-label={t('hotelGrowPreviewLabel')}>
        <button type="button" className="gz-reset gz-press go-act__toggle gz-t-label" aria-expanded={showPreview} onClick={() => setShowPreview(v => !v)}>
          <Icon name="eye" size="sm" tone="secondary" />
          <span className="go-act__toggle-text">{t('hotelGrowPreviewLabel')}</span>
          <Icon name={showPreview ? 'chevron-up' : 'chevron-down'} size="sm" tone="secondary" />
        </button>
        {showPreview ? <PreviewStrip flat rate={rate} packageIds={w.packageIds} dates={w.eventDates ?? []} /> : null}
      </section>

      {offline ? <Banner tone="offline" shape="card">{t('hotelGrowOffline')}</Banner> : null}
    </SheetFrame>
  )
}

/** The sheet of the standing voucher prices: how many packages carry one, and the way to change them (package prices, HL-VENU-02). */
export function StandingActions({ onEdit, onClose }: { onEdit: () => void; onClose?: () => void }) {
  const f = useFormat()
  const { t } = useWords()
  return (
    <SheetFrame
      title={t('hotelGrowStandingTitle')}
      onClose={onClose}
      info={
        <InfoButton title={t('hotelGrowStandingInfoTitle')}>
          <p>{t('hotelGrowStandingExplain')}</p>
          <p>{t('hotelGrowStandingNote')}</p>
        </InfoButton>
      }
      footer={
        <Button variant="primary" fullWidth iconEnd="chevron-right" onClick={onEdit}>
          {t('hotelGrowStandingEditCta')}
        </Button>
      }
    >
      <div className="go-act__what">
        <Tag icon="check">{t('hotelGrowAlwaysOn')}</Tag>
        <FactRow label={t('hotelGrowStandingCount')}>
          <FactChip icon="package" value={f.integer(voucherPackages().length)} label={t('hotelGrowStandingCount')} size="sm" tone="muted" />
        </FactRow>
      </div>
    </SheetFrame>
  )
}
