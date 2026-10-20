// HL-SETT-03 Staff and roles. Requirement IDs: HA-SET-01, HA-SET-02, HA-AUTH-04, HA-AUTH-02.
// The team of the venue (Admin only): monogram, name in its own script, and per person the role and the state as facts (Active = when last seen,
// Pending = a pill and its expiry, Expired, Deactivated). Invite staff and the edit sheet are real sheets; inviting, removing and changing a role
// need a fresh email code first (the Verify screen in step-up mode, ADR 0028 D6). The owner and your own row cannot be changed here, and nobody
// removes themselves. Roles are glyph strips (what each may open); the plain-words line of each role, that whoever manages visits reads the visit
// chats and that ownership moves through support are read in the sheet of the top bar's (i). Support is one row at the end.
// Voucher model (ADR 0033): role lines name redemption, visits, listings and billing; bank, revenue and invoice permissions are gone, and
// `visit:manage` decides who can read a visit group chat. A service provider has no staff list here.
// Owner round 1: staff are invited by email (Resend) and step-up codes come by email; the row shows Invited until the invitee sets a password.
// States: loading, empty, error, offline, invite-sheet, edit-sheet, invite-pending, invite-expired, step-up-required, role-hidden.
import { Fragment, useState } from 'react'
import { useFrame } from '../../../shell/frame'
import { ActionBar, Banner, Dialog, EmptyState, ErrorState, IconListRow, InfoSheet, Screen, Sheet, Skeleton, TopBar, useNav } from '../../../system'
import { useAccount, useBi, useStaff, useStepUp, useStepUpResume, useWords, type StaffEntry } from './_components/bits'
import { EditContent, InviteContent, ROLE_LINE, RoleStrip, StaffPerson, useStaffName, type EditActions, type InviteValues } from './_components/StaffParts'
import { ACCESS, ASSIGNABLE, roleOfState, type SettingsRole } from './_components/model'
import { roleLabelOf, useSettingsLocal, type PendingAction } from './_components/store'
import './HL-SETT-03.css'

export const states = ['loading', 'empty', 'error', 'offline', 'invite-sheet', 'edit-sheet', 'invite-pending', 'invite-expired', 'step-up-required', 'role-hidden']

const noop = () => undefined

