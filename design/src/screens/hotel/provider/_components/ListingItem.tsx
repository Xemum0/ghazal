// ListingItem (HL-PROV-02): one advertisement as the system card plus its next step under it. The card opens the editor, the review status or
// the performance by state; the step under it ("Choose a plan", "Fix and resubmit", "Renew") is the one thing the provider should do next.
import { Button } from '../../../../system'
import type { Listing } from '../../../../mock'
import { ListingCard } from './ListingCard'
import { useP } from './bits'
import { nextStepOf } from './model'
import './listing-item.css'

const LABEL = {
  finish: 'hotelProviderStepFinish',
  'choose-plan': 'hotelProviderStepChoosePlan',
  fix: 'hotelProviderStepFix',
  renew: 'hotelProviderStepRenew',
  submit: 'hotelProviderStepSubmit',
} as const

export type ListingItemProps = {
  listing: Listing
  exempt: boolean
  onOpen: () => void
  onStep: (to: string, params: Record<string, unknown>) => void
  /** The viewer's role may read but not change listings (role-limited). */
  readOnly?: boolean
}

export function ListingItem({ listing, exempt, onOpen, onStep, readOnly = false }: ListingItemProps) {
  const { t } = useP()
  const step = nextStepOf(listing, exempt)
  return (
    <li className="hp-item" data-gz="ListingItem" data-status={listing.status}>
      <ListingCard listing={listing} exempt={exempt} onOpen={onOpen} />
      {step && !readOnly ? (
        <div className="hp-item__step">
          <Button variant="secondary" size="md" iconEnd="chevron-right" onClick={() => onStep(step.to, step.params)}>
            {t(LABEL[step.id])}
          </Button>
        </div>
      ) : null}
    </li>
  )
}
