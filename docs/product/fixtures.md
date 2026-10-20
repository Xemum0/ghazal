# Fixtures: the bilingual seed behind both apps (voucher model)

> One seed feeds the Client App prototype, the Partner (hotel) App prototype and, later, the Flutter tests (ADR 0031 D6, ADR 0021 D4). It lives in `packages/contracts` and is read by screens only through `design/src/mock/index.ts`. Everything is fictional. Owner: fixtures-owner. Model: ADR 0033 and [voucher-model](voucher-model.md): Ghazal sells a KD 2 voucher; halls, hotels and service providers sell and collect everything else, off-app. Other rules: [seed-rulebook](../design/seed-rulebook.md), [content-guidelines](../design/content-guidelines.md), ADR 0002 (halls, sessions, sections), 0004 (tier engine, kept), 0010 (money), 0013 (Arabic), 0015 (imagery). ADR 0005 and 0006 (deposit, balance, cancellation tiers) are retired and nothing in the seed uses them.

## 1. How it is built and checked

| What | Where |
|---|---|
| Types | `packages/contracts/src/types/*.ts` (barrel `types.ts`), string-literal unions only |
| Seed source (authored) | `packages/contracts/seed/*.mjs`: compact specs and builders, one file per concern |
| Fixtures (generated, committed) | `packages/contracts/fixtures/*.json` and `fixtures/stress/*.json` |
| Engine | `src/engine/*`: pricing (two columns), availability, voucher rules, request state-machine table, visit slots, SLA, dates, money, seeded randomness, search normalisation |
| Typed loaders and selectors | `src/data.ts`, `src/selectors.ts` |
| Prototype barrel | `design/src/mock/index.ts` (re-exports the package, adds `clock`) |

```
pnpm -F @gz/contracts build       # seed/*.mjs -> fixtures/*.json (deterministic: no Math.random, no system clock)
pnpm -F @gz/contracts check       # fails when a fixture file is stale against the seed
pnpm -F @gz/contracts validate    # staleness + integrity + rules (about 16,200 checks)
pnpm -F @gz/contracts typecheck   # tsc over src
```

Edit `seed/*.mjs` and run `build`; never hand-edit `fixtures/*.json`. `validate` covers: ids and references; images in the curated manifest; integer-fils money; **both price columns** (voucher always below standard, every rule and package 15% to 35% lower, headline prices, savings above the KD 2 fee); every request re-quoted by the engine; the 24 hour confirm window; the thread and the transition table (R01 to R13); voucher codes, QR payloads, receipts, states (incl. `forfeited`, `credit_issued`) and the release and credit table, credit vouchers and support credit requests (no money refund fields, no VAT field); partner billing mode (contract for hotels and halls, plan for services, never a number), email staff invitations, calendar sync by email; visits and their three-member group chats; provider categories, listings, plans (rates null) and partner accounts; the hotel strip, SLA readings and analytics sums; content rules (no deposit, commission, payout or قسيمة wording, no Eastern digits, no emoji, no real brands).

## 2. Conventions every screen can rely on