export default function StaffAndRoles() {
  const { state } = useFrame()
  const nav = useNav()
  const { t, c } = useWords()
  const nameOf = useStaffName()
  const bi = useBi()
  const roleName = (r: Exclude<SettingsRole, 'admin'>) => bi(roleLabelOf(r).label)
  const role = roleOfState(state === 'role-hidden' ? 'role-reception' : state)
  const account = useAccount()
  const hidden = !ACCESS[role].staff || account.type === 'provider'
  const offline = state === 'offline'
  const all = useStaff(state === 'invite-expired')
  const staff = state === 'empty' ? all.filter(e => e.owner) : all
  const sara = all.find(e => e.person.id === 'staff-sara')
  const amal = all.find(e => e.person.id === 'staff-amal')

  const stepUp = useStepUp('staff')

  // What a confirmed step-up lets through (the Verify screen pops, the resume hook calls this when this screen is on top again).
  const run = (action: PendingAction) => {
    const store = useSettingsLocal.getState()
    if (action.kind === 'invite') {
      const person = store.invite(action.name, action.email, action.role)
      if (action.role === 'reception') store.patchStaff(person.id, { canAccept: action.canAccept })
      nav.toast({ message: t('hotelSettingsStaffSent'), tone: 'success', icon: 'mail' })
    } else if (action.kind === 'role') {
      store.patchStaff(action.id, { role: action.role })
      nav.toast({ message: roleName(action.role), tone: 'success', icon: 'check-circle' })
    } else if (action.kind === 'remove') {
      const entry = all.find(e => e.person.id === action.id)
      store.patchStaff(action.id, { removed: true })
      nav.toast({
        message: t('hotelSettingsStaffRemoved', { name: entry ? nameOf(entry) : '' }),
        icon: 'user-minus',
        undo: true,
        action: { label: c('commonActionUndo'), onPress: () => useSettingsLocal.getState().patchStaff(action.id, { removed: false }) },
      })
    }
  }
  useStepUpResume('staff', run)

  const guardOffline = (): boolean => {
    if (!offline) return false
    nav.toast({ message: c('commonStateOffline'), icon: 'offline' })
    return true
  }

  // ---- sheets
  const openInvite = () => {
    if (guardOffline()) return
    const key = nav.openSheet(
      <InviteContent
        onClose={() => nav.closeSheet(key)}
        onSubmit={v => {
          nav.closeSheet(key)
          void stepUp({ kind: 'invite', name: v.name, email: v.email, role: v.role, canAccept: v.canAccept }, run)
        }}
      />,
    )
  }

  const editActions = (entry: StaffEntry, close: () => void): EditActions => ({
    onClose: close,
    onCanAccept: on => useSettingsLocal.getState().patchStaff(entry.person.id, { canAccept: on }),
    onSaveRole: next => {
      close()
      void stepUp({ kind: 'role', id: entry.person.id, role: next }, run)
    },
    onSessions: () => {
      if (guardOffline()) return
      close()
      nav.toast({ message: t('hotelSettingsStaffSessionsDone'), tone: 'success', icon: 'sign-out' })
    },
    onToggleActive: () => {
      if (guardOffline()) return
      close()
      const id = entry.person.id
      const was = entry.state === 'deactivated'
      useSettingsLocal.getState().patchStaff(id, { status: was ? 'active' : 'deactivated' })
      nav.toast({
        message: was ? t('hotelSettingsStaffReactivated', { name: nameOf(entry) }) : t('hotelSettingsStaffDeactivated', { name: nameOf(entry) }),
        icon: was ? 'user-plus' : 'user-minus',
        undo: true,
        action: { label: c('commonActionUndo'), onPress: () => useSettingsLocal.getState().patchStaff(id, { status: was ? 'deactivated' : 'active' }) },
      })
    },
    onRemove: async () => {
      if (guardOffline()) return
      close()
      const result = await nav.openDialog({
        title: t('hotelSettingsStaffRemoveTitle', { name: nameOf(entry) }),
        icon: 'user-minus',
        confirmLabel: t('hotelSettingsStaffRemoveConfirm'),
        cancelLabel: c('commonActionCancel'),
        tone: 'destructive',
      })
      if (result === 'confirm') void stepUp({ kind: 'remove', id: entry.person.id }, run)
    },
    onResend: () => {
      if (guardOffline()) return
      close()
      useSettingsLocal.getState().resendInvite(entry.person.id)
      nav.toast({ message: t('hotelSettingsStaffResent'), tone: 'success', icon: 'mail' })
    },
  })

  const openEdit = (entry: StaffEntry) => {
    const key = nav.openSheet(<EditContent entry={entry} actions={editActions(entry, () => nav.closeSheet(key))} />)
  }

  const supportRow = () => nav.push('HL-TODY-05', { conversationId: 'conv-support-aurelia' })
  const [about, setAbout] = useState(false)

  // ---- body
  let body
  if (state === 'loading') {
    body = (
      <div className="hs-page__skeleton" aria-busy="true" aria-label={c('commonStateLoading')}>
        {[0, 1, 2, 3].map(i => (
          <Skeleton key={i} variant="line" blockSize={64} />
        ))}
      </div>
    )
  } else if (state === 'error') {
    body = <ErrorState kind="load" onRetry={() => nav.replace('HL-SETT-03')} />
  } else if (hidden) {
    body = <ErrorState kind="no-access" />
  } else if (state === 'empty') {
    body = (
      <>
        <div className="hs-staff__list">
          {staff.map((e, i) => (
            <StaffPerson key={e.person.id} entry={e} last={i === staff.length - 1} />
          ))}
        </div>
        <EmptyState
          illustration="invitation"
          size="lg"
          title={t('hotelSettingsStaffEmptyTitle')}
          action={{ label: t('hotelSettingsStaffInvite'), variant: 'primary', iconStart: 'user-plus', onPress: openInvite }}
          fill={false}
        />
      </>
    )
  } else {
    body = (
      <>
        <div className="hs-staff__list">
          {staff.map((e, i) => (
            <Fragment key={e.person.id}>
              <StaffPerson entry={e} last={i === staff.length - 1} onOpen={e.owner || e.person.isYou ? undefined : () => openEdit(e)} />
            </Fragment>
          ))}
        </div>
        <IconListRow icon="chat-text" title={t('hotelSettingsStaffSupport')} chevron onClick={supportRow} last />
      </>
    )
  }

  const showBar = !hidden && state !== 'loading' && state !== 'error' && state !== 'empty'
  const bar = showBar ? <ActionBar action={{ label: t('hotelSettingsStaffInvite'), onPress: openInvite }} /> : undefined
  const actions = hidden || state === 'loading' || state === 'error' ? [] : [{ icon: 'info' as const, label: c('commonA11yInfo'), onPress: () => setAbout(true) }]

  const noopInvite = (_: InviteValues) => undefined
  return (
    <div className="hs-root">
      <Screen top={<TopBar title={t('hotelSettingsMoreStaff')} actions={actions} />} bottom={bar}>
        {offline ? <Banner tone="offline">{c('commonStateOffline')}</Banner> : null}
        <div className="hs-page">{body}</div>
      </Screen>
      <InfoSheet open={about} onClose={() => setAbout(false)} title={t('hotelSettingsStaffAboutTitle')}>
        <div className="hs-rolehelp">
          {ASSIGNABLE.map(r => (
            <div key={r} className="hs-rolehelp__item">
              <span className="gz-t-title">{roleName(r)}</span>
              <RoleStrip role={r} />
              <p className="gz-t-body-s">{t(ROLE_LINE[r])}</p>
            </div>
          ))}
          <p className="gz-t-body-s">{t('hotelSettingsStaffVisitNote')}</p>
          <p className="gz-t-body-s">{t('hotelSettingsStaffFoot')}</p>
        </div>
      </InfoSheet>
      {state === 'invite-sheet' ? (
        <Sheet>
          <InviteContent onSubmit={noopInvite} />
        </Sheet>
      ) : null}
      {state === 'edit-sheet' && amal ? (
        <Sheet>
          <EditContent entry={amal} actions={editActions(amal, noop)} />
        </Sheet>
      ) : null}
      {(state === 'invite-pending' || state === 'invite-expired') && sara ? (
        <Sheet>
          <EditContent entry={sara} actions={editActions(sara, noop)} />
        </Sheet>
      ) : null}
      {state === 'step-up-required' ? (
        <Dialog title={t('hotelSettingsStepUpTitle')} body={t('hotelSettingsStepUpBodyStaff')} icon="lock" confirmLabel={t('hotelSettingsStepUpSend')} cancelLabel={c('commonActionCancel')} />
      ) : null}
    </div>
  )
}
