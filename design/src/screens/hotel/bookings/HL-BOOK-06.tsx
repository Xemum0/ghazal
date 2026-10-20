// HL-BOOK-06 Redeem a voucher. Requirement IDs: HA-VCH-01, HA-VCH-02, HA-VCH-05, HA-AUTH-02.
// Redeem a client voucher at the venue (ADR 0033, voucher-model 8.2): scan the QR or type the code, see the bound quote and confirm. The
// check says whether the code belongs to this partner, whether the request is confirmed and whether it was used before, with specific calm
// errors that never reveal client data. The single gold primary is "Redeem voucher" (Admin, Manager, Reception). Redeeming is never queued
// offline. Reachable from Bookings (header), Today (quick action) and the Booking detail bar, which opens it with the code prefilled.
// In the prototype the camera is a drawn viewfinder: "Simulate" reads the next ready voucher, and the four glyph chips under it reach every
// outcome by tapping (they are a prototype aid, not product UI).
// Text diet (ADR 0034): the scan and code choice is two glyphs with the chosen word; the viewfinder has no caption; the quote is one figure,
// the client, the date, the hall, the package and the guests; every error is a drawing, a title and one action with the reason behind an info
// glyph; the sentence that a redemption cannot be undone is behind the info glyph of the quote.
// States: manual-code, checking, ready-to-redeem, wrong-venue, not-confirmed-yet, already-used, expired-or-refunded, camera-denied, role-hidden, offline, error
import { useEffect, useRef, useState } from 'react'
import { useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { ActionBar, EmptyState, ErrorState, IconSegmented, Screen, Skeleton, TopBar, useNav } from '../../../system'
import { canRedeem, type BookingRole } from './_components/bits'
import { CameraDenied, CodeField, ProtoShortcuts, QuoteCard, ResultNotice, Viewfinder } from './_components/Redeem'
import { checkCode, fullCode, isComplete, sampleCodes, typedPart, youStaff, type RedeemOutcome } from './_components/redeem-model'
import { useBookingParams } from './_components/model'
import './_components/redeem.css'
import './HL-BOOK-06.css'

export const states = ['manual-code', 'checking', 'ready-to-redeem', 'wrong-venue', 'not-confirmed-yet', 'already-used', 'expired-or-refunded', 'camera-denied', 'role-hidden', 'offline', 'error']

type Mode = 'scan' | 'type'
type Phase = { kind: 'input' } | { kind: 'checking'; code: string } | { kind: 'result'; code: string; outcome: RedeemOutcome }

/** What a frame state starts from (a live visit starts at the scanner, or at the result when a code arrives prefilled). */
function seedOf(state: string | undefined, prefill: string | null): { mode: Mode; typed: string; phase: Phase; denied: boolean } {
  const codes = sampleCodes()
  const result = (code: string | null): Phase => (code ? { kind: 'result', code, outcome: checkCode(code) } : { kind: 'input' })
  switch (state) {
    case 'manual-code':
      return { mode: 'type', typed: typedPart(codes.ready ?? '').slice(0, 6), phase: { kind: 'input' }, denied: false }
    case 'checking':
      return { mode: 'type', typed: typedPart(codes.ready ?? ''), phase: { kind: 'checking', code: codes.ready ?? '' }, denied: false }
    case 'ready-to-redeem':
    case 'offline':
      return { mode: 'type', typed: typedPart(codes.ready ?? ''), phase: result(codes.ready), denied: false }
    case 'wrong-venue':
      return { mode: 'type', typed: typedPart(codes.other ?? ''), phase: result(codes.other), denied: false }
    case 'not-confirmed-yet':
      return { mode: 'type', typed: typedPart(codes.notConfirmed ?? ''), phase: result(codes.notConfirmed), denied: false }
    case 'already-used':
      return { mode: 'type', typed: typedPart(codes.used ?? ''), phase: result(codes.used), denied: false }
    case 'expired-or-refunded':
      return { mode: 'type', typed: '', phase: { kind: 'result', code: '', outcome: { kind: 'expired-or-refunded' } }, denied: false }
    case 'camera-denied':
      return { mode: 'scan', typed: '', phase: { kind: 'input' }, denied: true }
    default:
      return prefill
        ? { mode: 'type', typed: typedPart(prefill), phase: { kind: 'checking', code: prefill }, denied: false }
        : { mode: 'scan', typed: '', phase: { kind: 'input' }, denied: false }
  }
}

export default function RedeemVoucher() {
  const { state } = useFrame()
  const nav = useNav()
  const t = useT('hotel-bookings')
  const params = useBookingParams() as { role?: BookingRole; code?: string | null }
  const live = state === undefined
  const seed = useRef(seedOf(state, live ? (params.code ?? null) : null)).current
  const [mode, setMode] = useState<Mode>(seed.mode)
  const [typed, setTyped] = useState(seed.typed)
  const [phase, setPhase] = useState<Phase>(seed.phase)
  const [torch, setTorch] = useState(false)
  const [unknown, setUnknown] = useState(false)
  const [denied, setDenied] = useState(seed.denied)
  const scanTurn = useRef(0)
  const role: BookingRole = state === 'role-hidden' ? 'accountant' : (params.role ?? 'manager')
  const offline = state === 'offline'

  // A live check takes a moment: the code is looked up, then the quote or the specific reason shows.
  useEffect(() => {
    if (phase.kind !== 'checking' || !live) return
    const id = window.setTimeout(() => {
      const outcome = checkCode(phase.code)
      if (outcome.kind === 'unknown') {
        setUnknown(true)
        setMode('type')
        setPhase({ kind: 'input' })
      } else setPhase({ kind: 'result', code: phase.code, outcome })
    }, 700)
    return () => window.clearTimeout(id)
  }, [phase, live])

  const c = useT('common')
  const top = <TopBar title={c('commonRedeemVoucher')} />

  if (!canRedeem(role)) {
    return (
      <Screen top={top}>
        <div className="hbk-redeem">
          <EmptyState fill={false} illustration="shield" title={c('commonStateTitleNoAccess')} detail={t('hotelBookingsRoleHiddenBody')} action={{ label: t('hotelBookingsBackToList'), onPress: () => nav.pop() }} />
        </div>
      </Screen>
    )
  }

  if (state === 'error') {
    return (
      <Screen top={top}>
        <ErrorState kind="generic" body={t('hotelBookingsRedeemErrorBody')} onRetry={() => nav.replace('HL-BOOK-06')} secondary={{ label: t('hotelBookingsBackToList'), onPress: () => nav.pop() }} />
      </Screen>
    )
  }

  const reset = () => {
    setPhase({ kind: 'input' })
    setTyped('')
    setUnknown(false)
  }
  const startCheck = (code: string) => {
    setUnknown(false)
    setPhase({ kind: 'checking', code })
  }
  const pick = (code: string) => {
    setTyped(typedPart(code))
    setMode('type')
    startCheck(code)
  }
  // "Simulate a scan": the next ready voucher in turn, else any sample code (the prototype's camera is drawn, never opened).
  const simulateScan = () => {
    const codes = sampleCodes()
    const pool = [codes.ready, codes.used, codes.notConfirmed].filter((c): c is string => Boolean(c))
    const code = pool[scanTurn.current % Math.max(1, pool.length)] ?? codes.ready
    scanTurn.current += 1
    if (code) startCheck(code)
  }
  const redeem = () => {
    if (phase.kind !== 'result' || phase.outcome.kind !== 'ready') return
    const done = phase.outcome
    const res = usePrototype.getState().redeemVoucher(phase.code, youStaff?.nameLatin)
    if (res.ok) {
      nav.openSheet('HL-BOOK-07', { params: { bookingId: done.booking.id, code: phase.code } })
      reset()
    } else {
      setPhase({ kind: 'result', code: phase.code, outcome: checkCode(phase.code) })
    }
  }

  let body
  let bottom
  if (phase.kind === 'checking') {
    body = (
      <div className="hbk-redeem__skel" aria-busy="true" role="status" aria-label={t('hotelBookingsChecking')}>
        <Skeleton variant="line" inlineSize={160} blockSize={20} />
        <Skeleton variant="line" inlineSize={200} blockSize={32} />
        <Skeleton variant="block" blockSize={220} />
      </div>
    )
    bottom = <ActionBar action={{ label: t('hotelBookingsChecking'), loading: true }} />
  } else if (phase.kind === 'result') {
    const o = phase.outcome
    if (o.kind === 'ready') {
      // Offline is said once, under the disabled Redeem (the reason beside the action), not again in a banner above the quote.
      body = <QuoteCard booking={o.booking} voucher={o.voucher} />
      bottom = (
        <ActionBar
          action={{ label: c('commonRedeemVoucher'), onPress: redeem, disabled: offline, reason: offline ? t('hotelBookingsOfflineShort') : undefined }}
          secondary={{ label: t('hotelBookingsTryAnother'), onPress: reset }}
        />
      )
    } else {
      body = <ResultNotice outcome={o} onAgain={reset} />
    }
  } else {
    const inType = mode === 'type'
    body = (
      <>
        <IconSegmented<Mode>
          label={t('hotelBookingsRedeemMode')}
          value={mode}
          onChange={m => {
            setMode(m)
            setUnknown(false)
          }}
          options={[
            { value: 'scan', icon: 'scan', label: t('hotelBookingsModeScan') },
            { value: 'type', icon: 'key', label: t('hotelBookingsModeType') },
          ]}
        />
        {inType ? (
          <CodeField value={typed} onChange={v => { setTyped(v); setUnknown(false) }} error={unknown ? t('hotelBookingsErrUnknownField') : undefined} onSubmit={() => isComplete(typed) && startCheck(fullCode(typed))} />
        ) : denied ? (
          <CameraDenied
            onType={() => {
              setDenied(false)
              setMode('type')
            }}
          />
        ) : (
          <Viewfinder torch={torch} onTorch={() => setTorch(v => !v)} onScan={simulateScan} />
        )}
        <ProtoShortcuts codes={sampleCodes()} onPick={pick} />
      </>
    )
    bottom = inType ? <ActionBar action={{ label: t('hotelBookingsCheckCode'), onPress: () => startCheck(fullCode(typed)), disabled: !isComplete(typed) }} /> : undefined
  }

  return (
    <Screen top={top} bottom={bottom}>
      <div className="hbk-redeem">{body}</div>
    </Screen>
  )
}