| Topic | Rule |
|---|---|
| Clock | `PROTOTYPE_NOW = 2026-11-12T16:00:00+03:00` (Thu 12 Nov 2026, 4:00 PM, Asia/Kuwait). Read `clock.now()` |
| Money | `{ fils, currency: 'KWD' }`, integers; the voucher fee is `meta.config.voucherFeeFils = 2000`. A bound quote on a voucher is `{ standard, voucher }` in plain integer fils |
| Two prices | Every package rule carries `flat`/`perGuest` (standard) and `voucherFlat`/`voucherPerGuest`. A quote returns `standardTotal`, `voucherTotal`, `savings`, `voucherFee`, `netSavings`; `voucherEligible` is `savings > fee` |
| Dates | civil `YYYY-MM-DD` (Kuwait), instants with `+03:00` |
| Bilingual | `{ en, ar }`, both filled. Arabic says «كوبون», never «قسيمة» |
| Ids | venues `V01`..; halls `V01-danah`; packages `V01-ladies-weekend`; providers `vendor-<category>-<key>`; partner accounts `partner-<id>`; listings `lst-<key>`; bookings `bk-<ref>`; vouchers `vch-<code>`; visits `visit-<venue>-<client>` |
| Codes | request `GZ-YYMM-XXXX`, voucher `GV-YYMM-XXXX` (Crockford base32, month of creation or purchase), receipts `RC-050001..` gapless in payment order; all LTR isolates |
| Phones | `+965 5000 NNNN`, display-only, one per party: `0001` Ghazal Support, `0002` Aurelia, `0004` support representative Lama, `0012` Reem, `0040`-`0047` partner staff and owners, `01NN` and `02NN` providers |
| Statuses | requests: `pending approved declined expired confirmed redeemed completed cancelled`; vouchers: `unpaid active bound used expired forfeited credit_issued` (a bound voucher), plus unbound credit vouchers (`kind: credit`, `active used expired`, 60 days, any venue or service; kept in `creditVouchers`, wallet selector `walletFor`); visits: `requested confirmed reschedule_proposed arrived completed declined cancelled missed`; listings: `draft payment_pending pending_review approved rejected active expired paused` |
| Imagery | only curated manifest files, no people; a venue with no photos has `cover: null` (stress S02) |

## 3. What is in the seed

| File | Contents |
|---|---|
| `meta.json` | clock, hero ids (venue, booking, voucher GV-2611-K7QM), provider persona, configuration (voucher KD 2, validity 60 days, reuse 60 days, confirm window 24 h, reply 24 h or 4 h urgent, max 3 open requests, visit chat read-only 24 h and archived 30 days, listing retention 14 days, discount bounds 1500 to 3500 bps), occasion markers |
| `areas.json` | 6 governorates, 83 areas, 7 reference points |
| `taxonomy.json` | filter taxonomy: venue types (Private hall, Governmental facility, Hotel), capacity range 50 to 1,500 step 50 and five bands, pricing structures (per person, packages, either), sorts incl. voucher price |
| `venues.json` | 16 venues, 31 halls; each with `type`, `style`, `governorateId`, `major`, `partnerAccountId`, `voucherEnabled`, `visitSlots`, terms, contact phone |
| `packages.json` | 47 packages (`priceStructure`, `priceUnit`, `standardFils`, `voucherFils`, `voucherDiscountBps`), 72 price rules with both columns, 150 extras (one price, billed the same in both columns: OQ-V-18) |
| `voucher-windows.json` | 8 time-boxed voucher prices (replace offers, flash sales and coupons): V01 midweek, Thu 3 and Sat 5 Dec (ends Fri 13 Nov 4:00 PM), spring (scheduled), autumn (ended); V09 winter; last-minute at V06, V11, V14 |
| `reviews.json`, `day-overrides.json` | 133 reviews; pinned availability of story dates |
| `services.json` | 9 groups, 19 categories (5 primary: catering, buffet, flowers, decor, event_planning), 50 providers with packages in two prices |
| `partners.json` | 66 partner accounts (16 venues, 50 providers), 3 ad plans (rates null), 54 listings, 207 review decisions, 3 personas |
| `visits.json` | 3 visits (each with a `visit_group` conversation in `chat.json`) |
| `planners.json`, `people.json` | planner tiers (no deposit) and 45 users incl. partner staff, provider owner and the support representative |
| `client.json` | Reem's wedding profile, budget, checklist, saved and compare, 17 notifications and the post-NOW hero notifications; no loyalty, coupons or referral |
| `bookings.json` | 37 requests in all eight statuses (31 venue, 6 provider), the hero in nine other states, a competing request |
| `vouchers.json` | 39 vouchers in every state, plus the competing request's voucher |
| `chat.json` | 13 conversations (3 are visit group chats), 43 messages |
| `hotel.json` | 10 Needs-you items, 206 calendar claims, analytics (voucher tiles, no revenue), settings with billing (Aurelia is exempt), memberships, 14 notifications |
| `faq.json`, `stress/*.json` | platform FAQ in the voucher model; stress fixtures |

## 4. The venue roster

