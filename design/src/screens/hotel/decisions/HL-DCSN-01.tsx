// HL-DCSN-01 Accept request (sheet). Requirement IDs: HA-BOOK-03, HA-DASH-03, HA-DASH-04, HA-AUTH-02.
// Voucher model (ADR 0033 D3, D4): accepting APPROVES the request at the voucher price and starts the fixed 24 hour window in which the
// client must confirm; the date is held until then. The usual Accept is inline (two taps, from the triage card, ADR 0008 D6). THIS sheet is
// the compact confirm: it opens when approving has side effects the manager must see (a competing request or an event within 14 days) and
// ends in "Accept" followed by the same 8-second Undo. There is no pay window, deposit, balance, bank or KYC step: the client pays the
// venue directly, off the app, after confirming. The venue may approve at a LOWER voucher price, never higher.
// Text diet (ADR 0034, docs/design/02-text-diet.md): the sheet speaks in glyphs and figures. The hold is an hourglass and `24 h`, a competing
// request is `users +1` with the scale glyph, the price is a ticket, the struck standard price and the saving, the off-app payment is a
// receipt glyph with one word. The sentences (what the hold means, the rule when the client does not confirm, the lower-price limit) live
// behind the info glyph of the header (voucher terms, the exception of policy section 6). Every state is a drawing, a short title and one action.
// Requirement homes: HA-BOOK-03 the Accept button; HA-DASH-03 the sheet opened from the triage list; HA-DASH-04 the `24 h` hold figure and the
// deadline of the success state; HA-AUTH-02 the sheets are opened by the roles that may accept (the Cancel sheet carries the role-hidden state).
// Story: Reem Al-Dosari, Thu 14 Jan 2027, Aurelia Danah Ballroom, 350 guests, voucher GV-2611-K7QM, standard KD 18,200.000, voucher
// KD 15,400.000, no competing request in the base seed (the `confirm-sheet` frame shows the competing variant).
import { useEffect, useRef, useState } from 'react'
import { competingRequest, requestsFor, voucherFor, type Booking } from '../../../mock'
import { useFormat, useT, T } from '../../../i18n'
import { usePrototype } from '../../../shell/state'
import { Button, FactChip, FactRow, Figures, Icon, IconButton, InfoButton, StatusPill, TextField, ThreadKnot, UndoBar, VoucherChip, useNav } from '../../../system'
import { SheetShell } from './_components/SheetShell'
import { RequestContext } from './_components/RequestContext'
import { DiscloseRow, PriceFact, SheetError, SheetState } from './_components/Blocks'
import { Fx } from './_components/Fx'
import { RICH } from './_components/local'
import {
  STORY_BOOKING_ID,
  commitAfterUndoWindow,
  confirmWindowHours,
  inHours,
  useClientName,
  useDecisionBooking,
  useDecisionParams,
  useHoursFig,
} from './_components/decisions'
import './HL-DCSN-01.css'

export const states = ['confirm-sheet', 'compare', 'lower-price', 'loading', 'success', 'undo', 'conflict', 'offline', 'error', 'already-updated', 'voucher-released-elsewhere']

type Phase = 'idle' | 'loading' | 'success' | 'undone'
type View = 'form' | 'success' | 'undone' | 'already-updated' | 'conflict' | 'released'

/** The demo reduction of the `lower-price` frame: KD 400.000 off the voucher price (KD 15,400.000 becomes KD 15,000.000). */
const DEMO_REDUCTION_TEXT = '400'

