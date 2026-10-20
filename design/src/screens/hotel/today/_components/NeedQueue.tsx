// NeedQueue: the rows of the Needs-you queue, shared by Today (requests only, compact) and the full queue (HL-TODY-02, every type).
// One request row at a time opens in place as the full triage card, so Accept is two taps from the list (expand, Accept; ADR 0008 D6).
// Every other item opens its object (a thread, a visit, a booking, a review, a listing decision, the voucher prices) and the weekly calendar check
// confirms in place (OQ-B-22). Offline, the open card is replaced by its disabled twin that says why (ADR 0008 D10).
import { useEffect, useRef, useState } from 'react'
import { IconButton, RequestCard, useNav } from '../../../../system'
import { useRequestActions } from './actions'
import { useWords } from './bits'
import { OfflineDecision } from './OfflineDecision'
import { NeedRow } from './NeedRow'
import { useTodayLocal } from './store'
import type { NeedItem } from './data'

export type NeedQueueProps = {
  entries: NeedItem[]
  offline?: boolean
  /** Which request is open on arrival (static frames). */
  initiallyOpen?: string | null
  /** The deadline line (absolute reply-by time) under each request row. */
  detail?: boolean
  /** Rows are not tappable (loading the next page, a read-only role). */
  disabled?: boolean
  /** The calendar check confirmed in place. */
  onConfirmed?: () => void
}

export function NeedQueue({ entries, offline = false, initiallyOpen = null, detail = false, disabled = false, onConfirmed }: NeedQueueProps) {
  const nav = useNav()
  const { c } = useWords()
  const actions = useRequestActions()
  const confirm = useTodayLocal(s => s.confirmCalendar)
  const [open, setOpen] = useState<string | null>(initiallyOpen)
  const cardRef = useRef<HTMLLIElement>(null)
  const touched = useRef(false)
  // A card opened by a tap scrolls to the top of the screen so Accept is in view; static frames that arrive open stay where they are.
  useEffect(() => {
    if (!open || !touched.current) return
    const quiet = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches
    cardRef.current?.scrollIntoView({ block: 'start', behavior: quiet ? 'auto' : 'smooth' })
  }, [open])

  const openObject = (e: NeedItem) => {
    if (e.kind === 'message') nav.push('HL-TODY-05', { conversationId: e.conversationId, bookingId: e.booking?.id ?? null })
    else if (e.kind === 'visit') nav.push('HL-VIST-02', { visitId: e.visit?.id })
    else if (e.kind === 'listing') nav.push('HL-PROV-06', { listingId: e.listing?.id, account: 'provider' })
    else if (e.kind === 'review') nav.push('HL-GROW-06', { reviewId: e.reviewId })
    else if (e.kind === 'window') nav.push('HL-GROW-01')
    else if (e.booking) nav.push('HL-BOOK-03', { bookingId: e.booking.id })
  }

  return (
    <ul className="ht-list">
      {entries.map((e, i) => {
        const r = e.request
        const isOpen = Boolean(r && open === r.booking.id)
        if (r && isOpen) {
          return (
            <li key={e.id} ref={cardRef} className="ht-list__card" data-open="true">
              {offline ? (
                <OfflineDecision request={r} />
              ) : (
                <RequestCard
                  request={r}
                  state="viewed"
                  inlineUndo={false}
                  onOpen={() => actions.open(r)}
                  onAccept={() => actions.accept(r)}
                  onReschedule={() => actions.reschedule(r)}
                  onDecline={() => actions.decline(r)}
                  onChat={() => actions.chat(r)}
                  onCall={() => actions.call(r)}
                  onCompare={() => actions.compare(r)}
                />
              )}
              <span className="ht-list__less">
                <IconButton icon="chevron-up" iconSize="sm" label={c('commonActionShowLess')} aria-expanded onClick={() => setOpen(null)} />
              </span>
            </li>
          )
        }
        return (
          <NeedRow
            key={e.id}
            entry={e}
            detail={detail}
            disabled={disabled}
            last={i === entries.length - 1}
            onPress={() => {
              touched.current = true
              if (r) setOpen(open === r.booking.id ? null : r.booking.id)
              else openObject(e)
            }}
            onConfirm={() => {
              confirm()
              onConfirmed?.()
            }}
          />
        )
      })}
    </ul>
  )
}
