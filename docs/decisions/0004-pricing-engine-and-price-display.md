# ADR 0004: Pricing model: deterministic tier engine (weekday, weekend, holiday, season), flat plus per-guest, one best offer, frozen quote, all-in display

| Field | Value |
|---|---|
| Status | accepted; partially superseded: D3 shading by 0011 D4, D6 currency strings by 0010 D7; D4, D6 (second price) and D8 by 0033 |
| Date | 2026-10-12 |
| Scope | API (pricing engine, quote endpoint), Client app (cards, calendar, package, Review), Hotel app (package and price editing), venue web (tier editor) |
| Owner confirmation still needed | OQ-B-14 (coupon and credit stacking and funding), OQ-B-15 ('No booking fee'), OQ-B-16 (commission, service charge, payout visibility); the prototype uses placeholders |
| Related ADRs | 0001 (frozen snapshot at send), 0005 (deposit from the client total), 0006 (policy snapshot), 0009 (compare price rows), 0010 (units and number formats), 0011 (calendar and day types), 0018 (card price line) |
| Screens | CL-DISC-03, CL-VENU-01, CL-VENU-03, CL-VENU-04, CL-BOOK-02, CL-BOOK-03, CL-BOOK-05, HL-VENU-02, HL-VENU-03, HL-GROW-01..03 |

> Superseded by 0033 on 2026-10-14 (owner changed the business model to the KD 2 voucher marketplace): The tier engine, frozen quote and calendar price view stand; each package now carries a standard and a voucher price and platform credit and venue coupons are removed. The body below is the historical record.

## Context

Kuwaiti venues do not sell one number. The real cost is hall fee + per-guest catering + extras (kosha, florals, lighting, valet, cake, bridal suite) + an optional service charge, and it swings between weekday, weekend and holiday nights. Published hotel packages add complimentary guests (for example 10% of attendees), complimentary cake and valet, and a minimum guest count. Independent halls and villas charge a flat fee per night; government halls charge a flat ministry fee. A bare 'From KD 46' is meaningless without a unit and a guest basis.

Further constraints:

- The PRD web pricing engine has weekday, weekend, holiday and season prices (VD-PRC-01..04, VD-CAL-03/04), but the hotel app edits only base prices (CF-25).
- Thursday night is the wedding peak, so Thursday is priced as weekend while the Kuwait calendar weekend is Friday-Saturday.
- Ramadan, Eid and National Day dates move with moon sighting; existing bookings must never reprice because of a late announcement.
- Kuwait has no VAT in 2026 and none is expected before 2028.
- Honest pricing is a differentiator: the UK CMA forced several large travel platforms to show all-in prices and only verifiable 'was' prices.
- Prices in a calendar must be stable per day, which absolute tier prices guarantee and multiplicative uplifts do not.

## Decision

**D1. What a price is.** Hall fee + per-guest catering (menu-tier uplift) + extras (kosha/decoration, lighting, sound, valet, cake, bridal suite, companion section) + optional venue service charge. Packages may include complimentary guests and inclusions. `package.pricing_basis` = `flat` | `per_guest` | `flat_plus_per_guest`. Government halls use a flat `government_fee`, display only, no engine.

**D2. Engine order.**

1. **Tier** per package and extra by precedence `special_date` > `holiday` (Super Admin date ranges incl. Ramadan/Eid windows) > `season` (venue range) > `weekend` > `weekday`; first match wins; no multiplicative stacking; each tier stores absolute flat and per-guest amounts (editor shortcuts such as '+20%' write absolutes).
2. `billable_guests = max(guests, min_guests)` less complimentary % (10% on 400 guests bills 360).
3. **Lines:** package flat, food, menu uplift, extras (`flat` | `per_guest` | `per_unit`).
4. **One best venue-funded offer.**
5. **Service charge** on lines after venue discounts.
6. **Tax lines** at 0% (hidden until a rate exists).
7. `venue_bill`.
8. **Platform credit.**
9. `client_total`.

Integer fils, half-up rounding per line, a leftover fil goes to the venue share.

**D3. Night types.** Weekday = Sun-Wed; Weekend tier = Thu, Fri, Sat by default (venue-editable mask), because Thursday night is the wedding peak. The calendar's visual weekend shading is Fri-Sat only; weeks start on Sunday. (See the note on ADR 0011 below.)

