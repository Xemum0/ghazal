// Developer gallery for the i18n layer: every formatter output and a slice of common.json, in the current language.
// Row labels are code identifiers (always LTR); every value is produced by GzFormat or by t(). Open it in both languages
// and with ?digits=eastern: #/gallery/i18n?lang=ar&digits=eastern
import { Fragment, type ReactNode } from 'react'
import { plainText } from '@gz/i18n'
import { Ltr, Num, Phone, T, useFormat, useT } from '..'
import './I18nGallery.css'

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="gz-i18n-g__section">
      <h2 className="gz-i18n-g__title">
        <Ltr>{title}</Ltr>
      </h2>
      <dl className="gz-i18n-g__rows">{children}</dl>
    </section>
  )
}

function Row({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="gz-i18n-g__row">
      <dt className="gz-i18n-g__label">
        <Ltr>{label}</Ltr>
      </dt>
      <dd className="gz-i18n-g__value">{children}</dd>
    </div>
  )
}

/** Amount face per docs/design/01-direction.md 2.4: the fils are quiet and smaller, the currency is a label. */
function Price({ fils, mode }: { fils: number; mode: 'browse' | 'exact' }) {
  const f = useFormat()
  const p = f.moneyParts(fils, { mode })
  return (
    <span className="gz-i18n-g__price">
      <bdi dir="ltr" className="gz-i18n-g__money">
        <span className="gz-i18n-g__currency">{p.currency}</span>
        <span className="gz-i18n-g__amount">
          {p.negative ? '−' : ''}
          {p.integer}
        </span>
        {p.fraction ? <span className="gz-i18n-g__fils">{p.fraction}</span> : null}
      </bdi>
    </span>
  )
}

