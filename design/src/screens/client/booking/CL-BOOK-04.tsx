// CL-BOOK-04 Your details (step 4 of 5). Covers CA-BOOK-07, CA-BOOK-08, CA-AUTH-05, CA-AUTH-06, CA-AUTH-10.
// Text diet (ADR 0034): fields with one-word labels and no helpers. Who the booking is for is a two-glyph switch, the relation a row of
// glyph chips (bride, groom, family, planner), the common special requests glyph chips whose words are accessible names, and who sees the phone
// (CA-BOOK-07) is one sentence behind a "Privacy" row. Who the venue calls, who the booking is for, anything it should know, and a verified phone
// (a request cannot be sent without one). A person signed in by WhatsApp arrives verified; a changed number is verified here by a code sheet.
// One primary action: Continue (errors appear on tap, blameless and specific). Navigates to CL-BOOK-05, CL-AUTH-02, CL-BOOK-03.
import { useState } from 'react'
import { Banner, ChipGroup, ErrorState, Icon, IconSegmented, PhoneField, Skeleton, TextArea, TextField, useBi, useNav } from '../../../system'
import type { IconName } from '@gz/tokens'
import { useFormat, useT } from '../../../i18n'
import { usePrototype } from '../../../shell/state'
import { useFrame } from '../../../shell/frame'
import * as mock from '../../../mock'
import { AsideInfo } from './_components/AsideInfo'
import { PhoneStatus } from './_components/PhoneStatus'
import { StepScreen } from './_components/StepScreen'
import { useContact, useFlow, useFlowStore, useLive, useScenario, type Relation } from './_components/flow'
import { centerInBody } from './_components/centerInBody'
import './_components/step.css'
import './_components/details.css'

export const states = ['validation-error', 'phone-unverified', 'phone-verified', 'loading', 'error', 'offline']

const RELATIONS: Relation[] = ['bride', 'groom', 'family', 'planner']
const RELATION_KEY = {
  bride: 'clientBookingRelationBride',
  groom: 'clientBookingRelationGroom',
  family: 'clientBookingRelationFamily',
  planner: 'clientBookingRelationPlanner',
} as const
const RELATION_GLYPH: Record<Relation, IconName> = { bride: 'dress', groom: 'groom', family: 'team', planner: 'checklist' }

/** The story booking's own typed request (user text is stored as typed, dir auto): the filled form of the frames. */
const STORY_REQUEST = () => mock.heroBookingAs('pending').specialRequests ?? ''

