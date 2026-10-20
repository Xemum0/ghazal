// CL-SAVD-04 Compare (pushed, tab bar hidden). Covers CA-CMP-04, CA-CMP-05, CA-CMP-06, CA-CMP-07, CA-CMP-08, CA-CMP-09, CA-CMP-10, CA-CMP-11,
// CA-CMP-12, CA-BOOK-01, CA-VCH-02.
// The hardest layout of the app: three equal columns at 360 to 430, no label column, no sideways scroll. Text diet (ADR 0034): the table has
// no row labels and no group bands; a cell is a fact with its own glyph. The Brief echo is three facts and a pencil (`[women] [users] 350
// [calendar] 14 Jan`), the header (4:5 thumbnails, serif names, one glyph badge each) hands over to a compact pinned strip, a two-glyph
// switch (differences | all) is on differences by default, rows carry Best in row on objective rows, range bars (your guests ticked on
// capacity), a chevron that opens the Packages names, photo strips, and a footer of three 48 buttons of one word aligned to the thirds.
// Gold appears only on a hall the family has picked. Words left on the face: hall names (authored), one status word per availability cell,
// the switch's selected word, and the footer's one-word buttons (a decision is never icon-only). The few marks that a shape does not
// explain (best bead, saving, check, coin, dash, ticket, bank) are an icon list behind the info glyph in the top bar (CompareKey).
// Drive time reads `18 min` / `18 دقيقة` (the compact `18 m` is ambiguous beside a road glyph), dates and times go through Fx.
// Voucher model (ADR 0033): both prices and the saving in one Price cell, and the footer says Voucher, Dates, Official, View or Remove: the
// hall's price is requested with a voucher (CL-VCHR-01 binds it to the date and the guests), there is no Request or Book here.
import { useMemo, useState } from 'react'
import { clock, compareSet, getArea, getVenue } from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { Banner, Button, EmptyState, ErrorState, FactChip, Icon, InfoSheet, Monogram, Photo, Screen, Skeleton, TopBar, imageSrc, useBi, useNav } from '../../../system'
import { useLang } from '../../../shell/lang'
import { BriefFacts } from './_components/BriefFacts'
import { CompareKey } from './_components/CompareKey'
import { Fx } from './_components/Fx'
import { CompareBar, CompareGrid } from './_components/CompareGrid'
import { briefFor, originOf, useSavedModel } from './_components/useSavedData'
import type { ActionKind } from './_components/compare-model'
import './CL-SAVD-04.css'

export const states = ['loading', 'fewer-than-two', 'no-date', 'venue-unavailable', 'venue-unlisted', 'government-column', 'offline', 'error', 'shared-link-guest']

/** The column set a state draws: the story set by default; real fixtures for each edge (V06 is booked on the story date, V19 is the ministry hall). */
function idsFor(state: string | undefined, current: string[]): string[] {
  switch (state) {
    case 'venue-unavailable':
      return ['V01', 'V05', 'V06']
    case 'government-column':
      return ['V01', 'V08', 'V19']
    case 'fewer-than-two':
      return current.slice(0, 1)
    default:
      return current.slice(0, 3)
  }
}