**D4. Offers and credits.** Venue offers (percent or fixed; package or line scope; last-minute at 14 days or less, early-bird at 120 days or more; usage limits) never stack with each other; a flash sale is an offer with an end time; a venue coupon code is an offer that needs entry. A strike-through 'was' price is shown only against a real prior price. Platform credit (loyalty points, referral, platform coupon) is platform-funded, applies after the venue offer, lowers the client total and platform commission but never the venue payout, and is capped so platform net commission stays at or above zero (OQ-B-14). A venue may approve with an extra discount, never at a higher price.

**D5. Frozen quote.** An immutable price + policy snapshot is stored when the request is sent (or instant checkout starts). Venue price edits, new holidays and moon-sighting date shifts never reprice an existing booking. After confirmation, changes are amendments with priced deltas (guest-count true-up, extras, package upgrade, reschedule to a higher tier).

**D6. Display.** Always all-in (service charge inside the headline; the breakdown shows it as a line); no fee may appear after Review; every price states its basis. Card grammar:

| Brief state | Card price line | Availability line |
|---|---|---|
| Date and guests set | 'KD 7,843 for 400 guests' | 'Thu 21 Jan - Free' |
| Guests only | 'From KD 6,900 for 400 guests - weekday' | none |
| Neither | 'From KD 2,100 - min 200 guests' (lowest package at its minimum, weekday), with '46 per guest' added for per-guest packages | none |

