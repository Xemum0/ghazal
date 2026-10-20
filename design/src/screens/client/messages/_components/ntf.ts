// The notification feed of the couple: the seeded notifications, plus the ones the shared story adds as the request moves (the hotel
// approves, the couple confirms, the hotel redeems the voucher, the confirm window lapses, the hotel declines: `heroVariantNotifications`),
// newest first. "Read" is the shared store's `readNotificationIds` laid over the fixture flag, so the bell on Home and My Wedding and this
// centre always agree.
import { useMemo } from 'react'
import type { Notification, NotificationKind } from '@gz/contracts'
import { heroVariantNotifications, notificationsFor } from '../../../../mock'
import { usePrototype } from '../../../../shell/state'
import { HERO_BOOKING, useLiveBooking } from './model'

export type NtfFilter = 'all' | 'bookings' | 'vouchers' | 'visits' | 'messages' | 'planning'

const FILTER_OF: Partial<Record<NotificationKind, Exclude<NtfFilter, 'all'>>> = {
  request_sent: 'bookings',
  request_approved: 'bookings',
  confirm_reminder: 'bookings',
  request_confirmed: 'bookings',
  request_declined: 'bookings',
  request_expired: 'bookings',
  booking_cancelled: 'bookings',
  review_prompt: 'bookings',
  voucher_ready: 'vouchers',
  voucher_released: 'vouchers',
  voucher_redeemed: 'vouchers',
  credit_voucher_issued: 'vouchers',
  voucher_forfeited: 'vouchers',
  voucher_expiring: 'vouchers',
  visit_requested: 'visits',
  visit_confirmed: 'visits',
  visit_reminder: 'visits',
  visit_message: 'visits',
  message: 'messages',
  planner_assigned: 'messages',
  new_venue: 'planning',
  countdown: 'planning',
  checklist_due: 'planning',
}

export const filterOfKind = (kind: NotificationKind): Exclude<NtfFilter, 'all'> => FILTER_OF[kind] ?? 'bookings'

export function useNotificationFeed(): { items: Notification[]; unread: number } {
  const readIds = usePrototype(s => s.readNotificationIds)
  const live = useLiveBooking(HERO_BOOKING)
  const kinds = useMemo(() => new Set(live?.events.map(e => (e.kind === 'expired' ? `expired-${e.reason ?? 'venue'}` : e.kind)) ?? []), [live])
  return useMemo(() => {
    const v = heroVariantNotifications
    const extra: Notification[] = [
      ...(kinds.has('approved') ? [v.approved] : []),
      ...(kinds.has('confirmed') ? [v.confirmed] : []),
      ...(kinds.has('redeemed') ? [v.redeemed] : []),
      ...(kinds.has('not_accepted') ? [v.declined] : []),
      ...(kinds.has('expired-client') ? [v.lapsed] : []),
    ]
    const items = [...extra, ...notificationsFor('client')]
      .map(n => (n.read || readIds.includes(n.id) ? { ...n, read: true } : n))
      .sort((a, b) => Date.parse(b.at) - Date.parse(a.at))
    return { items, unread: items.filter(n => !n.read).length }
  }, [readIds, kinds])
}
