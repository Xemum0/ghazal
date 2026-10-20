// Compositions (ADR 0034): onboarding, empty states, success states and partner tasks, built from the spot drawings with the same
// hand. One hero object keeps the gold accent, the tint and the ground line; companions are `Quiet` (no gold, tint or ground) so a
// composition never carries more than one accent.
import type { ComponentType, ReactNode } from 'react'
import { A, AL, At, Dash, DashS, G, K, L, Quiet, S, T, circ, rr, spark } from './kit'
import { Doorway, Hall } from './spots-arch'
import { Envelope, Rings } from './spots-objects'
import { Bell, Calendar, Card, Hourglass, NoResult, Qr, Route, Seal, TICKET, Voucher } from './spots-ui'

type Entry = { Draw: ComponentType; kind: 'scene'; mirror: boolean }
const scene = (Draw: ComponentType, mirror = false): Entry => ({ Draw, kind: 'scene', mirror })

/** A badge: a small drawing inside a knockout disc, used to mark a state on a larger object (done, waiting, blocked). */
function Badge({ x, y, r = 16, children }: { x: number; y: number; r?: number; children: ReactNode }) {
  return (
    <>
      <K d={circ(x, y, r)} />
      <L d={circ(x, y, r)} />
      {children}
    </>
  )
}

const HEART = 'M60 98C22 72 20 38 42 32C52 30 58 36 60 42C62 36 68 30 78 32C100 38 98 72 60 98Z'

function ListingCard({ dashed = false }: { dashed?: boolean }) {
  const Out = dashed ? Dash : L
  return (
    <>
      <K d={rr(24, 14, 72, 88, 8)} />
      <T d={rr(34, 24, 52, 38, 4)} />
      <Out d={rr(24, 14, 72, 88, 8)} />
      <L d={rr(34, 24, 52, 38, 4)} />
      <L d="M48 62V50A12 12 0 0 1 72 50V62" />
      <S d="M34 74H72M34 84H58" />
    </>
  )
}

// ---- onboarding -------------------------------------------------------------------------------------------------------------
function OnboardCompare() {
  return (
    <>
      <Quiet gold={false} tint={false} ground={false}>
        <At x={-10} y={52} s={0.5}><Doorway /></At>
        <At x={70} y={52} s={0.5}><Doorway /></At>
      </Quiet>
      <At x={15.6} y={27} s={0.74}><Doorway /></At>
      <G d="M6 104H114" />
    </>
  )
}

function OnboardDates() {
  return (
    <>
      <At x={-10} y={-4} s={1}><Calendar /></At>
      <Quiet gold={false} tint={false}>
        <At x={58} y={56} s={0.5}><Seal /></At>
      </Quiet>
    </>
  )
}

function OnboardVoucher() {
  return (
    <>
      <Quiet gold={false} tint={false} ground={false}>
        <At x={30} y={6} s={0.88}><Doorway /></At>
      </Quiet>
      <G d="M10 104H110" />
      <At x={-6} y={14} s={0.96} r={-8}><Voucher /></At>
    </>
  )
}

// ---- empty states -----------------------------------------------------------------------------------------------------------
function EmptySaved() {
  return (
    <>
      <K d={HEART} />
      <T d={HEART} />
      <Dash d={HEART} />
      <A d={spark(94, 24, 5)} />
    </>
  )
}

function EmptyMessages() {
  const b1 = rr(12, 16, 52, 32, 8)
  const b2 = rr(52, 38, 56, 32, 8)
  const b3 = rr(22, 62, 56, 34, 8)
  return (
    <>
      <K d={b1} />
      <T d={b1} />
      <Dash d={b1} />
      <Dash d="M22 48L18 58L32 48" />
      <K d={b2} />
      <Dash d={b2} />
      <Dash d="M98 70L104 82L88 70" />
      <K d={b3} />
      <L d={b3} />
      <L d="M32 96L28 106L44 96" />
      <L d={circ(41, 79, 2)} />
      <L d={circ(50, 79, 2)} />
      <A d={circ(59, 79, 2.6)} />
    </>
  )
}

function EmptyBookings() {
  return (
    <>
      <Quiet gold={false} ground={false}>
        <At x={-12} y={12} s={0.86}><Calendar /></At>
      </Quiet>
      <At x={49} y={31} s={0.66}><Doorway /></At>
    </>
  )
}

function EmptyVouchers() {
  return (
    <>
      <K d={TICKET} />
      <T d={TICKET} />
      <Dash d={TICKET} />
      <DashS d="M78 40V80" />
      <A d={spark(92, 60, 6)} />
    </>
  )
}

function EmptyVisits() {
  return (
    <>
      <At x={-10} y={4} s={0.9}><Doorway /></At>
      <Quiet gold={false} tint={false} ground={false}>
        <At x={46} y={33} s={0.64}><Route /></At>
      </Quiet>
    </>
  )
}

function EmptyResults() {
  return (
    <>
      <Quiet gold={false}>
        <At x={-4} y={0} s={0.9}><Hall /></At>
      </Quiet>
      <At x={50} y={42} s={0.66}><NoResult /></At>
    </>
  )
}

