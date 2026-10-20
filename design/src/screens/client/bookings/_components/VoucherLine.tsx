// VoucherLine (CL-BKNG-02, a request that is not confirmed yet, and a request that is over): the KD 2 voucher of this request as one quiet row,
// the way the wallet shows it but without the venue name (the header of the same screen already names the venue). A ticket disc, the code as
// a figure, one fact (`[calendar] 11 Jan 2027` while it is live, `[check] 3 Jan 2027` once it is used) and a chevron: the row is a target and
// opens the voucher. A voucher that is simply attached to this request carries no word (the page is that request, so "in request" says
// nothing); only a state that changed it (used, refunded, expired) is a pill. Same row anatomy and classes as the system VoucherCard
// (compact); a `showTarget={false}` option there is requested in docs/engineering/requests.md and this twin goes when it exists.
import type { Voucher } from '@gz/contracts'
import { FactChip, FactRow, Icon, StatusPill, type VoucherState } from '../../../../system'
import { Fx } from './Fx'
import { useBk } from './useBk'

export function VoucherLine({ voucher: v, onOpen }: { voucher: Voucher; onOpen: () => void }) {
  const { t, tc, dayYear } = useBk()
  const state = `voucher_${v.status}` as VoucherState
  const attached = v.status === 'bound' || v.status === 'active'
  const usedOn = v.status === 'used' && v.usedAt ? dayYear(v.usedAt.slice(0, 10)) : null
  const validUntil = v.validUntil ? dayYear(v.validUntil.slice(0, 10)) : null
  const fact = usedOn ?? validUntil
  return (
    <div data-gz="VoucherLine" data-status={v.status} className="gz-vch gz-vch--compact">
      <button type="button" className="gz-reset gz-vch__row gz-press" onClick={onOpen} aria-label={`${tc('commonVoucher')} ${v.code}`}>
        <span className="gz-vch__icon" aria-hidden="true">
          <Icon name="ticket" size="md" />
        </span>
        <span className="gz-vch__row-text">
          {/* The figure role sits on the inner isolate, so the code lines up with the date under it at the inline-start in both scripts. */}
          <span data-gz-id="code">
            <span className="gz-sr-only">{tc('commonVoucherCode')}</span>
            <bdi dir="ltr" className="gz-t-fig-body">
              {v.code}
            </bdi>
          </span>
          {fact ? (
            <FactRow>
              <FactChip
                icon={usedOn ? 'check-double' : 'calendar'}
                label={usedOn ? t('clientBookingsTicketUsedOn') : t('clientBookingsTicketValidUntil')}
                value={<Fx text={fact} />}
                size="sm"
                tone="muted"
              />
            </FactRow>
          ) : null}
        </span>
        {attached ? <Icon name="chevron-right" size="sm" tone="secondary" /> : <StatusPill status={state} />}
      </button>
    </div>
  )
}
