// The pieces of the venue terms screen (HL-VENU-05): the voucher terms Ghazal sets (read only, shown next to the venue's own terms), and the
// opening hours rows with the sheet that edits one set of days. Times and day names come from the formatter; nothing here types a digit.
import { useState } from 'react'
import type { Weekday } from '../../../../mock'
import { Button, Icon, SelectRow, useNav } from '../../../../system'
import { SheetFrame } from './fields'
import { Figures, ReadOnlyRow, useV } from './bits'
import { useTimeLabel } from './HallParts'
import type { HoursModel } from './store'
import { TIME_SLOTS, platform } from './venue'
import './policy.css'

/** `Sun to Thu` for a run of days, else the list (`Fri and Sat`). */
export function useDaysLabel() {
  const { f, t } = useV()
  return (days: readonly Weekday[]): string => {
    const sorted = [...days].sort((a, b) => a - b)
    const first = sorted[0]
    const last = sorted[sorted.length - 1]
    if (first === undefined || last === undefined) return ''
    const run = sorted.length > 2 && last - first === sorted.length - 1
    return run ? t('hotelVenueHoursRun', { from: f.weekdayName(first, 'short'), to: f.weekdayName(last, 'short') }) : f.list(sorted.map(d => f.weekdayName(d, 'short')))
  }
}

/** What Ghazal sets for every voucher, stated beside the venue's own terms (voucher-model sections 4 and 10). Configuration, never typed. */
export function VoucherTerms() {
  const { t, c, f } = useV()
  return (
    <div className="hv-vt" data-gz="VoucherTerms">
      <p className="hv-vt__head gz-t-title">
        <Icon name="ticket" size="sm" tone="secondary" />
        {t('hotelVenueVoucherTermsTitle')}
      </p>
      <div className="hv-vt__rows">
        <ReadOnlyRow label={t('hotelVenueVtFee')} value={<Figures text={f.money(platform.voucherFeeFils, { mode: 'browse' })} />} />
        <ReadOnlyRow label={t('hotelVenueVtValidity')} value={<Figures text={c('commonCountDays', { count: platform.voucherValidityDays })} />} />
        <ReadOnlyRow label={t('hotelVenueVtConfirm')} value={<Figures text={c('commonCountHours', { count: platform.confirmWindowHours })} />} />
        <ReadOnlyRow label={t('hotelVenueVtRedeem')} value={t('hotelVenueVtRedeemValue')} />
      </div>
    </div>
  )
}

export function HoursRow({ h, onOpen, disabled }: { h: HoursModel; onOpen: () => void; disabled?: boolean }) {
  const { t } = useV()
  const days = useDaysLabel()
  const time = useTimeLabel()
  return (
    <button type="button" className="gz-reset hv-hrs gz-press" onClick={onOpen} disabled={disabled} data-gz="HoursRow">
      <span className="hv-hrs__text">
        <span className="gz-t-title">{days(h.days)}</span>
        <span className="gz-t-body-s hv-hrs__time">
          <Figures text={t('hotelVenueHoursLine', { from: time(h.open), to: time(h.close) })} />
        </span>
      </span>
      <Icon name="chevron-right" size="sm" tone="secondary" />
    </button>
  )
}

export function HoursSheet({ hours, onSave }: { hours: HoursModel; onSave: (next: HoursModel) => void }) {
  const { t, c } = useV()
  const nav = useNav()
  const days = useDaysLabel()
  const time = useTimeLabel()
  const [draft, setDraft] = useState(hours)
  const slots = TIME_SLOTS.map(v => ({ value: v, label: time(v) }))
  return (
    <SheetFrame
      footer={
        <Button
          variant="primary"
          fullWidth
          onClick={() => {
            onSave(draft)
            nav.closeSheet()
          }}
        >
          {c('commonActionSave')}
        </Button>
      }
    >
      <p className="gz-t-body hv-hrs__lead">{days(hours.days)}</p>
      <SelectRow<string> label={t('hotelVenueHoursOpen')} value={draft.open} onChange={v => v && setDraft(d => ({ ...d, open: v }))} options={slots} />
      <SelectRow<string>
        label={t('hotelVenueHoursClose')}
        value={draft.close}
        onChange={v => v && setDraft(d => ({ ...d, close: v }))}
        options={slots}
        helper={draft.close <= draft.open ? t('hotelVenueSessionAfterMidnight') : undefined}
      />
    </SheetFrame>
  )
}
