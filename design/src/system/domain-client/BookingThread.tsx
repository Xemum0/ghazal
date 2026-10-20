// BookingThread (direction section 4, ADR 0033 D3, booking-state-machine section 10): five knots on one gold thread,
// Voucher > Request > Approval > Confirmed (24 h) > Redeemed at the venue. A knot ties only when its event is recorded; times are
// absolute; the thread is never the only signal (label and glyph always sit beside it); it draws on once, from inline-start,
// over 480 ms, and a knot pops once on a live change. The wedding day is not a knot (the day is the booking's own date line).
//
// ADR 0034 (text diet): every knot has a glyph; only the ACTIVE knot carries a word; a deadline is a timer glyph and a time, never a sentence.
// variants   full      glyph over each 20 px knot (IconProgress), one word under the active knot, the deadline under the thread
//            compact   12 px knots, the current glyph, word and time on one line (list rows, the partner request card)
//            vertical  rail and content (booking detail): glyph and 2-word label per knot, past knots with absolute times, at most two faint future knots
// onDark     for an ink panel (confirmation hero, countdown): ring gap and tracks switch to the on-dark tokens
// Input is a `Booking` (its recorded thread supplies the times; the voucher purchase time comes from its bound voucher) or just a
// `status` (the ADR 0033 mapping in `threadModel`).
import { useMemo, type CSSProperties } from 'react'
import { flat } from '@gz/tokens'
import type { IconName } from '@gz/tokens'
import type { Booking, BookingStatus, ThreadKnot as RecordedKnot } from '@gz/contracts'
import { getVoucher } from '../../mock'
import { useFormat, useT } from '../../i18n'
import { cx } from '../core/cx'
import { useRevealOnce } from '../core/useRevealOnce'
import { ThreadKnot, type KnotEndedTone, type KnotState } from '../brand'
import { Icon } from '../core/Icon'
import { IconProgress, type IconProgressStep } from '../core/IconProgress'
import { Figures } from './bits'
import { defineWords, p } from './copy'
import './booking-thread.css'

const useW = defineWords({
  voucher: p('Voucher', 'الكوبون'),
  request: p('Request', 'الطلب'),
  approval: p('Approval', 'الموافقة'),
  confirmation: p('Confirmed', 'التأكيد'),
  redemption: p('Redeemed', 'الاستخدام'),
  voucherLong: p('Voucher bought', 'شراء الكوبون'),
  requestLong: p('Request sent', 'إرسال الطلب'),
  approvalLong: p('Venue approval', 'موافقة المكان'),
  confirmationLong: p('You confirmed', 'تأكيدكم'),
  redemptionLong: p('Redeemed', 'تم الاستخدام'),
  // Step forms: the word under a knot that is still ahead names the step, never a result the status has not reached ("Confirm" while the
  // booking is Approved, "At venue" while it is Confirmed).
  confirmationStep: p('Confirm', 'التأكيد'),
  redemptionStep: p('At venue', 'في القاعة'),
  confirmationStepLong: p('Your confirmation', 'تأكيدكم'),
  redemptionStepLong: p('At the venue', 'في القاعة'),
  notRedeemed: p('Not redeemed', 'لم يُستخدم'),
  label: p('Booking progress', 'مراحل الحجز'),
  stepOf: p('Step {n} of {total}', 'المرحلة {n} من {total}'),
})

/** One glyph per knot (ADR 0034): the voucher, the request sent, the venue's answer, your date, the code at the venue. */
export const THREAD_ICON: Record<'voucher' | 'request' | 'approval' | 'confirmation' | 'redemption', IconName> = {
  voucher: 'ticket',
  request: 'send',
  approval: 'verified',
  confirmation: 'calendar-check',
  redemption: 'qr-code',
}

export type ThreadKey = 'voucher' | 'request' | 'approval' | 'confirmation' | 'redemption'
export const THREAD_KEYS: readonly ThreadKey[] = ['voucher', 'request', 'approval', 'confirmation', 'redemption']

export type ThreadKnotModel = {
  key: ThreadKey
  state: KnotState
  /** `ended` knots only: the terminal glyph and tone (direction section 4). */
  ended?: { icon: IconName; tone: KnotEndedTone; status: BookingStatus }
  /** The recorded absolute time of a tied knot, or the deadline of the one in progress. */
  at: string | null
}

export type ThreadInput = {
  status: BookingStatus
  /** The recorded knots of the booking (times). */
  recorded?: readonly RecordedKnot[]
  /** When the bound voucher was paid (the Voucher knot's time). */
  voucherAt?: string | null
  /** How many knots had tied before a cancel (default: from `recorded`, else 3). */
  reached?: number
  expiredReason?: Booking['expiredReason']
}

