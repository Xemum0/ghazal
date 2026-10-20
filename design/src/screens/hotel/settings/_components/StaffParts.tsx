// The pieces of Staff and roles (text diet, ADR 0034): one person row (monogram, name, role, state as facts), a role as a strip of glyphs, the
// role picker, and the contents of the invite and edit sheets. The plain-words line of each role is the accessible name of its glyph strip and
// is read in full behind the (i) of the screen; the one permission an Admin can switch is Reception's "accept and decline", a real switch.
// Actions that need a step-up are handed back to the screen, which closes the sheet first.
import { useState } from 'react'
import { useFormat } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { Avatar, Badge, Button, FactChip, Icon, StatusPill, Switch, TextField } from '../../../../system'
import { Fx } from './Fx'
import { SheetFrame, UserText, useBi, useWords, type StaffEntry } from './bits'
import { ASSIGNABLE, ROLE_GLYPHS, type SettingsRole } from './model'
import { roleLabelOf } from './store'

type Assignable = Exclude<SettingsRole, 'admin'>

/** The person's name in the UI language when the fixture has both scripts (staff typed in one script keep it). */
export function useStaffName() {
  const { lang } = useLang()
  return (entry: StaffEntry) => (lang === 'ar' ? entry.person.name : entry.person.nameLatin)
}

/** The state of a person as facts: Active = when last seen (a clock and a date), Pending = a pill and when it expires, Expired, Deactivated. */
export function StaffFacts({ entry }: { entry: StaffEntry }) {
  const { t, c } = useWords()
  const f = useFormat()
  const bi = useBi()
  const { person } = entry
  return (
    <span className="hs-person__facts">
      <Badge variant="quiet" bead={false}>
        {entry.owner ? t('hotelSettingsRoleOwner') : bi(person.roleLabel)}
      </Badge>
      {entry.state === 'active' && person.lastSeenAt ? <FactChip icon="clock" size="sm" tone="muted" label={t('hotelSettingsStaffLastSeen')} value={<Fx text={f.date(person.lastSeenAt, 'dayMonth')} />} /> : null}
      {entry.state === 'invited' ? (
        <>
          <StatusPill status="pending" audience="hotel" />
          {person.inviteExpiresAt ? <FactChip icon="timer" size="sm" tone="muted" label={t('hotelSettingsStaffExpires')} value={<Fx text={f.date(person.inviteExpiresAt, 'dayMonth')} />} /> : null}
        </>
      ) : null}
      {entry.state === 'expired' ? <StatusPill status="expired" audience="hotel" label={c('commonStatusExpired')} /> : null}
      {entry.state === 'deactivated' ? (
        <Badge variant="quiet" bead={false} icon="user-minus">
          {t('hotelSettingsStaffStateDeactivated')}
        </Badge>
      ) : null}
    </span>
  )
}

export function StaffPerson({ entry, last, onOpen }: { entry: StaffEntry; last: boolean; onOpen?: () => void }) {
  const { t } = useWords()
  const nameOf = useStaffName()
  const name = nameOf(entry)
  const body = (
    <>
      <span aria-hidden="true">
        <Avatar name={name} initial={entry.person.monogram} size="sm" voice="sans" />
      </span>
      <span className="hs-person__text">
        <span className="hs-person__line">
          <UserText role="title" className="hs-person__name">{name}</UserText>
          {entry.person.isYou ? <span className="gz-t-caption hs-person__you">{t('hotelSettingsStaffYou')}</span> : null}
        </span>
        <StaffFacts entry={entry} />
      </span>
      {onOpen ? <Icon name="chevron-right" size="sm" tone="secondary" /> : null}
    </>
  )
  const cls = `hs-person${last ? ' is-last' : ''}${entry.state === 'deactivated' ? ' is-off' : ''}`
  return onOpen ? (
    <button type="button" className={`gz-reset gz-press ${cls}`} onClick={onOpen} aria-label={t('hotelSettingsStaffOpen', { name })}>
      {body}
    </button>
  ) : (
    <div className={cls}>{body}</div>
  )
}

// ---------------------------------------------------------------- role picker

/** One plain line per role (ADR 0033): what each person will see, in the words of the voucher model. Read in full behind the (i) of the screen. */
export const ROLE_LINE = {
  manager: 'hotelSettingsRoleLineManager',
  reception: 'hotelSettingsRoleLineReception',
  accountant: 'hotelSettingsRoleLineAccountant',
  marketing: 'hotelSettingsRoleLineMarketing',
} as const satisfies Record<Assignable, string>

/** What a role may open, drawn as glyphs (muted = read only). The plain-words line is the accessible name of the strip. */
export function RoleStrip({ role }: { role: Assignable }) {
  const { t } = useWords()
  return (
    <span className="hs-strip" role="img" aria-label={t(ROLE_LINE[role])}>
      {ROLE_GLYPHS[role].map((g, i) => (
        <Icon key={i} name={g.icon} size="sm" tone={g.muted ? 'disabled' : 'secondary'} />
      ))}
    </span>
  )
}

export function RolePicker({ value, onChange, label }: { value: Assignable; onChange: (role: Assignable) => void; label: string }) {
  const bi = useBi()
  return (
    <div role="radiogroup" aria-label={label} className="hs-roles">
      {ASSIGNABLE.map(role => {
        const info = roleLabelOf(role)
        const on = value === role
        return (
          <button key={role} type="button" role="radio" aria-checked={on} className={`gz-reset gz-press hs-role${on ? ' is-on' : ''}`} onClick={() => onChange(role)}>
            <span className="hs-role__text">
              <span className="gz-t-title hs-role__name">{bi(info.label)}</span>
              <RoleStrip role={role} />
            </span>
            <span className="hs-role__mark" aria-hidden="true">
              {on ? <Icon name="check" size="sm" tone="primary" /> : null}
            </span>
          </button>
        )
      })}
    </div>
  )
}

