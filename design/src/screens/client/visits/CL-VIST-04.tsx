// CL-VIST-04 My visits. Requirements: CA-VIS-04, CA-PROF-12.
// Text diet (ADR 0034): a two-glyph switch (calendar = Upcoming, clock = Past; the chosen one spells its word), then one row per visit
// (photograph, venue name, status pill, day and time as icon + value). The footnote ("Visits are free") is gone: it lives behind the info
// glyph of the booking sheet. Each state is a drawing, a title of at most four words and one action. A tap opens the chat (CL-VIST-03).
// Reached from Profile and My Wedding. Visits start from a venue, so there is no "Book another visit" here: the empty state sends the
// person to the halls.
// States: default, empty, loading, error, offline.
import { useMemo, useState } from 'react'
import { Banner, EmptyState, ErrorState, IconSegmented, Screen, Skeleton, TopBar, useNav } from '../../../system'
import { useFrame } from '../../../shell/frame'
import { VisitRow } from './_components/VisitRow'
import { isUpcoming, useMyVisits, useV } from './_components/model'
import './CL-VIST-04.css'

export const states = ['empty', 'loading', 'error', 'offline']

type Tab = 'upcoming' | 'past'

export default function MyVisits() {
  const { state } = useFrame()
  const nav = useNav()
  const { t, tc } = useV()
  const mine = useMyVisits()
  const [tab, setTab] = useState<Tab>('upcoming')

  const visits = state === 'empty' ? [] : mine
  const upcoming = useMemo(() => visits.filter(isUpcoming).sort((a, b) => (a.slotStart < b.slotStart ? -1 : 1)), [visits])
  const past = useMemo(() => visits.filter(v => !isUpcoming(v)), [visits])
  const list = tab === 'upcoming' ? upcoming : past

  const top = <TopBar title={t('clientVisitsListTitle')} />
  const open = (id: string) => nav.push('CL-VIST-03', { visitId: id })
  const seeHalls = () => nav.push('CL-DISC-03')

  if (state === 'error') {
    return (
      <Screen top={top}>
        <ErrorState kind="load" />
      </Screen>
    )
  }
  if (state === 'loading') {
    return (
      <Screen top={top}>
        <div className="gzvt-ls__page" aria-busy="true" aria-label={tc('commonStateLoading')}>
          <Skeleton blockSize={52} />
          <Skeleton blockSize={112} />
          <Skeleton blockSize={112} />
        </div>
      </Screen>
    )
  }
  if (visits.length === 0) {
    return (
      <Screen top={top}>
        <EmptyState illustration="empty-visits" title={t('clientVisitsEmptyTitle')} action={{ label: t('clientVisitsEmptyAction'), variant: 'primary', onPress: seeHalls }} />
      </Screen>
    )
  }

  return (
    <Screen top={top}>
      {state === 'offline' ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}
      <div className="gzvt-ls__page">
        <IconSegmented
          label={t('clientVisitsListTitle')}
          value={tab}
          onChange={setTab}
          options={[
            { value: 'upcoming', icon: 'calendar', label: t('clientVisitsTabUpcoming') },
            { value: 'past', icon: 'clock', label: t('clientVisitsTabPast') },
          ]}
        />
        {list.length === 0 ? (
          <EmptyState
            fill={false}
            size="lg"
            illustration="empty-visits"
            title={tc('commonStateTitleEmpty')}
            action={tab === 'upcoming' ? { label: t('clientVisitsEmptyAction'), variant: 'secondary', onPress: seeHalls } : undefined}
          />
        ) : (
          <ul className="gzvt-ls__list" aria-label={tab === 'upcoming' ? t('clientVisitsTabUpcoming') : t('clientVisitsTabPast')}>
            {list.map(v => (
              <li key={v.id}>
                <VisitRow visit={v} onOpen={() => open(v.id)} />
              </li>
            ))}
          </ul>
        )}
      </div>
    </Screen>
  )
}