**One grammar, decided 2026-10-12 (this ADR owns it; ADR 0018 D4, pricing-and-payments section 3, the screen JSON and the Flutter fixtures all follow it).** 'From' appears only when the guest count alone is set, or when neither is set. When a date and guests are both set the card, results row, Home shelf, Saved row and Replace sheet show the exact price of the lowest eligible package for that date and guests with no 'From' and no 'Est.' ('KD 7,843 for 400 guests'); 'Est.' prefixes the same number only where it is shown before a package is chosen inside a flow (the venue date strip and the booking footer: 'Est. KD 7,843 for 400 guests'), and Review is exact. Currency strings use `KD` in consumer English per ADR 0010 D7 (this ADR's older 'KWD' strings above are superseded by it). Formatter modes: *compact* for browse (drops `.000` but never shows `18.5`, shows `18.500`) and *exact* 3 dp for Review, payment, invoices, ledgers, analytics. Digits, numbering system and currency placement follow ADR 0010 (Western digits, pinned) and are not re-decided here.

**D7. Calendar Price view.** Each day shows the lowest eligible package price for the current guests and audience as whole dinars with a thousands separator (no 'k' abbreviation: unfamiliar and fragile in bidi), small glyphs for weekend / holiday / special-date tiers, and an exact summary card (price, sessions, deposit) for the focused day. Fallback if comprehension tests poorly: tier glyphs only plus the exact summary.

**D8. Venue editing.** The hotel app edits per-package weekday and weekend prices, per-guest rate, min/max guests, extras and the active toggle, with a 'what couples see' preview. Season, holiday and special-date overrides, menus and tier grids are read-only in the app ('Edit on dashboard') because the PRD places the pricing engine on web (VD-PRC-*, VD-CAL-03/04) and editing a money grid on a phone invites costly errors. Venue package names must not reuse Silver / Gold / Royal (reserved for planner packages).

**D9. Worked example (arithmetic checked; the offer is a plain dated percent offer, deliberately not an early-bird, because the prototype clock is Thu 12 Nov 2026, 70 days before this event, below the 120-day early-bird rule).** Thu 21 Jan 2027, Evening, hall 1,800.000 + 360 billable guests x 12.500 = 4,500.000 + extras 920.000 = 7,220.000; winter offer -90.000 = 7,130.000; service charge 10% = 713.000, venue bill 7,843.000; platform credit -50.000, client total 7,793.000. Deposit rules are in ADR 0005.

| Line | KWD |
|---|---|
| Hall fee | 1,800.000 |
| Food: 360 billable (400 less 10% complimentary) x 12.500 | 4,500.000 |
| Extras: kosha 650.000 + valet 150.000 + cake 120.000 | 920.000 |
| Subtotal | 7,220.000 |
| Winter offer (percent, -5% of the hall fee, venue-funded, valid for events 1 Jan-28 Feb 2027, no lead-time rule) | -90.000 |
| After venue discount | 7,130.000 |
| Service charge 10% | 713.000 |
| **Venue bill** | **7,843.000** |
| Welcome credit (platform-funded) | -50.000 |
| **Client total** | **7,793.000** |

Deposit under ADR 0005 D1: 30% of 7,793.000 = 2,337.900, rounded up to the next KWD 5 = 2,340.000; balance 5,453.000. Commission at the placeholder 8% of the venue bill is 627.440 (ADR 0005, OQ-B-16).

## Consequences

- Cards, Compare ('Price for my date') and the calendar all need the Brief (date + guests) and fall back gracefully to labelled 'From' prices.
- The pricing engine must expose a per-day quote endpoint (`GET /venues/:id/availability?month&guests&audience` returns state, `from_price_fils` and tier per day).
- The venue web dashboard must ship the tier editor (not the mobile app).
- Strike-through prices and 'No booking fee' copy are constrained by the honesty rules and OQ-B-15.
- Commission, service-charge percentage and coupon funding are owner money rules (OQ-B-14, OQ-B-16); the prototype uses placeholders (commission 8%, hard cap 10%).
- Prices in seed content must show units and guest counts (for example 46 per guest, min 200).
- Price rules need a GiST index on `valid_range` and precedence `priority` (`price_rules (scope_type, scope_id, tier_kind, priority)`); quote lines are normalised `booking_lines` with `funded_by` venue | platform (ADR 0020).
- Engine tests: fixtures for rounding (half-up per line; a 1-fil remainder goes to the venue), complimentary guests, offer precedence and the worked example above.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Free-form venue price per day | No explanation for the couple; no engine for deposits, snapshots or amendments |
| Multiplicative uplifts ('+20% on weekends', stacked with season and holiday) | Unstable per-day prices and hard to explain; D2 stores absolutes and keeps '+20%' only as an editor shortcut |
| A single 'from' price per card | Misleading in a per-guest market; replaced by Brief-driven grammar (D6) |
| Fees shown at checkout (service charge or Ghazal fee added late) | Violates all-in honesty and the CMA remedies; service charge lives inside the headline |
| Offers that stack | Hard to audit and risks cutting the venue payout silently; one best offer only |
| Platform coupons that reduce the venue payout | Venue entitlement must never be cut by Ghazal marketing; credits are platform-funded |
| Calendar prices in thousands ('2.45') | Unfamiliar and bidi-fragile; whole KWD with a thousands separator instead |
| Season, holiday and tier grids editable on the phone | Money grids on a small screen invite costly errors; read-only with 'Edit on dashboard' |
| Tax lines now | No VAT; the tax table exists at 0% and stays hidden |
| Floating-point money | Integer fils everywhere (ADR 0010 item 6) |

## Related requirement IDs

| ID | Effect |
|---|---|
| CA-BOOK-05, CA-BOOK-09, CA-BOOK-14 | Extras, itemised Review, live price updates by date and guests |
| CA-CARD-05, CA-CMP-05 | Card and Compare price grammar |
| CA-VDET-07, CA-VDET-22 | Package prices on detail; calendar Price view |
| CA-LOY-03, CA-LOY-05 | Points and coupons apply as platform credit at Review |
| HA-VMGT-03, HA-VMGT-04, HA-VMGT-05 | Package, price and extras editing on mobile (base prices only) |
| HA-OFFR-01..04, HA-OFFR-06 | One best offer, flash sale, coupon, badges on cards |
| VD-PRC-01..07, VD-CAL-03, VD-CAL-04 | Tier editor on web |
| PL-BOOK-04, PL-BOOK-05 | Pricing engine and commission engine |
| NF-LOC-05 | Money through one formatter |
| CF-20 | Single starting-price figure, now with a stated basis |

## Notes on conflicting inputs

- **Currency in English.** The card grammar above is quoted from the accepted decision with 'KWD'. ADR 0010 item 7 (the owner of currency strings) writes `KD` on consumer English surfaces and keeps `KWD` for invoices, receipts, payout settings and the API. Implementations follow ADR 0010; the examples here show structure, not final strings.
- **Weekend shading.** D3 says the calendar's visual weekend shading is Fri-Sat only. ADR 0011 item 4 shades the Thu-Fri-Sat peak band (config `weekend: [5, 6]`, `peakBand: [4, 5, 6]`). ADR 0011 owns calendar visuals; this ADR owns the pricing day types (Weekday Sun-Wed, Weekend tier Thu-Sat by default). The word 'weekend' therefore means Thu-Sat in pricing and Fri-Sat in calendar config; use `tier: weekend` and `weekend` config names exactly as above to avoid confusion.
