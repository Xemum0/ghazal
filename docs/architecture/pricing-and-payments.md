# Pricing and payments (voucher model)

> Status: from ADR 0033 (2026-10-14). The price engine (tiers, billable guests, lines, service charge, frozen quote) is kept from ADR 0004 and now runs once per price column: **standard** and **voucher**. Everything about deposits, balances, cash, commission, payouts, cancellation tiers and the refund calculator (ADR 0005, 0006 and the money half of ADR 0027) is retired. The only in-app payments are the **KD 2 voucher** (client to Ghazal) and **listing or advertising plans** (partner to Ghazal, major hotels exempt). All amounts are integer fils (1 KWD = 1,000 fils). Voucher fee, validity and plan rates are configuration (section 8); plan rates are **not decided** and nothing here carries a number for them. State changes: [booking-state-machine](booking-state-machine.md). Business rules: [voucher-model](../product/voucher-model.md).

## 1. Principles

1. **Deterministic and explainable.** A price is the output of a rule engine, never a free-form number. The same inputs always give the same fils, in both columns.
2. **Two real prices.** Every voucher-eligible package has a standard price and a voucher price, on the same basis, set by the partner. The saving is their difference. No invented "was" price.
3. **All-in and honest.** The headline includes the venue service charge; a price never appears without its unit and guest basis. Kuwait has no VAT, so no tax lines until a rate exists.
4. **The voucher is the only client fee, and it is shown before it is charged.** KD 2 is stated on the detail screen, on the explainer sheet and on the pay screen. The event itself is paid to the partner off-app and no Ghazal screen collects it.
5. **A voucher is offered only when it pays for itself:** `savings_fils > voucher_fee_fils`.
6. **Frozen quote.** The quote (both totals) is snapshotted when the request is sent; partner price edits never reprice an existing request. The partner may approve at a lower voucher price, never higher.
7. **The server is the source of truth.** Clients display the server's snapshot through `GzFormat`; they never compute totals. The gateway webhook plus a status re-query, never the app's return URL, decides that money arrived.
8. **No money is held, split or paid out by Ghazal for events.** Gateway receipts for vouchers and listing plans are Ghazal revenue; refunds return to the original method.

## 2. The price engine

Runs in `pricing`; exposed as a per-day quote (`GET /v1/venues/{id}/quote`, `.../calendar-prices`) returning `{standard, voucher, savings}` and re-run when a request is created or edited.

| Step | Rule |
|---|---|
| 0. Inputs | hall (or listing), session, audience, `event_date`, guests (or quantity), package, menu tier, extras, today's date |
| 1. Tier | Per package and per extra, per column, the first match wins by precedence **special_date > holiday > season > weekend > weekday** (unchanged). Weekday = Sun-Wed; weekend tier = Thu, Fri, Sat by default (partner-editable mask). No multiplicative stacking: every tier stores absolute `flat_fils` and `per_guest_fils` for `standard` and for `voucher` |
| 2. Billable guests | `max(guests, package.min_guests)`, less the complimentary share (`complimentary_bps`). Same count for both columns |
| 3. Lines | package flat; food (billable guests x per-guest); menu uplift per guest; extras by unit (`flat`, `per_guest`, `per_unit`). An extra with no voucher price is billed at its standard price in both columns |
| 4. Service charge | Partner percentage on lines (per column) |
| 5. Tax | 0%; no line is rendered |
| 6. `standard_total` and `voucher_total` | lines plus service charge, per column |
| 7. `savings` | `standard_total - voucher_total` (never negative) |
| 8. Eligibility | `voucher_total < standard_total` and `savings > voucher_fee_fils`; governmental facilities and packages with no voucher column are never eligible |
| Rounding | Integer fils, half-up per line |

Removed from the engine: venue-funded offers and coupon codes (the voucher column is the reduction; a time-boxed voucher price is a rule with `valid_range`), platform credit, loyalty redemption, commission. The partner can approve at a lower voucher total at approval time (an `approval_adjustment` line), never higher.

**Pricing structure.** `pricing_structure` per package: `per_person` (`per_guest_fils` with `min_guests`), `package` (bundled: `flat_fils`, or `flat_plus_per_guest` for packages with a fixed core and a variable catering part). A venue may carry both kinds. Filters and cards name the structure. Governmental facilities show an official rental fee with no engine and no voucher.

**Snapshot.** `price_snapshot` stores lines, applied rule ids, both totals, savings and the voucher fee at the time. It is replaced only while `pending` (client edit, `quote_version + 1`) and at approval if the partner lowers the price; from `approved` it is immutable (trigger). After confirmation nothing changes the price in-app.

