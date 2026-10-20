// Ticket: one voucher in the wallet. A paper ticket (hairline card, perforation with two notches, the system voucher look). The top half is the
// one tap target that opens the voucher: the venue (photograph or monogram, name), the event date as a fact, the saving as a figure with its
// glyph and the state as icon + one word. The bottom half (the stub) carries ONE fact, the date that matters for this state (valid until,
// reusable until, confirm by, used on), and the actions that fit it. No sentences (ADR 0034). No gold fill: the verb of the screen is the button
// the viewer chooses, and a ticket is a fact.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import type { CreditVoucher, Voucher, WalletVoucher } from '../../../../mock'
import { AnyVenueMark, FactChip, FactRow, Icon, StatusPill, type VoucherState } from '../../../../system'
import { Fx } from './Fx'
import { Saving } from './Saving'
import { Thumb } from './Thumb'
import { useVc } from './useVc'
import { useFactsOfVoucher } from './model'
import './ticket.css'

/** The one fact of the stub: a glyph, the word that names it (read by assistive technology only) and its value. */
export type StubFact = { icon: IconName; label: string; value: string; tone?: 'muted' | 'accent' }

export type TicketProps = {
  voucher: WalletVoucher
  stub?: StubFact
  actions?: ReactNode
  onOpen?: () => void
}

export function Ticket({ voucher: v, stub, actions, onOpen }: TicketProps) {
  if (v.kind === 'credit') return <CreditTicket voucher={v} stub={stub} actions={actions} onOpen={onOpen} />
  return <BoundTicket voucher={v} stub={stub} actions={actions} onOpen={onOpen} />
}

/** A credit voucher from support: a gift glyph and the "any hall, hotel or service" line instead of a venue, no event date, no saving. */
function CreditTicket({ voucher: v, ...rest }: TicketProps & { voucher: CreditVoucher }) {
  const { tc } = useVc()
  const state = (v.status === 'active' ? 'voucher_credit' : `voucher_${v.status}`) as VoucherState
  const name = tc('commonVoucherCredit')
  const top = (
    <>
      <span className="gzv-ticket__who">
        <span className="gz-vch__icon" aria-hidden="true">
          <Icon name="gift" size="md" />
        </span>
        <span className="gzv-ticket__text">
          <span className="gzv-ticket__name gz-t-d1" dir="auto">
            {name}
          </span>
          <AnyVenueMark />
        </span>
      </span>
      <span className="gzv-ticket__meta">
        <span />
        <StatusPill status={state} />
      </span>
    </>
  )
  return <Shell {...rest} status={v.status} label={`${name} ${v.code}`} top={top} />
}

function BoundTicket({ voucher: v, ...rest }: TicketProps & { voucher: Voucher }) {
  const { t, dayMon } = useVc()
  const facts = useFactsOfVoucher(v)
  const saving = Math.max(0, v.quoteFils.standard - v.quoteFils.voucher)
  const state = `voucher_${v.status}` as VoucherState
  const top = (
    <>
      <span className="gzv-ticket__who">
        <Thumb facts={facts} />
        <span className="gzv-ticket__text">
          <span className="gzv-ticket__name gz-t-d1" dir="auto">
            {facts.name}
          </span>
          <FactRow>
            <FactChip icon="calendar" label={t('clientVouchersLabelEvent')} value={<Fx text={dayMon(v.eventDate)} />} tone="muted" />
          </FactRow>
        </span>
      </span>
      <span className="gzv-ticket__meta">
        {saving > 0 ? <Saving fils={saving} /> : <span />}
        <StatusPill status={state} />
      </span>
    </>
  )
  return <Shell {...rest} status={v.status} label={`${facts.name} ${v.code}`} top={top} />
}

function Shell({ stub, actions, onOpen, status, label, top }: Omit<TicketProps, 'voucher'> & { status: string; label: string; top: ReactNode }) {
  return (
    <article className="gzv-ticket" data-gz="WalletTicket" data-status={status} data-solo={!stub && !actions ? '' : undefined} aria-label={label}>
      {onOpen ? (
        <button type="button" className="gz-reset gz-press gzv-ticket__top gzv-ticket__open" onClick={onOpen}>
          {top}
        </button>
      ) : (
        <div className="gzv-ticket__top">{top}</div>
      )}
      {stub || actions ? (
        <>
          <div className="gzv-ticket__perf" aria-hidden="true">
            <span className="gzv-ticket__cap" />
            <span className="gzv-ticket__dash" />
            <span className="gzv-ticket__cap" />
          </div>
          <div className="gzv-ticket__bottom">
            {stub ? (
              <FactRow>
                <FactChip icon={stub.icon} label={stub.label} value={<Fx text={stub.value} />} tone={stub.tone ?? 'muted'} />
              </FactRow>
            ) : null}
            {actions ? <div className="gzv-ticket__actions">{actions}</div> : null}
          </div>
        </>
      ) : null}
    </article>
  )
}
