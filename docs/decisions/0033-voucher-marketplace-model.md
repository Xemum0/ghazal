# ADR 0033: Voucher marketplace model: Ghazal sells a KD 2 voucher, venues and providers sell and collect everything else

| Field | Value |
|---|---|
| Status | accepted (the model, D1 to D5, D7 to D9); **proposed-needs-owner** (the working assumptions A-01 to A-15 in D6, built as configuration) |
| Date | 2026-10-14 |
| Scope | Client app, Partner app (the former hotel app), API, web Super Admin (context), pricing, payments, booking state machine, fixtures, screen inventory |
| Owner confirmation still needed | OQ-V-01 to OQ-V-16 in `docs/product/open-questions.md` (section 2b) |
| Supersedes | The in-app-payment parts of ADR 0001 (D1 instant mode, D2 pay step, D3, D4 corollaries, D6 pay window, D11 late payment, D12 pay and Review schedule line, D13); ADR 0003 (statuses and transitions, D1, D3, D5 to D8 as listed in D3 below); ADR 0004 (D4 offers and credits, D5 snapshot scope, D6 price display, D8 venue editing); ADR 0005 (whole); ADR 0006 (whole); ADR 0027 (D-items on supplier split, payouts, KYC and the ledger; the gateway boundary stays for the voucher and listing fees). Amends ADR 0008 (Today money tiles, Bookings segments, More menu, roles) |
| Related ADRs | 0002 (granularity, still binding), 0007 (client navigation and guest gating), 0010 (money format), 0011, 0013, 0014, 0017, 0028 (auth), 0031 (typefaces addendum) |
| Naming note | The task that asked for this ADR named it 0032. The number 0032 was already allocated to `0032-design-pass-implementation-notes.md` and numbers are never reused (`docs/decisions/README.md` section "Adding"), so this ADR is 0033. |
| Screens | CL-VCHR-*, CL-VIST-*, CL-PAYM-01..05 (repurposed), CL-BOOK-*, CL-BKNG-*, CL-VENU-*, CL-DISC-*, CL-SERV-*, CL-MSGS-*, HL-VIST-*, HL-PROV-*, HL-BOOK-*, HL-VENU-*, HL-GROW-*, HL-SETT-* |

## Context

On 2026-10-14 the owner changed the business model: "We will have hotel and service providers for weddings and we provide only a voucher (coupon) for 2 KWD. All operations are done with the hall owners, hotels or service providers, but the coupon allows clients to get much lower prices." Clarifications: the client pays the 2 KD **online** through the gateway; with the voucher the client becomes eligible to request the hall or service at Ghazal's lower price; a client may also search without a voucher and pay the venue normally at the standard price; one voucher per booking; providers use the same Partner app with a Hotel or Service-provider account type. The owner also supplied a feature list: filters (governorate, venue type, capacity range, pricing structure, availability), account types, a service-provider module with five categories and paid advertising (weekly, monthly, annual) behind manual review, app-exclusive discounts for registered clients, a major-hotel fee exemption, a 24 hour booking-confirmation window, and a three-way group chat for site visits.

The earlier ADRs encode a different business: Ghazal took a deposit and balance through the gateway, split the money with the venue (commission, payouts, KYC), refunded by a tiered policy and ran a payment-state booking machine. That business no longer exists. This ADR replaces it and keeps everything that is still true (halls, sessions and sections, the tier price engine, the frozen quote, guest gating, navigation, formats, voice, RTL, motion).

## Decision

**D1. The model.** Ghazal sells one product to clients: a **voucher** (coupon) of KD 2.000 (`voucher_fee_fils`, configuration), paid online by KNET, Visa, Mastercard, Apple Pay or Google Pay through the existing gateway boundary. The voucher makes the client eligible to **request a hall or service at the voucher price**. All operations, contracts and payments for the event are between the client and the venue or provider, off-app. A client may use none of this and pay the venue the standard price. The only in-app payments are the voucher (clients) and listing or advertising fees (partners, major hotels exempt). There are no deposits, balances, commissions, payouts, bank details for venues, cash records or event invoices. Full detail: `docs/product/voucher-model.md`.