**Partner editing.** The Partner app edits, per package, weekday and weekend prices in both columns, the per-guest rate, minimum and maximum guests, extras, the active toggle and the optional voucher `valid_range`, with a "what couples see" preview showing both prices and the saving. Season, holiday and special-date overrides stay web-only (ADR 0004 D8).

## 3. Display grammar

Formatting is owned by `GzFormat` ([i18n-rtl](i18n-rtl.md)); this table says which shape each surface needs. Illustrative seed (not product pricing, fixtures will set them): V01 Aurelia Gulf Hotel, ladies' reception, standard KD 46 weekday and KD 52 weekend per guest, voucher KD 40 and KD 44, minimum 200 (Majlis Hall) and 300 (Danah Ballroom).

| Brief state | Card line | English / Arabic example |
|---|---|---|
| Date + guests set | Voucher price for that date and guests, standard price beneath, saving chip | `KD 15,400 voucher price for 350 guests · standard KD 18,200` / `15,400 د.ك بالقسيمة لعدد 350 ضيفًا · السعر العادي 18,200 د.ك` |
| Guests only | Lowest matching voucher price, standard beneath | `From KD 14,000 for 350 guests` (voucher) |
| Neither | Lowest package at its minimum, weekday | `From KD 8,000 · min 200 guests`, `KD 40 per guest` |
| Below the hall minimum | Priced for the minimum, said so | `From KD 8,000 for 200 guests (minimum)` |
| Flat package | Flat unit | `KD 2,800 per night` |
| Government facility | Rental fee only, no voucher | `KD 100 rental fee` |
| Guest (not signed in) | Both prices, voucher price with a lock | `Voucher price · register to unlock` |
| No voucher price | One price only | as before |

Rules: no "From" when date and guests are both set; "Est." prefixes a number inside a flow before a package is chosen; the request summary is exact. Browse surfaces drop `.000` but never show `18.5` (they show `18.500`); the request summary, receipt and booking detail show three decimals; one precision per list. The saving chip reads "Save KD 2,798" (net of the voucher) on browse and "You save KD 2,800 with a KD 2 voucher" in the detail and summary. The calendar Price view shows the voucher price when eligible, else the standard price, as whole dinars with a thousands separator.

## 4. Worked examples (illustrative seed values)

**A. The hero request `GZ-2611-0147`** (Reem Al-Dosari, V01, Danah Ballroom, Evening, ladies, Thu 14 Jan 2027, 350 guests; clock Thu 12 Nov 2026, 63 days out).

