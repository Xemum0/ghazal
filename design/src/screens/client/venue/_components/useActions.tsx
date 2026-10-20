// What a tap does on the venue detail (CL-VENU-01 and CL-VENU-06): every edge of the inventory's navigatesTo, wired once. In a static
// frame nothing is wired (a frame is a picture, the player is the prototype); in the player each action moves the prototype store and
// the navigator, so no tap on this page is a dead end.
import { useCallback } from 'react'
import { create } from 'zustand'
import type { IsoDate, Venue, Voucher } from '../../../../mock'
import { useT } from '../../../../i18n'
import { usePrototype } from '../../../../shell/state'
import { useNav } from '../../../../system'
import type { VenueBrief } from './model'
import { ContactSheet } from './ContactSheet'

/** What a quote carries into the voucher explainer and the request (CL-VCHR-01, CL-BOOK-01): the page's own choices on top of the Brief. */
export type QuoteCarry = { brief: VenueBrief; hallId?: string; sessionId?: string | null; packageId?: string | null; date?: IsoDate | null }

/**
 * A guest who tapped Get voucher: the quote waits here while the sign-in sheet runs, and the page reopens the voucher sheet with it
 * once the person is signed in (ADR 0007 D8: the exact quote is restored after sign-in).
 */
export const usePendingVoucher = create<{ pending: { venueId: string; carry: QuoteCarry } | null; set: (p: { venueId: string; carry: QuoteCarry } | null) => void }>()(set => ({
  pending: null,
  set: pending => set({ pending }),
}))

const paramsOf = (venueId: string | undefined, carry: QuoteCarry) => ({
  venueId,
  hallId: carry.hallId,
  sessionId: carry.sessionId ?? undefined,
  packageId: carry.packageId ?? undefined,
  date: carry.date ?? carry.brief.date ?? undefined,
  guests: carry.brief.guests ?? undefined,
  audience: carry.brief.audience,
})

export type VenueActions = ReturnType<typeof useVenueActions>

