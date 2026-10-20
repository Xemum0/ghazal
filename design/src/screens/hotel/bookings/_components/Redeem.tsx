// The pieces of the redeem screen (HL-BOOK-06, ADR 0034): the scanner viewfinder (a drawn frame and a torch, no caption), the code field, the
// "ready to redeem" quote (the voucher price as one figure with the standard struck, the client, the date, the hall, the package, the guests;
// the sentence that a redemption cannot be undone is behind an info glyph), the specific outcomes (a drawing, a title of at most four words,
// one fact, one action, the reason behind an info glyph) and the prototype shortcuts (glyph chips, one per outcome, so every state is
// reachable by tapping). Content is read from the fixtures through the live store; nothing numeric is typed here. The camera is a drawn
// viewfinder: the prototype never opens one.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { getHall, getPackage, meta, type Booking, type Voucher } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { Avatar, Button, FactChip, FactRow, Icon, IconButton, InfoButton, Price, StatusPill, TextField, VoucherChip } from '../../../../system'
import { Fx, UserText, minutesBetween, useBi, useDays, useDurLead } from './bits'
import { Line, Lines, Panel } from './DetailParts'
import { QuietMoney, StruckMoney } from './Money'
import { StateStack } from './States'
import { CODE_PREFIX, formatTyped, type RedeemOutcome, type SampleCodes } from './redeem-model'
import './redeem.css'

// ---------------------------------------------------------------- scanner

export function Viewfinder({ torch, onTorch, onScan }: { torch: boolean; onTorch: () => void; onScan: () => void }) {
  const t = useT('hotel-bookings')
  return (
    <div className="hbk-scan" data-gz="Viewfinder">
      <div className="hbk-scan__glass" aria-hidden="true">
        <span className="hbk-scan__corner hbk-scan__corner--tl" />
        <span className="hbk-scan__corner hbk-scan__corner--tr" />
        <span className="hbk-scan__corner hbk-scan__corner--bl" />
        <span className="hbk-scan__corner hbk-scan__corner--br" />
        <Icon name="qr-code" size="lg" tone="inherit" />
        <span className="hbk-scan__line" />
      </div>
      <div className="hbk-scan__torch">
        <IconButton icon="bolt" label={torch ? t('hotelBookingsTorchOff') : t('hotelBookingsTorchOn')} variant="on-scrim" active={torch} onClick={onTorch} />
      </div>
      <Button variant="tertiary" iconStart="scan" onClick={onScan} className="hbk-scan__demo">
        {t('hotelBookingsScanDemo')}
      </Button>
    </div>
  )
}

export function CameraDenied({ onType }: { onType: () => void }) {
  const t = useT('hotel-bookings')
  const c = useT('common')
  return (
    <StateStack
      illustration="camera"
      title={t('hotelBookingsCameraDeniedTitle')}
      info={{ title: c('commonLabelDetails'), body: <p>{t('hotelBookingsCameraDeniedBody')}</p> }}
      actions={
        <Button variant="secondary" iconStart="key" onClick={onType}>
          {t('hotelBookingsTypeCode')}
        </Button>
      }
    />
  )
}

// ---------------------------------------------------------------- code field

export function CodeField({
  value,
  onChange,
  error,
  loading,
  onSubmit,
}: {
  value: string
  onChange: (typed: string) => void
  error?: string
  loading?: boolean
  onSubmit?: () => void
}) {
  const c = useT('common')
  return (
    <div className="hbk-code">
      <TextField
        label={c('commonVoucherCode')}
        value={value}
        onValueChange={v => onChange(formatTyped(v))}
        dir="ltr"
        autoCapitalize="characters"
        autoComplete="off"
        spellCheck={false}
        inputMode="text"
        maxLength={9}
        placeholder="2611-K7QM"
        startAdornment={
          <bdi dir="ltr" className="hbk-code__prefix gz-t-fig-title">
            {CODE_PREFIX}
          </bdi>
        }
        error={error}
        loading={loading}
        onKeyDown={e => {
          if (e.key === 'Enter') onSubmit?.()
        }}
      />
    </div>
  )
}

// ---------------------------------------------------------------- the quote of a code that can be redeemed

export function QuoteCard({ booking, voucher }: { booking: Booking; voucher: Voucher }) {
  const f = useFormat()
  const t = useT('hotel-bookings')
  const c = useT('common')
  const bi = useBi()
  const section = booking.sections[0]
  const hall = section ? getHall(section.hallId) : undefined
  const pkg = section ? getPackage(section.packageId) : undefined
  const first = booking.clientName.trim().split(/\s+/)[0] ?? booking.clientName
  const { voucherTotal, standardTotal, savings } = booking.totals
  const guests = booking.sections.reduce((n, s) => n + s.guests, 0)
  return (
    <Panel tone="paper" className="hbk-quote">
      <div className="hbk-quote__head">
        <Avatar name={booking.clientName} size="sm" voice="sans" />
        <UserText role="title" className="hbk-quote__name">
          {first}
        </UserText>
        <span className="hbk-quote__chips">
          <VoucherChip code={voucher.code} tone="bound" />
          <InfoButton title={c('commonVoucher')}>
            <p>{t('hotelBookingsRedeemFine')}</p>
          </InfoButton>
        </span>
      </div>
      <div className="hbk-quote__price">
        <span className="gz-sr-only">{c('commonVoucherPrice')}</span>
        <Price fils={voucherTotal.fils} mode="exact" size="total" />
        {standardTotal.fils > voucherTotal.fils ? (
          <span className="hbk-quote__compare">
            <span className="hbk-quote__was">
              <Icon name="offer" size="xs" tone="secondary" />
              <StruckMoney fils={standardTotal.fils} mode="exact" label={c('commonStandardPrice')} />
            </span>
            <span className="hbk-quote__save">
              <Icon name="trend-down" size="xs" tone="success" />
              <QuietMoney fils={savings.fils} mode="exact" label={t('hotelBookingsClientSaves')} />
            </span>
          </span>
        ) : null}
      </div>
      <Lines>
        {hall ? (
          <Line icon="hall" label={t('hotelBookingsRowHall')}>
            {bi(hall.hall.name)}
          </Line>
        ) : null}
        {pkg ? (
          <Line icon="package" label={t('hotelBookingsRowPackage')}>
            {bi(pkg.name)}
          </Line>
        ) : null}
        <Line
          icon="calendar"
          label={t('hotelBookingsRowDate')}
          facts={
            <FactRow label={t('hotelBookingsFactsLabel')}>
              <FactChip icon="users-three" label={t('hotelBookingsFactGuests')} value={f.integer(guests)} />
            </FactRow>
          }
        >
          <Fx text={f.date(booking.eventDate, 'short')} />
        </Line>
      </Lines>
    </Panel>
  )
}

