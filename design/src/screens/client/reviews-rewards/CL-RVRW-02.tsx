// CL-RVRW-02 Write a review. Requirements: CA-REV-01, CA-REV-02, CA-REV-03, CA-REV-04, CA-STAT-07, CA-TOOL-19, CA-AUTH-10.
// Rate a completed booking, built to the text diet (ADR 0034): five large stars with one live word, four optional category scores as glyph
// + word + stars, a comment, photos with a one-glyph rule ("No people") and how the name is shown. The sentences that survive (people rule,
// what is allowed, the moderation check) sit behind the (i) on the Photos header. The draft autosaves in the prototype store, so leaving
// and coming back loses nothing ("Saved"). Only a Completed booking opens it (the others see the day reviews open). Text publishes after an automated check; photographs wait in
// moderation and only the author sees them until they pass (ADR 0015 D7).
// Navigates to CL-BKNG-02 (back), CL-RVRW-01 (see reviews).
import { useEffect, useMemo, useRef, useState } from 'react'
import {
  ActionBar, Banner, EmptyState, FactChip, FactRow, Figures, Icon, InfoButton, Photo, Screen, SuccessState, TextArea, ToggleRow, TopBar, imageSrc, useNav,
} from '../../../system'
import { clock, reviewsFor, heroBookingAs } from '../../../mock'
import { useLang } from '../../../shell/lang'
import { Fx } from './_components/Fx'
import { PhotoTile } from './_components/PhotoTile'
import { StarRow } from './_components/StarRow'
import { bookingById, reviewerName, venueById } from './_components/model'
import { useRewardsFlow, type Categories, type Media, type ReviewDraft, type StarValue } from './_components/store'
import { useRr, useStateParam, useViewer } from './_components/useRr'
import './CL-RVRW-02.css'

export const states = ['ineligible', 'uploading', 'photo-rejected-people', 'submitting', 'success', 'media-under-review', 'error', 'offline-draft', 'already-reviewed']

const MAX_PHOTOS = 5
const PER_ROW = 3
const CATEGORIES = [
  { key: 'venue', icon: 'hall', label: 'clientReviewsRewardsWriteCatVenue' },
  { key: 'food', icon: 'catering', label: 'clientReviewsRewardsWriteCatFood' },
  { key: 'service', icon: 'staff', label: 'clientReviewsRewardsWriteCatService' },
  { key: 'value', icon: 'coins', label: 'clientReviewsRewardsWriteCatValue' },
] as const
const ZONES = ['stage_kosha', 'buffet', 'hall', 'entrance_valet'] as const
const TEXT_MAX = 600

type Phase = 'idle' | 'submitting' | 'done'