export default function I18nGallery() {
  const f = useFormat()
  const t = useT('common')
  const shell = useT('client-shell')
  const hotel = useT('hotel-shell')
  const now = f.now()
  const thu = '2027-01-14'

  return (
    <div className="gz-i18n-g" data-gz="I18nGallery">
      <header className="gz-i18n-g__head">
        <h1 className="gz-i18n-g__h1">{shell('clientShellBriefTitle')}</h1>
        <p className="gz-i18n-g__note">
          <Ltr>{`lang=${f.lang} · digits=${f.digitStyle} · NOW=${f.isoDay(now)} ${plainText(f.time(now, '24h'))}`}</Ltr>
        </p>
      </header>

      <Section title="money · browse / exact">
        <Row label="browse 18,200,000">{f.money(18200000)}</Row>
        <Row label="browse 18,500">{f.money(18500)}</Row>
        <Row label="exact 5,460,000">{f.money(5460000, { mode: 'exact' })}</Row>
        <Row label="exact −50,000">{f.money(-50000, { mode: 'exact' })}</Row>
        <Row label="legal (invoice)">{f.money(5460000, { mode: 'exact', label: 'legal' })}</Row>
        <Row label="parts · exact 5,460,000">
          <Price fils={5460000} mode="exact" />
        </Row>
        <Row label="parts · browse 18,500">
          <Price fils={18500} mode="browse" />
        </Row>
      </Section>

      <Section title="money · grammar">
        <Row label="perGuest">{f.priceUnit(46000, 'perGuest')}</Row>
        <Row label="perNight">{f.priceUnit(2800000, 'perNight')}</Row>
        <Row label="flatFee">{f.flatFee(100000, t('commonMoneyRentalFee'))}</Row>
        <Row label="range">{f.moneyRange(22000, 52000)}</Row>
        <Row label="forGuests · exact">{f.priceForGuests(7843000, 400)}</Row>
        <Row label="forGuests · from">{f.priceForGuests(16100000, 350, 'from')}</Row>
        <Row label="forGuests · est">{f.priceForGuests(7843000, 400, 'est')}</Row>
        <Row label="fromPriceMin">{f.fromPriceMin(2100000, 200)}</Row>
        <Row label="axis 18.4K / 1.2M">
          {f.moneyAxis(18400000)} · {f.moneyAxis(1200000000)}
        </Row>
      </Section>

      <Section title="plurals · guests (CLDR by last two digits)">
        {[0, 1, 2, 3, 11, 100, 103, 350, 400, 1000].map(n => (
          <Row key={n} label={`count=${n}`}>
            {t('commonCountGuests', { count: n })}
          </Row>
        ))}
      </Section>

      <Section title="dates · Asia/Kuwait, Sunday-first">
        <Row label="full">{f.date(thu, 'full')}</Row>
        <Row label="short (this year)">{f.date('2026-11-15', 'short')}</Row>
        <Row label="short (next year)">{f.date(thu, 'short')}</Row>
        <Row label="compact">{f.date(thu, 'compact')}</Row>
        <Row label="monthYear">{f.date(thu, 'monthYear')}</Row>
        <Row label="hijri line (ar only)">{f.dateWithHijri(thu).secondary ?? '—'}</Row>
        <Row label="time">{f.time('2027-01-14T21:00')}</Row>
        <Row label="timeRange">{f.timeRange('2027-01-14T19:00', '2027-01-15T01:00')}</Row>
        <Row label="deadline">{f.dateTime('2026-11-15T18:00')}</Row>
        <Row label="relative">
          {f.relativeDay('2026-11-12')} · {f.relativeDay('2026-11-13')}
        </Row>
        <Row label="countdown">{f.countdownDays(f.daysUntil(thu))}</Row>
        <Row label="duration / ago">
          {f.duration(19200000)} · {f.ago('2026-11-12T15:12:00+03:00')}
        </Row>
      </Section>

      <Section title="calendar · week order and peak band">
        <div className="gz-i18n-g__cal" role="grid">
          <div className="gz-i18n-g__week" role="row">
            {f.weekdayHeaders().map((h, i) => (
              <span key={i} className="gz-i18n-g__dow" role="columnheader" aria-label={f.weekdayLabels()[i]}>
                {h}
              </span>
            ))}
          </div>
          {f.monthGrid(2027, 1).map((week, wi) => (
            <div key={wi} className="gz-i18n-g__week" role="row">
              {week.map(d => (
                <span
                  key={d.iso}
                  role="gridcell"
                  className="gz-i18n-g__day"
                  data-in-month={d.inMonth}
                  data-peak={d.isPeak}
                >
                  <Num value={d.day} />
                </span>
              ))}
            </div>
          ))}
        </div>
      </Section>

      <Section title="phone · LTR isolate, Western digits">
        <Row label="phone">
          <Phone value="+965 5000 0012" />
        </Row>
        <Row label="in a sentence">
          {t('commonActionCall')}: <Phone value="50000001" />
        </Row>
      </Section>

      <Section title="status · common.json">
        {(
          [
            'commonStatusRequested',
            'commonStatusAwaitingDeposit',
            'commonStatusConfirmed',
            'commonStatusRejected',
            'commonStatusExpired',
            'commonStatusCancelled',
            'commonStatusCompleted',
            'commonStatusRefunded',
            'commonStatusNoShow',
          ] as const
        ).map(k => (
          <Row key={k} label={k.replace('commonStatus', '')}>
            {t(k)}
          </Row>
        ))}
      </Section>

      <Section title="copy · states and rich text">
        <Row label="offline">{t('commonStateOffline')}</Row>
        <Row label="payment error">{t('commonStateErrorPayment')}</Row>
        <Row label="no payment now">{t('commonNoPaymentNowFull')}</Row>
        <Row label="empty search">{t('commonStateTitleEmptySearch')}</Row>
        <Row label="greeting">{shell('clientShellGreeting', { name: 'Reem' })}</Row>
        <Row label="hotel today">
          {hotel('hotelShellTodayNeedsReply', { count: 3 })} · {hotel('hotelShellTodayFirstIn', { time: f.duration(19200000) })}
        </Row>
        <Row label="<T> rich">
          <T
            ns="common"
            k="commonStateErrorLoad"
            components={{}}
          />
        </Row>
      </Section>

      <Section title="bidi · mixed content in one sentence">
        <Row label="price + phone + date">
          <Fragment>
            {f.priceForGuests(7843000, 400)} · <Phone value="50000012" /> · {f.date('2026-11-15', 'short')}
          </Fragment>
        </Row>
      </Section>
    </div>
  )
}