function EmptyNotifications() {
  return (
    <>
      <Quiet gold={false}>
        <At x={0} y={8} s={1}><Bell /></At>
      </Quiet>
      <DashS d="M26 66C22 58 22 48 28 40M94 66C98 58 98 48 92 40" />
      <DashS d="M16 72C10 60 10 46 18 34M104 72C110 60 110 46 102 34" />
      <A d={spark(60, 12, 5)} />
      <G d="M30 104H90" />
    </>
  )
}

function EmptyListings() {
  return (
    <>
      <ListingCard dashed />
      <Badge x={90} y={92}>
        <AL d="M90 85V99M83 92H97" />
      </Badge>
    </>
  )
}

// ---- success states ---------------------------------------------------------------------------------------------------------
function SuccessRequest() {
  return (
    <>
      <At x={-6} y={-8} s={1}><Envelope /></At>
      <Quiet gold={false} tint={false}>
        <At x={62} y={58} s={0.5}><Seal /></At>
      </Quiet>
    </>
  )
}

function SuccessVoucher() {
  return (
    <>
      <At x={-6} y={-10} s={0.98}><Voucher /></At>
      <Quiet gold={false} ground={false}>
        <At x={58} y={56} s={0.52}><Qr /></At>
      </Quiet>
    </>
  )
}

function SuccessBooking() {
  return (
    <>
      <At x={-12} y={8} s={0.84}><Calendar /></At>
      <Quiet gold={false} ground={false}>
        <At x={56} y={52} s={0.56}><Rings /></At>
      </Quiet>
    </>
  )
}

function SuccessPayment() {
  return (
    <>
      <At x={-6} y={-12} s={1}><Card /></At>
      <Quiet gold={false} tint={false}>
        <At x={64} y={62} s={0.52}><Seal /></At>
      </Quiet>
    </>
  )
}

function SuccessVisit() {
  return (
    <>
      <At x={-8} y={8} s={0.86}><Doorway /></At>
      <Quiet gold={false} ground={false}>
        <At x={50} y={14} s={0.62}><Calendar /></At>
      </Quiet>
      <Quiet gold={false} tint={false}>
        <At x={64} y={58} s={0.44}><Seal /></At>
      </Quiet>
    </>
  )
}

// ---- partner ----------------------------------------------------------------------------------------------------------------
function PartnerScanner() {
  const phone = rr(32, 8, 56, 104, 10)
  return (
    <>
      <K d={phone} />
      <T d={rr(38, 28, 44, 62, 4)} />
      <L d={phone} />
      <S d="M52 17H68M52 103H68" />
      <At x={22.8} y={22.8} s={0.62}><Qr /></At>
    </>
  )
}

function PartnerCalendar() {
  return (
    <>
      <At x={-10} y={-2} s={1}><Calendar /></At>
      <Badge x={92} y={90}>
        <L d="M85 90H99V99H85Z" />
        <L d="M88 90V86A4 4 0 0 1 96 86V90" />
      </Badge>
    </>
  )
}

function PartnerReview() {
  return (
    <>
      <ListingCard />
      <Badge x={90} y={92} r={18}>
        <Quiet tint={false}>
          <At x={72} y={74} s={0.3}><Hourglass /></At>
        </Quiet>
      </Badge>
    </>
  )
}

function PartnerAds() {
  return (
    <>
      <L d="M44 68L34 106M76 68L86 106M60 68V104" />
      <K d={rr(24, 12, 72, 58, 5)} />
      <L d={rr(24, 12, 72, 58, 5)} />
      <Quiet gold={false} ground={false}>
        <At x={33} y={14} s={0.45}><Doorway /></At>
      </Quiet>
      <K d={spark(96, 12, 7)} />
      <A d={spark(96, 12, 6)} />
      <G d="M24 106H96" />
    </>
  )
}

function PartnerRedeemed() {
  return (
    <>
      <At x={-8} y={-8} s={1}><Voucher /></At>
      <Quiet gold={false} tint={false}>
        <At x={58} y={52} s={0.58}><Seal /></At>
      </Quiet>
    </>
  )
}

export const scenes = {
  'onboard-compare': scene(OnboardCompare),
  'onboard-dates': scene(OnboardDates),
  'onboard-voucher': scene(OnboardVoucher, true),
  'empty-saved': scene(EmptySaved),
  'empty-messages': scene(EmptyMessages, true),
  'empty-bookings': scene(EmptyBookings),
  'empty-vouchers': scene(EmptyVouchers),
  'empty-visits': scene(EmptyVisits, true),
  'empty-results': scene(EmptyResults, true),
  'empty-notifications': scene(EmptyNotifications),
  'empty-listings': scene(EmptyListings),
  'success-request': scene(SuccessRequest),
  'success-voucher': scene(SuccessVoucher),
  'success-booking': scene(SuccessBooking),
  'success-payment': scene(SuccessPayment),
  'success-visit': scene(SuccessVisit),
  'partner-scanner': scene(PartnerScanner),
  'partner-calendar': scene(PartnerCalendar),
  'partner-review': scene(PartnerReview),
  'partner-ads': scene(PartnerAds),
  'partner-redeemed': scene(PartnerRedeemed),
} as const