Standard / voucher headline per guest (the cheapest rule of the package); the voucher discount is a deterministic per-venue share between 15% and 35%.

| ID | Venue | Type / style | Area, governorate | Halls | Packages standard / voucher |
|---|---|---|---|---|---|
| V01 | Aurelia Gulf Hotel | hotel, **major** | Sharq, Capital | Danah 650, Majlis 450 | ladies weekday 46/39, weekend 52/44, signature 50/42.5, men 32/27 |
| V02 | Madar Grand Hotel | hotel, **major** | Bneid Al-Qar, Capital | Qamar 800, Nujoum 400 | 44/33.5, 50/38, men 30/23 |
| V03 | Nawar Beach Resort | hotel (resort), **major** | Messila, Mubarak Al-Kabeer | Seaview 300, Lawn Terrace 450 | 49/34.5, 55/39, lawn night, men 34/24 |
| V04 | Bayan Villa Estate | private hall (villa) | Bayan, Hawalli | Garden 160, Indoor Majlis 60 | villa night 4,200/3,060 flat |
| V05 | Lumi Marina Hotel | hotel (non-major) | Salmiya, Hawalli | Marina 500, Terrace 180 | 34/27, 38/30.5, men 24/19, hall only 1,600/1,280 |
| V06 | Rawnaq Events Hotel | hotel | Shuwaikh, Capital | Diwan 600, Rawda 300 | 31/22, 35/24.5, men 22/15.5 |
| V07 | Jawharat Al-Salmiya Palace | private hall | Salmiya, Hawalli | Ladies 700, Men 500 | 29/21.5, 33/24, men 21/15.5, hall only 2,800/2,050 |
| V08 | Wasl Convention and Wedding Centre | private hall (convention) | Mishref, Hawalli | Grand 1,200, Hall A 600, Men's Majlis 500 | 27/21, 31/24, men 20/15.5 |
| V09 | Qasr Al-Nakheel | private hall | Jabriya, Hawalli | Ladies 550, Men 400 | 30/23.5, 34/26.5, men 22/17, hall only 3,200/2,490 |
| V10 | Qurain Grand Hall | private hall | Qurain, Mubarak Al-Kabeer | Ladies 800, Men 600 | hall only 1,800/1,340; with buffet (flat plus per guest) 15/11 |
| V11 | Mahboula Crown Hall | private hall | Mahboula, Ahmadi | Ladies 650, Men 450 | 24/18, 27/20, men 18/13.5 |
| V12 | Khiran Lagoon Estate | private hall (outdoor) | Khiran, Ahmadi | Lagoon Lawn 300, Indoor Majlis 120 | estate night 3,600/2,490 |
| V13 | Fintas Sea Pavilion | private hall (outdoor) | Fintas, Ahmadi | Pavilion 350 | 36/27, 42/31.5, men 26/19.5 |
| V14 | Khaitan Orchard Hall | private hall | Khaitan, Farwaniya | Ladies 700, Men 700 | 20/16.5, 23/19, men 15/12.5 |
| V17 | Taima Grand Palace | private hall | Taima, Jahra | Ladies 750, Men 500 | 22/16, 25/18, men 17/12 |
| V19 | Government Wedding Hall, Hateen | **governmental**, browse-only | Hateen, Hawalli | Main Hall 400 | rental fee KD 100 (official channel), no voucher, no visits, no packages |

V01 is pinned at 15.4% so the hero pair is exact (350 x 52 = 18,200 standard, 350 x 44 = 15,400 voucher); its weekday voucher is 39 (not the 40 sketched in `pricing-and-payments.md`) so it stays above the owner's 15% floor. Instant booking, deposit, balance, cancellation tiers, venue offers and coupon codes no longer exist. Visit slots: hotels Sun to Thu 10:00 to 20:00 and Fri, Sat 16:00 to 21:00 in 30-minute windows; halls end at 19:00 on weekdays; V19 has none.

## 5. Personas

