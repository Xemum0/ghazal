// StaffRow: one person on the hotel's team (HL-SETT-03, HA-SET-01, HA-SET-02, ADR 0008 D12). Monogram, the name in its own script, the role
// as a quiet badge (Owner and You as markers), and the state line: Active with when they were last seen, Invite pending with its expiry,
// or Deactivated. Opened, it explains the role in one plain line and lists what that role may do (the role matrix of ADR 0008 D12): a
// check for what the role has, a minus for what it does not; the one permission an Admin can switch is Reception's "accept and decline",
// a real switch. Roles are fixed by the role, so a locked permission says so rather than showing a dead switch.
import { useState } from 'react'
import type { HotelStaff, StaffRole } from '@gz/contracts'
import { useFormat } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { Avatar, Badge, Icon, Switch } from '../../core'
import { cx } from '../../core/cx'
import { Figures, UserText, useBi } from '../internal/bits'
import { defineWords, p } from '../internal/copy'
import './settings.css'

const useW = defineWords({
  you: p('You', 'أنتم'),
  active: p('Active', 'نشط'),
  lastSeen: p('last seen {time}', 'آخر ظهور {time}'),
  pending: p('Invite pending', 'الدعوة قيد الانتظار'),
  expires: p('expires {date}', 'تنتهي {date}'),
  deactivated: p('Deactivated', 'معطّل'),
  allowed: p('Allowed', 'مسموح'),
  notAllowed: p('Not for this role', 'ليس لهذا الدور'),
  open: p('Permissions of {name}', 'صلاحيات {name}'),
  accept: p('Accept, decline and propose dates', 'قبول الطلبات والاعتذار واقتراح موعد آخر'),
  block: p('Block and open dates', 'إغلاق التواريخ وفتحها'),
  cancel: p('Reschedule or cancel a confirmed booking', 'تغيير موعد حجز مؤكد أو إلغاؤه'),
  cash: p('Record cash received', 'تسجيل مبلغ نقدي مستلم'),
  revenue: p('See revenue and payments', 'الاطلاع على الإيرادات والدفعات'),
  offers: p('Create and end offers', 'إنشاء العروض وإنهاؤها'),
  manage: p('Staff and bank information', 'الموظفون وبيانات الحساب البنكي'),
  switchable: p('Can be switched off by the owner', 'يمكن للمالك إيقافه'),
})

type Permission = 'accept' | 'block' | 'cancel' | 'cash' | 'revenue' | 'offers' | 'manage'
const MATRIX: Record<StaffRole, readonly Permission[]> = {
  admin: ['accept', 'block', 'cancel', 'cash', 'revenue', 'offers', 'manage'],
  manager: ['accept', 'block', 'cancel', 'cash', 'revenue', 'offers'],
  reception: ['accept', 'block', 'cash'],
  accountant: ['cash', 'revenue'],
  marketing: ['offers'],
}
const ORDER: readonly Permission[] = ['accept', 'block', 'cancel', 'cash', 'revenue', 'offers', 'manage']

export type StaffRowProps = {
  staff: HotelStaff
  defaultExpanded?: boolean
  /** Reception only: "Can accept and decline requests" (the owner may switch it off). */
  canAccept?: boolean
  onCanAcceptChange?: (on: boolean) => void
  onPress?: () => void
  last?: boolean
  className?: string
}

export function StaffRow({ staff, defaultExpanded = false, canAccept = true, onCanAcceptChange, last = false, className }: StaffRowProps) {
  const f = useFormat()
  const w = useW()
  const bi = useBi()
  const { lang } = useLang()
  const [open, setOpen] = useState(defaultExpanded)
  const name = lang === 'ar' ? staff.name : staff.nameLatin
  const state =
    staff.status === 'active'
      ? [w('active'), staff.lastSeenAt ? w('lastSeen', { time: f.dateTime(staff.lastSeenAt) }) : ''].filter(Boolean).join(' · ')
      : staff.status === 'invited'
        ? [w('pending'), staff.inviteExpiresAt ? w('expires', { date: f.date(staff.inviteExpiresAt, 'short') }) : ''].filter(Boolean).join(' · ')
        : w('deactivated')
  const allowed = new Set(MATRIX[staff.role])

  return (
    <section data-gz="StaffRow" data-status={staff.status} className={cx('gz-staff', last && 'is-last', open && 'is-open', className)}>
      <button type="button" className="gz-reset gz-staff__head gz-press" aria-expanded={open} aria-label={w('open', { name })} onClick={() => setOpen(!open)}>
        <Avatar name={name} initial={staff.monogram} size="sm" voice="sans" />
        <span className="gz-staff__text">
          <span className="gz-staff__line">
            <UserText role="title" className="gz-staff__name">
              {name}
            </UserText>
            <Badge variant="quiet" bead={false}>
              {bi(staff.roleLabel)}
            </Badge>
            {staff.isYou ? <span className="gz-t-caption gz-staff__marker">{w('you')}</span> : null}
          </span>
          <span className={cx('gz-t-caption gz-staff__state', staff.status === 'deactivated' && 'is-muted')}>
            <Figures text={state} />
          </span>
        </span>
        <Icon name={open ? 'chevron-up' : 'chevron-down'} size="sm" tone="secondary" />
      </button>

      {open ? (
        <div className="gz-staff__body">
          <p className="gz-t-body-s gz-staff__summary">{bi(staff.roleSummary)}</p>
          <ul className="gz-staff__perms">
            {ORDER.map(perm => {
              const has = allowed.has(perm)
              const switchable = staff.role === 'reception' && perm === 'accept'
              return (
                <li key={perm} className="gz-staff__perm">
                  <span className="gz-staff__perm-text">
                    <span className="gz-t-body-s">{w(perm)}</span>
                    {switchable ? <span className="gz-t-caption gz-staff__why">{w('switchable')}</span> : null}
                  </span>
                  {switchable ? (
                    <Switch checked={canAccept} onChange={onCanAcceptChange} label={w('accept')} />
                  ) : (
                    <span className={cx('gz-staff__flag gz-t-caption', has && 'is-yes')}>
                      <Icon name={has ? 'check' : 'minus'} size="xs" tone={has ? 'success' : 'secondary'} />
                      {has ? w('allowed') : w('notAllowed')}
                    </span>
                  )}
                </li>
              )
            })}
          </ul>
        </div>
      ) : null}
    </section>
  )
}
