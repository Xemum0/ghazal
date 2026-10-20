// What a representative can do to a visit (HA-VIS-02 to HA-VIS-06), wired to the shared prototype store so the client app sees every change.
//   Confirm: one tap with the 8 s Undo toast   Propose another time / Decline: the two sheets of this flow   Mark arrived: HL-VIST-04
//   Open: the visit detail (HL-VIST-02)        Chat: the group chat (HL-VIST-03)
// A decision is never queued offline: the screens disable it in place with a plain reason, so nothing here runs without a connection.
import { useMemo } from 'react'
import type { HotelStaff, ThreadMember, VisitAppointment } from '../../../../mock'
import { useFormat } from '../../../../i18n'
import { usePrototype } from '../../../../shell/state'
import { useNav } from '../../../../system'
import { AttachContent, DeclineContent, MembersContent, ProposeContent, RepContent } from './Sheets'
import { useWords } from './bits'
import { firstName } from './model'
import { useVisitsLocal } from './store'

export function useVisitActions() {
  const nav = useNav()
  const f = useFormat()
  const { t, c } = useWords()
  return useMemo(() => {
    const store = () => usePrototype.getState()
    const open = (v: VisitAppointment) => nav.push('HL-VIST-02', { visitId: v.id })
    const chat = (v: VisitAppointment) => nav.push('HL-VIST-03', { visitId: v.id })
    const arrival = (v: VisitAppointment) => nav.openSheet('HL-VIST-04', { params: { visitId: v.id } })

    const confirm = (v: VisitAppointment) => {
      const before = v
      store().setVisitStatus(v.id, 'confirmed')
      nav.toast({
        message: t('hotelVisitsToastConfirmed', { when: f.dateTime(v.slotStart, 'short') }),
        tone: 'success',
        undo: true,
        action: {
          label: c('commonActionUndo'),
          onPress: () => usePrototype.setState(s => ({ visits: s.visits.map(x => (x.id === before.id ? before : x)) })),
        },
      })
    }

    const propose = (v: VisitAppointment) => {
      const key = nav.openSheet(
        <ProposeContent
          visit={v}
          onSend={slot => {
            nav.closeSheet(key)
            useVisitsLocal.getState().propose(v.id, slot)
            store().setVisitStatus(v.id, 'reschedule_proposed')
            nav.toast({ message: t('hotelVisitsToastProposed', { name: firstName(v.clientName) }), tone: 'success', icon: 'check-circle' })
          }}
        />,
      )
    }

    const decline = (v: VisitAppointment, after?: () => void) => {
      const key = nav.openSheet(
        <DeclineContent
          visit={v}
          onCancel={() => nav.closeSheet(key)}
          onConfirm={(reason, note) => {
            nav.closeSheet(key)
            useVisitsLocal.getState().decline(v.id, reason, note)
            store().setVisitStatus(v.id, 'declined')
            nav.toast({ message: t('hotelVisitsToastDeclined', { name: firstName(v.clientName) }), icon: 'check-circle' })
            after?.()
          }}
        />,
      )
    }

    const assign = (v: VisitAppointment, currentId: string) => {
      const key = nav.openSheet(
        <RepContent
          currentId={currentId}
          onPick={(s: HotelStaff) => {
            nav.closeSheet(key)
            useVisitsLocal.getState().assign(v.id, s.userId)
            nav.toast({ message: t('hotelVisitsToastAssigned', { name: s.nameLatin }), tone: 'success', icon: 'check-circle' })
          }}
        />,
      )
    }

    const members = (list: readonly ThreadMember[], meId?: string) => nav.openSheet(<MembersContent members={list} meId={meId} />)

    const attach = (onPick: (kind: 'camera' | 'photo' | 'document') => void) => {
      const key = nav.openSheet(
        <AttachContent
          onPick={kind => {
            nav.closeSheet(key)
            onPick(kind)
          }}
        />,
      )
    }

    return { open, chat, arrival, confirm, propose, decline, assign, members, attach }
  }, [nav, f, t, c])
}
