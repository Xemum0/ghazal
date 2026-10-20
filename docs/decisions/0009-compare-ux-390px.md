# ADR 0009: Compare UX on a 390px screen: anti-nag tray, full-bleed fluid thirds with label above value, differences-only by default

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-10-12 |
| Scope | Client app: Compare tray, Compare table, entry points, states, share |
| Owner confirmation still needed | OQ-B-12 (Share with a universal link and generated preview image) |
| Deviation recorded | CA-CMP-03 says the compare indicator opens the comparison 'from anywhere'; this design makes Compare reachable from Saved at any time and from the tray or badge on every discovery surface (D3) |
| Related ADRs | 0001 (Book carries date and guests), 0002 (government hall column), 0004 (price rows), 0007 (tabs and persistence), 0010 (numbers), 0014 (RTL and edge-swipe), 0018 (card compare control), 0019 (compare events) |
| Screens | CL-SAVD-02 (tray), CL-SAVD-03 (replace), CL-SAVD-04 (table), CL-SAVD-01, CL-DISC-03, CL-VENU-01 |

## Context

Compare is a PRD requirement (up to 3 venues, side by side, book from the comparison view) and a family-meeting artefact: the decision runs for weeks across WhatsApp groups, so the table must be screenshot-friendly and shareable by someone who never creates an account. Research raised these constraints:

- Three columns have to fit in 390px without hiding the third venue. A pinned-label-column table with horizontal scroll leaves the third venue permanently off-screen, and horizontal edge swipes collide with the iOS back gesture, which flips in RTL.
- Baymard's proven comparison details: hide identical rows, group by category, sticky headers, horizontal row styling. Contentsquare: short phrases and a differences-only toggle.
- Compare must stay visible without nagging. The brief names this explicitly (open question 4).
- Arabic strings run longer than English, so row copy needs a strict length budget and QA at 360px in Arabic.
- CA-CMP-05..09 name the rows: price, guests, area, rating, buffet, parking, decoration, photos, packages, availability for the chosen date, distance.
- The same table component should serve the planner package comparison (Silver | Gold | Royal).

## Decision

**D1. Compare is a tray plus a pushed table, not a tab.** Maximum 3 (CA-CMP-01). The 4th add opens 'Replace which one?' (a sheet; nothing is dropped silently, CA-CMP-02).

**D2. Entry.** A compare toggle at the top-start of every card image (44px target; the heart sits top-end), a header toggle on Venue detail, 'Compare (n/3)' multi-select in Saved, and a 'Your shortlist' module on Home once something is saved.

**D3. Tray (one component, anti-nag).**

- Appears only after the first add; with 1 venue it reads 'Add one more to compare' with empty slots drawn as hairline boxes (neutral); with 2-3 it reads 'Compare (n)' (actionable).
- Sits above the tab bar with three 40x40 slots; collapses to a 44px pill after 3 seconds idle and on scroll-down, returns on scroll-up.
- Shown only on Discover (Home), Results and Saved. On Venue detail it is replaced by the header badge so it never covers the sticky price and CTA bar.
- Never inside booking, My Wedding, Messages or Profile; never triggers a push; 'Clear' is not re-prompted that session.
- The set persists locally for guests and merges on sign-in (CA-CMP-12).

**D4. Table layout.** Full-bleed fluid thirds, 130 / 120 / 143 px columns at 390 / 360 / 430 wide, 12px inner padding (usable 106 / 96 / 119), 1px hairline dividers, no horizontal scroll and no label column. Each attribute is a block: a 12px muted label spanning the row, the three values beneath aligned to the columns. Sticky header: expanded 106x132 (4:5) thumbnails with a remove control (24px icon in a 44px target), name (2 lines; Arabic 15/24) and area; collapses on scroll to 56px with 40px thumbnails. Rejected: pinned label column plus horizontal scroll (matrix CA-CMP-04 note), because the third venue is always off-screen and horizontal edge swipes collide with iOS back, which flips in RTL.

**D5. Row groups in order.**

| Group | Rows |
|---|---|
| Your date | availability on the Brief date; price for your date and guests; deposit |
| Price | from-price; per guest |
| Capacity and layout | max guests with 'fits your N guests'; hall; audience; setting indoor/outdoor/mixed |
| Facilities | parking, valet, bridal room, decoration, buffet, photography: Included / Extra / Not offered as icon + text |
| Rating | score and count |
| Distance | device location, else preferred area |
| Packages | count and from-price, expandable |
| Photos | three 106x80 strips opening the gallery |

Covers CA-CMP-05..09. For a two-section booking intent, capacity and price rows show the section in the Brief.

