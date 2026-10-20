// StatusVariants (CL-DISC-01 state `status-card-variants`): the seven faces of the one urgency-ranked card, stacked, so a reviewer sees the
// whole ladder at once. The card is a single button in every variant; none carries a second action, so the gold CTA of the Brief card stays
// the only verb on Home. No captions: each card says what it is by its drawing, its pill and its one fact (ADR 0034).
import * as mock from '../../../../mock'
import { useFormat } from '../../../../i18n'
import { StatusCard, type StatusModel } from './StatusCard'
import { storyBrief } from '../../../../shell/state/defaults'
import type { StatusKind } from './scenario'
import './status-card.css'

const ORDER: StatusKind[] = ['no-date', 'brief-set', 'voucher-ready', 'pending', 'approved', 'confirmed', 'visit-soon']

/** Reem's released voucher (Lumi, no reply): ready to use again. */
const readyVoucher = () => mock.vouchersFor(mock.meta.clientUserId).find(v => v.status === 'active') ?? null

function modelFor(kind: StatusKind): StatusModel {
  const brief = storyBrief()
  switch (kind) {
    case 'no-date':
      return { kind, brief: { ...brief, date: null } }
    case 'brief-set':
      return { kind, brief, count: 3 }
    case 'voucher-ready':
      return { kind, brief, voucher: readyVoucher() }
    case 'pending':
      return { kind, brief, booking: mock.heroBookingAs('pending') }
    case 'approved':
      return { kind, brief, booking: mock.heroBookingAs('approved') }
    case 'confirmed':
      return { kind, brief, booking: mock.heroBookingAs('confirmed') }
    case 'visit-soon':
      // The seeded visit is Sat 14 Nov; the card appears inside the last 24 hours, so the specimen states the day it would say.
      return { kind, brief, visit: mock.visitsFor({ clientId: mock.meta.clientUserId, status: 'confirmed' })[0] ?? null, visitDay: 'tomorrow' }
  }
}

export function StatusVariants() {
  useFormat()
  return (
    <div className="gzd-variants" data-gz-id="variants">
      {ORDER.map(kind => (
        <section key={kind} className="gzd-variants__item" data-kind={kind}>
          <StatusCard model={modelFor(kind)} />
        </section>
      ))}
    </div>
  )
}
