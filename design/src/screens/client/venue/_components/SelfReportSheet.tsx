// SelfReportSheet (CL-VENU-06 "Mark booked"): the date and the fee the couple paid on the official channel. Honest about what it is: a record
// for the budget, the checklist and the countdown, not a Ghazal booking (that sentence is behind the (i), ADR 0034). A node sheet opened by
// the government screen.
import { useState } from 'react'
import { useFormat, useT } from '../../../../i18n'
import { Button, DateField, InfoButton, TextField, useNav } from '../../../../system'
import { useSelfReports } from './selfReport'
import './sections.css'

export function SelfReportSheet({ venueId, defaultDate, defaultFils }: { venueId: string; defaultDate: string; defaultFils: number }) {
  const t = useT('client-venue')
  const tc = useT('common')
  const f = useFormat()
  const nav = useNav()
  const [date, setDate] = useState<string | null>(defaultDate)
  const [fee, setFee] = useState(String(defaultFils / 1000))
  const fils = Math.round(Number(f.normalizeDigits(fee).replace(',', '.')) * 1000)
  const valid = Boolean(date) && Number.isFinite(fils) && fils > 0

  const save = () => {
    if (!date || !valid) return
    useSelfReports.getState().save(venueId, { date, fils })
    nav.closeSheet()
    nav.toast({ message: t('clientVenueGovSelfToast'), tone: 'success', action: { label: t('clientVenueGovSelfView'), onPress: () => nav.switchTab('my-wedding') } })
  }

  return (
    <div className="gzv-self" data-gz-id="venue.self-report">
      <DateField label={t('clientVenueGovSelfDate')} value={date} onChange={setDate} />
      <TextField
        label={t('clientVenueGovSelfFee')}
        value={fee}
        onValueChange={setFee}
        inputMode="decimal"
        dir="ltr"
        startAdornment={<span className="gz-t-caption">{f.moneyParts(0).currency}</span>}
      />
      <div className="gzv-self__foot">
        <InfoButton title={t('clientVenueGovSelfInfoTitle')}>
          <p>{t('clientVenueGovSelfNote')}</p>
        </InfoButton>
        <Button variant="primary" fullWidth disabled={!valid} onClick={save}>
          {tc('commonActionSave')}
        </Button>
      </div>
    </div>
  )
}
