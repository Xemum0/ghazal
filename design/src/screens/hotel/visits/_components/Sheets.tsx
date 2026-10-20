// The small sheets of the Visits flow, opened from the queue, the detail and the chat: Propose another time, Decline (reason chips), the
// assigned representative, the three chat members and the attach menu. Each is plain content for nav.openSheet; none is an inventory
// screen (the inventory has five). Decisions are never queued offline: the screens disable them in place before a sheet opens.
import { useMemo, useState } from 'react'
import type { HotelStaff, ThreadMember, VisitAppointment } from '../../../../mock'
import { visitDatesFor, visitSlotsFor } from '../../../../mock'
import { useFormat } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { Avatar, Button, ChipGroup, Icon, RoleBadge, TextArea } from '../../../../system'
import { Notice, SheetShell, UserText, useWords } from './bits'
import { firstName, visitStaff, VENUE_ID } from './model'
import type { DeclineReason } from './store'

// ---------------------------------------------------------------- propose another time

export function ProposeContent({ visit, onSend }: { visit: VisitAppointment; onSend: (slotStart: string) => void }) {
  const { t } = useWords()
  const f = useFormat()
  const name = firstName(visit.clientName)
  const days = useMemo(() => visitDatesFor(VENUE_ID, 14).slice(0, 8), [])
  const [day, setDay] = useState<string | null>(null)
  const [slot, setSlot] = useState<string | null>(null)
  const slots = useMemo(() => (day ? visitSlotsFor(VENUE_ID, day) : []), [day])
  const free = slots.filter(s => s.available)
  const need = !slot
  return (
    <SheetShell
      title={t('hotelVisitsProposeTitle')}
      footer={
        <Button size="cta" fullWidth iconStart="calendar-check" disabled={need} reason={need ? t('hotelVisitsProposeNeed') : undefined} onClick={() => slot && onSend(slot)}>
          {t('hotelVisitsProposeCta')}
        </Button>
      }
    >
      <div className="hv-sheet__field">
        <p className="gz-t-label hv-sheet__label">{t('hotelVisitsProposeDay')}</p>
        <ChipGroup<string>
          label={t('hotelVisitsProposeDay')}
          layout="wrap"
          value={day}
          onChange={v => {
            setDay(v)
            setSlot(null)
          }}
          options={days.map(d => ({ value: d, label: f.date(d, 'short') }))}
        />
      </div>
      {day ? (
        <div className="hv-sheet__field">
          <p className="gz-t-label hv-sheet__label">{t('hotelVisitsProposeTime')}</p>
          {free.length === 0 ? null : (
            <ChipGroup<string> label={t('hotelVisitsProposeTime')} layout="wrap" value={slot} onChange={setSlot} options={slots.map(s => ({ value: s.start, label: <bdi dir="ltr">{f.time(s.start)}</bdi>, disabled: !s.available }))} />
          )}
        </div>
      ) : null}
    </SheetShell>
  )
}

// ---------------------------------------------------------------- decline

export function DeclineContent({ visit, onConfirm, onCancel }: { visit: VisitAppointment; onConfirm: (reason: DeclineReason, note: string) => void; onCancel: () => void }) {
  const { t, c } = useWords()
  const name = firstName(visit.clientName)
  const [reason, setReason] = useState<DeclineReason | null>(null)
  const [note, setNote] = useState('')
  const [tried, setTried] = useState(false)
  const needNote = reason === 'other' && note.trim() === ''
  const submit = () => {
    if (!reason) return
    if (needNote) {
      setTried(true)
      return
    }
    onConfirm(reason, note.trim())
  }
  return (
    <SheetShell
      title={t('hotelVisitsDeclineTitle')}
      footer={
        <>
          <Button variant="destructive" size="cta" fullWidth disabled={!reason} reason={!reason ? t('hotelVisitsDeclineNeed') : undefined} onClick={submit}>
            {t('hotelVisitsDeclineCta')}
          </Button>
          <Button variant="tertiary" fullWidth onClick={onCancel}>
            {c('commonActionCancel')}
          </Button>
        </>
      }
    >
      <div className="hv-sheet__field">
        <p className="gz-t-label hv-sheet__label">{t('hotelVisitsDeclineReason')}</p>
        <ChipGroup<DeclineReason>
          label={t('hotelVisitsDeclineReason')}
          layout="wrap"
          value={reason}
          onChange={setReason}
          options={[
            { value: 'unavailable', label: t('hotelVisitsReasonUnavailable') },
            { value: 'closed', label: t('hotelVisitsReasonClosed') },
            { value: 'other', label: t('hotelVisitsReasonOther') },
          ]}
        />
      </div>
      {reason ? <TextArea label={t('hotelVisitsDeclineNote')} optional={reason !== 'other'} rows={3} value={note} onValueChange={setNote} error={tried && needNote ? t('hotelVisitsDeclineNoteRequired') : undefined} /> : null}
    </SheetShell>
  )
}