| Persona | Facts |
|---|---|
| Client `user-reem` | Reem Al-Dosari, bride, wedding Thu 14 Jan 2027 (63 days), 350 ladies, venue budget KD 20,000 - 35,000. Wallet of five vouchers: GV-2611-K7QM **bound** (Aurelia, the hero), GV-2611-R4TF **active** and released (Lumi, no reply; reusable until 9 Jan 2027, may ask support for a credit voucher), GV-2609-F6TM **forfeited** (Qasr Al-Nakheel, not confirmed within 24 h: not valid, never comes back), GV-2610-H9XB **credit_issued** (Qasr Al-Nakheel declined; Reem asked support on 2 Nov and support granted a credit voucher on 5 Nov, in the support thread `conv-support-reem`), and the **credit voucher GV-2611-C4RD** (unbound, any hall, hotel or service, valid until 4 Jan 2027). Visits: Aurelia Sat 14 Nov 5:00 PM (confirmed), Lumi Wed 4 Nov (completed) |
| Hotel `user-hind` | Hind Al-Enezi, Manager, Aurelia Gulf Hotel (major: no fees, badge instead of the plan chooser). Staff: Khalid (Admin), Amal (Reception, the hotel representative in visit chats), Mahmoud (Accountant: billing and receipts only), Sara (Marketing, invited) |
| Non-major hotel `user-lumi-manager` | Badriya Al-Kandari, Lumi Marina Hotel (pays a listing plan; rep Nadia Al-Failakawi) |
| Provider `user-zahra` | Zahra Al-Mutairi, Zahra Floral Studio (`vendor-flowers-zahra`), service-provider account |
| Support `user-support-lama` | Lama Al-Khalidi, the Ghazal support representative of every visit group chat |
| Planner | Nouf Al-Otaibi (unchanged) |

## 6. The shared story (client app and partner app tell the same thing)

| When (Asia/Kuwait) | Event | Where it shows |
|---|---|---|
| Mon 9 Nov, 9:52 AM | Reem buys voucher GV-2611-R4TF (Apple Pay) and at 10:00 AM sends a request to Lumi (`GZ-2611-0098`, Thu 14 Jan, 300 guests) | client Bookings |
| Tue 10 Nov, 10:00 AM | Lumi did not reply: request `expired` (venue_no_response); voucher released, reusable; the client may ask support for a credit voucher | client Bookings "Expired", My vouchers, notifications |
| Thu 12 Nov, 12:31 PM | Reem pays KD 2 by KNET: voucher **GV-2611-K7QM**, bound to Aurelia, Danah Ballroom, Thu 14 Jan 2027, 350 guests | My vouchers |
| Thu 12 Nov, 12:40 PM | request `GZ-2611-0147`: standard KD 18,200.000, voucher KD 15,400.000, saving KD 2,800.000 (KD 2,798.000 after the voucher) | client "Request sent"; partner Pending card with voucher chip, `Reply by Fri 13 Nov, 12:40 PM - 20h 40m left` |
| Thu 12 Nov, 3:12 PM | Reem's message (unanswered) | both inboxes |
| **NOW** Thu 12 Nov, 4:00 PM | prototype clock; the request is `pending` | Pending chip / Needs-you |
| after NOW (walk) | hotel approves at 4:00 PM (8 s undo); **client confirms by Fri 13 Nov, 4:00 PM**; confirms 4:12 PM; settles with the hotel off-app; Amal redeems the voucher (variant: Sun 3 Jan 2027, 12:20 PM) | `heroBookingAs('approved' / 'confirmed' / 'redeemed' / 'completed')`, `heroVoucherAs`, `heroVariantNotifications` |
| other walks | `declined` (voucher released; ask support for a credit voucher), `expired` (no reply), `lapsed` (24 h passed without confirming at the venue: the voucher is **forfeited**, not valid), `cancelled` (withdrawn), `counter_offer` (Thu 21, Fri 22, Sat 23 Jan, voucher price held) | same selectors |
| Thu 14 Jan 2027 | wedding, Danah Ballroom 9:00 PM - 2:00 AM | |