// ---------------------------------------------------------------- calm outcomes for every specific error

export function ResultNotice({ outcome, onAgain }: { outcome: Exclude<RedeemOutcome, { kind: 'ready' }>; onAgain: () => void }): ReactNode {
  const t = useT('hotel-bookings')
  const c = useT('common')
  const f = useFormat()
  const days = useDays()
  const lead = useDurLead()
  const again = (
    <Button variant="secondary" iconStart="scan" onClick={onAgain}>
      {t('hotelBookingsTryAnother')}
    </Button>
  )
  const info = (key: 'hotelBookingsErrOtherBody' | 'hotelBookingsErrNotConfirmedBody' | 'hotelBookingsErrUsedBody' | 'hotelBookingsErrExpiredBody' | 'hotelBookingsErrUnknownBody') => ({
    title: c('commonLabelDetails'),
    body: <p>{t(key)}</p>,
  })
  let art: 'shield' | 'hourglass' | 'seal' | 'clock' | 'no-result' = 'no-result'
  let title: string
  let fact: ReactNode = null
  let detail
  switch (outcome.kind) {
    case 'other-partner':
      art = 'shield'
      title = t('hotelBookingsErrOtherTitle')
      detail = info('hotelBookingsErrOtherBody')
      break
    case 'not-confirmed': {
      art = 'hourglass'
      title = t('hotelBookingsErrNotConfirmedTitle')
      detail = info('hotelBookingsErrNotConfirmedBody')
      const by = outcome.booking?.confirmBy
      fact = by ? (
        <FactRow label={t('hotelBookingsConfirmLeft', { time: lead(minutesBetween(meta.now, by)).spoken })}>
          <FactChip icon="hourglass" tone="accent" label={t('hotelBookingsConfirmLeft', { time: lead(minutesBetween(meta.now, by)).spoken })} value={<Fx text={lead(minutesBetween(meta.now, by)).visual} />} />
        </FactRow>
      ) : null
      break
    }
    case 'already-used':
      art = 'seal'
      title = t('hotelBookingsErrUsedPlain')
      detail = info('hotelBookingsErrUsedBody')
      fact = outcome.usedAt ? (
        <FactRow label={t('hotelBookingsErrUsedPlain')}>
          <FactChip icon="calendar" label={t('hotelBookingsRowDate')} value={<Fx text={days.dayY(outcome.usedAt.slice(0, 10))} />} />
          <FactChip icon="clock" label={t('hotelBookingsRowTime')} value={<Fx text={f.time(outcome.usedAt)} />} />
        </FactRow>
      ) : null
      break
    case 'expired-or-refunded':
      art = 'clock'
      title = t('hotelBookingsErrExpiredTitle')
      detail = info('hotelBookingsErrExpiredBody')
      break
    default:
      title = t('hotelBookingsErrUnknownTitle')
      detail = info('hotelBookingsErrUnknownBody')
  }
  return (
    <div role="status">
      <StateStack illustration={art} title={title} info={detail} actions={again}>
        {fact}
      </StateStack>
    </div>
  )
}

// ---------------------------------------------------------------- prototype shortcuts

/** One code per outcome so the owner can reach every state by tapping. Quiet by design (glyph chips, no sentence); a prototype aid, not product UI. */
export function ProtoShortcuts({ codes, onPick }: { codes: SampleCodes; onPick: (code: string) => void }) {
  const t = useT('hotel-bookings')
  const items: { key: string; icon: IconName; label: string; code: string | null }[] = [
    { key: 'ready', icon: 'ticket', label: t('hotelBookingsProtoReady'), code: codes.ready },
    { key: 'notConfirmed', icon: 'hourglass', label: t('hotelBookingsProtoNotConfirmed'), code: codes.notConfirmed },
    { key: 'used', icon: 'check-double', label: t('hotelBookingsProtoUsed'), code: codes.used },
    { key: 'other', icon: 'lock', label: t('hotelBookingsProtoOther'), code: codes.other },
  ]
  const shown = items.filter(i => i.code)
  if (shown.length === 0) return null
  return (
    <div className="hbk-proto" data-proto role="group" aria-label={t('hotelBookingsProtoTitle')}>
      <span className="hbk-proto__tag gz-t-label">{t('hotelBookingsProtoTag')}</span>
      {shown.map(i => (
        <IconButton key={i.key} icon={i.icon} iconSize="sm" label={i.label} variant="outline" onClick={() => onPick(i.code as string)} />
      ))}
    </div>
  )
}