**D2. Voucher.** One single-use code and QR per voucher; one voucher per request; bound at purchase to one venue or provider and to its quote (A-01); states `unpaid`, `active`, `bound`, `used`, `expired`, `refunded`. Offered only when the saving exceeds the fee. Registered clients only buy; guests see both prices and are gated at "Get voucher".

**D3. Request state machine (supersedes ADR 0003 D1, D3, D5 to D8 and the Booking Thread nodes).** Statuses: `pending`, `approved`, `declined`, `expired` (reasons `venue_no_response`, `client_no_confirmation`), `confirmed`, `redeemed`, `completed`, `cancelled` (plus the client-side `draft`, which is not a server object). `refunded` and `no_show` are removed as request statuses (refund is a voucher state; a missed visit is a visit state). Approval creates a 24 hour hold; the client must **confirm within 24 hours** or the approval lapses; confirmation converts the hold to a booking claim; the partner redeems the voucher by code or QR. Instant booking is removed. Counter-offers (propose other dates) remain. The Booking Thread nodes become Request, Approval, Confirmation, Redemption, Day. The old labels in ADR 0003 D2 are replaced by those in `docs/architecture/booking-state-machine.md` section 3; the chip words follow ADR 0013 D4 where they overlap (Pending, Not accepted).

**D4. Price display (supersedes ADR 0004 D4 and D6 in part; D1 to D3, D5 principle, D7 stay).** Every package, and every priced extra, has two prices on the same basis: standard and voucher. The tier engine runs once per column. Venue offers, coupon codes and platform credit are removed from the engine (the venue's voucher price is the only reduction); the savings line is computed from two real prices; a struck-through "was" price is always the venue's standard price. The quote snapshot is taken when the request is sent and holds both totals. The venue may approve at a lower voucher price, never higher.

**D5. Money.** Replaces ADR 0005 and 0006 and the money half of ADR 0027: see `docs/architecture/pricing-and-payments.md`. The gateway adapter shrinks to `createSession`, `getStatus`, `refund`, `listMethods`; `createSupplier`, `uploadSupplierDocument` and the supplier-split flows are removed. The webhook plus re-query discipline, idempotency keys and the hosted payment pages stay. Voucher refund rules: D6 A-03.

**D6. Working assumptions (proposed-needs-owner, built as configuration).**

| A | Assumption |
|---|---|
| A-01 | Voucher bound to one target and quote at purchase; code single-use |
| A-02 | Validity 60 days; 60-day reuse window at the same target after a release |
| A-03 | Refund and reuse table (venue-fault releases refundable; client-caused releases reusable only; cancel after confirm consumes the voucher) |
| A-04 | A completed request without a redemption still closes the voucher; 72 h issue report |
| A-05 | No in-app reschedule after confirmation |
| A-06 | One login may hold both partner account types |
| A-07 | Ad plan period starts at approval |
| A-08 | Rejected listing keeps its paid plan 14 days, then refunded in full |
| A-09 | Material edits to an active listing re-enter review, old version stays live |
| A-10 | Visits for hotels and halls only |
| A-11 | Visit group chat read-only 24 h after the slot, archived at 30 days |
| A-12 | Non-major hotels and halls also pay a listing plan to be live (the spec exempts only major hotels) |
| A-13 | Governmental facilities are browse-only, no voucher |
| A-14 | Guests see the voucher price number |
| A-15 | KD 2.000, no VAT line; gateway fees on refunds borne by Ghazal |

The ad plan rates for weekly, monthly and annual cycles are **not decided**: the UI says "Rates announced soon" and nothing in code, fixtures or copy carries a price for them.

**D7. Partner app.** The hotel app is the Partner app. Account types: Hotel or wedding hall (`venue`) and Service provider (`service_provider`); the major-hotel flag `fee_exempt` is set only by the Super Admin and removes the fee, not the review. Tabs stay Today, Bookings, Calendar, Messages, More (ADR 0008 D1); Today's money tiles become voucher tiles (requests, vouchers redeemed this month, open dates), the revenue and payout screens are retired, Settings loses Bank information and gains Billing and fees, More gains Visits and (for providers) Listings. Redemption is allowed for Admin, Manager and Reception. Service providers have no calendar of halls: their Calendar tab is replaced by Listings (the tab keeps its slot; label and root are role-aware as ADR 0008 D1 already allows).

**D8. Provider module and listing review.** Five primary categories (hospitality and catering, buffet services, floral arrangements, event styling and decor, event planning and coordination) plus secondary categories. Listing lifecycle draft, payment, pending review, approved or rejected, active or expired. Listings are **never published automatically on payment**: every advertisement needs moderator approval for content compliance and category placement, major hotels included. Paid plans are weekly, monthly or annual.

**D9. Visits and group chat.** Booking a site visit is free and independent of the voucher. Each visit creates one dedicated group chat of exactly three roles: client, hotel representative, Ghazal support representative (call center). The client is redirected into it to confirm arrival. It is a new conversation kind (`visit_group`) with member-only visibility and read-only closing after the visit.

## Consequences

- Money is trivial and low-risk: no money is held, split, paid out or escrowed; no PCI scope beyond the hosted gateway; legal questions about merchant of record shrink to two invoices (voucher receipt, listing plan).
- Refund exposure is KD 2 per voucher plus listing plans.
- Trust is the new risk: the venue can decline to honour the voucher price after the client has confirmed. Mitigation: `redeemed` creates a record, the 72 h issue report, support follow-up and reliability strikes (A-04, OQ-V-04).
- Ghazal no longer controls the venue's price after approval; the frozen quote and the redemption screen (which shows the bound quote to the partner) are the evidence.
- The `bookings` table keeps its name and reference; statuses change; `payment_milestones`, `payouts`, `commission_rules`, `ledger_*` tables for events are retired from the MVP schema; `vouchers`, `visits`, `listings`, `listing_plans`, `listing_payments`, `review_decisions` are added (`docs/architecture/data-model.md`).
- Roughly a third of the screen inventory changes (`docs/product/voucher-model-changes.json` lists each); the former payment flow becomes voucher purchase with the same screen ids.
- The Super Admin web app gains a review queue and a voucher console and loses commission and payout screens (context only).

## Alternatives considered

1. **Keep the deposit model and add the voucher as a discount code.** Rejected: the owner removed in-app event payments entirely.
2. **Voucher not bound to a target (a wallet credit usable anywhere).** Rejected as the working assumption: the saving depends on a specific venue price, and an unbound credit invites resale; kept as OQ-V-01.
3. **Charge the venue a redemption fee instead of the client KD 2.** Rejected: contradicts the owner's statement that the client pays the voucher.
4. **Publish listings on payment and moderate afterwards.** Rejected: the owner requires manual approval before activation.
5. **Phone-only (non-chat) visit coordination.** Rejected: the owner specified an in-app three-way group chat.

## Related requirement IDs

New (85 lines): CA-VCH-01..14, CA-VIS-01..06, CA-FLT-01..07, CA-SVC-13..18, CA-STAT-11..14, CA-AUTH-12, CA-PROF-12, PA-ACC-01..05, PA-LST-01..07, PA-ADS-01..07, PA-REV-01..05, HA-VCH-01..05, HA-VIS-01..06, HA-VMGT-11..13, HA-ANLY-08, HA-SET-06, SA-REV-01..06. Superseded or amended (notes appended in the matrix): CA-PAY-01..11, CA-BOOK-09..11 and 15, CA-SRCH-15, CA-STAT-04, 05, 08, 09, CA-LOY-01..07, CA-CARD-13, CA-PROF-05, HA-BOOK-05, 09, 10, HA-DASH-02, HA-SET-03, HA-OFFR-01..06, HA-ANLY-04, SA-COMM-01..06, SA-FIN-05, 06, SA-SUBS-01..04, MK-COM-01, 02, PL-PAY-*, PL-BOOK-01, 03.

## Notes on conflicting inputs

- ADR 0002 (granularity) stays binding: hall by date by session, up to two sections, government halls as a separate channel. The only change is that the "channel" of a normal venue is now `ghazal_voucher` in place of `ghazal` (A-13 keeps governmental facilities as `external_link`).
- ADR 0007 D8 (guest gating) stays: the commit moments change from "send a request, pay" to "get a voucher, send a request, send a message".
- ADR 0015 and the brief ban emoji and faces: visit chat roles use text chips and monograms.
- The brief (`docs/design/00-brief.md`) still describes the deposit flow in its questions; those are answered by the superseded ADRs and now by this one.
- ADR 0031 addendum typefaces (El Messiri, Manrope, Almarai) are unaffected.
