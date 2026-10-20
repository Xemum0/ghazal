// VoucherLock: the facts a voucher binds, shown as locked rows on step 1 (ADR 0033 D3, A-01): the date, then the hall as the same photograph
// plate the Review closes with (the flow's bookends), with its facts. One ruled block, not a panel. The lock glyph and the voucher chip say why nothing here is editable (the words are the accessible name); one quiet
// "Change" opens the voucher quote sheet (CL-VCHR-04) where a change is checked against the saving test. Facts are glyph and value:
// the reception section (glyph is the value), the guests, the session, how soon the venue answers.
import { Button, FactChip, Figures, Icon, VoucherChip, useBi } from '../../../../system'
import { useFormat, useT } from '../../../../i18n'
import { AUDIENCE_GLYPH, sessionGlyph } from './glyphs'
import { ReplyFact } from './ReplyFact'
import { RequestPlate } from './ReviewParts'
import type { FlowModel } from './flow'
import './lock.css'

export type VoucherLockProps = {
  flow: FlowModel
  onChange: () => void
}

const HOSTING_KEY = { women: 'clientBookingHostingWomen', men: 'clientBookingHostingMen', mixed: 'clientBookingHostingMixed' } as const

export function VoucherLock({ flow, onChange }: VoucherLockProps) {
  const t = useT('client-booking')
  const f = useFormat()
  const bi = useBi()
  const voucher = flow.voucher
  const first = flow.sections[0]!
  const session = first.sessions.find(s => s.id === first.sessionId)
  return (
    <div className="bk-lock" data-gz="VoucherLock" data-gz-id="booking.lock">
      <header className="bk-lock__head">
        <span className="bk-lock__title">
          <Icon name="lock" size="xs" tone="secondary" />
          <span className="gz-sr-only">{t('clientBookingFromVoucher')}</span>
          {voucher ? <VoucherChip code={voucher.code} tone="ready" /> : null}
        </span>
        <Button variant="tertiary" onClick={onChange} className="bk-lock__change" aria-label={t('clientBookingFromVoucherChangeAria')}>
          {t('clientBookingFromVoucherChange')}
        </Button>
      </header>
      <ul className="bk-lock__rows">
        <li className="bk-lock__row" data-gz-id="booking.date">
          <Icon name="calendar" size="md" tone="secondary" />
          <span className="bk-lock__text">
            <span className="bk-lock__value gz-t-title">
              <Figures text={f.date(flow.date, 'full')} />
            </span>
          </span>
        </li>
        <li className="bk-lock__row bk-lock__row--plate">
          <RequestPlate
            wide
            cover={first.hall.cover ?? flow.venue.cover}
            hallName={bi(first.hall.name)}
            facts={
              <>
                <FactChip icon={AUDIENCE_GLYPH[first.audience]} label={t(HOSTING_KEY[first.audience])} />
                <FactChip icon="users-three" label={t('clientBookingGuestsLabel')} value={f.integer(first.guests)} />
                {session ? <FactChip icon={sessionGlyph(session.start)} label={bi(session.name)} /> : null}
                <ReplyFact flow={flow} />
              </>
            }
          />
        </li>
      </ul>
    </div>
  )
}