export default function Compare() {
  const { state } = useFrame()
  const t = useT('client-saved-compare')
  const c = useT('common')
  const f = useFormat()
  const bi = useBi()
  const nav = useNav()
  const { lang } = useLang()
  const m = useSavedModel()
  const brief = briefFor(m, state)
  const [diff, setDiff] = useState(true)
  const [picked, setPicked] = useState<string | null>(null)
  const [keyOpen, setKeyOpen] = useState(false)

  const ids = idsFor(state, m.compare)
  const unlistedId = state === 'venue-unlisted' ? 'V07' : null
  const origin = originOf(brief)
  const originName = bi(getArea(origin.areaId)?.name)
  const columns = useMemo(
    () => compareSet(ids, brief, origin.id),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [ids.join('|'), brief.date, brief.guests, brief.audience, origin.id],
  )

  const loading = state === 'loading'
  const errored = state === 'error'
  const offline = state === 'offline'
  const shared = state === 'shared-link-guest'
  const guest = shared || m.guest
  const fewer = state === 'fewer-than-two' || (!loading && !errored && columns.length < 2)

  // ---- actions
  const remove = (id: string) => {
    if (m.live) usePrototype.getState().removeFromCompare(id)
    if (picked === id) setPicked(null)
  }
  const openVenue = (id: string) => nav.push(getVenue(id)?.channel === 'external_link' ? 'CL-VENU-06' : 'CL-VENU-01', { venueId: id })
  const onAction = (id: string, kind: ActionKind) => {
    if (kind === 'remove') return remove(id)
    if (kind === 'official') return nav.push('CL-VENU-06', { venueId: id })
    if (kind === 'view') return openVenue(id)
    if (kind === 'dates') return nav.openSheet('CL-VENU-03', { params: { venueId: id } })
    // Get voucher: CL-VCHR-01 carries the date and the guests of the Brief and binds the voucher to this hall. A guest meets the sign-in
    // sheet there first ("to get your voucher") and returns with the quote intact (ADR 0007 D8).
    if (m.live) usePrototype.getState().startDraft(id, { eventDate: brief.date ?? null, guests: brief.guests ?? null, audience: brief.audience ?? null })
    nav.openSheet('CL-VCHR-01', { params: { venueId: id, eventDate: brief.date ?? null, guests: brief.guests ?? null } })
  }
  const pick = (id: string) => setPicked(p => (p === id ? null : id))
  const share = () => nav.toast({ message: t('clientSavedCompareCompareLinkCopied'), tone: 'success' })
  const signIn = () => nav.openSheet('CL-AUTH-01', { params: { reason: 'save' } })

  const pickedVenue = picked ? getVenue(picked) : undefined
  const showBar = !loading && !errored && !fewer

  return (
    <Screen
      top={
        <TopBar
          title={t('clientSavedCompareCompareTitle')}
          actions={[
            ...(showBar ? [{ icon: 'info' as const, label: t('clientSavedCompareKeyTitle'), onPress: () => setKeyOpen(true) }] : []),
            { icon: 'share', label: c('commonActionShare'), onPress: share },
          ]}
        />
      }
      bottom={showBar ? <CompareBar columns={columns} brief={brief} unlistedId={unlistedId} pickedId={picked} onAction={onAction} /> : undefined}
    >
      {offline ? <Banner tone="offline">{c('commonStateOffline')}</Banner> : null}
      {shared ? (
        <aside className="svd-shared" data-gz-id="shared.note">
          <span className="svd-shared__pair">
            <Icon name="ticket" size="sm" tone="secondary" />
            <Icon name="lock" size="sm" tone="secondary" />
            <span className="gz-sr-only">{c('commonLabelGuestVoucher')}</span>
          </span>
          <Button variant="tertiary" onClick={signIn}>
            {t('clientSavedCompareSavedGuestSignIn')}
          </Button>
        </aside>
      ) : null}

      {errored ? (
        <ErrorState kind="load" />
      ) : fewer ? (
        <section className="svd-fewer" data-gz="CompareFewer">
          {columns[0] ? (
            <div className="svd-fewer__hall">
              <span className="svd-fewer__thumb">
                {columns[0].venue.cover ? <Photo src={imageSrc(columns[0].venue.cover.file)} alt={bi(columns[0].venue.cover.alt)} className="svd-fewer__photo" /> : <Monogram size="sm" />}
              </span>
              <span className="svd-fewer__who">
                <span className="svd-fewer__name gz-t-d1 gz-clamp-2" lang={lang}>
                  {bi(columns[0].venue.name)}
                </span>
                <span className="svd-fewer__area gz-t-caption">{bi(getArea(columns[0].venue.areaId)?.name)}</span>
              </span>
            </div>
          ) : null}
          <EmptyState
            illustration="onboard-compare"
            title={t('clientSavedCompareCompareFewerTitle')}
            action={{ label: t('clientSavedCompareCompareFewerAction'), variant: 'primary', onPress: () => nav.pop() }}
            fill={false}
            size="hero"
          />
        </section>
      ) : (
        <>
          <div className="svd-echo">
            {brief.audience || brief.guests || brief.date ? <BriefFacts brief={brief} onEdit={() => nav.openSheet('CL-DISC-02')} /> : null}
            <p className="gz-sr-only" aria-live="polite" data-gz-id="pick.hint">
              {pickedVenue ? t('clientSavedCompareComparePicked', { name: bi(pickedVenue.name) }) : ''}
            </p>
            {offline ? (
              <div className="svd-echo__stale">
                <FactChip icon="clock" size="sm" tone="muted" label={t('clientSavedCompareLastUpdated')} value={<Fx text={f.time(clock.now())} />} />
              </div>
            ) : null}
          </div>
          {loading ? (
            <CompareSkeleton label={c('commonStateLoading')} />
          ) : (
            <CompareGrid
              columns={columns}
              brief={brief}
              origin={originName}
              unlistedId={unlistedId}
              pickedId={picked}
              onPick={pick}
              onRemove={remove}
              onOpen={openVenue}
              onGallery={(id, index) => nav.push('CL-VENU-02', { venueId: id, index })}
              onSetDate={() => nav.openSheet('CL-DISC-02')}
              audience={guest ? 'guest' : 'member'}
              diff={diff}
              onDiffChange={setDiff}
            />
          )}
        </>
      )}
      <InfoSheet open={keyOpen} onClose={() => setKeyOpen(false)} title={t('clientSavedCompareKeyTitle')}>
        <CompareKey />
      </InfoSheet>
    </Screen>
  )
}

/** Header and a few rows as static ink-100 shapes in the same thirds: no shimmer, nothing loops. */
function CompareSkeleton({ label }: { label: string }) {
  return (
    <div className="svd-skel" aria-busy="true" aria-label={label}>
      <div className="svd-skel__head">
        {[0, 1, 2].map(i => (
          <div key={i} className="svd-skel__col">
            <Skeleton variant="block" blockSize={120} />
            <Skeleton blockSize={24} />
            <Skeleton inlineSize={64} blockSize={20} />
          </div>
        ))}
      </div>
      {[0, 1, 2, 3, 4].map(r => (
        <div key={r} className="svd-skel__row">
          <Skeleton inlineSize={96} blockSize={16} />
          <div className="svd-skel__cells">
            {[0, 1, 2].map(i => (
              <div key={i} className="svd-skel__cell">
                <Skeleton blockSize={24} />
                <Skeleton inlineSize={48} blockSize={4} />
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  )
}