`heroBookingAs(variant)` and `heroVoucherAs(variant)` return the same booking and voucher (same ids, reference, code and quote) in `pending` (stored), `approved`, `confirmed`, `redeemed`, `completed`, `declined`, `expired`, `lapsed`, `cancelled`, `counter_offer`. `checklistFor` completes the Venue item only at `confirmed` or later; `budgetFor` shows the KD 2 voucher as paid and the voucher price (KD 15,400) as committed from `confirmed`, remaining KD 44,598 (no event money moves through Ghazal).

## 7. Pricing as the seed applies it

- **Tier precedence** `special_date > holiday > peak > season > weekend > weekday`, first match wins, absolute amounts only, run once per column.
- **Voucher column**: per-guest rates round to KD 0.5, flat amounts to KD 10, clamped so every rule is 15% to 35% lower; one deterministic share per venue (and per provider). Extras are billed at one price in both columns.
- **Voucher windows** replace offers: inside the window the voucher rate is the window rate when lower (V01 Thu 3 and Sat 5 Dec: 41 per guest, KD 14,350 for 350; V09 winter).
- **Eligibility**: the voucher is offered only when `savings > KD 2`. Cards return the voucher only then (`CardPrice.voucher`, `savings`).
- **Effective minimum** `max(package.minGuests, hall section minimum)`; Danah asks 300, so 280 guests bill as 300 (standard 15,600, voucher 13,200, saving 2,400).
- **Venue approval** may lower the voucher total, never raise it (Asmaa Al-Roumi KD 2,080 and Huda Al-Shaya KD 1,040 off).
- **Card price grammar** unchanged (`exact`, `from_guests`, `from_minimum`, `flat_night`, `rental_fee`), each with the voucher price beside the standard `amount`.
- A request's `lines` carry the voucher column in `unit`/`amount` and the standard column in `standardUnit`/`standardAmount`, so a screen can strike the standard price.

## 8. Requests and vouchers

