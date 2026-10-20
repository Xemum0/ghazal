// Words the vouchers screens share: the payment method name and why a released voucher came back (a glyph and one word on the screen, the
// sentence behind an info glyph). Everything is a key of client-vouchers.
import type { IconName } from '@gz/tokens'
import type { GatewayMethod, Voucher, VoucherReleaseReason } from '../../../../mock'
import { useT, type MessageKey } from '../../../../i18n'

const METHOD: Record<GatewayMethod, MessageKey<'client-vouchers'>> = {
  knet: 'clientVouchersMethodKnet',
  card: 'clientVouchersMethodCard',
  apple_pay: 'clientVouchersMethodApplePay',
  google_pay: 'clientVouchersMethodGooglePay',
}

type WhyKeys = { icon: IconName; word: MessageKey<'client-vouchers'>; sentence: MessageKey<'client-vouchers'> }

const WHY: Record<VoucherReleaseReason, WhyKeys> = {
  declined: { icon: 'x-circle', word: 'clientVouchersWordDeclined', sentence: 'clientVouchersWhyDeclined' },
  venue_no_response: { icon: 'clock-off', word: 'clientVouchersWordNoResponse', sentence: 'clientVouchersWhyNoResponse' },
  withdrawn: { icon: 'undo', word: 'clientVouchersWordWithdrawn', sentence: 'clientVouchersWhyWithdrawn' },
  client_no_confirmation: { icon: 'timer', word: 'clientVouchersWordNoConfirmation', sentence: 'clientVouchersWhyNoConfirmation' },
  slot_taken: { icon: 'calendar-x', word: 'clientVouchersWordSlotTaken', sentence: 'clientVouchersWhySlotTaken' },
  approval_revoked: { icon: 'warning-circle', word: 'clientVouchersWordRevoked', sentence: 'clientVouchersWhyRevoked' },
  venue_cancelled: { icon: 'calendar-x', word: 'clientVouchersWordVenueCancelled', sentence: 'clientVouchersWhyVenueCancelled' },
  partner_suspended: { icon: 'pause', word: 'clientVouchersWordSuspended', sentence: 'clientVouchersWhySuspended' },
}

/** The gateway method of a voucher's payment as a word ("KNET card", "card"), or KNET when it was never paid. */
export function useMethodName(): (v: Voucher) => string {
  const t = useT('client-vouchers')
  return v => (v.payment ? t(METHOD[v.payment.method]) : t(METHOD.knet))
}

export type Why = { icon: IconName; word: string; sentence: string }

/** Why a released voucher came back: a glyph, one word for the screen and the sentence for the info sheet ("{name} did not reply in time."). */
export function useWhy(): (reason: VoucherReleaseReason | null, name: string) => Why {
  const t = useT('client-vouchers')
  return (reason, name) => {
    const k = WHY[reason ?? 'withdrawn']
    return { icon: k.icon, word: t(k.word), sentence: t(k.sentence, { name }) }
  }
}

/** Copies a voucher code (the clipboard may be blocked in a preview: the toast still confirms what the viewer asked for). */
export function copyCode(code: string): void {
  try {
    void navigator.clipboard?.writeText(code)
  } catch {
    /* blocked in a preview; the code is on screen anyway */
  }
}
