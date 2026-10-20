// CL-BOOK-01 Your event (step 1 of 5). Covers CA-BOOK-01, CA-BOOK-02, CA-BOOK-03, CA-BOOK-06, CA-BOOK-14, CA-VDET-22, CA-CMP-10, CA-VCH-09.
// Text diet (ADR 0034): the screen is a date, a hall, a guest count and a few glyphs. With a voucher bound to the quote the date, reception,
// hall and guests arrive locked as facts (lock glyph and the voucher chip; change = CL-VCHR-04; the hall is the same photograph plate the
// Review closes with, so the flow has bookends); without one a "voucher first" panel (a drawing,
// two words, the KD 2 figure, the sentence behind its info glyph) opens CL-VCHR-01 and the same step composes a quote. The reception is three
// glyphs, the session a sun, sunset or moon with its time, the occasion one row that opens its five choices (optional either way).
// One primary action: Continue (or Get voucher), with the voucher price (an estimate until a package is chosen) beside it.
// Navigates to CL-BOOK-02, CL-VENU-03 (calendar), CL-BOOK-07, CL-VENU-01, CL-VCHR-01, CL-VCHR-04.
import { useLayoutEffect } from 'react'
import { Banner, ChipGroup, Figures, Icon, IconListRow, IconSegmented, Skeleton, useBi, useNav } from '../../../system'
import { useFormat, useT } from '../../../i18n'
import { usePrototype } from '../../../shell/state'
import { useFrame } from '../../../shell/frame'
import * as mock from '../../../mock'
import { BarTotal } from './_components/BarTotal'
import { DateRow } from './_components/DateRow'
import { HallChoice } from './_components/HallChoice'
import { GuestsField } from './_components/GuestsField'
import { ReplyFact } from './_components/ReplyFact'
import { StateNote } from './_components/StateNote'
import { StepScreen } from './_components/StepScreen'
import { VoucherLock } from './_components/VoucherLock'
import { VoucherNeed } from './_components/VoucherNeed'
import { useVoucherActions } from './_components/voucherActions'
import { AUDIENCE_GLYPH, sessionGlyph } from './_components/glyphs'
import { findVoucher, quotePair, useFlow, useFlowStore, useLive, type FlowModel, type OccasionKey, type SectionModel } from './_components/flow'
import './_components/step.css'
import './_components/lock.css'
import './CL-BOOK-01.css'

export const states = ['loading-price', 'error', 'offline', 'guests-below-minimum', 'guests-over-capacity', 'session-picker', 'date-just-taken', 'no-voucher-redirect']

const SCENARIO: Record<string, string> = {
  'guests-below-minimum': 'below-min',
  'guests-over-capacity': 'over-cap',
  'session-picker': 'session',
  'no-voucher-redirect': 'novoucher',
}

const OCCASIONS: OccasionKey[] = ['wedding', 'milka', 'henna', 'engagement', 'other']
const OCCASION_KEY = {
  wedding: 'clientBookingOccasionWedding',
  milka: 'clientBookingOccasionMilka',
  henna: 'clientBookingOccasionHenna',
  engagement: 'clientBookingOccasionEngagement',
  other: 'clientBookingOccasionOther',
} as const