export function useVenueActions(venue: Venue | undefined, live: boolean) {
  const nav = useNav()
  const t = useT('client-venue')
  const tc = useT('common')
  const venueId = venue?.id

  /** Heart: saved locally for a guest too; the third heart as a guest raises the once-only sign-up nudge (ADR 0007 D10). */
  const toggleFavourite = useCallback(() => {
    if (!live || !venueId) return
    const store = usePrototype.getState()
    const on = store.toggleFavourite('venue', venueId)
    if (on && usePrototype.getState().signupNudge) {
      store.clearSignupNudge()
      nav.openSheet('CL-AUTH-01', { params: { reason: 'save' } })
      return
    }
    nav.toast({
      message: on ? tc('commonStateSaved') : t('clientVenueSavedRemoved'),
      icon: on ? 'heart-fill' : undefined,
      undo: !on,
      action: on
        ? { label: t('clientVenueSavedView'), onPress: () => nav.switchTab('saved') }
        : { label: tc('commonActionUndo'), onPress: () => usePrototype.getState().toggleFavourite('venue', venueId) },
    })
  }, [live, venueId, nav, t, tc])

  /** Compare toggle (a header badge on this page, so the tray never covers the sticky bar). The fourth add asks which one to replace. */
  const toggleCompare = useCallback(() => {
    if (!live || !venueId) return
    const store = usePrototype.getState()
    // Already in the set: the header badge opens the list sheet (remove, Compare), the only way to the table from a venue's page (ADR 0009 D3).
    if (store.compareList.includes(venueId)) {
      nav.openSheet('CL-SAVD-02')
      return
    }
    if (store.addToCompare(venueId) === 'full') {
      nav.openSheet('CL-SAVD-03', { params: { newId: venueId, incoming: venueId } })
      return
    }
    const count = usePrototype.getState().compareList.length
    nav.toast({
      message: t('clientVenueCompareAdded'),
      icon: 'compare',
      action: count >= 2 ? { label: t('clientVenueCompareView'), onPress: () => nav.push('CL-SAVD-04') } : undefined,
    })
  }, [live, venueId, nav, t])

  /** Share: the OS sheet carries a universal link; the prototype says the link is on the clipboard. */
  const share = useCallback(() => {
    if (!live) return
    nav.toast({ message: t('clientVenueShareCopied'), icon: 'link', tone: 'success' })
  }, [live, nav, t])

  const openCalendar = useCallback(
    (hallId?: string) => {
      if (!venueId) return
      nav.openSheet('CL-VENU-03', { params: { venueId, hallId } })
    },
    [nav, venueId],
  )

  /** The Brief owns date and guests; its sheet is the one editor (CL-DISC-02). */
  const editBrief = useCallback(() => nav.openSheet('CL-DISC-02', { params: { focus: 'guests' } }), [nav])

  const openPackage = useCallback(
    (packageId: string, hallId?: string) => {
      if (!venueId) return
      nav.openSheet('CL-VENU-04', { params: { venueId, packageId, hallId } })
    },
    [nav, venueId],
  )

  const openPolicies = useCallback(
    (segment: 'terms' | 'rules' | 'good', hallId?: string) => {
      if (!venueId) return
      nav.openSheet('CL-VENU-05', { params: { venueId, segment, hallId } })
    },
    [nav, venueId],
  )

  /** Get voucher: the explainer bound to this quote (CL-VCHR-01). A guest meets the sign-in sheet first and comes back to it (ADR 0007 D8). */
  const openVoucher = useCallback(
    (carry: QuoteCarry) => {
      if (!live || !venueId) return
      nav.openSheet('CL-VCHR-01', { params: paramsOf(venueId, carry) })
    },
    [live, venueId, nav],
  )
  const getVoucher = useCallback(
    (carry: QuoteCarry) => {
      if (!live || !venueId) return
      const store = usePrototype.getState()
      if (store.auth === 'guest') {
        usePendingVoucher.getState().set({ venueId, carry })
        // The sign-in sheet names what waits behind it (its strip reads the booking draft): this venue, this date, these guests.
        store.startDraft(venueId, {
          hallId: carry.hallId ?? null,
          sessionId: carry.sessionId ?? null,
          packageId: carry.packageId ?? null,
          eventDate: carry.date ?? carry.brief.date,
          guests: carry.brief.guests,
          audience: carry.brief.audience,
        })
        store.openGate('voucher', { screenId: 'CL-VCHR-01', params: paramsOf(venueId, carry) })
        nav.openSheet('CL-AUTH-01', { params: { reason: 'voucher' } })
        return
      }
      openVoucher(carry)
    },
    [live, venueId, nav, openVoucher],
  )

  /** Send request with a ready voucher: the booking flow opens with the quote and the voucher carried over (CL-BOOK-01). */
  const sendRequest = useCallback(
    (carry: QuoteCarry, voucher?: Voucher) => {
      if (!live || !venueId) return
      const store = usePrototype.getState()
      store.startDraft(venueId, {
        hallId: carry.hallId ?? null,
        sessionId: carry.sessionId ?? null,
        packageId: carry.packageId ?? null,
        eventDate: carry.date ?? carry.brief.date,
        guests: carry.brief.guests,
        audience: carry.brief.audience,
      })
      if (voucher) store.patchDraft({ voucherId: voucher.id })
      nav.push('CL-BOOK-01', { venueId })
    },
    [live, venueId, nav],
  )

  /** Book a visit (CL-VIST-01): no voucher needed, the account is asked at Send. */
  const bookVisit = useCallback(() => {
    if (!live || !venueId) return
    nav.openSheet('CL-VIST-01', { params: { venueId } })
  }, [live, venueId, nav])

  /** Contact the venue, the browse-only path: a registered client opens the chat, a guest gets the venue's own phone and WhatsApp. */
  const contactVenue = useCallback(() => {
    if (!live || !venue) return
    if (usePrototype.getState().auth === 'guest') {
      nav.openSheet(<ContactSheet venueId={venue.id} />, { title: t('clientVenueContactTitle') })
      return
    }
    nav.push('CL-MSGS-02', { venueId: venue.id })
  }, [live, venue, nav, t])

  const openHow = useCallback(
    (carry: QuoteCarry) => {
      if (!live || !venueId) return
      nav.openSheet('CL-VCHR-01', { params: { ...paramsOf(venueId, carry), mode: 'explain' } })
    },
    [live, venueId, nav],
  )

  const openMessages = useCallback(() => {
    if (!venueId) return
    nav.push('CL-MSGS-02', { venueId })
  }, [nav, venueId])

  const openReviews = useCallback(() => {
    if (!venueId) return
    nav.push('CL-RVRW-01', { venueId })
  }, [nav, venueId])

  const openSimilar = useCallback(
    (v: Venue) => {
      nav.push(v.channel === 'external_link' ? 'CL-VENU-06' : 'CL-VENU-01', { venueId: v.id, from: 'venue' })
    },
    [nav],
  )

  return { toggleFavourite, toggleCompare, share, openCalendar, editBrief, openPackage, openPolicies, getVoucher, openVoucher, sendRequest, bookVisit, contactVenue, openHow, openMessages, openReviews, openSimilar }
}