**D6. 'Differences only'** segmented control, default ON, with '7 matching rows hidden'. Best-in-row marker: a small gold-ink dot before the winning value on objective rows only: price (lowest for the Brief date and guests), distance (nearest), rating (highest, only with 5 or more reviews), and on the capacity row 'best fit' = closest to your guests while still at or above your guests (never 'largest'). Never on subjective rows; never green/red.

**D7. Copy budget:** at most 14 characters per cell in English and 12 in Arabic; longer content lives behind an expandable row. Mandatory QA at 360px in Arabic.

**D8. Footer.** Three 48px outline buttons aligned exactly to the columns (a choice group, so the one-primary-action rule holds), labelled by channel and state: 'Request' (request mode), 'Book' (instant), 'See dates' when unavailable on the Brief date, 'Official' for government halls (the row above reads 'Official channel'). Tapping carries date and guests into booking step 1 (CA-CMP-10).

**D9. States.** Fewer than 2 venues; no date set (top group shows an inline 'Set your date' that opens the Brief sheet, price rows show 'From' with basis, availability row reads 'Pick a date'); a venue became unavailable (row shows 'Booked', header stays); a venue is no longer listed (column replaced by 'No longer listed' with Remove); offline (cached with timestamp); government hall column shows '-' in booking-only rows.

**D10. Share** (OS share sheet) sends the universal link `/compare?ids=a,b,c` plus a generated preview image; it opens for a guest family member without sign-in. Flagged as outside the PRD text (OQ-B-12).

```text
Sticky header          [ A 106x132 ] [ B 106x132 ] [ C 106x132 ]
Group: Your date
  label (12px muted, spans the row)
  value A | value B | value C        (130 / 130 / 130 at 390, hairline dividers)
Footer                 [ Request ]   [ Book ]      [ Official ]
```

## Consequences

- A single Compare column component also serves the planner package comparison (Silver | Gold | Royal 'Compare packages'), so it must be data-driven.
- Needs Brief-aware batch endpoints (price and availability for up to 3 venues; ADR 0004 quote endpoint).
- Arabic strings run longer and Eastern digits (if ever enabled, ADR 0010) are heavier, so the length budget is enforced in content review and the shaping-and-bidi golden sheet (ADR 0025).
- The tray and badge rules go into the design system as one component spec with states (ADR 0024).
- Metrics to track: adds, tray taps, table opens, Book from table, shares (events in ADR 0019 item 5; NF-MET-03 share of bookings that used comparison).
- The 'Official channel' column and '-' cells for government halls follow ADR 0002 D10.
- Share needs a server-rendered preview image and an unauthenticated read endpoint for compare ids.

## Alternatives considered

| Layout | Description | Verdict |
|---|---|---|
| **A. Fluid thirds, label above values** | Full-bleed three equal columns, sticky header, differences-only | **Chosen** |
| B. Pinned label column plus swiping venue columns (NN/g priority column) | Label column about 88px, then two and a half venue columns | Rejected: the third venue is always off-screen; horizontal swipes collide with iOS back (flipped in RTL) |
| C. Anchor-and-delta pager | One venue full width, the others as deltas ('+KD 300') | Rejected as primary: asymmetrical and harder to learn. Kept as a small 'At a glance' idea only |

Also rejected:

- **A Compare tab:** a transient task is not a destination (ADR 0007).
- **A permanent tray everywhere** (CA-CMP-03 literal reading): covers the sticky price bar and nags; replaced by the anti-nag rules in D3.
- **Highlighting identical rows instead of hiding them:** users prefer hiding identical attributes (Baymard).
- **'Largest hall' as best capacity:** misleads; best fit is closest to your guests at or above your count.
- **Green and red cell colours:** colour alone and moralising; a gold-ink dot only.
- **Silently dropping the oldest venue on a 4th add:** CA-CMP-02 requires a replace choice.

## Related requirement IDs

| ID | Effect |
|---|---|
| CA-CMP-01, CA-CMP-02, CA-CMP-03 | Max 3, replace sheet, persistent indicator (deviation recorded above) |
| CA-CMP-04..09 | Table, rows for price, guests, area, rating, buffet, parking, decoration, photos, packages, availability, distance |
| CA-CMP-10, CA-CMP-11, CA-CMP-12 | Book from the table, remove, persistence and merge |
| CA-CARD-10, CA-VDET-25 | Compare toggle on card and on detail |
| NF-ANL-03, NF-MET-03 | Comparison event; share of bookings that used comparison |
| NF-LOC-02 | Mirrored layout; first venue at inline-start |
| CF-09, CF-10 | Section-aware rows; government 'Official channel' |

## Related ADRs

ADR 0007 D1 and D8 (no Compare tab; guest gating of Compare), ADR 0014 item 7 (compare and lists in RTL), ADR 0018 item 7 (compact card variant for the tray), ADR 0019 (compare events).
