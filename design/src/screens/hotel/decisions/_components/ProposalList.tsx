// ProposalList: the dates a venue has picked, in the order the couple will see them (ADR 0034: no words). One row per date: a calendar glyph,
// the absolute short date, then what the same booking costs there as a ticket glyph and an amount. A date that normally costs more keeps
// the quoted voucher price, so it shows a lock glyph and the date's own price struck through; a cheaper date shows a trend-down glyph and
// the difference. A date taken while the sheet was open is struck and says "Taken" with a warning glyph (state is never colour alone).
// Remove is the universal close glyph at inline-end (44), named "Remove {date}" for assistive technology.
import type { IsoDate } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { BarButton, Icon, Price } from '../../../../system'
import { Fx } from './Fx'
import './proposal-list.css'

export type ProposalEntry = {
  date: IsoDate
  /** What the booking costs on this date as the couple will see it (integer fils). */
  fils: number
  /** Against the original voucher total: negative = lower, 0 = the same or held. */
  delta: number
  /** A date that normally costs more than the quoted voucher price: by how much. The venue holds the voucher price and absorbs it. */
  normally?: number
  taken?: boolean
}

export function ProposalList({ entries, onRemove, readOnly = false }: { entries: readonly ProposalEntry[]; onRemove: (date: IsoDate) => void; readOnly?: boolean }) {
  const f = useFormat()
  const t = useT('hotel-decisions')
  const tc = useT('common')
  return (
    <ul className="gzd-prop" aria-label={t('hotelDecisionsProposeChosen')}>
      {entries.map(e => {
        const day = f.date(e.date, 'short')
        const held = !e.taken && e.normally !== undefined && e.normally > 0
        const lower = !e.taken && !held && e.delta < 0
        return (
          <li key={e.date} className="gzd-prop__row" data-taken={e.taken || undefined}>
            <span className="gzd-disk gzd-prop__disk" aria-hidden="true">
              <Icon name={e.taken ? 'calendar-x' : 'calendar-check'} size="md" tone={e.taken ? 'danger' : 'primary'} />
            </span>
            <span className="gz-t-body gzd-prop__date">
              <Fx text={day} />
            </span>
            {e.taken ? (
              <span className="gz-t-caption gzd-prop__taken">
                <Icon name="warning-circle" size="xs" tone="danger" />
                {t('hotelDecisionsProposeTakenBadge')}
              </span>
            ) : (
              <span className="gzd-prop__money">
                <span className="gzd-prop__price">
                  <Icon name="ticket" size="xs" tone="success" />
                  <span className="gz-sr-only">{tc('commonVoucherPrice')}</span>
                  <Price fils={e.fils} size="strong" />
                </span>
                {held ? (
                  <span className="gzd-prop__note gz-t-fig-caption">
                    <Icon name="lock" size="xs" tone="accent" />
                    <span className="gz-sr-only">{t('hotelDecisionsProposeHeldLabel')}</span>
                    <span className="gz-strike" dir="ltr">
                      {f.money(e.fils + (e.normally ?? 0), { mode: 'browse' })}
                    </span>
                  </span>
                ) : lower ? (
                  <span className="gzd-prop__note gz-t-fig-caption gzd-prop__note--lower">
                    <Icon name="trend-down" size="xs" tone="success" mirror={false} />
                    <span className="gz-sr-only">{t('hotelDecisionsProposeLowerLabel')}</span>
                    <bdi dir="ltr">{f.money(Math.abs(e.delta), { mode: 'browse' })}</bdi>
                  </span>
                ) : null}
              </span>
            )}
            {readOnly ? null : <BarButton icon="close" label={t('hotelDecisionsProposeRemove', { date: f.plain(day) })} onPress={() => onRemove(e.date)} />}
          </li>
        )
      })}
    </ul>
  )
}