const ENDED_ICON: Partial<Record<BookingStatus, { icon: IconName; tone: KnotEndedTone }>> = {
  declined: { icon: 'close', tone: 'danger' },
  expired: { icon: 'clock-off', tone: 'neutral' },
  cancelled: { icon: 'close', tone: 'neutral' },
  completed: { icon: 'clock-off', tone: 'neutral' },
}

const TIED_THROUGH: Partial<Record<BookingStatus, number>> = { pending: 1, approved: 2, confirmed: 3, redeemed: 4, completed: 4 }

/** The knot states of every ADR 0033 status. Pure: the same function feeds the partner app. */
export function threadModel(input: ThreadInput): ThreadKnotModel[] {
  const node = (key: ThreadKey) => (key === 'voucher' ? undefined : input.recorded?.find(k => k.node === key))
  const at = (key: ThreadKey) => (key === 'voucher' ? (input.voucherAt ?? input.recorded?.find(k => k.node === 'request')?.at ?? null) : (node(key)?.at ?? null))
  const knot = (key: ThreadKey, state: KnotState, ended?: ThreadKnotModel['ended']): ThreadKnotModel => ({ key, state, ended, at: at(key) })
  const s = input.status
  // `through` = index of the last tied knot; `now` = the one after it (absent when the request ended).
  const run = (through: number, nowAt?: number, endAt?: number, endStatus: BookingStatus = s): ThreadKnotModel[] =>
    THREAD_KEYS.map((k, i) => {
      if (endAt === i) return knot(k, 'ended', { ...ENDED_ICON[endStatus]!, status: endStatus })
      if (i <= through) return knot(k, 'tied')
      if (nowAt === i) return knot(k, 'now')
      return knot(k, 'open')
    })

  switch (s) {
    case 'pending':
      return run(1, 2)
    case 'approved':
      return run(2, 3)
    case 'confirmed':
      return run(3, 4)
    case 'redeemed':
      return run(4)
    case 'completed': {
      // Redeemed normally; a request that completed without a redemption ends its last knot quietly.
      const redeemed = node('redemption')?.state === 'done' || !input.recorded
      return redeemed ? run(4) : run(3, undefined, 4)
    }
    case 'declined':
      return run(1, undefined, 2)
    case 'expired':
      // Venue silence ends Approval; a client who did not confirm in 24 h ends Confirmation. Earlier knots stay tied.
      return input.expiredReason === 'client_no_confirmation' ? run(2, undefined, 3) : run(1, undefined, 2)
    case 'cancelled': {
      const reached = input.reached ?? (input.recorded ? input.recorded.filter(k => k.state === 'done').length : 3)
      // Request is the first recorded knot; the Voucher knot is always tied before it.
      const end = Math.min(Math.max(reached + 1, 2), 4)
      return run(end - 1, undefined, end)
    }
    default:
      return run(TIED_THROUGH[s] ?? 0)
  }
}

export type BookingThreadVariant = 'full' | 'compact' | 'vertical'

export type BookingThreadProps = {
  /** The booking (preferred): status, recorded times, deadlines, overlays. */
  booking?: Pick<Booking, 'status' | 'thread' | 'expiredReason' | 'eventDate' | 'respondBy' | 'confirmBy' | 'overlays' | 'proposal'> & Partial<Pick<Booking, 'voucherId'>>
  /** Without a booking: just the status (a spec cell, a status filter preview). */
  status?: BookingStatus
  variant?: BookingThreadVariant
  /** `full` only. `active` (default): one word under the active knot. `all`: every knot is labelled. `none`: glyphs only. */
  labels?: 'active' | 'all' | 'none'
  onDark?: boolean
  /** `inview` draws once when first on screen, `mount` immediately, `false` shows the finished thread (gallery spec cells). */
  draw?: 'inview' | 'mount' | false
  /** Knot that just changed in view: it pops once. */
  pop?: ThreadKey
  className?: string
}

const SEG_DELAY = flat['motion.duration.fast']

type Sub = { text: string; tone: 'muted' | 'now' | 'danger'; icon?: IconName }