export default function YourEvent() {
  const t = useT('client-booking')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const nav = useNav()
  const { state } = useFrame()
  const flow = useFlow(state ? SCENARIO[state] : undefined)
  const local = useFlowStore()
  const patchDraft = usePrototype(s => s.patchDraft)
  const first = flow.sections[0]!

  // A static frame never touches the store. In the player the request starts here: a venue (and optionally a date) arrives as params
  // from a card, Venue detail, the calendar or Compare; the draft then autosaves every change, so Back is always safe.
  const live = useLive()
  const params = nav.params as { venueId?: string; date?: string; hallId?: string; guests?: number; fresh?: boolean; voucherId?: string }
  useLayoutEffect(() => {
    if (!live) return
    const s = usePrototype.getState()
    const wanted = params.venueId
    // A new run (no booking step on screen yet) starts from a clean flow memory: no consent left over.
    if (wanted && !Object.values(useFlowStore.getState().entered).some(Boolean)) useFlowStore.getState().reset()
    // The voucher the person just bought (or chose) survives the fresh draft: it is looked up before the draft is replaced.
    const carriedVoucher = params.voucherId ?? s.bookingDraft.voucherId
    if (wanted && (wanted !== s.bookingDraft.venueId || params.fresh)) {
      s.startDraft(wanted, {
        ...(params.date ? { eventDate: params.date } : {}),
        ...(params.hallId ? { hallId: params.hallId } : {}),
        ...(params.guests ? { guests: params.guests } : {}),
      })
    } else {
      if (!s.bookingDraft.venueId) s.startDraft(wanted ?? flow.venue.id)
      if (params.date && params.date !== s.bookingDraft.eventDate) s.patchDraft({ eventDate: params.date })
    }
    // A ready voucher for this venue binds the quote: date, hall, package and guests come from it (A-01).
    const after = usePrototype.getState()
    const venueId = after.bookingDraft.venueId ?? flow.venue.id
    const v = after.auth === 'signedIn' ? findVoucher(after.vouchers, after.user?.id ?? mock.meta.clientUserId, venueId, carriedVoucher, params.date ?? after.bookingDraft.eventDate) : null
    if (v) {
      after.patchDraft({ voucherId: v.id, eventDate: v.eventDate, hallId: v.hallId, packageId: v.packageId, guests: v.guests ?? after.bookingDraft.guests })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [live])

  const { getVoucher, changeVoucher } = useVoucherActions(flow, 'CL-BOOK-01')
  const bound = Boolean(flow.voucher)
  const fee = f.money(mock.meta.config.voucherFeeFils, { mode: 'browse' })

  const setHosting = (h: FlowModel['hosting']) => patchDraft({ audience: h, hallId: null, packageId: null })

  const hallsOf = (s: SectionModel) => flow.venue.halls.filter(h => h.sections.some(x => x.audience === s.audience))
  const sessionLabel = (s: SectionModel['sessions'][number]) => (
    <span className="bk-session">
      <Icon name={sessionGlyph(s.start)} size="sm" />
      <span className="gz-sr-only">{bi(s.name)}</span>
      <Figures text={f.time(mock.engine.at(flow.date, s.start))} />
    </span>
  )

  const blocks = flow.sections.map(sec => {
    const halls = bound ? [] : hallsOf(sec)
    return (
      <div className="bk-block" key={sec.position} data-gz-id={`booking.section.${sec.position}`}>
        {halls.length > 1 ? (
          <HallChoice
            label={t('clientBookingHallLabel')}
            value={sec.hall.id}
            halls={halls.map(h => ({ hall: h, max: h.sections.find(x => x.audience === sec.audience)?.maxGuests ?? h.capacity.max }))}
            onChange={v => patchDraft({ hallId: v, packageId: null })}
          />
        ) : null}
        {sec.sessions.length > 1 ? (
          <ChipGroup
            label={t('clientBookingSessionLabel')}
            options={sec.sessions.map(s => ({ value: s.id, label: sessionLabel(s) }))}
            value={sec.sessionId}
            onChange={v => v && patchDraft({ sessionId: v })}
          />
        ) : null}
        {bound ? null : <GuestsField section={sec} onChange={n => patchDraft({ guests: n })} />}
      </div>
    )
  })

  const over = flow.sections.some(s => s.guests > s.maxGuests)
  const taken = state === 'date-just-taken' || (live && !flow.dateOk)
  const offline = state === 'offline'
  const error = state === 'error'
  const loading = state === 'loading-price'

  const openTaken = () => nav.openSheet('CL-BOOK-07', { params: { reason: 'date_taken', venueId: flow.venue.id, date: flow.date, from: 'CL-BOOK-01' } })
  const openCalendar = () => nav.openSheet('CL-VENU-03', { params: { source: 'booking', venueId: flow.venue.id, hallId: first.hall.id, date: flow.date, guests: first.guests } })
  const commit = () => {
    patchDraft({ venueId: flow.venue.id, hallId: first.hall.id, sessionId: first.sessionId, eventDate: flow.date, audience: flow.audience, guests: first.guests, step: 'package' })
    nav.push('CL-BOOK-02')
  }
  // The occasion is optional: one row, its five choices in a sheet (a choice closes it; the same choice again clears it).
  const pickOccasion = () =>
    nav.openSheet(
      <div className="bk-sheet-body">
        <ChipGroup
          label={t('clientBookingOccasionLabel')}
          options={OCCASIONS.map(o => ({ value: o, label: t(OCCASION_KEY[o]) }))}
          defaultValue={useFlowStore.getState().occasion}
          deselectable
          onChange={v => {
            useFlowStore.getState().set({ occasion: v })
            nav.closeSheet()
          }}
        />
      </div>,
      { title: t('clientBookingOccasionLabel') },
    )

  const pair = quotePair(flow.quote)
  // No voucher bound yet: the one gold action is getting it (a request cannot be sent without one).
  const needVoucher = !bound && !error && !offline && !taken
  // The offline banner above already says why the action waits: no second caption under it.
  const reason = taken ? t('clientBookingDateTakenReason') : over ? tc('commonUnitUpToGuests', { count: first.maxGuests }) : undefined
  const voucherLabel = t(flow.final ? 'clientBookingVoucherTotalLabel' : 'clientBookingVoucherEstimateLabel')

  return (
    <StepScreen
      step={1}
      venueName={bi(flow.venue.name)}
      title={t('clientBookingEventTitle')}
      notice={
        offline ? (
          <Banner tone="offline" shape="card">{t('clientBookingOfflineBanner')}</Banner>
        ) : error ? (
          <div className="bk-notice">
            <StateNote tone="danger" icon="warning-circle">
              {t('clientBookingPriceErrorBanner')}
            </StateNote>
          </div>
        ) : taken ? (
          <div className="bk-notice">
            <StateNote tone="danger" icon="calendar-x" action={{ label: t('clientBookingDateTakenAction'), onPress: openTaken }}>
              {t('clientBookingDateTakenBanner', { date: f.date(flow.date, 'short') })}
            </StateNote>
          </div>
        ) : null
      }
      bar={{
        summaryValue: loading ? (
          <Skeleton inlineSize={96} blockSize={24} />
        ) : error || !pair ? null : (
          <BarTotal fils={pair.total} icon={bound && pair.has ? 'ticket' : 'coins'} label={bound && pair.has ? voucherLabel : tc('commonMoneyTotal')} estimate={!bound && !flow.final} />
        ),
        action: needVoucher
          ? { label: t('clientBookingNeedVoucherAction', { fee }), onPress: getVoucher, loading, disabled: Boolean(reason) || offline, reason }
          : { label: error ? tc('commonActionRetry') : tc('commonActionContinue'), onPress: commit, loading, disabled: Boolean(reason) || offline, reason },
      }}
    >
      {bound ? (
        <section className="bk-section bk-section--tight" aria-label={t('clientBookingFromVoucher')}>
          <VoucherLock flow={flow} onChange={changeVoucher} />
        </section>
      ) : (
        <section className="bk-section bk-section--tight" aria-label={t('clientBookingDateChange')}>
          <VoucherNeed onGet={getVoucher} />
          <DateRow date={flow.date} onPress={openCalendar} />
          <div className="bk-facts-line">
            <ReplyFact flow={flow} />
          </div>
        </section>
      )}

      {!bound && flow.hostingOptions.length > 1 ? (
        <section className="bk-section bk-section--tight">
          <IconSegmented
            label={t('clientBookingHostingLabel')}
            value={flow.hosting}
            onChange={setHosting}
            options={flow.hostingOptions.map(h => ({
              value: h,
              icon: AUDIENCE_GLYPH[h],
              label: t(h === 'women' ? 'clientBookingHostingWomenShort' : h === 'men' ? 'clientBookingHostingMenShort' : 'clientBookingHostingMixedShort'),
            }))}
          />
        </section>
      ) : null}

      {bound && !flow.sections.some(x => x.sessions.length > 1) ? null : <section className="bk-section">{blocks}</section>}

      <section className="bk-section bk-section--tight">
        <IconListRow
          flush
          last
          icon="sparkle"
          title={t('clientBookingOccasionLabel')}
          trailing={local.occasion ? <span className="gz-t-body-s">{t(OCCASION_KEY[local.occasion])}</span> : undefined}
          chevron
          onClick={pickOccasion}
        />
      </section>
    </StepScreen>
  )
}