export default function AcceptRequest({ state }: { state?: string }) {
  const f = useFormat()
  const t = useT('hotel-decisions')
  const tc = useT('common')
  const nav = useNav()
  const params = useDecisionParams()
  const booking = useDecisionBooking(STORY_BOOKING_ID)
  const voucher = usePrototype(s => s.vouchers.find(v => v.id === booking.voucherId)) ?? voucherFor(booking)
  const live = state === undefined

  // ---- what the sheet knows about the request
  const others =
    state === 'confirm-sheet' || state === 'compare' || params.simulateCompeting
      ? 1
      : booking.venueId
        ? (requestsFor(booking.venueId).find(r => r.booking.id === booking.id)?.otherRequestsSameDate ?? 0)
        : 0
  const client = useClientName(booking)
  const name = client.first
  const date = f.date(booking.eventDate, 'short')
  const hours = confirmWindowHours()
  const duration = tc('commonCountHours', { count: hours })
  const hold = useHoursFig()(hours)

  // ---- local interaction state
  const [phase, setPhase] = useState<Phase>(state === 'success' ? 'success' : state === 'undo' ? 'undone' : state === 'loading' ? 'loading' : 'idle')
  const [lowerOpen, setLowerOpen] = useState(state === 'lower-price')
  const [reductionText, setReductionText] = useState(state === 'lower-price' ? DEMO_REDUCTION_TEXT : '')
  const [compareOpen, setCompareOpen] = useState(state === 'compare')
  const [failed, setFailed] = useState(state === 'error')
  const moneyBlock = useRef<HTMLDivElement>(null)
  const timer = useRef(0)
  useEffect(() => () => window.clearTimeout(timer.current), [])
  // Opening the reduction brings its field into view (the middle of the sheet scrolls under the pinned footer).
  useEffect(() => {
    if (lowerOpen) moneyBlock.current?.scrollIntoView({ block: 'end', behavior: 'auto' })
  }, [lowerOpen])

  const stale = live && phase === 'idle' && booking.status !== 'pending'
  const released = (live && phase === 'idle' && voucher !== undefined && voucher.status !== 'bound') || state === 'voucher-released-elsewhere'
  const view: View =
    state === 'already-updated' || stale
      ? 'already-updated'
      : released
        ? 'released'
        : state === 'conflict'
          ? 'conflict'
          : phase === 'success'
            ? 'success'
            : phase === 'undone'
              ? 'undone'
              : 'form'
  const offline = state === 'offline'

  // ---- the price: integer fils, the voucher column is what the client pays the venue; a reduction can only lower it
  const quoted = booking.totals.voucherTotal
  const standard = booking.totals.standardTotal
  const typed = f.normalizeDigits(reductionText).replace(/[\s,]/g, '')
  const typedFils = /^\d+(\.\d{1,3})?$/.test(typed) ? Math.round(Number(typed) * 1000) : 0
  const reductionFils = lowerOpen ? typedFils : 0
  const tooHigh = reductionFils >= quoted.fils
  const appliedFils = tooHigh ? 0 : reductionFils
  const voucherFils = quoted.fils - appliedFils
  const savingFils = Math.max(0, standard.fils - voucherFils)
  const currency = f.moneyParts(0).currency
  const deadline = f.dateTime(view === 'success' ? (booking.confirmBy ?? inHours(hours)) : inHours(hours))

  // ---- the approval (live prototype only)
  const accept = () => {
    if (!live) return
    setPhase('loading')
    timer.current = window.setTimeout(() => {
      usePrototype.getState().acceptRequest(booking.id, appliedFils > 0 ? { lowerVoucherTotal: { fils: voucherFils, currency: quoted.currency } } : undefined)
      commitAfterUndoWindow(booking.id)
      setPhase('success')
    }, 480)
  }
  const undo = () => {
    usePrototype.getState().undoLastHotelAction()
    setPhase('undone')
  }
  const close = () => nav.closeSheet()
  const propose = () => {
    close()
    nav.openSheet('HL-DCSN-03', { params: { bookingId: booking.id } })
  }

  // ---- footer: one action; the way out is the close glyph of the header
  let footer
  if (failed) {
    footer = null
  } else if (offline) {
    footer = (
      <Button variant="primary" fullWidth iconStart="check" disabled>
        {t('hotelDecisionsAcceptCta')}
      </Button>
    )
  } else if (view === 'success') {
    footer = (
      <>
        <UndoBar message={t('hotelDecisionsNotifying')} onUndo={undo} onExpire={close} />
        <Button variant="tertiary" onClick={() => { close(); nav.push('HL-BOOK-03', { bookingId: booking.id }) }}>
          {t('hotelDecisionsViewBooking')}
        </Button>
      </>
    )
  } else if (view === 'undone') {
    footer = (
      <Button variant="secondary" size="cta" fullWidth onClick={close}>
        {tc('commonActionDone')}
      </Button>
    )
  } else if (view === 'already-updated') {
    footer = (
      <Button variant="primary" fullWidth onClick={close}>
        {t('hotelDecisionsRefresh')}
      </Button>
    )
  } else if (view === 'released') {
    footer = (
      <Button variant="secondary" size="cta" fullWidth onClick={close}>
        {tc('commonActionClose')}
      </Button>
    )
  } else if (view === 'conflict') {
    footer = (
      <>
        <Button variant="primary" fullWidth iconStart="check" disabled>
          {t('hotelDecisionsAcceptCta')}
        </Button>
        <Button variant="secondary" fullWidth onClick={propose}>
          {t('hotelDecisionsProposeTitle')}
        </Button>
      </>
    )
  } else {
    footer = (
      <Button variant="primary" fullWidth iconStart="check" loading={phase === 'loading'} disabled={tooHigh} onClick={accept}>
        {t('hotelDecisionsAcceptCta')}
      </Button>
    )
  }

  // The sentences of the sheet, behind the info glyph of the header (voucher terms).
  const info =
    view === 'form' && !failed && !offline ? (
      <InfoButton title={t('hotelDecisionsTermsTitle')}>
        <p>
          <T ns="hotel-decisions" k="hotelDecisionsAcceptConsequence" values={{ date, name, duration }} components={RICH} />
        </p>
        <p>{t('hotelDecisionsAcceptConfirmRule')}</p>
        <p>{t('hotelDecisionsAcceptPriceHint')}</p>
        <p>{t('hotelDecisionsAcceptLowerHint')}</p>
      </InfoButton>
    ) : undefined

  let body
  if (failed) {
    body = <SheetError onRetry={() => setFailed(false)} />
  } else if (offline) {
    body = <SheetState illustration="wifi-off" title={tc('commonStateTitleNetwork')} detail={t('hotelDecisionsOfflineInfo')} />
  } else if (view === 'already-updated') {
    body = <SheetState illustration="empty-bookings" title={t('hotelDecisionsAlreadyTitle')} detail={t('hotelDecisionsAlreadyBody')} />
  } else if (view === 'released') {
    body = <SheetState illustration="voucher" title={t('hotelDecisionsReleasedTitle')} detail={t('hotelDecisionsReleasedBody')} />
  } else if (view === 'conflict') {
    body = (
      <SheetState
        illustration="calendar"
        title={t('hotelDecisionsConflictTitle')}
        detail={<T ns="hotel-decisions" k="hotelDecisionsConflictBody" values={{ date }} components={RICH} />}
      />
    )
  } else if (view === 'success') {
    body = (
      <SheetState
        kind="success"
        illustration="success-booking"
        title={t('hotelDecisionsAcceptedTitle')}
        detail={
          <>
            <p>
              <T ns="hotel-decisions" k="hotelDecisionsAcceptedBody" values={{ name, deadline }} components={RICH} />
            </p>
            <p>{t('hotelDecisionsAcceptedUndoHint')}</p>
          </>
        }
      >
        <FactRow label={t('hotelDecisionsAcceptHoldLabel', { duration })}>
          <FactChip icon="hourglass" tone="accent" label={t('hotelDecisionsAcceptHoldLabel', { duration })} value={<Fx text={hold} />} />
          <FactChip icon="clock" label={t('hotelDecisionsAcceptDeadlineLabel')} value={<Fx text={deadline} />} />
        </FactRow>
      </SheetState>
    )
  } else if (view === 'undone') {
    body = (
      <SheetState illustration="hourglass" title={t('hotelDecisionsUndoneTitle')} detail={t('hotelDecisionsUndoneBody')}>
        <StatusPill status="pending" audience="hotel" />
      </SheetState>
    )
  } else {
    body = (
      <>
        <section className="gzd-acc__hold" aria-label={t('hotelDecisionsAcceptHoldLabel', { duration })}>
          <span className="gzd-acc__hold-disk" aria-hidden="true">
            <Icon name="hourglass" size="md" tone="accent" />
          </span>
          <span className="gz-sr-only">{t('hotelDecisionsAcceptHoldLabel', { duration })}</span>
          <span className="gzd-acc__hold-fig gz-t-kpi">
            <Fx text={hold} />
          </span>
          <span className="gzd-acc__thread" aria-hidden="true">
            <ThreadKnot state="now" size="compact" />
            <span className="gz-thread-track gzd-acc__line">
              <span className="gz-thread-fill gz-thread-draw" />
            </span>
            <ThreadKnot state="open" size="compact" />
          </span>
        </section>

        {others > 0 ? (
          <>
            <div className="gzd-acc__others">
              <FactChip icon="users-three" tone="accent" label={t('hotelDecisionsAcceptOthersLine', { count: others })} value={<Figures text={`+${f.integer(others)}`} />} />
              <IconButton
                icon="compare"
                iconSize="sm"
                variant="outline"
                label={t('hotelDecisionsAcceptCompare')}
                active={compareOpen}
                aria-expanded={compareOpen}
                onClick={() => setCompareOpen(o => !o)}
              />
            </div>
            {compareOpen ? <ComparePanel booking={booking} other={competingRequest} /> : null}
          </>
        ) : null}

        <div ref={moneyBlock} className="gzd-acc__money">
          <section className="gzd-acc__price" aria-label={tc('commonVoucherPrice')}>
            <div className="gzd-acc__price-main">
              <PriceFact fils={voucherFils} label={tc('commonVoucherPrice')} size="total" />
              <FactChip icon="receipt" tone="muted" size="sm" label={t('hotelDecisionsAcceptPriceHint')} value={<span className="gz-t-caption">{t('hotelDecisionsAcceptOffApp')}</span>} />
            </div>
            <div className="gzd-acc__price-sub">
              <span className="gzd-acc__was">
                <Icon name="offer" size="xs" tone="secondary" />
                <span className="gz-sr-only">{tc('commonStandardPrice')}</span>
                <span className="gz-t-fig-body-s gz-strike">
                  <bdi dir="ltr">{f.money(standard.fils, { mode: 'browse' })}</bdi>
                </span>
              </span>
              <span className="gzd-acc__save gz-t-body-s">
                <Icon name="trend-down" size="xs" tone="success" mirror={false} />
                <span className="gz-sr-only">{tc('commonYouSave', { amount: f.money(savingFils, { mode: 'browse' }) })}</span>
                <span aria-hidden="true">
                  <Figures text={f.money(savingFils, { mode: 'browse' })} />
                </span>
              </span>
            </div>
          </section>

          <DiscloseRow icon="percent" title={t('hotelDecisionsAcceptLower')} open={lowerOpen} onToggle={() => setLowerOpen(o => !o)} />
          {lowerOpen ? (
            <div className="gzd-acc__lower">
              <TextField
                label={t('hotelDecisionsAcceptLowerLabel')}
                value={reductionText}
                onValueChange={setReductionText}
                inputMode="decimal"
                dir="ltr"
                startAdornment={<span className="gz-t-label gzd-acc__unit">{currency}</span>}
                error={tooHigh ? t('hotelDecisionsAcceptLowerTooHigh') : undefined}
              />
            </div>
          ) : null}
        </div>
      </>
    )
  }

  // End of the context strip: the voucher code while the decision is open (it is what the couple shows at the venue), the status once it moved.
  const contextEnd =
    view === 'already-updated' ? <StatusPill status={booking.status} audience="hotel" /> : view === 'form' && voucher ? <VoucherChip code={voucher.code} /> : undefined

  return (
    <SheetShell
      title={t('hotelDecisionsAcceptTitle')}
      info={info}
      context={<RequestContext booking={booking} end={contextEnd} />}
      footer={footer}
      onClose={close}
    >
      {body}
    </SheetShell>
  )
}

/** The count-only comparison of ADR 0008 D5: this request beside the other one, details and no identities (no names, no note about privacy). */
function ComparePanel({ booking, other }: { booking: Booking; other: Booking }) {
  const f = useFormat()
  const t = useT('hotel-decisions')
  const tc = useT('common')
  const col = (b: Booking, title: string) => (
    <div className="gzd-acc__col">
      <span className="gz-t-label gzd-acc__col-title">{title}</span>
      <FactChip icon="users-three" label={t('hotelDecisionsFactGuests')} value={f.integer(b.sections[0]?.guests ?? 0)} />
      <PriceFact fils={b.totals.voucherTotal.fils} label={tc('commonVoucherPrice')} />
      <FactChip icon="clock" tone="muted" label={t('hotelDecisionsAcceptCompareReceived')} value={<Fx text={f.time(b.createdAt)} />} />
    </div>
  )
  return (
    <div className="gzd-acc__compare" role="group" aria-label={t('hotelDecisionsAcceptCompare')}>
      {col(booking, t('hotelDecisionsAcceptCompareThis'))}
      {col(other, t('hotelDecisionsAcceptCompareOther'))}
    </div>
  )
}