Requests (37): pending 7 (five at Aurelia, the hero's competing request is separate, two at Zahra), approved 2 (Haya Al-Mutairi, confirm by 7:30 PM today; one at Zahra), confirmed 8, redeemed 8, completed 5 (one without a redemption, A-04), cancelled 2 (Huda after confirming: voucher consumed; Fatima inside the 24 h window: released), declined 2 (Malak: voucher released, may ask support for credit; Reem at Qasr Al-Nakheel: credit voucher granted by support), expired 3 (Badr no reply, Amna lapsed, Reem at Lumi). Every request has exactly one voucher; vouchers (40 bound-kind): 17 bound, 14 used, 4 active (released), 2 forfeited (Amna, and the stress lapse), 1 credit_issued, 1 expired (GV-2608-D5QN, never used), 1 unpaid (GV-2611-M2WD, Shahad Al-Mutawa mid-checkout, "Payment in progress"). Release rules follow ADR 0035 (`releaseOutcome`): declined, no reply, slot taken, revoked and venue cancel release the voucher and are credit-eligible (a request to support, never money back); withdrawal releases it without a credit route; a lapsed 24 h window forfeits it; cancel after confirming consumes it. A released voucher has a 60-day `reuseUntil`.

The request machine is a table in `engine/transitions.ts` (R01 to R13 with actor, voucher effect and guard); the reason registry is typed in `types/booking.ts` and `types/voucher.ts`. Provider requests (`targetType: 'provider'`) have no sections and no calendar claim.

## 9. Availability

12 months from Nov 2026, per hall and day: `available | held | unavailable | closed`, the tier, session states, the lowest eligible package price in **both columns** (`fromPrice`, `voucherPrice`). Aurelia is decided by explicit claims: confirmed, redeemed and completed requests are `booking`, approved requests are a `hold` until `confirmBy`, pending requests are informational `requested` dots (never a claim). The six soft dates and the 12 to 25 Nov strip are unchanged (16 November events; Thu 12 Nov both halls booked, Mon 23 Nov blocked). Other venues use the seeded generator plus `day-overrides.json`.

## 10. The partner side (Aurelia Gulf Hotel)

| Area | Seed |
|---|---|
| Needs you (10) | five pending requests (Dana 3h left danger, Abdullah 15h, Maryam 17h, Faisal 19h, Reem 20h 40m), each with its voucher code; **Haya awaiting the client** (confirm countdown, 3h 30m left); Reem's message; Rashed Al-Ajmi's visit request; Mona S.'s review; the calendar check |
| Upcoming | approved: Haya (hold on Thu 10 Dec); confirmed: Lulwa Al-Saleh (Sat 12 Dec), Asmaa Al-Roumi; redeemed: Munira, Salman, Najla and five background events |
| Past | Nora, Thamer, Jood and Alya completed; Huda and Fatima cancelled; Malak declined; Badr and Amna expired |
| Analytics | this month (stored aggregates, not sums of the seeded rows): views 1,296 (+12%), clicks 238, requests 41, approved 22, confirmed 12, vouchers bought 38, redeemed 9, open dates 9. No revenue, finance, payout or bank data exists |
| Settings | hours, notification prefs (requests, messages, reviews, vouchers, visits), request mode only (reply 24 h, confirm window 24 h fixed), billing: **fee-exempt major hotel** |

## 11. Additional services, listings and plans

- **Categories**: five primary in the owner's order (Hospitality and catering, Buffet services, Floral arrangements, Event styling and decor, Event planning and coordination) with 5, 4, 5, 4 and 4 providers; the 14 secondary categories have 2 providers each. Providers keep their ids (`vendor-photography-lamha` ...); each package has a standard and a voucher price and a pricing structure (per person with a minimum, or package).
- **Listings** (54, one per provider plus Zahra's extra four): active 46, pending review 3, approved 1 (today 3:58 PM), rejected 1 (wrong category and unclear pricing, plan kept to 24 Nov), expired 2, draft 1. Only `active` listings are visible to clients (`providersFor`). Every live listing has a moderator decision in its trail; none was published on payment.
- **Ad plans**: weekly, monthly, annual with `ratesFils: null` everywhere and `exemptForMajorHotels: true`. No listing carries an amount; billing is `rates_pending` (OQ-V-17, A-16). `planRates()` returns `announced_soon`.
- **Partner accounts**: one per venue and provider; `feeExempt` only for V01, V02, V03 (the major hotels).

## 12. Visits and the three-way group chat

Three visits, three `visit_group` conversations, each with exactly three members: the client, a hotel representative (Amal at Aurelia, Nadia at Lumi) and Lama of Ghazal support, with role chips (Client, Hotel representative, Ghazal support) and monogram avatars: Aurelia Sat 14 Nov 5:00 PM **confirmed** (Reem), Lumi Wed 4 Nov **completed** (read-only since Thu 5 Nov, with a "Get your voucher" card), Aurelia Sat 21 Nov 6:00 PM **requested** (Rashed Al-Ajmi, waiting for the representative). `visitSlotsFor(venueId, date)`, `visitDatesFor`, `groupThreadFor(visitId)` serve the screens.

## 13. Selectors (`design/src/mock/index.ts`)

Venues and search: `getVenue`, `listVenues(filter, brief)` (region, types, styles, capacity, price structure, voucher only, availability on a date or range, query, sort incl. voucher price), `searchRegions`, `cardPrice`, `compareSet`, `quoteFor`, `quoteForProvider`, `availabilityFor`, `windowsFor`, `activeWindows`. Requests: `bookingsFor`, `getBooking`, `heroBookingAs`, `heroVoucherAs`, `confirmCountdown`, `bookingTarget`. Vouchers: `vouchersFor` (bound), `walletFor` (credit vouchers and bound), `creditVouchersFor`, `getCreditVoucher`, `getVoucher`, `voucherOptions` (`creditEligible`), `refundRequestsFor`, `getRefundRequest`, `redeemableFor`, `checkRedemption`. Partner: `billingFor` (plan or contract), `staffInvitationsFor`. Visits: `visitsFor`, `getVisit`, `visitSlotsFor`, `visitDatesFor`, `groupThreadFor`. Services: `primaryCategories`, `secondaryCategories`, `providersFor`, `getProvider`, `listingsFor`, `activeListingOf`, `partnerFor`, `personaFor`, `paysFees`, `planRates`. Partner: `requestsFor`, `needsYou`, `slaOf`, `calendarFor`, `softDatesFor`, `openWeekendDates`. Other: `conversationsFor`, `messagesFor`, `notificationsFor`, `checklistFor`, `budgetFor`, `daysToWedding`, plus `engine.*` and the raw collections. Removed: offers, coupons, loyalty, referral, payment schedules, payments, invoices, refund calculator, cancellation bands, finance. `vendors` and `vendorsFor` remain as deprecated aliases of `serviceProviders` and `providersFor`.

## 14. Stress fixtures

S01 long mixed-script name, 1,500-guest hall, flat KD 12,500 and a KD 0.5 extra; S02 no photos; S03 no reviews; `compareUnits` (per guest, flat per night, rental fee); three stress requests (lapsed approval, slot taken by another couple, withdrawn two minutes after sending) with their released vouchers; empty lists (now also vouchers, visits, listings); the bidi sheet (voucher code isolate, amount inside Arabic, phone in RTL, Hijri line).

## 15. Reconciliations and open points

| Topic | Seed |
|---|---|
| Voucher discount range | owner brief 15% to 35% wins over the sketch in `pricing-and-payments.md` (V01 weekday 39, not 40; V07 hall only 2,490, not 3,000) |
| Bound voucher validity | `validUntil` records the original 60-day validity; a bound voucher does not expire, so only `active` vouchers are tested against it |
| Listings before rates | live listings with billing `rates_pending` (OQ-V-17) |
| Extras | one price in both columns (OQ-V-18) |
| Analytics vs bookings | tiles are stored aggregates; the Bookings list is the seeded rows |
| `type` of a venue | now Private hall, Governmental facility or Hotel; the old display type is `style` |

Not done: the Dart port of the engine; a reactive prototype store (owned elsewhere); a native Kuwaiti read of the new Arabic copy (OQ-L-06); partner settings for Lumi and providers beyond the billing flag (Aurelia only).

## 16. Owner round 1 (ADR 0035, 2026-10-20)

| Topic | Seed |
|---|---|
| Voucher | KD 2.000, 60 days, no VAT field anywhere; the Arabic word is «كوبون» |
| `kind` | `bound` (a `Voucher`, tied to one venue or provider) or `credit` (a `CreditVoucher`: no venue, quote, payment or event date; `grantedFrom` names the request, the replaced voucher and the support representative) |
| 24 h confirm | the client confirms at the hotel or service within 24 h of approval; if not, status `forfeited` (`forfeitedAt`), request `expired` with `client_no_confirmation`, the voucher never returns |
| Credit request | `refundRequests` (`requested`, `granted`, `declined`), linked to the support conversation; granting turns the original into `credit_issued` and creates the credit voucher. One seeded: `rr-GV-2610-H9XB`, granted, with the credit card in `conv-support-reem` and the notification `credit_voucher_issued` |
| Partner billing | `partners.billing`: hotels and halls `contract` (one-line summary, no number), service providers `plan` (`ratesFils` null, "Rates announced soon"); `hotel.settings.billing.mode = 'contract'`; ad plan rates stay null (Super Admin sets them) |
| Rejected listing | notes from the Ghazal team, the provider refines and resubmits; `planKeptUntil` is null (no 14-day rule); a listing-fee refund is a support request outside the gateway, recorded in `Listing.feeRefund` |
| Staff and calendar | `people.staffInvitations` (email, role, `invited` or `accepted`, `sentAt`; sent through Resend); `hotel.settings.calendarSync` is an email address and an .ics setting, never WhatsApp. Client sign-in codes stay WhatsApp (implemented without credentials) |
| Reviews | reply once, report, and `Review.supportRequest` (hide or delete is a request to support, performed there) |
| Media | `MEDIA.videoMaxBytes = 500 MB` (`@gz/contracts`), high quality; the old 60 s, 100 MB, 720p limits are gone |
| Config | `creditVoucherValidityDays = 60` replaces `voucherRefundDaysAfterExpiry`; `listingRejectedRetentionDays` is deprecated until HL-PROV-05 and HL-PROV-06 are rebuilt |