export default function YourDetails() {
  const t = useT('client-booking')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const nav = useNav()
  const live = useLive()
  const { state } = useFrame()
  const flow = useFlow(useScenario(state, {}))
  const contact = useContact()
  const draft = usePrototype(s => s.bookingDraft)
  const patchDraft = usePrototype(s => s.patchDraft)
  const local = useFlowStore()

  const filled = state === 'phone-verified'
  const invalid = state === 'validation-error'
  const unverified = state === 'phone-unverified'
  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'

  // The fields keep their own text (a cleared field stays cleared); in the player each change is also written to the draft (autosave).
  const [name, setName] = useState(invalid ? '' : contact.name)
  const [phone, setPhone] = useState(invalid ? '5000' : unverified ? '50000099' : contact.phone)
  const [email, setEmail] = useState(contact.email)
  const [requests, setRequests] = useState(filled ? STORY_REQUEST() : draft.requests)
  const [showErrors, setShowErrors] = useState(invalid)
  const [forWho, setForWho] = useState<'self' | 'other'>(filled || invalid ? 'other' : local.forWho)
  const [otherName, setOtherName] = useState(filled ? 'فهد الشمري' : local.otherName)
  const [relation, setRelation] = useState<Relation>(local.relation)

  const phoneValid = f.isValidPhone(phone)
  const verified = phoneValid && (phone === contact.signedPhone || phone === local.verifiedPhone) && !unverified
  const nameError = showErrors && !name.trim() ? t('clientBookingNameError') : undefined
  const phoneError = showErrors && !phoneValid ? t('clientBookingPhoneDigits', { count: 8 }) : undefined
  const otherError = showErrors && forWho === 'other' && !otherName.trim() ? t('clientBookingNameError') : undefined

  const save = (patch: { name?: string; phone?: string; email?: string; requests?: string; relation?: Relation }) => {
    if (!live) return
    const p = { ...draft.personal }
    if (patch.name !== undefined) p.name = patch.name
    if (patch.phone !== undefined) p.phone = patch.phone
    if (patch.email !== undefined) p.email = patch.email
    if (patch.relation !== undefined) p.bookingFor = patch.relation
    patchDraft({ personal: p, ...(patch.requests !== undefined ? { requests: patch.requests } : {}) })
  }

  const addSuggestion = (text: string) => {
    const next = requests.trim() ? `${requests.trim()}\n${text}` : text
    setRequests(next)
    save({ requests: next })
  }
  const kosha = t('clientBookingSuggestKosha', { time: f.time(mock.engine.at(flow.date, '12:00')) })
  // A glyph and one word each (the glyph alone is ambiguous: a chair and a clock is not "kosha team access"); the full request is what is added.
  const suggestions: { value: string; icon: IconName; word: string; text: string }[] = [
    { value: 'photographer', icon: 'camera', word: t('clientBookingSuggestPhotographerShort'), text: t('clientBookingSuggestPhotographer') },
    { value: 'kosha', icon: 'armchair', word: t('clientBookingSuggestKoshaShort'), text: kosha },
    { value: 'wheelchair', icon: 'accessible', word: t('clientBookingSuggestWheelchairShort'), text: t('clientBookingSuggestWheelchair') },
  ]

  const openVerify = () =>
    nav.openSheet('CL-AUTH-02', {
      params: { presentation: 'sheet', reason: 'send-request' },
      onClose: () => useFlowStore.getState().set({ verifiedPhone: phone }),
    })

  const next = () => {
    const bad = !name.trim() || !phoneValid || (forWho === 'other' && !otherName.trim())
    if (bad) {
      setShowErrors(true)
      // The first invalid field comes into view (clear of the sticky footer) so its blameless message is read.
      window.setTimeout(() => {
        const el = document.querySelector<HTMLElement>('.bk-form [aria-invalid="true"]')
        if (!el) return
        const calm = window.matchMedia('(prefers-reduced-motion: reduce)').matches
        centerInBody(el, calm)
        el.focus({ preventScroll: true })
      }, 60)
      return
    }
    useFlowStore.getState().set({ forWho, otherName: otherName.trim(), relation })
    patchDraft({ step: 'review', personal: { name: name.trim(), phone, email: email.trim(), bookingFor: forWho === 'other' ? relation : draft.personal.bookingFor }, requests: requests.trim() })
    if (!verified) openVerify()
    else nav.push('CL-BOOK-05')
  }

  return (
    <StepScreen
      step={4}
      venueName={bi(flow.venue.name)}
      title={t('clientBookingDetailsTitle')}
      notice={offline ? <Banner tone="offline" shape="card">{t('clientBookingOfflineBanner')}</Banner> : null}
      bar={error ? null : { action: { label: tc('commonActionContinue'), onPress: next, loading, disabled: offline } }}
    >
      {error ? (
        <div className="bk-section">
          <ErrorState kind="load" fill={false} />
        </div>
      ) : loading ? (
        <div className="bk-section bk-form" aria-busy="true">
          {[0, 1, 2].map(i => (
            <div key={i} className="bk-field">
              <Skeleton inlineSize={96} blockSize={20} />
              <Skeleton blockSize={56} />
            </div>
          ))}
          <Skeleton blockSize={44} />
          <Skeleton blockSize={96} />
        </div>
      ) : (
        <>
          <section className="bk-section bk-form" aria-label={t('clientBookingReviewContact')}>
            <TextField
              label={t('clientBookingNameLabel')}
              value={name}
              onValueChange={v => {
                setName(v)
                save({ name: v })
              }}
              autoComplete="name"
              error={nameError}
              enterKeyHint="next"
            />
            <div className="bk-phone">
              <PhoneField
                label={t('clientBookingPhoneLabel')}
                value={phone}
                onChange={n => {
                  setPhone(n)
                  save({ phone: n })
                }}
                error={phoneError}
                validateOnBlur={false}
              />
              {phoneValid ? <PhoneStatus verified={verified} onVerify={openVerify} disabled={offline} /> : null}
            </div>
            <TextField
              label={t('clientBookingEmailLabel')}
              dir="ltr"
              type="email"
              inputMode="email"
              autoComplete="email"
              value={email}
              onValueChange={v => {
                setEmail(v)
                save({ email: v })
              }}
            />
          </section>

          <section className="bk-section bk-form" aria-label={t('clientBookingForLabel')}>
            <IconSegmented
              label={t('clientBookingForLabel')}
              value={forWho}
              onChange={setForWho}
              options={[
                { value: 'self', icon: 'user', label: t('clientBookingForSelf') },
                { value: 'other', icon: 'user-plus', label: t('clientBookingForOther') },
              ]}
            />
            {forWho === 'other' ? (
              <>
                <TextField label={t('clientBookingForNameLabel')} value={otherName} onValueChange={setOtherName} error={otherError} />
                <ChipGroup
                  label={t('clientBookingForRelationLabel')}
                  layout="wrap"
                  options={RELATIONS.map(r => ({
                    value: r,
                    label: (
                      <span className="bk-glyphs">
                        <Icon name={RELATION_GLYPH[r]} size="sm" />
                        {t(RELATION_KEY[r])}
                      </span>
                    ),
                  }))}
                  value={relation}
                  onChange={v => {
                    if (!v) return
                    setRelation(v)
                    save({ relation: v })
                  }}
                />
              </>
            ) : null}
          </section>

          <section className="bk-section bk-form" aria-label={t('clientBookingRequestsLabel')}>
            <TextArea
              label={t('clientBookingRequestsLabel')}
              value={requests}
              onValueChange={v => {
                setRequests(v)
                save({ requests: v })
              }}
              rows={3}
            />
            <ChipGroup
              label={t('clientBookingRequestsSuggestions')}
              layout="wrap"
              selection="multiple"
              value={suggestions.filter(s => requests.includes(s.text)).map(s => s.value)}
              options={suggestions.map(s => ({
                value: s.value,
                label: (
                  <span className="bk-glyphs">
                    <Icon name={s.icon} size="sm" />
                    {s.word}
                    <span className="gz-sr-only">{s.text}</span>
                  </span>
                ),
              }))}
              onChange={v => {
                const added = suggestions.find(s => v.includes(s.value) && !requests.includes(s.text))
                if (added) addSuggestion(added.text)
              }}
            />
          </section>

          <section className="bk-section" data-gz-id="booking.privacy">
            <AsideInfo icon="lock" word={t('clientBookingPrivacyWord')} title={t('clientBookingPrivacyWord')}>
              <p>{t('clientBookingPrivacy', { venue: bi(flow.venue.name) })}</p>
            </AsideInfo>
          </section>
        </>
      )}
    </StepScreen>
  )
}
