// CL-VENU-05 Terms and hall rules (sheet). Covers CA-VDET-06, CA-VDET-15..19, CA-VDET-26, CA-SRCH-12, CA-SRCH-13.
// The terms and the per-section facts families actually ask about (ADR 0033: there is no event payment in the app, so the cancellation tier
// bar and the cooling-off are retired). Three tabs: Terms (the venue's own words, clamped, then the voucher terms as five short rows: the fee,
// the binding, who is paid, the reuse and refund rule, the confirm window; every value is configuration), Hall rules (a ladies | men glyph
// switch, each fact a glyph chip, never a judgement), Good to know (children, dress code, working hours, closures as glyph rows).
// There is no request button here: the sheet's close returns to the page. Navigates to CL-VENU-01 and, from the booking review, CL-BOOK-05.
// Text diet (ADR 0034): this sheet is where the voucher and venue terms live (the exception that has a home), so it keeps its sentences as
// fragments of six words or fewer; everything else is a glyph, a chip or a figure.
import { useMemo, useState } from 'react'
import * as mock from '../../../mock'
import { engine } from '../../../mock'
import type { Audience, Hall, Venue } from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { Banner, ErrorState, Figures, Icon, IconSegmented, IconTabs, Skeleton, SkeletonText, useBi, useNav } from '../../../system'
import { Clamp } from './_components/Clamp'
import { RuleChips } from './_components/RuleChips'
import { SheetFrame } from './_components/SheetFrame'
import { SECTION_ICON } from './_components/glyphs'
import { fittingHalls, VOUCHER_FEE_FILS, useVenueBrief, useVenueId } from './_components/model'
import './CL-VENU-05.css'

export const states = ['single-section', 'loading', 'offline']

type Segment = 'terms' | 'rules' | 'good'
type Params = { venueId?: string; hallId?: string; segment?: string; date?: string }

const AUD_LONG = { women: 'clientVenueAudWomen', men: 'clientVenueAudMen', mixed: 'clientVenueAudMixed' } as const

