// HL-CALN-05 Calendar by email (sheet): keep an outside calendar (Google, Outlook, Apple) in step by email. One switch (an .ics invitation for each
// confirmed booking and block, to the account address), one optional second address, one test action. Emails go through Resend; there is no
// WhatsApp channel for this (ADR 0035 D8). Reception sees it read-only.
// Text diet (ADR 0034): a mail glyph and one short line per control, addresses as LTR isolates, nothing else.
// Requirements: HA-CAL-10, HA-CAL-06
// States: default, address-added, address-invalid, sending-test, test-sent, loading, error, offline
import { useEffect, useRef, useState } from 'react'
import { Button, Icon, Skeleton, Switch, TextField, useNav } from '../../../system'
import { Notice } from './_components/CalNotice'
import { SheetFrame } from './_components/CalSheetFrame'
import { canBlock } from './_components/data'
import { roleFrom, useWords } from './_components/calBits'
import './HL-CALN-05.css'

export const states = ['default', 'address-added', 'address-invalid', 'sending-test', 'test-sent', 'loading', 'error', 'offline']

/** Account email of the signed-in manager (fixture). */
const ACCOUNT_EMAIL = 'reservations@danah-hotel.com'
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/

export default function CalendarByEmail({ state }: { state?: string }) {
  const { t, c } = useWords()
  const nav = useNav<{ role?: string }>()
  const readOnly = !canBlock(roleFrom(nav.params.role))
  const [on, setOn] = useState(true)
  const [extra, setExtra] = useState(state === 'address-added' || state === 'test-sent' || state === 'sending-test' ? 'calendar@danah-hotel.com' : state === 'address-invalid' ? 'calendar@danah' : '')
  const [phase, setPhase] = useState<'idle' | 'sending' | 'sent'>(state === 'sending-test' ? 'sending' : state === 'test-sent' ? 'sent' : 'idle')
  const timer = useRef<number | undefined>(undefined)
  useEffect(() => () => window.clearTimeout(timer.current), [])

  const offline = state === 'offline'
  const invalid = extra.trim() !== '' && !EMAIL.test(extra.trim())
  const test = () => {
    setPhase('sending')
    timer.current = window.setTimeout(() => {
      setPhase('sent')
      nav.toast({ message: t('hotelCalendarEmailTestSent'), tone: 'success', icon: 'check-circle' })
    }, 700)
  }

  const footer = (
    <Button
      variant="primary"
      fullWidth
      iconStart="send"
      loading={phase === 'sending'}
      disabled={!on || invalid || readOnly || offline || state === 'error'}
      reason={offline ? c('commonStateOffline') : undefined}
      onClick={test}
    >
      {t('hotelCalendarEmailTest')}
    </Button>
  )

  return (
    <SheetFrame title={t('hotelCalendarEmailTitle')} footer={state === 'loading' ? undefined : footer}>
      {offline ? <Notice tone="offline">{c('commonStateOffline')}</Notice> : null}
      {state === 'error' ? <Notice tone="danger" action={{ label: c('commonActionRetry'), onPress: () => nav.replace('HL-CALN-05') }}>{t('hotelCalendarSaveFailed')}</Notice> : null}
      {state === 'loading' ? (
        <div className="cal-e">
          <Skeleton variant="block" blockSize={56} />
          <Skeleton variant="block" blockSize={56} />
        </div>
      ) : (
        <div className="cal-e">
          <div className="cal-e__row">
            <Icon name="mail" size="md" />
            <span className="cal-e__text">
              <span className="gz-t-body">{t('hotelCalendarEmailSwitch')}</span>
              <bdi dir="ltr" className="gz-t-caption cal-e__addr">{ACCOUNT_EMAIL}</bdi>
            </span>
            <Switch checked={on} onChange={setOn} label={t('hotelCalendarEmailSwitch')} disabled={readOnly || offline} />
          </div>
          <TextField
            label={t('hotelCalendarEmailAdd')}
            type="email"
            dir="ltr"
            inputMode="email"
            value={extra}
            onValueChange={v => {
              setExtra(v)
              setPhase('idle')
            }}
            error={invalid ? t('hotelCalendarEmailInvalid') : undefined}
            disabled={!on || readOnly || offline}
            startAdornment={<Icon name="mail" size="sm" tone="secondary" />}
          />
        </div>
      )}
    </SheetFrame>
  )
}