export function BookingThread({ booking, status, variant = 'full', labels = 'active', onDark = false, draw = 'inview', pop, className }: BookingThreadProps) {
  const f = useFormat()
  const t = useT('common')
  const w = useW()
  const [ref, seen] = useRevealOnce<HTMLDivElement>(draw === 'inview' && variant !== 'full')
  const st: BookingStatus = booking?.status ?? status ?? 'pending'
  const voucherAt = booking?.voucherId ? (getVoucher(booking.voucherId)?.purchasedAt ?? null) : null
  const model = useMemo(
    () => threadModel({ status: st, recorded: booking?.thread, voucherAt, expiredReason: booking?.expiredReason }),
    [st, booking?.thread, booking?.expiredReason, voucherAt],
  )
  const armed = draw === 'inview' && !seen
  const drawing = draw === 'mount' || (draw === 'inview' && seen)

  /** A tied or ended knot is named by its result; a knot still ahead (in progress or open) by its step, so the thread never contradicts the status. */
  const label = (k: ThreadKnotModel) => {
    const ahead = k.state === 'now' || k.state === 'open'
    if (variant === 'vertical') {
      if (ahead && (k.key === 'confirmation' || k.key === 'redemption')) return w(`${k.key}StepLong` as 'confirmationStepLong' | 'redemptionStepLong')
      return w(`${k.key}Long` as `${ThreadKey}Long`)
    }
    if (ahead && (k.key === 'confirmation' || k.key === 'redemption')) return w(`${k.key}Step` as 'confirmationStep' | 'redemptionStep')
    return w(k.key)
  }
  /** `12 Nov 4:00 PM`: day, short month and time, no weekday and no comma (a figure, not a sentence). */
  const stamp = (iso: string) => {
    const c = f.civil(iso)
    return `${f.integer(c.day)}\u00a0${f.monthName(c.month, 'short')}\u00a0${f.time(iso).replace(/\s/g, '\u00a0')}`
  }

  /** The line under a knot's label: a recorded time, a deadline (timer glyph and time), or the reason a knot ended. */
  const sub = (k: ThreadKnotModel): Sub | null => {
    if (k.state === 'ended' && k.ended) {
      if (k.ended.status === 'completed') return { text: w('notRedeemed'), tone: 'muted' }
      return { text: t(endedKey(k.ended.status)), tone: k.ended.tone === 'danger' || k.ended.tone === 'danger-outline' ? 'danger' : 'muted' }
    }
    if (k.state === 'tied') return k.at ? { text: stamp(k.at), tone: 'muted' } : null
    if (k.state === 'now') {
      if (k.key === 'approval') {
        const by = booking?.respondBy ?? k.at
        return by ? { text: stamp(by), tone: 'now', icon: 'timer' } : null
      }
      if (k.key === 'confirmation') {
        const by = booking?.confirmBy ?? k.at
        return by ? { text: stamp(by), tone: 'now', icon: 'timer' } : null
      }
      // Redemption in progress = the booking is Confirmed: the code is on the voucher below, so the thread names the step and nothing more.
    }
    return null
  }

  // A segment is drawn gold when the knot it leads to has been reached (tied, now or ended): the thread runs up to where you are.
  const reached = (k: ThreadKnotModel) => k.state === 'tied' || k.state === 'now' || k.state === 'ended'
  const stepNow = Math.max(0, model.findIndex(k => k.state === 'now' || k.state === 'ended'))
  const current = model.find(k => k.state === 'now' || k.state === 'ended') ?? model[model.length - 1]!
  const describe = `${label(current)}, ${w('stepOf', { n: f.integer(stepNow + 1), total: f.integer(model.length) })}`
  const ariaLabel = `${w('label')}: ${describe}`
  const currentSub = sub(current)
  const noteOf = (s: Sub) => (
    <>
      {s.icon ? <Icon name={s.icon} size="xs" /> : null}
      <Figures text={s.text} />
    </>
  )

  const segStyle = (i: number): CSSProperties => ({ '--gz-delay': `${i * SEG_DELAY}ms` }) as CSSProperties
  const knotSize = variant === 'compact' ? 'compact' : 'booking'

  if (variant === 'full') {
    const steps: IconProgressStep[] = model.map(k => ({
      key: k.key,
      icon: THREAD_ICON[k.key],
      label: label(k),
      state: k.state,
      ended: k.ended ? { icon: k.ended.icon, tone: k.ended.tone } : undefined,
    }))
    return (
      <div data-gz="BookingThread" data-variant="full" data-status={st} className={cx('gz-bthread gz-bthread--full', className)}>
        <IconProgress
          steps={steps}
          label={w('label')}
          describe={describe}
          labels={labels}
          note={currentSub && (current.state === 'now' || current.state === 'ended') ? noteOf(currentSub) : undefined}
          noteTone={currentSub?.tone}
          onDark={onDark}
          draw={draw}
          pop={pop}
        />
      </div>
    )
  }

  if (variant === 'vertical') {
    // Past and current knots in full, then at most two faint future knots; nothing after a terminal knot.
    const endedAt = model.findIndex(k => k.state === 'ended')
    let futures = 0
    const shown = model.filter((k, i) => {
      if (k.state !== 'open') return true
      if (endedAt >= 0 && i > endedAt) return false
      return ++futures <= 2
    })
    return (
      <div
        ref={ref}
        data-gz="BookingThread"
        data-variant="vertical"
        data-status={st}
        role="list"
        aria-label={ariaLabel}
        className={cx('gz-bthread gz-bthread--vertical', onDark && 'gz-on-dark', className)}
      >
        {shown.map((k, i) => {
          const line = sub(k)
          const next = shown[i + 1]
          return (
            <div key={k.key} role="listitem" className={cx('gz-bthread__item', `is-${k.state}`)} data-gz-id={`knot.${k.key}`}>
              <span className="gz-bthread__rail">
                <ThreadKnot state={k.state} onDark={onDark} endedIcon={k.ended?.icon} endedTone={k.ended?.tone} pop={pop === k.key} />
                {next ? (
                  <span className="gz-bthread__vseg gz-thread-track" aria-hidden="true">
                    {reached(next) ? <span className={cx('gz-bthread__vfill', armed && 'is-armed', drawing && 'gz-bthread__vdraw')} style={segStyle(i)} /> : null}
                  </span>
                ) : null}
              </span>
              <span className="gz-bthread__text">
                <span className={cx('gz-bthread__label gz-t-title', k.state === 'open' && 'is-faint')}>
                  <Icon name={THREAD_ICON[k.key]} size="xs" tone={onDark ? 'on-dark' : k.state === 'open' ? 'disabled' : k.state === 'now' ? 'accent' : 'secondary'} />
                  {label(k)}
                </span>
                {line ? (
                  <span className={cx('gz-bthread__sub gz-t-caption', line.tone === 'now' && 'is-now', line.tone === 'danger' && 'is-danger')}>
                    {line.icon ? <Icon name={line.icon} size="xs" /> : null}
                    <Figures text={line.text} />
                  </span>
                ) : null}
              </span>
            </div>
          )
        })}
      </div>
    )
  }

  // compact: 12 px knots on the thread, then ONE line: the current glyph, its word and the time (a deadline is a timer glyph and a time).
  return (
    <div
      ref={ref}
      data-gz="BookingThread"
      data-variant="compact"
      data-status={st}
      role="group"
      aria-label={ariaLabel}
      className={cx('gz-bthread gz-bthread--compact', onDark && 'gz-on-dark', className)}
    >
      <div className="gz-bthread__cols">
        {model.map((k, i) => {
          const last = i === model.length - 1
          return (
            <div key={k.key} className={cx('gz-bthread__col', `is-${k.state}`, last && 'is-last')} data-gz-id={`knot.${k.key}`}>
              <div className="gz-bthread__head">
                <ThreadKnot state={k.state} size={knotSize} align="start" onDark={onDark} endedIcon={k.ended?.icon} endedTone={k.ended?.tone} pop={pop === k.key} />
                {!last ? (
                  <span className="gz-bthread__seg gz-thread-track" aria-hidden="true">
                    {reached(model[i + 1]!) ? <span className={cx('gz-thread-fill gz-bthread__fill', armed && 'is-armed', drawing && 'gz-thread-draw')} style={segStyle(i)} /> : null}
                  </span>
                ) : null}
              </div>
            </div>
          )
        })}
      </div>
      <p className="gz-bthread__current gz-t-caption">
        <Icon name={THREAD_ICON[current.key]} size="xs" tone={onDark ? 'on-dark' : 'secondary'} />
        <span className="gz-bthread__current-label">{label(current)}</span>
        {currentSub ? (
          <span className={cx('gz-bthread__current-sub', currentSub.tone === 'now' && 'is-now', currentSub.tone === 'danger' && 'is-danger')}>
            {currentSub.icon ? <Icon name={currentSub.icon} size="xs" /> : null}
            <Figures text={currentSub.text} />
          </span>
        ) : null}
      </p>
    </div>
  )
}

function endedKey(s: BookingStatus) {
  switch (s) {
    case 'declined':
      return 'commonStatusDeclined' as const
    case 'expired':
      return 'commonStatusExpired' as const
    default:
      return 'commonStatusCancelled' as const
  }
}