export default function PoliciesSheet() {
  const t = useT('client-venue')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const nav = useNav<Params>()
  const { state } = useFrame()
  const venueId = useVenueId()
  const venue: Venue | undefined = mock.getVenue(venueId)
  const brief = useVenueBrief(venue)
  const initial: Segment = state === 'single-section' ? 'rules' : nav.params.segment === 'rules' || nav.params.segment === 'good' ? nav.params.segment : 'terms'
  const [segment, setSegment] = useState<Segment>(initial)
  const halls = useMemo(() => (venue ? fittingHalls(venue, brief.audience, brief.guests) : []), [venue, brief.audience, brief.guests])
  const hall: Hall | undefined = (venue?.halls.find(h => h.id === nav.params.hallId) ?? halls[0]) as Hall | undefined
  const [audience, setAudience] = useState<Audience | null>(null)

  if (state === 'error') {
    return (
      <SheetFrame title={t('clientVenuePolTitle')}>
        <ErrorState kind="load" fill={false} />
      </SheetFrame>
    )
  }
  if (state === 'loading') {
    return (
      <SheetFrame title={t('clientVenuePolTitle')}>
        <div className="gzv-pol__skeleton" aria-busy="true" aria-label={tc('commonStateLoading')}>
          <Skeleton blockSize={56} />
          <SkeletonText lines={6} />
        </div>
      </SheetFrame>
    )
  }
  if (!venue || !hall) return null

  const sections = hall.sections
  const activeAudience: Audience = audience && sections.some(s => s.audience === audience) ? audience : (sections.find(s => s.audience === brief.audience)?.audience ?? sections[0]!.audience)
  const section = sections.find(s => s.audience === activeAudience) ?? sections[0]!
  const today = mock.clock.today()
  const config = mock.meta.config
  const fee = f.plain(f.money(VOUCHER_FEE_FILS, { mode: 'browse' }))
  const days = tc('commonCountDays', { count: config.voucherReuseDays })
  const hours = tc('commonCountHours', { count: config.confirmWindowHours })
  const voucherTerms = [
    { icon: 'ticket' as const, text: t('clientVenueTermsVoucherFee', { fee }) },
    { icon: 'link' as const, text: t('clientVenueTermsVoucherBound') },
    { icon: 'receipt' as const, text: t('clientVenueTermsDirect') },
    { icon: 'refresh' as const, text: t('clientVenueTermsVoucherReuse', { days }) },
    { icon: 'timer' as const, text: t('clientVenueTermsVoucherConfirm', { hours }) },
  ]

  // Working hours: consecutive weekdays as `Sun – Thu`, otherwise `Fri and Sat`.
  const dayNames = (list: readonly number[]): string => {
    const sorted = [...list].sort((a, b) => a - b)
    const contiguous = sorted.every((d, i) => i === 0 || d === sorted[i - 1]! + 1)
    const name = (d: number) => f.weekdayName(d, 'short')
    return contiguous && sorted.length > 2 ? `${name(sorted[0]!)} – ${name(sorted[sorted.length - 1]!)}` : f.list(sorted.map(name))
  }
  const clock = (hhmm: string) => f.plain(f.time(engine.at(today, hhmm)))

  const tabs = [
    { value: 'terms' as const, icon: 'document' as const, label: t('clientVenuePolTabTerms') },
    { value: 'rules' as const, icon: 'clipboard' as const, label: t('clientVenuePolTabRules') },
    { value: 'good' as const, icon: 'info' as const, label: t('clientVenuePolTabGood') },
  ]

  return (
    <SheetFrame title={t('clientVenuePolTitle')}>
      {state === 'offline' ? <Banner tone="offline" shape="card">{tc('commonStateOffline')}</Banner> : null}
      <IconTabs items={tabs} value={segment} onChange={setSegment} label={t('clientVenuePolTabsLabel')} />

      {segment === 'terms' ? (
        <div className="gzv-pol__panel" data-gz-id="policy.terms">
          <section className="gzv-pol__block" aria-label={t('clientVenueTermsVenueTitle', { venue: bi(venue.name) })}>
            <div className="gzv-pol__venue">
              <Icon name="venue" size="md" tone="secondary" />
              <Clamp text={bi(venue.policies.terms)} limit={104} />
            </div>
          </section>
          <section className="gzv-pol__block" aria-label={t('clientVenueTermsVoucherTitle')} data-gz-id="policy.voucher">
            <ul className="gzv-pol__terms">
              {voucherTerms.map(v => (
                <li key={v.icon} className="gz-t-body-s">
                  <Icon name={v.icon} size="md" tone="secondary" />
                  <span>
                    <Figures text={v.text} />
                  </span>
                </li>
              ))}
            </ul>
          </section>
        </div>
      ) : null}

      {segment === 'rules' ? (
        <div className="gzv-pol__panel" data-gz-id="policy.rules">
          {sections.length > 1 ? (
            <IconSegmented
              label={t('clientVenuePolRulesLabel')}
              value={activeAudience}
              onChange={setAudience}
              options={sections.map(s => ({ value: s.audience, icon: SECTION_ICON[s.audience], label: t(AUD_LONG[s.audience]) }))}
            />
          ) : (
            <span className="gz-sr-only">{t(AUD_LONG[section.audience])}</span>
          )}
          <RuleChips facts={section.policy} />
        </div>
      ) : null}

      {segment === 'good' ? (
        <div className="gzv-pol__panel" data-gz-id="policy.good">
          <ul className="gzv-pol__facts">
            <li className="gzv-pol__fact">
              <Icon name="guests" size="md" tone="secondary" />
              <span className="gz-sr-only">{t('clientVenuePolChildren')}</span>
              <span className="gz-t-body-s">
                <Figures text={bi(venue.policies.children[activeAudience === 'men' ? 'men' : 'women'])} />
              </span>
            </li>
            <li className="gzv-pol__fact">
              <Icon name="dress" size="md" tone="secondary" />
              <span className="gz-sr-only">{t('clientVenuePolDress')}</span>
              <span className="gz-t-body-s">{bi(venue.policies.dressCode)}</span>
            </li>
            <li className="gzv-pol__fact">
              <Icon name="clock" size="md" tone="secondary" />
              <span className="gz-sr-only">{t('clientVenuePolHours')}</span>
              <span className="gz-t-body-s gzv-pol__lines">
                {venue.hours.rules.map((r, i) => (
                  <span key={i}>
                    <Figures text={t('clientVenuePolHoursLine', { days: dayNames(r.days), open: clock(r.open), close: clock(r.close) })} />
                  </span>
                ))}
              </span>
            </li>
            {venue.hours.closures.length > 0 ? (
              <li className="gzv-pol__fact">
                <Icon name="calendar-x" size="md" tone="secondary" />
                <span className="gz-sr-only">{t('clientVenuePolClosures')}</span>
                <span className="gz-t-body-s gzv-pol__lines">
                  {venue.hours.closures.map((c, i) => (
                    <span key={i}>
                      <Figures text={t('clientVenuePolClosureLine', { name: bi(c.label), from: f.plain(f.date(c.from, 'dayMonth')), to: f.plain(f.date(c.to, 'dayMonth')) })} />
                    </span>
                  ))}
                </span>
              </li>
            ) : null}
          </ul>
        </div>
      ) : null}
    </SheetFrame>
  )
}