// ---------------------------------------------------------------- assigned representative

export function RepContent({ currentId, onPick }: { currentId: string; onPick: (staff: HotelStaff) => void }) {
  const { t } = useWords()
  const { lang } = useLang()
  const staff = visitStaff()
  return (
    <SheetShell title={t('hotelVisitsRepTitle')}>
      <ul className="hv-pick-list" role="radiogroup" aria-label={t('hotelVisitsRepTitle')}>
        {staff.map(s => {
          const on = s.userId === currentId
          const name = lang === 'ar' ? s.name : s.nameLatin
          return (
            <li key={s.id}>
              <button type="button" role="radio" aria-checked={on} className="gz-reset gz-press hv-pick-row" onClick={() => onPick(s)}>
                <Avatar name={name} initial={lang === 'ar' ? s.monogram : undefined} size="sm" voice="sans" />
                <span className="hv-pick-row__text">
                  <UserText role="title">{name}</UserText>
                  <span className="gz-t-caption hv-pick-row__sub">{s.roleLabel[lang]}</span>
                </span>
                <span className={`hv-pick-row__mark${on ? ' is-on' : ''}`} aria-hidden="true">
                  {on ? <Icon name="check" size="sm" /> : null}
                </span>
              </button>
            </li>
          )
        })}
      </ul>
    </SheetShell>
  )
}

// ---------------------------------------------------------------- chat members

export function MembersContent({ members, meId }: { members: readonly ThreadMember[]; meId?: string }) {
  const { t } = useWords()
  const { lang } = useLang()
  const order = { client: 0, hotel_representative: 1, support: 2 } as const
  const sorted = [...members].sort((a, b) => order[a.role] - order[b.role])
  return (
    <SheetShell title={t('hotelVisitsMembersTitle')}>
      <ul className="hv-pick-list">
        {sorted.map(m => {
          const name = lang === 'ar' ? m.name : m.nameLatin
          return (
            <li key={m.userId} className="hv-pick-row hv-pick-row--static">
              <Avatar name={name} initial={lang === 'ar' ? m.monogram : undefined} size="sm" voice="sans" />
              <span className="hv-pick-row__text">
                <UserText role="title">{name}</UserText>
                {m.organisation ? <span className="gz-t-caption hv-pick-row__sub">{m.organisation[lang]}</span> : null}
              </span>
              <RoleBadge role={m.role} you={m.userId === meId} />
            </li>
          )
        })}
      </ul>
    </SheetShell>
  )
}

// ---------------------------------------------------------------- attach

export function AttachContent({ onPick }: { onPick: (kind: 'camera' | 'photo' | 'document') => void }) {
  const { t } = useWords()
  const rows = [
    { kind: 'camera' as const, icon: 'camera' as const, label: t('hotelVisitsAttachCamera') },
    { kind: 'photo' as const, icon: 'image' as const, label: t('hotelVisitsAttachPhoto') },
    { kind: 'document' as const, icon: 'document' as const, label: t('hotelVisitsAttachDocument') },
  ]
  return (
    <SheetShell title={t('hotelVisitsAttachTitle')}>
      <ul className="hv-pick-list">
        {rows.map(r => (
          <li key={r.kind}>
            <button type="button" className="gz-reset gz-press hv-pick-row" onClick={() => onPick(r.kind)}>
              <span className="hv-pick-row__icon">
                <Icon name={r.icon} size="md" />
              </span>
              <span className="gz-t-body hv-pick-row__label">{r.label}</span>
            </button>
          </li>
        ))}
      </ul>
    </SheetShell>
  )
}