| Line | KWD |
|---|---|
| Standard: 350 guests x 52.000 (weekend tier; 350 is above the 300 minimum) | 18,200.000 |
| Voucher: 350 guests x 44.000 | 15,400.000 |
| Savings | 2,800.000 |
| Voucher fee (paid online to Ghazal) | 2.000 |
| Net saving | 2,798.000 |
| What the client pays the venue after confirming (off-app, per the venue's terms) | 15,400.000 |

**B. Below the minimum.** 280 guests in Danah: billed as 300. Standard 300 x 52 = 15,600.000; voucher 300 x 44 = 13,200.000; savings 2,400.000.

**C. Package (hall only).** V07 flat standard 3,400.000 weekend; voucher 3,000.000; savings 400.000, still more than the KD 2 fee, so the voucher is offered. A hall whose voucher price is KD 1.500 below standard would not offer one.

## 5. The voucher payment

**Methods and order.** iOS: Apple Pay, KNET, Visa or Mastercard. Android: KNET, Google Pay (only if the gateway enables it), Visa or Mastercard. The server computes the list (gateway methods cached about 10 minutes, filtered by `X-Platform`); the apps hardcode none. Wallets and cards use hosted flows; card data never touches Ghazal (NF-PAYS-01, SAQ-A). KNET is a full-page redirect shown in an in-app authentication session with an HTTPS return link.

**Flow** (screens `CL-PAYM-01..05`, repurposed): `POST /v1/vouchers/{id}/payment-sessions` (Idempotency-Key; only while the voucher is `unpaid`) returns `{ paymentId, paymentUrl, expiresAt, amount, methods }`; the app opens `paymentUrl`; whatever the launcher reports, the app then reads `GET /v1/payments/{id}`. The return URL is never trusted.

| Outcome | UI |
|---|---|
| Success | "Your voucher is ready": code and QR, bound venue and quote, validity, primary "Send request at the voucher price", secondary "View in My vouchers" |
| Failed | "The payment could not be completed. No amount was charged." Retry (same Idempotency-Key for the same attempt) or switch method; after a KNET failure suggest Apple Pay or card |
| Pending bank confirmation | "Confirming with your bank". Poll with backoff; at about 30 s "We are confirming. You can leave; we will notify you."; push and email take over after 90 s |
| Checkout lapsed | New checkout offered; a SUCCESS arriving after the lapse still activates the voucher (the client paid) |

**Gateway boundary** (ADR 0027, narrowed). One port `PaymentGateway { createSession, getStatus, refund, listMethods }` with one MyFatoorah adapter. Removed: `createSupplier`, `uploadSupplierDocument`, supplier split, balance transfer. Webhook handling is unchanged: raw body, signature check, inbox row (duplicates are no-ops), **re-query**, then the compare-and-swap. Events handled: `PAYMENT_STATUS_CHANGED`, `REFUND_STATUS_CHANGED`, `DISPUTE_STATUS_CHANGED`. The session carries our payment, voucher and user ids in `ExternalIdentifier` and `UserDefinedField`. Gateway fees are recorded per payment from the webhook, never as constants. Unconfirmed facts that change copy, not design (OQ-B-02, OQ-T-04): refund timings per method, Auto Refund, per-method fees, KNET limits.

## 6. Voucher refunds

Rules are in [voucher-model](../product/voucher-model.md) section 4.4. Execution: the client taps "Refund KD 2" on the voucher detail (eligible cases only); the server checks eligibility, creates a `refunds` row (`calculated`, `approved`, `submitted`, `processing`, `completed`, `failed`, `manual_bank_transfer`), submits to the gateway within 1 business day, returns to the original method, always `ServiceChargeOnCustomer = false`. Arrival copy stays soft until the gateway confirms: KNET "1 to 3 working days", cards and wallets "up to 10 working days". Gateway fees on refunds are borne by Ghazal. One refund per voucher.

## 7. Listing and advertising plans

| Item | Rule |
|---|---|
| Plans | Weekly, Monthly, Annual (`listing_plans`, one row per cycle) |
| Rates | **Not decided.** `rate_fils` is nullable; when null every surface says "Rates announced soon" and the pay button is disabled with the reason "Payment opens when rates are announced". No amount appears in the UI, fixtures or docs. A sample amount in a prototype state is labelled "Sample" and never shipped |
| Who pays | Service providers always; hotels and halls that are not `fee_exempt` (A-12); major hotels never (`fee_exempt = true`, set by the Super Admin) |
| Payment | Hosted gateway page, same method list as the voucher; Idempotency-Key; webhook plus re-query; receipt and plan invoice (bilingual PDF, amounts in KWD) |
| When it counts | Payment moves the listing to `pending_review` only; the plan period starts at approval (A-07); no auto-debit, no saved cards |
| Rejection | The paid plan is kept for 14 days for a resubmission; afterwards refunded in full to the original method (A-08) |
| Expiry and renewal | Reminders at -7 and -1 days; an expired listing disappears from search; renewal is a new payment |
| Labelling | Paid placement ("Featured", "Sponsored") is labelled to clients; the base listing is not |

## 8. Cash and documents

- **There is no cash handling and no recorded payment of any event.** The client and the partner settle between themselves.
- **Documents:** a receipt per voucher payment at once; a receipt and plan invoice per listing payment; a credit note on a refund. Bilingual PDFs from `ghazal-pdf`; they say **KWD** and keep Western digits; numbers are a gapless 7-digit sequence per issuer and kind. The issuing entity wording is pending legal review (OQ-B-06, OQ-T-12). There are no event invoices.
- **Planner packages (Silver, Gold, Royal):** unchanged from the earlier state: proposal only, no in-app checkout (OQ-P-19). Planning is now a service-provider category and requests go through the same voucher request path (the partner's own price list).

## 9. Configuration (every number above lives here, not in code)

| Setting | Default | Bounds | Set by | Decision status |
|---|---|---|---|---|
| Voucher fee | KD 2.000 (`voucher_fee_fils = 2000`) | Super Admin | Super Admin | owner-given |
| Voucher validity / reuse window | 60 days / 60 days | 30-180 | Super Admin | proposed, OQ-V-02 |
| Voucher checkout lifetime | 30 min | fixed | Platform | proposed |
| Refund eligibility | per voucher-model section 4.4 | | Platform | proposed, OQ-V-03 |
| Partner reply time | 24 h | 12 / 24 / 48 h | Partner | accepted (ADR 0001) |
| Confirm window | 24 h | fixed | Platform | owner rule |
| Service charge | per partner, inside the headline | percentage | Partner | accepted (ADR 0004) |
| Listing plan rates (weekly, monthly, annual) | **null (announced soon)** | | Super Admin | open, OQ-V-07 |
| Listing fee required, per partner type | hotel true, hall true, provider true | | Super Admin | proposed, OQ-V-13 |
| `fee_exempt` (major hotel) | false | | Super Admin | owner rule |
| Rejected-listing plan retention | 14 days | 7-30 | Super Admin | proposed, OQ-V-08 |

Next: [i18n-rtl](i18n-rtl.md).
