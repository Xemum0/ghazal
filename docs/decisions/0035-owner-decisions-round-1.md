# ADR 0035: Owner decisions, round 1 (2026-10-20): voucher validity and forfeiture, credit voucher instead of refunds, partner billing, staff email invitations, NestJS, bundle ids

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-10-20 |
| Scope | Voucher model, refunds, partner billing, staff and calendar email flows, reviews, legal assets, backend, identifiers, video limits |
| Confirmed by the owner | 2026-10-20, answers to `docs/product/owner-decisions.md` items 1 to 46 |
| Supersedes | In ADR 0033: A-03 (refund and reuse table), A-08 (automatic 14-day plan refund), A-15 (gateway fee on refunds), and the `refunded` voucher state in D2 (replaced by `forfeited` and `credit_issued`. A-02 stays: 60 days, and a release by the venue side or a withdrawal still returns the voucher to `active` at the same venue within its validity). Confirms A-01, A-04 to A-14 as stated in the owner rule below |
| Related ADRs | 0033, 0027, 0028, 0020, 0022, 0026, 0010, 0013 |
| Screens | CL-VCHR-*, CL-BOOK-*, CL-BKNG-*, CL-MSGS-*, HL-ACCS-*, HL-SETT-*, HL-VENU-*, HL-CALD-*, HL-GROW-*, HL-PROV-* (list: `docs/product/owner-round1-changes.json`) |

## Context

The owner answered the open decisions of `docs/product/owner-decisions.md` on 2026-10-20 and gave one rule: any item not mentioned takes the "Prototype assumes" answer in that document. This ADR records the answers, states which earlier assumptions they replace, and turns the confirmed proposed ADRs into accepted ones.

## Decision

**D1. Owner rule.** Every item of `owner-decisions.md` that the owner did not mention is **decided = the prototype assumption**, as of 2026-10-20. Those assumptions are no longer "working assumptions" but remain settings (configuration), not constants.

**D2. Voucher price and validity (items 1, 3).** The voucher is KD 2.000 (`voucher_fee_fils` = 2000, a setting) valid for 60 days, paid online through the gateway. There is **no VAT** in the customer payment and no tax line on the receipt. The Arabic UI name is «كوبون» (OQ-V-15 answered).

**D3. Binding (item 2).** A voucher is tied to one venue or provider at purchase (A-01 confirmed).

**D4. 24 hour confirmation and forfeiture (items 4).** After the venue approves, the client has 24 hours to confirm at the hotel or service, that is to go there and pay the reservation. If the 24 hours lapse the voucher is **not valid**: state `forfeited`, it does not come back and cannot be reused. This replaces A-03, where a lapse made the voucher reusable. Declined, venue-silent and venue-cancelled requests still release the voucher (reusable at the same venue); a refund of those is a credit voucher on support request.

**D5. No money refunds; credit voucher (items 4, 10, 11).** There are no money refunds of the voucher. The client sends a refund request to Ghazal support (a chat entry); if support agrees, the client receives a **credit voucher** (`kind = credit`) in the account wallet: unbound, valid 60 days, claimable at any hall, hotel or service. The original voucher becomes `credit_issued`. The request and decision are recorded. Consequences: the gateway `refund` call is not used for vouchers, the gateway-fee-on-refund question (A-15) and the MyFatoorah refund-window question (OQ-B-02) are moot; ADR 0027 refund parts are moot (the webhook plus re-query, hosted pages and idempotency stand).

**D6. Venue non-compliance and rescheduling (items 5, 6).** Keep the prototype: 72 hour "Report an issue", reliability strikes, no compensation promised in the app (A-04); no in-app rescheduling (A-05).

**D7. Partner billing and listings (items 12 to 16).** Two billing modes: `plan` (weekly, monthly, annual; rates managed in the Super Admin panel, the prototype carries no number and shows "Rates announced soon") for service providers, and `contract` (terms as contracted, no public plan) mostly for hotels and halls. Soft-launch submission is allowed and managed from Super Admin. A rejected listing is reviewed by the Ghazal team; when not allowed the provider receives **notes** explaining why, refines and resubmits. Listing-fee refunds happen on a support request, independently of the gateway, and are recorded in the platform (replaces A-08, the automatic 14-day rule).

**D8. Staff and calendar by email (items 18, 16).** Partner staff are invited by email through Resend (not WhatsApp); sign-in is email plus password, with a code on new devices and an authenticator for admins as before. External calendar sync uses email (an .ics or an invitation address), not WhatsApp. Client sign-in codes stay WhatsApp OTP (item 45): implemented without credentials until the Meta business account is open.

**D9. Reviews and legal assets (items 19, 37).** Venues reply once and report only; deleting or hiding a review is done on request to support and performed there. Logo, Terms, Privacy and the store-hosting page are as assumed and editable in the Super Admin panel.

**D10. Technology (items 40 to 43, 46).** Backend is NestJS (ADR 0020 accepted). Bundle ids: `com.ghazal.client` and `com.ghazal.provider` (the Partner app is the provider app; the `hotel` app id and `HL-` prefix stay in the repository). iOS 15 and Android 8 (minSdk 26) accepted (ADR 0022 item A, CF-35). Venue videos: high quality, 500 MB limit per video (replaces 60 s, 100 MB, 720p).

## Consequences

- Voucher states: `unpaid`, `active`, `bound`, `used`, `expired`, `forfeited`, `credit_issued`; the old `refunded` state is dropped and the wallet gains a `credit` kind.
- Support gets a refund-request queue and a credit-grant action; the data model gains `refund_requests`.
- Partner billing needs a `billing_mode` and Super Admin rate configuration; hotels and halls show a contract state, not a plan picker.
- Remaining owner items: `docs/product/owner-decisions.md` "Still open for the owner".

## Alternatives considered

1. Keep the reusable-after-lapse rule. Rejected by the owner: a lapse forfeits the voucher.
2. Refund the KD 2 to the card. Rejected by the owner: credit voucher only.
3. WhatsApp staff invitations. Rejected by the owner: email through Resend.

## Related requirement IDs

New: CA-VCH-15..17, HA-VCH-06, PA-BIL-01, PA-ACC-06, HA-CAL-10, HA-REV-01, HA-VMGT-14 (`docs/product/feature-matrix.json`).
