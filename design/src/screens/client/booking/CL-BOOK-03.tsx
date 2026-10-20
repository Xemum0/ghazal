// CL-BOOK-03 Extras (step 3 of 5). Covers CA-BOOK-05, CA-BOOK-14, CA-VDET-13, CA-AUTH-10, CA-VCH-02.
// Text diet (ADR 0034): an extra is a glyph, a name and a price in its unit; choosing is the whole row (a ring that fills) or a stepper. No
// descriptions, ranges or counts. The one sentence of the step (extras are optional, priced separately at the voucher price where the venue has
// one, and settled with the venue directly) lives behind the info glyph beside the title. Optional add-ons in both columns (an extra the venue
// gives no voucher price is billed at its standard price), a running voucher total, and for a guest the account gate right before personal data.
// Continue is never disabled. Navigates to CL-BOOK-04, CL-AUTH-01 (sign in).
import { useEffect, useRef } from 'react'
import { Banner, Button, EmptyState, ErrorState, InfoButton, Skeleton, useBi, useNav } from '../../../system'
import { useT } from '../../../i18n'
import { usePrototype } from '../../../shell/state'
import { useFrame } from '../../../shell/frame'
import { useDevice } from '../../../shell/device/context'
import { BarTotal } from './_components/BarTotal'
import { ExtraRow } from './_components/ExtraRow'
import { StepScreen } from './_components/StepScreen'
import { quotePair, useFlow, useFlowStore, useScenario } from './_components/flow'
import './_components/step.css'
import './_components/extras.css'

export const states = ['none-offered', 'loading', 'error', 'offline', 'extras-selected', 'guest-gate']

const SCENARIO: Record<string, string> = { 'extras-selected': 'chosen-extras' }
/** The extras the screen lists, in the order a Kuwaiti couple asks about them (the rest stay in the venue's own list). */
const CATEGORIES = ['kosha', 'florals', 'photographer', 'zaffa', 'extra_hour', 'coffee_station', 'kids_corner', 'cake']

export default function ExtrasStep() {
  const t = useT('client-booking')
  const tc = useT('common')
  const bi = useBi()
  const nav = useNav()
  const { state } = useFrame()
  const { mode } = useDevice()
  const flow = useFlow(useScenario(state, SCENARIO))
  const local = useFlowStore()
  const draft = usePrototype(s => s.bookingDraft)
  const auth = usePrototype(s => s.auth)
  const patchDraft = usePrototype(s => s.patchDraft)
  const guest = state === 'guest-gate' || (mode === 'live' && auth === 'guest')
  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'
  const none = state === 'none-offered'

  const rows = none
    ? []
    : CATEGORIES.flatMap(c => flow.extras.filter(e => e.extra.category === c)).sort((a, b) => Number(a.included) - Number(b.included))
  const pair = quotePair(flow.quote)
  const gateReason = flow.voucher ? 'send-request' : 'voucher'
  const totalLabel = pair?.has ? t('clientBookingVoucherTotalLabel') : tc('commonMoneyTotal')

  // After the account sheet signs the guest in, the flow resumes on step 4 with every choice intact.
  const waiting = useRef(false)
  useEffect(() => {
    if (waiting.current && auth === 'signedIn') {
      waiting.current = false
      usePrototype.getState().clearGate()
      nav.push('CL-BOOK-04')
    }
  }, [auth, nav])

  const setIds = (ids: string[]) => patchDraft({ extras: ids })
  const toggle = (id: string) => setIds(draft.extras.includes(id) ? draft.extras.filter(x => x !== id) : [...draft.extras, id])
  const setQty = (id: string, qty: number) => {
    local.set({ extraQty: { ...local.extraQty, [id]: Math.max(qty, 1) } })
    if (qty > 0 && !draft.extras.includes(id)) setIds([...draft.extras, id])
    if (qty <= 0) setIds(draft.extras.filter(x => x !== id))
  }

  const next = () => {
    if (guest) {
      waiting.current = true
      usePrototype.getState().openGate(gateReason, { screenId: 'CL-BOOK-04' })
      nav.openSheet('CL-AUTH-01', { params: { reason: gateReason, resume: 'CL-BOOK-04' } })
    } else nav.push('CL-BOOK-04')
  }
  const skip = () => {
    setIds([])
    next()
  }

  return (
    <StepScreen
      step={3}
      venueName={bi(flow.venue.name)}
      title={t('clientBookingExtrasTitle')}
      info={
        // Nothing to explain when the venue sells no extras here: the empty state carries its own info glyph.
        none || error ? null : (
          <InfoButton title={t('clientBookingExtrasInfoTitle')}>
            <p>{t('clientBookingExtrasLead')}</p>
            <p>{t('clientBookingExtrasSettledNote')}</p>
          </InfoButton>
        )
      }
      notice={offline ? <Banner tone="offline" shape="card">{t('clientBookingOfflineBanner')}</Banner> : null}
      bar={
        error
          ? null
          : {
              summaryValue: loading || !pair ? <Skeleton inlineSize={96} blockSize={24} /> : <BarTotal fils={pair.total} icon={pair.has ? 'ticket' : 'coins'} label={totalLabel} />,
              // The offline banner above says why; the disabled action carries no second caption.
              action: { label: tc('commonActionContinue'), onPress: next, loading, disabled: offline },
            }
      }
    >
      {error ? (
        <div className="bk-section">
          <ErrorState kind="load" fill={false} />
        </div>
      ) : loading ? (
        <div className="bk-section" aria-busy="true">
          {[0, 1, 2, 3].map(i => (
            <div key={i} className="bk-extra__main">
              <Skeleton variant="block" inlineSize={40} blockSize={40} />
              <div className="bk-extra__text">
                <Skeleton inlineSize={160} blockSize={24} />
                <Skeleton inlineSize={96} blockSize={20} />
              </div>
              <Skeleton variant="block" inlineSize={24} blockSize={24} />
            </div>
          ))}
        </div>
      ) : none ? (
        <div className="bk-section">
          <EmptyState fill={false} illustration="bouquet" title={t('clientBookingExtrasNone')} detail={t('clientBookingExtrasNoneOffered')} detailTitle={t('clientBookingExtrasInfoTitle')} />
        </div>
      ) : (
        <section className="bk-section" aria-label={t('clientBookingExtrasTitle')}>
          <ul className="bk-extras">
            {rows.map(r => (
              <ExtraRow
                key={r.extra.id}
                extra={r.extra}
                date={flow.date}
                included={r.included}
                selected={r.selected}
                qty={r.qty}
                onToggle={() => toggle(r.extra.id)}
                onQty={q => setQty(r.extra.id, q)}
              />
            ))}
          </ul>
        </section>
      )}

      {!error && !loading && !none ? (
        <section className="bk-section bk-skip">
          <Button variant="tertiary" onClick={skip}>
            {t('clientBookingExtrasNone')}
          </Button>
        </section>
      ) : null}
    </StepScreen>
  )
}