/** Reception only: may this person accept and decline requests. */
function AcceptRow({ checked, onChange }: { checked: boolean; onChange: (on: boolean) => void }) {
  const { t } = useWords()
  return (
    <div className="hs-switchrow">
      <span className="hs-switchrow__disk" aria-hidden="true">
        <Icon name="check-double" size="md" tone="primary" />
      </span>
      <span className="gz-t-title hs-switchrow__title">{t('hotelSettingsStaffAccept')}</span>
      <Switch checked={checked} onChange={onChange} label={t('hotelSettingsStaffAccept')} />
    </div>
  )
}

// ---------------------------------------------------------------- invite sheet

export type InviteValues = { name: string; email: string; role: Assignable; canAccept: boolean }

export function InviteContent({ onSubmit, onClose }: { onSubmit: (v: InviteValues) => void; onClose?: () => void }) {
  const { t } = useWords()
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [role, setRole] = useState<Assignable>('reception')
  const [canAccept, setCanAccept] = useState(true)
  const [tried, setTried] = useState(false)
  const nameBad = name.trim().length < 2
  const emailBad = !/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email.trim())
  const submit = () => {
    setTried(true)
    if (nameBad || emailBad) return
    onSubmit({ name: name.trim(), email: email.trim(), role, canAccept })
  }
  return (
    <SheetFrame
      title={t('hotelSettingsStaffInvite')}
      onClose={onClose}
      footer={
        <Button fullWidth onClick={submit} iconStart="mail">
          {t('hotelSettingsStaffSend')}
        </Button>
      }
    >
      <TextField label={t('hotelSettingsStaffName')} value={name} onValueChange={setName} autoComplete="off" error={tried && nameBad ? t('hotelSettingsStaffNameError') : undefined} />
      <TextField
        label={t('hotelSettingsStaffEmail')}
        dir="ltr"
        type="email"
        inputMode="email"
        autoComplete="off"
        autoCapitalize="none"
        spellCheck={false}
        value={email}
        onValueChange={setEmail}
        error={tried && emailBad ? t('hotelSettingsStaffEmailError') : undefined}
      />
      <div className="hs-field">
        <p className="gz-t-label">{t('hotelSettingsStaffRole')}</p>
        <RolePicker value={role} onChange={setRole} label={t('hotelSettingsStaffRole')} />
      </div>
      {role === 'reception' ? <AcceptRow checked={canAccept} onChange={setCanAccept} /> : null}
    </SheetFrame>
  )
}

// ---------------------------------------------------------------- edit sheet

export type EditActions = {
  onSaveRole: (role: Assignable) => void
  onSessions: () => void
  onToggleActive: () => void
  onRemove: () => void
  onResend: () => void
  onCanAccept: (on: boolean) => void
  onClose?: () => void
}

export function EditContent({ entry, actions }: { entry: StaffEntry; actions: EditActions }) {
  const { t } = useWords()
  const nameOf = useStaffName()
  const current = entry.person.role === 'admin' ? 'manager' : (entry.person.role as Assignable)
  const [role, setRole] = useState<Assignable>(current)
  const [canAccept, setCanAccept] = useState(entry.canAccept)
  const pending = entry.state === 'invited' || entry.state === 'expired'
  const deactivated = entry.state === 'deactivated'
  const name = nameOf(entry)
  return (
    <SheetFrame
      title={<UserText role="ui-title">{name}</UserText>}
      onClose={actions.onClose}
      footer={
        role !== current ? (
          <Button fullWidth onClick={() => actions.onSaveRole(role)}>
            {t('hotelSettingsStaffSaveRole')}
          </Button>
        ) : undefined
      }
    >
      <StaffFacts entry={entry} />
      <div className="hs-field">
        <p className="gz-t-label">{t('hotelSettingsStaffRole')}</p>
        <RolePicker value={role} onChange={setRole} label={t('hotelSettingsStaffRole')} />
      </div>
      {role === 'reception' ? (
        <AcceptRow
          checked={canAccept}
          onChange={on => {
            setCanAccept(on)
            actions.onCanAccept(on)
          }}
        />
      ) : null}
      <div className="hs-actions">
        {pending ? (
          <Button variant="secondary" iconStart="refresh" onClick={actions.onResend}>
            {t('hotelSettingsStaffResend')}
          </Button>
        ) : null}
        {!pending ? (
          <button type="button" className="gz-reset gz-press hs-action" onClick={actions.onSessions}>
            <Icon name="sign-out" size="sm" tone="secondary" />
            <span className="gz-t-body">{t('hotelSettingsStaffSessions')}</span>
          </button>
        ) : null}
        {!pending ? (
          <button type="button" className="gz-reset gz-press hs-action" onClick={actions.onToggleActive}>
            <Icon name={deactivated ? 'user-plus' : 'user-minus'} size="sm" tone="secondary" />
            <span className="gz-t-body">{deactivated ? t('hotelSettingsStaffReactivate') : t('hotelSettingsStaffDeactivate')}</span>
          </button>
        ) : null}
        <Button variant="destructive" iconStart="trash" onClick={actions.onRemove}>
          {t('hotelSettingsStaffRemove')}
        </Button>
      </div>
    </SheetFrame>
  )
}