export default function WriteReview() {
  const { t, tc, bi, dayMonth, audience, sectionIcon } = useRr()
  const { lang } = useLang()
  const nav = useNav<{ bookingId?: string; venueId?: string; from?: 'list' }>()
  const state = useStateParam()
  const { live } = useViewer(state)
  const sentMap = useRewardsFlow(s => s.sent)

  const booking = state === 'ineligible' ? heroBookingAs('pending') : bookingById(nav.params.bookingId)
  const venue = venueById(booking.venueId ?? undefined)
  const venueName = bi(venue.name)
  const who = reviewerName()
  const cover = venue.cover

  // The photographs a viewer can "pick": the stand-in for the OS picker is the venue's own library (the hall, the stage, the buffet, the entrance).
  const samples = useMemo(
    () => ZONES.flatMap(z => venue.gallery.filter(g => g.zone === z).slice(0, 1)).map(g => ({ file: g.file, alt: g.alt })),
    [venue],
  )

  // ---------------------------------------------------------------- the draft: the store in the player, local in a frame
  const preset = useMemo<ReviewDraft>(() => {
    const filled = state && ['uploading', 'photo-rejected-people', 'submitting', 'error', 'offline-draft', 'success', 'media-under-review'].includes(state)
    const sample = reviewsFor(venue.id).find(r => r.id === 'rv-V01-01')
    const shot = (i: number, status: Media['status']): Media | null => {
      const s = samples[i]
      return s ? { id: `pick-${i + 1}`, file: s.file, alt: s.alt, status } : null
    }
    const media =
      state === 'uploading' ? [shot(0, 'uploading')] : state === 'photo-rejected-people' ? [shot(0, 'review'), shot(1, 'rejected')] : state === 'media-under-review' ? [shot(0, 'review'), shot(1, 'review')] : filled && state !== 'success' ? [shot(0, 'review')] : []
    return {
      rating: filled ? 5 : 0,
      categories: filled ? { venue: 5, food: 5, service: 5, value: 4 } : { venue: 0, food: 0, service: 0, value: 0 },
      text: filled && sample ? sample.text[lang] : '',
      anonymous: false,
      media: media.filter((m): m is Media => m !== null),
    }
  }, [state, samples, venue.id, lang])

  const storeDraft = useRewardsFlow(s => s.draft)
  const [local, setLocal] = useState<ReviewDraft>(preset)
  const draft = live ? storeDraft : local
  // One functional updater for both homes of the draft, so two photographs settling at once never overwrite each other.
  const update = (fn: (d: ReviewDraft) => ReviewDraft) => (live ? useRewardsFlow.setState(s => ({ draft: fn(s.draft) })) : setLocal(fn))
  const patch = (p: Partial<ReviewDraft>) => update(d => ({ ...d, ...p }))
  const setRating = (rating: StarValue) => patch({ rating })
  const setCategory = (key: keyof Categories, value: StarValue) => update(d => ({ ...d, categories: { ...d.categories, [key]: value } }))
  const setMedia = (fn: (m: Media[]) => Media[]) => update(d => ({ ...d, media: fn(d.media) }))

  const [phase, setPhase] = useState<Phase>('idle')
  const timers = useRef<number[]>([])
  const picks = useRef(0)
  useEffect(() => () => timers.current.forEach(id => window.clearTimeout(id)), [])

  const shown: Phase = state === 'submitting' ? 'submitting' : state === 'success' || state === 'media-under-review' ? 'done' : phase
  const offline = state === 'offline-draft'
  const failed = state === 'error'
  const busy = shown === 'submitting'
  const sent = sentMap[booking.id]

  const closeBack = () => nav.pop()
  // Came from the reviews list: that list is the screen below, so "back" is the way to it (the reviews list is never stacked twice).
  const fromList = nav.params.from === 'list'
  const seeReviews = () => (fromList ? nav.pop() : nav.replace('CL-RVRW-01', { venueId: venue.id }))

  // ---------------------------------------------------------------- photographs
  const addPhoto = () => {
    if (draft.media.length >= MAX_PHOTOS || samples.length === 0) return
    picks.current += 1
    const n = picks.current
    const s = samples[(n - 1) % samples.length]!
    setMedia(m => [...m, { id: `pick-${n}`, file: s.file, alt: s.alt, status: 'uploading' }])
  }
  // The second photograph the viewer adds shows how the no-people rule answers; every other one passes the check.
  const settle = (id: string) => setMedia(m => m.map(x => (x.id === id ? { ...x, status: id === 'pick-2' ? 'rejected' : 'review' } : x)))
  const removePhoto = (id: string) => setMedia(m => m.filter(x => x.id !== id))

  // ---------------------------------------------------------------- submit
  const submit = () => {
    if (busy || offline) return
    setPhase('submitting')
    timers.current.push(
      window.setTimeout(() => {
        if (live) useRewardsFlow.getState().send(booking.id, venue.id, clock.now())
        setPhase('done')
      }, 900),
    )
  }

  const top = <TopBar title={t('clientReviewsRewardsWriteTitle')} back={live ? 'auto' : true} onBack={closeBack} />
  const eligible = booking.status === 'completed'

  // ---------------------------------------------------------------- not yet: the day reviews open, and the way back
  if (!eligible) {
    return (
      <Screen top={top}>
        <EmptyState
          illustration="hourglass"
          title={<Figures text={t('clientReviewsRewardsOpens', { date: dayMonth(booking.eventDate) })} />}
          action={{ label: t('clientReviewsRewardsWriteLockedAction'), onPress: closeBack }}
        />
      </Screen>
    )
  }

  // ---------------------------------------------------------------- already reviewed
  if (state === 'already-reviewed' || (live && sent && shown !== 'done')) {
    return (
      <Screen top={top}>
        <SuccessState
          illustration="seal"
          title={t('clientReviewsRewardsWriteAlreadyTitle')}
          action={{ label: t('clientReviewsRewardsWriteDoneSee'), onPress: seeReviews }}
        />
      </Screen>
    )
  }

  // ---------------------------------------------------------------- sent: one drawing, one line, the photographs still in review
  if (shown === 'done') {
    const kept = (draft.media.length > 0 ? draft.media : sent?.media ?? preset.media).filter(x => x.status !== 'rejected')
    return (
      <Screen
        top={top}
        bottom={
          <ActionBar
            // From the list, "Done" already returns to the reviews, so a second way to the same place is dropped.
            secondary={fromList ? undefined : { label: t('clientReviewsRewardsWriteDoneSee'), onPress: seeReviews }}
            action={{ label: tc('commonActionDone'), onPress: closeBack }}
          />
        }
      >
        <div className="rvw-done" data-gz-id="review.done">
          <SuccessState
            fill={kept.length === 0}
            illustration="success-request"
            title={t('clientReviewsRewardsWriteDoneTitle')}
            body={t('clientReviewsRewardsWriteDoneHelper')}
          />
          {kept.length > 0 ? (
            <div className="rvw-done__media">
              <div className="rvw-tiles">
                {Array.from({ length: PER_ROW }, (_, i) => {
                  const m = kept[i]
                  return m ? <PhotoTile key={m.id} media={{ ...m, status: 'review' }} /> : <span key={`s${i}`} className="rvw-slot" aria-hidden="true" />
                })}
              </div>
            </div>
          ) : null}
        </div>
      </Screen>
    )
  }

  // ---------------------------------------------------------------- the composer
  const rated = draft.rating > 0
  const word = rated ? t(`clientReviewsRewardsWriteStar${draft.rating}` as 'clientReviewsRewardsWriteStar5') : '\u00A0'
  const shownName = draft.anonymous ? t('clientReviewsRewardsGuest') : lang === 'ar' ? who.ar : who.en
  const reason = offline ? t('clientReviewsRewardsWriteOfflineReason') : !rated ? t('clientReviewsRewardsWriteSubmitReason') : undefined
  // Slots in rows of three: the photographs, then the add tile, then blanks to the end of the row.
  const used = Math.min(draft.media.length + 1, MAX_PHOTOS)
  const count = Math.ceil(used / PER_ROW) * PER_ROW
  const rows = Array.from({ length: count / PER_ROW }, (_, r) => Array.from({ length: PER_ROW }, (_, c) => r * PER_ROW + c))
  const hasDraft = rated || draft.text.length > 0 || draft.media.length > 0

  return (
    <Screen
      top={top}
      bottom={
        <ActionBar
          action={{ label: failed ? tc('commonActionRetry') : tc('commonActionSend'), onPress: submit, loading: busy, disabled: !rated || offline, reason }}
        />
      }
    >
      {offline ? <Banner tone="offline">{t('clientReviewsRewardsWriteOffline')}</Banner> : null}
      {failed ? <Banner tone="danger">{t('clientReviewsRewardsWriteError')}</Banner> : null}

      <div className="rvw" data-gz-id="review.composer" aria-busy={busy || undefined}>
        <header className="rvw-plate">
          {cover ? (
            <span className="rvw-plate__thumb">
              <Photo src={imageSrc(cover.file)} alt="" className="rvw-plate__img" sizes="64px" priority />
            </span>
          ) : null}
          <div className="rvw-plate__text">
            <h2 className="rvw-plate__name gz-t-d1">
              <bdi dir="auto">{venueName}</bdi>
            </h2>
            <FactRow>
              <FactChip icon={sectionIcon(booking.sections[0]?.audience)} label={audience(booking.sections[0]?.audience)} />
              <FactChip icon="calendar" tone="muted" label={t('clientReviewsRewardsListEvent')} value={<Fx text={dayMonth(booking.eventDate)} />} />
            </FactRow>
          </div>
        </header>

        <section className="rvw-section rvw-rate" aria-label={t('clientReviewsRewardsWritePrompt', { venue: venueName })}>
          <div className="rvw-section rvw-overall">
            <StarRow label={t('clientReviewsRewardsWriteOverall')} value={draft.rating} onChange={setRating} disabled={busy} spread />
            <p className={`rvw-word gz-t-d2${rated ? ' is-set' : ''}`} role="status">
              {word}
            </p>
          </div>
          <div className="rvw-cats">
            {CATEGORIES.map(c => (
              <div key={c.key} className="rvw-cat">
                <span className="rvw-cat__label">
                  <Icon name={c.icon} size="sm" tone="secondary" />
                  <span className="gz-t-body">{t(c.label)}</span>
                </span>
                <StarRow size="md" label={t(c.label)} value={draft.categories[c.key]} onChange={v => setCategory(c.key, v)} disabled={busy} />
              </div>
            ))}
          </div>
        </section>

        <section className="rvw-section">
          <TextArea
            label={t('clientReviewsRewardsWriteTextLabel')}
            value={draft.text}
            onValueChange={text => patch({ text })}
            maxLength={TEXT_MAX}
            rows={3}
            disabled={busy}
          />
        </section>

        <section className="rvw-section" aria-label={t('clientReviewsRewardsWriteMediaTitle')}>
          <div className="rvw-head">
            <h3 className="gz-t-title">{t('clientReviewsRewardsWriteMediaTitle')}</h3>
            <span className="rvw-rule" data-gz-id="review.mediaRule">
              <Icon name="user" size="xs" tone="secondary" />
              <Icon name="x-circle" size="xs" tone="danger" />
              <span className="gz-t-caption">{t('clientReviewsRewardsWriteMediaNoPeople')}</span>
            </span>
            <InfoButton title={t('clientReviewsRewardsWriteMediaInfoTitle')} className="rvw-info">
              <p>{t('clientReviewsRewardsWriteMediaRule')}</p>
              <p>{t('clientReviewsRewardsWriteMediaAllowed')}</p>
              <p>{t('clientReviewsRewardsWriteMediaChecked')}</p>
            </InfoButton>
          </div>
          <div className="rvw-media" data-gz-id="review.media">
            {rows.map((row, r) => (
              <div key={r} className="rvw-tiles">
                {row.map(i => {
                  const m = draft.media[i]
                  if (m) {
                    return (
                      <PhotoTile key={m.id} media={m} frozenPercent={live ? undefined : 60} onSettled={settle} onRemove={busy ? undefined : removePhoto} />
                    )
                  }
                  if (i === draft.media.length && draft.media.length < MAX_PHOTOS) {
                    return (
                      <button key="add" type="button" className="gz-reset rvw-add gz-press" onClick={addPhoto} disabled={busy} aria-label={t('clientReviewsRewardsWriteMediaAdd')}>
                        <Icon name="camera" size="lg" />
                      </button>
                    )
                  }
                  return <span key={`s${i}`} className="rvw-slot" aria-hidden="true" />
                })}
              </div>
            ))}
          </div>
        </section>

        <section className="rvw-section">
          <ToggleRow
            title={t('clientReviewsRewardsWriteNameHide')}
            description={<bdi dir="auto">{shownName}</bdi>}
            checked={draft.anonymous}
            onChange={anonymous => patch({ anonymous })}
            disabled={busy}
            divider={false}
          />
          {hasDraft ? (
            <p className="rvw-saved gz-t-caption" role="status">
              <Icon name="check" size="xs" tone="success" />
              {tc('commonStateSaved')}
            </p>
          ) : null}
        </section>
      </div>
    </Screen>
  )
}
